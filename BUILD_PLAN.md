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

## Phase 6 — Web: auth  ⟶ DONE (part 1 #52, part 2 #56 — pending merge)
- OmniAuth Discord (`identify email guilds`) + CSRF; `User` + session. **DONE (#52)** — `User` (PK `usr_`), `SessionsController`, `current_user`. **Phlex** view layer (`phlex-rails`; renders into the ERB layout). Live login verified.
- Manageable-server list. **DONE (#56).** `Discord::UserGuilds` seam (`GET /users/@me/guilds`, stdlib Net::HTTP, mocked) + `Discord::Guild` value object (`manageable?` = owner OR ADMINISTRATOR(0x8)/MANAGE_GUILD(0x20)); `ServersController` intersects with `ServerConfiguration`. Token in the session; 401 → auto re-auth via a Stimulus-submitted OAuth POST (one-shot loop guard); session bounded (`expire_after: 2.weeks`). Picker in Phlex (icons + invite + empty state), `require_login`, `/` → `/servers` when signed in. Also fixed dev/test DB sharing (test derives `<db>_test`).
- **GATE:** login works (done); correct server list shown (done) — live gate is Tim's.

## Phase 7 — Web: config UI (the big one)
**Design delivered + unpacked at `docs/design/`** (`README.md` = system guide + voice; `ui_kits/dashboard/index.html` = click-through kit with EVERY screen; `tailwind/theme.css` = the v4 `@theme` block; `tokens/*` = source CSS custom props incl. dark + motion; `foundations/*` = specimens; self-hosted woff2 under `fonts/`+`packages/`). The HTML mockups are throwaway prototype wiring (Google-Fonts/Lucide/Tailwind-Play CDNs); the **token files + `@theme` are the production spec**. Port the kit ~1:1 into Phlex + Stimulus; auto-save via Turbo; dropdowns via Tom Select.

Locked design facts/decisions:
- **Fonts (self-hosted; woff2 ship in the bundle):** display = **Space Grotesk** (variable 300–700), body = **IBM Plex Sans** (400/500/600/700), mono = **IBM Plex Mono** (400/500). `tokens/fonts.css` `@font-face` is the production source — copy woff2 into the app (Propshaft), rewrite `url('../…')` → asset paths, DROP the Google-Fonts CDN. (README/`typography.css` comments saying Hanken/JetBrains are STALE; the binaries + `--font-*` values are Plex/Space Grotesk.)
- **Tokens:** add `tailwind/theme.css`'s `@theme` AFTER `@import "tailwindcss";` → `bg-brand-500` (#39afe5), `text-ink-600` (cool neutral, named `ink` to dodge Tailwind's `slate`), semantic + `-soft`, `rounded-{sm,md,lg,xl}`, `shadow-{xs,sm,md,lg}`, `font-{display,sans,mono}`. Tailwind v4 must scan Phlex `.rb` (`@source` the views/components dirs) or utility classes in Ruby literals get purged.
- **Dark mode (REAL WORK — specced but UNBUILT):** `[data-theme="dark"]` on `<html>` swaps CSS custom props (semantic aliases, `tokens/colors.css` ~ll.99–124; brand `#39afe5` unchanged; surfaces GitHub-dark). The `@theme` ships light-only; the documented raw-channel-variable path (so `text-ink-600` responds with NO `dark:` variants) is NOT implemented — build it. Toggle in the app-shell top bar; persist via `localStorage` `shrk-theme` (Stimulus); set the attr server-side to avoid FOUC. (Mock's `!important` overrides are throwaway.)
- **Motion (CSS-only):** `--dur-fast 120ms`/`--dur-base 180ms`/`--dur-slow 260ms`, `--ease-standard cubic-bezier(.2,0,0,1)`. Patterns (`tokens/motion.css`): `btn-fill` (hover fill L→R via `::after` scaleX), `card-lift`, `menuEnter`, `slideUp` (toast), `fadeIn` (gate). `prefers-reduced-motion: reduce` already handled — preserve it.
- **Icons = Heroicons** (gem, inline SVG), NOT the kit's Lucide. Plugin icons: Roles `users-round`, Welcomes `hand`, Logging `scroll-text`, Reminders `alarm-clock`. UI: chevron-down/right, chevrons-up-down, check, plus, arrow-right/left, log-in/out, shield, lock, info, triangle-alert, refresh-cw, search, grip-vertical, pencil, trash, sun/moon, check-circle, anchor.
- **CSP:** once ported (self-host fonts, compiled Tailwind, no CDN) keep `font/script/style-src 'self'`; `img-src` needs `https://cdn.discordapp.com` (server icons/avatars).
- **Voice (first-class copy):** shrkbot always lowercase; sentence-case headings, Title Case labels; NO em dashes; explain *why* on disabled/blocked states; slash commands in mono.

Suggested chunk sequence (one PR each):
1. **Design foundation** — self-host fonts + `@font-face`; integrate `@theme`; `@source` for Phlex scanning; motion CSS + reduced-motion; **build the dark-mode token swap** + theme-toggle Stimulus (localStorage + server-side attr); Heroicons gem + icon helper. Gate: a sample page renders in brand type/colors, dark toggle works, motion respects reduced-motion.
2. **App shell + reusable patterns** — `Components::AppShell` (top bar: wordmark, server switcher w/ search, Saved pill, dark toggle, user menu w/ Log out + Owner-admin link); every authed view renders into it; **move sign-out off the picker into the shell** (delete the temporary button). Reusable Phlex+Stimulus: switch/toggle, segmented control, enable-gate (overlay + dimmed inert content), setting row + inline warning, Tom Select wrapper (channel `#`-prefix + role color-dot + **disabled-with-reason**: lock + `title` tooltip), save feedback (Turbo auto-save → toast + Saved pill), flash/toasts.
3. **Restyle the server picker** to the kit (cards, Heroicons, real Discord icons; add `?with_counts=true` to the guilds seam for member counts; "N plugins on" badge; styled empty state).
4. **Server dashboard** — 3 plugin rows (icon tile, status badges Enabled/Needs-setup/Off, Configure entry, enable toggle) + server-level **force_dm_reminders** row + the `/remind`-only note.
5. **Plugin config pages** (shared template):
   - **Logging** — channel Tom Select + @everyone-visibility warning + the **event-toggle matrix** (events grouped by plugin, off by default, whole matrix gated when Logging off). NEEDS the F4 toggle surface: a setter op for `logging_settings.enabled_actions` (jsonb) + an **enumerable per-plugin catalog of loggable events** to render the toggles (none exists yet — build it; bot already writes via `ActivityLog`, keyed `<plugin>.<event>`).
   - **Roles** (hardest) — default channel; set list + set editor (name, single/multi **segmented control**, channel-override select, assignable-roles Tom Select with **grey-out of unassignable roles** via synced `bot_role_position`/`position`/`managed` (#51) + a "why" warning; UI-prevention only, op still fails gracefully); per-set **re-post** → `ConfigBus.repost_roles` (#46, wired). Reorder: kit shows a drag handle but NO drag JS — decide drag→`Ops::Roles::Sets` reorder vs leave position-by-add (assignable-role order already settled = position, not draggable).
   - **Welcomes** — channel + join/leave textareas + placeholder helper (`{user}`,`{membercount}`) + **live Discord-styled preview** (Stimulus: `{user}` → mention pill in JOIN, plain `@username` in LEAVE; `{membercount}` → number; empty textarea = "disabled" hint).
6. **Owner-only admin page** (owner-id-guarded) — owner-DM toggle (`BotSetting.owner_error_dms`), deferred from Phase 3.
7. **i18n** — web strings through Rails I18n (idiomatic, ~free); bot stays English.
- Deferred/optional: per-plugin **docs page** (introspect `BaseCommand.descendants` + `requires_permissions`) — not in the design kit, lower priority.
- **GATE:** toggle a plugin, set a log channel, configure a role set (incl. grey-out) — persist + validate; dark mode + auto-save + enable-gate work end-to-end.

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
