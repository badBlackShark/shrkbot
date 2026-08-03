# Commands and events

How a slash command or gateway handler declares itself, gets its permissions, and
reaches the right guilds.

discordrb is `require: false` — only `bin/bot` and `bin/jobs` load it. Commands and
events subclass `Bot::BaseCommand` / `Bot::BaseEvent` and auto-register via `.descendants`.

The whole bot layer lives under the `Bot::` namespace (`app/bot/`, pushed with
`namespace: Bot` in `config/application.rb`, mirroring `Ops`). Files are grouped into
`events/`, `config/`, and `registration/` subdirs that are Zeitwerk-**collapsed**, so a
handler at `app/bot/events/role_upsert.rb` is still `Bot::RoleUpsert`, not `Bot::Events::RoleUpsert`
— the directories organize the tree without deepening constants. `commands/` and `discord/`
stay real nested namespaces (`Bot::Commands::`, `Bot::Discord::`).

- `Bot::BaseCommand` declares metadata via class macros (`command_name`, `description`,
  `requires_permissions`, `owner_only`, `register_in`, `options`) and owns connection
  hygiene + uniform error handling. Subclasses implement `#execute`.
- `Bot::BaseEvent` declares its gateway event(s) via `on :event_name` (multiple allowed)
  and implements `#handle`.
- A command that defines `#autocomplete` auto-gets an autocomplete handler.

## Permissions

Permissions are native Discord permission bits declared per command via
`requires_permissions :moderate_members`; the registrar sends them as
`default_member_permissions`. Discord enforces them server-side, and guild admins can
retune access per role, member, or channel in Server Settings → Integrations. Those
overrides are authoritative — the bot does not re-check permission bits at runtime, or
it would veto users an admin deliberately allowed.

`owner_only` combined with the `OWNER_ID` env var remain runtime checks — a bot-level
concept Discord can't express. A command with no declaration is available to everyone.

## Registration context

Declared with `register_in`:

- `:guild` (default) — bulk-overwritten per guild on ready (`Bot::CommandBackfill`),
  server join (`Bot::CommandSetup`), and plugin toggle (Bot::ConfigBus `commands_sync`,
  published by `Ops::ServerConfiguration::Plugins::Toggle` for the dashboard's plugin
  cards and by `Ops::PluginConfiguration#save_activation!` for the enable switch on a
  plugin's own config page — a plugin's Configure operation must persist its activation
  through that helper, or its commands never appear). A
  command's `plugin :key` macro ties it to a `PluginCatalog` key; it only registers
  in guilds where that plugin (and its parent, if any) is enabled. Plugin-less guild
  commands register in every guild. Guild commands cannot appear in DMs.
- `:global` — registered once globally in production via `Bot::CommandRegistrar#define_global`.
  In development, global commands are folded into every guild's bulk-overwrite set for
  instant appearance (no ~1h propagation delay). Always-on; works in DMs.

`Bot::CommandRegistrar` notes:

- `define_commands: false` attaches handlers without redefining the (application-
  global) command definitions — under sharding only the first shard defines them.
- discordrb's `autocomplete(name)` matches the focused **option**, not the command,
  so we pass `command_name:` and match on that.

## The 3-second ack window

Discord gives roughly three seconds to acknowledge a component or slash
interaction. A handler that does slow REST work — an unban, a kick lookup, fetching
a user, opening and sending a DM, each its own round-trip — *before* its first
`event.respond`/`update_message` blows that window. The interaction token dies and
the eventual response raises `Unknown interaction` (API error 10062), which reaches
the person who clicked as an error DM from the bot.

So: if an interaction handler does any Discord REST between the click and its
reply, ack first, then work, then fill in.

- `event.defer(ephemeral: true)` immediately — that acks inside the window and buys
  a 15-minute edit window;
- do the slow work;
- `event.edit_response(content:)` with the outcome.

Fast handlers need none of this. A DB write followed by `event.update_message` or
`event.respond` (the confirm/dismiss/undo-verdict handlers on phash confirmations)
is fine as it stands, as is a plain rejection response that does no work at all.
`Moderation::UndoPunishment` — an unban plus an apology DM before responding — is
what originally tripped it.
