# shrkbot rewrite — build plan

Crystal/discordcr → Ruby 4.0.5 / Rails 8.1 / discordrb. One codebase, processes: `web` (Puma), `bot` (discordrb gateway), `sidekiq`, `postgres`, `redis`. See the design-decision log for rationale; this is the sequenced execution.

Each phase ends with a **verification gate** — don't advance until it passes. Phases 2–3 and 6 can overlap once 1 is done.

---

## Phase 0 — Scaffold & toolchain
- Work on a branch off `master`. `rails new` **in place** at repo root (adds Rails alongside Crystal), then delete Crystal artifacts (`src/`, `shard.yml`, `shard.lock`, `shard.override.yml`, `spec/`, `Dockerfile` Crystal bits) in the same branch — preserves git history.
- `rails new . --css=tailwind --database=postgresql` (Ruby 4.0.5, Rails 8.1.x, Puma 6+).
- Gemfile: `discordrb`, `sidekiq`, `omniauth`, `omniauth-discord`, `omniauth-rails_csrf_protection`, `dotenv-rails`, `pg`, `redis`. Import-map pins: `turbo`, `stimulus` (default), `tom-select` (+ CSS vendored/CDN).
- Env vars (dotenv dev): `DISCORD_TOKEN`, `CLIENT_ID`, `OWNER_ID`, `DISCORD_CLIENT_ID`, `DISCORD_CLIENT_SECRET`, `DATABASE_URL`, `REDIS_URL`.
- **GATE:** `bundle install` compiles discordrb's native deps (ffi, websocket-client-simple) on Ruby 4.0.5; `rails s` boots; Tailwind renders. (This is where the flagged native-ext risk surfaces, if anywhere.)

## Phase 1 — Data model & migrations
- `ServerConfiguration` (+ `force_dm_reminders:boolean`).
- `Plugin` catalog (+ seed: logging, roles, welcomes) + `PluginActivation(server_configuration, plugin, enabled:boolean)`; `has_many :plugins, through:`; `enabled_plugins` scope.
- Synced-metadata models: server channels, roles, channel permission overwrites (bot writes, web reads).
- Plugin settings models: `Plugins::Logging::Settings(channel_id)`, `Plugins::Roles::{Settings, AssignableRole}`, `Plugins::Welcomes::Settings(channel_id, join_message, leave_message)`, `Plugins::Reminders::Reminder(server_id NULLABLE, user_id, channel_id, remind_at, created_at, message, deliver_via_dm)`.
- Validations: logging channel @everyone-visibility warning; "can't enable plugin without required settings".
- Zeitwerk collapse for `app/plugins/*/commands` + `/events`.
- **GATE:** migrations + seeds run; model specs (house RSpec style) green.

## Phase 2 — Bot infrastructure (`app/bot/`)
- `BaseCommand` + `with_connection` concern (pool hygiene, uniform error handling); `BaseEvent` shares the concern.
- Registrar: eager-load, iterate `BaseCommand.descendants`, register with discordrb.
- `Plugins::X` metadata DSL → feeds catalog seed + registration + docs page.
- `requires_permissions` macro → sets `default_member_permissions` + centralized runtime check; `OWNER_ID` = creator override.
- Registration context (#23): `:guild` (default, re-sync on enable) vs `:global` (contexts=[GUILD,BOT_DM]).
- `bin/bot` runner (`require config/environment`; eager_load; `bot.run`). Connection-pool sizing.
- Presence/status updater (guild_create/delete → "Listening to /help • N servers").
- **GATE:** bot connects to a test server; a trivial command responds; permission gating + hiding work.

## Phase 3 — Operations layer (`app/operations/`)
- Base operation (mirror the team's existing result/errors convention — point me at one to match), transaction-wrapped.
- `ModLog` service (no-op if logging disabled / no channel).
- Operations: `TogglePlugin`, `SetLoggingChannel`, `CreateReminder`, `DeleteReminder`, `ToggleAssignableRole`, welcomes settings update, etc. Shared by bot + web.
- **GATE:** operation specs green.

## Phase 4 — Plugins (bot side)
- **Reminders** (`:global`): `/remind` (duration parse + sanitization), `/reminders`, `/unremind` (autocomplete). Sidekiq `DeliverJob` (`perform_at`, idempotent guard). `force_dm_reminders` resolved at delivery. `distance_of_time_in_words`.
- **Roles**: multiple assignable-role *sets* per server (plugin-level default channel + optional per-set channel override; per-plugin notify/log). Each set posts its own public message with a "Manage your roles" button → ephemeral, per-user picker showing current state: `single` sets use buttons (exclusive — picking one strips the set's others), `multi` sets use a `string_select` (current roles pre-checked, diff on submit). Component handlers toggle/diff + re-render; re-post/edit on config change. Backend (op + handler) **fails gracefully** if asked to assign a role the bot can't (above its top role / Manage Roles missing) — guards against forged requests; the UI prevents it for normal users (see Phase 7). Carries the per-plugin metadata DSL + prerequisite-validation hardening + `ModLog`/notify hooks.
- **Welcomes**: `guild_member_add`/`remove` handlers; placeholders `{user}`, `{membercount}`.
- **Logging**: `ModLog` sink (already from Phase 3).
- `/info`, `/donate`, `/sendOwnerMessage` (creator-only).
- **GATE:** each verified in a test server.

## Phase 5 — Guild metadata sync
- Bot writes channels/roles/permission-overwrites to DB on guild events + on change.
- Role sync must also capture each role's `position` + `managed`, and the bot's highest-role position, so the Phase 7 role configurator can grey out roles the bot can't assign. (Done for channels/roles/overwrites; `position`/`managed`/bot-top-role still TODO — add when building Roles.)
- **GATE:** test server's channels/roles/overwrites reflected in DB.

## Phase 6 — Web: auth  ⟶ PART 1 DONE (#52), PART 2 IS THE CURRENT NEXT STEP
- OmniAuth Discord (`identify email guilds`) + CSRF; `User` model + session. **DONE (#52)** — `User` (PK `usr_`), `SessionsController`, `current_user`. **Phlex** introduced as the view layer (`phlex-rails`; renders into the ERB layout). Live login verified by Tim.
- Manageable-server list = user is admin/Manage-Server ∩ bot present. **← NEXT (part 2).** `GET /users/@me/guilds` with the OAuth bearer token (behind a seam, mocked in specs); manageable = owner OR ADMINISTRATOR(0x8)/MANAGE_GUILD(0x20) ∩ `ServerConfiguration.exists?`. Server-picker page in Phlex; add `require_login` + memoize `current_user`.
- **GATE:** login works (done); correct server list shown (part 2).

## Phase 7 — Web: config UI
- **Design brief at `docs/design-brief.md` (#54)** — hand to Claude Design (repo-connected); apply its HTML+Tailwind output as Phlex components.
- One page per plugin: Turbo auto-save, reusable Stimulus enable-gate controller, Tom Select dropdowns (channels/roles from synced metadata).
- Roles configurator: grey out / disable roles above the bot's highest role (and `managed` roles) in the selector, with a tooltip explaining why. UI prevention only — NOT a backend constraint; the op still fails gracefully on a forged request asking for an unassignable role.
- Per-plugin docs page (introspect command registry + `requires_permissions`).
- Server-level settings (`force_dm_reminders`).
- Web UI strings go through Rails I18n (idiomatic, ~free). Bot stays English.
- Deferred TODOs to land here: **F4 logging tab** (a setter op for `logging_settings.enabled_actions` + an enumerable per-plugin catalog of loggable events to render the toggles — none exists yet; enabling an event is DB-only until then); **owner-only admin page** (owner-DM toggle, deferred from Phase 3 awaiting auth). Roles grey-out data is ready (`bot_role_position`/`position`/`managed`, #51).
- **GATE:** toggle a plugin, set a log channel, configure roles — all persist + validate.

## Phase 8 — Wiring: Redis pub/sub + Sidekiq
- Web publishes config-change events; bot subscribes → re-register guild commands / re-render role message / reload settings.
- Sidekiq: reminder delivery + command re-sync jobs.
- **GATE:** change config in web → bot reacts (commands re-registered, role message updated) within seconds.

## Phase 9 — Deploy: docker-compose
- Services: postgres, redis, web, bot, sidekiq off one image. Dockerfile (Ruby 4.0.5, Puma 6+). Healthchecks. Env wiring.
- **GATE:** `docker compose up` brings the full stack live; bot online; web reachable; a reminder fires end-to-end.

---

### Dependency spine
0 → 1 → (2 ∥ 3) → 4 → 5 → 6 → 7 → 8 → 9. Web auth (6) can start once 1 is done. Metadata sync (5) must precede the Tom Select dropdowns in 7.
