# Config propagation

How a config change made on the website reaches the running bot process, and the
five events that bus carries.

Config is written on the web side, but anything that touches Discord (posting a
role message, re-registering commands) can only run in the bot process, which
holds the gateway and token. The two are bridged by a one-way Redis pub/sub bus:
the web UI publishes, the bot subscribes.

`Bot::ConfigBus` (`app/bot/config/config_bus.rb`) publishes typed JSON events on a single
channel (`shrkbot:config`); `Bot::ConfigSubscriber` (`app/bot/config/config_subscriber.rb`)
runs a listener thread on the first shard's bot, routes each event by `type`, and
hands off to an operation inside a `with_connection` block (its own AR
connection, like every other bot thread). A malformed or failing event is logged
and reported to the owner rather than killing the listener.

Five event types are currently defined:

- **`commands_sync`** — published with a `discord_id` whenever a plugin is toggled
  for a server. The bot calls `Bot::GuildCommandSync#sync` for that guild, re-running the
  filtered bulk-overwrite so the command list reflects the new plugin state immediately.
- **`roles_post`** — published per surviving role set after a successful web save
  when the roles plugin is enabled. The bot calls `Roles::MessagePoster.post`,
  which edits the set's existing message in place if `message_id` is set, or
  creates a new one (idempotent).
- **`roles_message_delete`** — published with raw channel/message snowflakes.
  Fired for destroyed sets and sets whose effective channel changed (default channel
  change or `channel_override` change). Carries enough information for the bot to
  delete without loading the set record.
- **`roles_menu_remove`** — published per set (carrying `set_id`) when the plugin
  is disabled and the set's channel has not changed. The bot loads the set, deletes
  the Discord message, then clears `message_id`. Crucially, `message_id` is kept in
  the DB at save time so the `:ready` reconcile sweep can act on it after downtime.
- **`roles_repost`** — published by the per-set "Resync" button on the web UI,
  the force-fresh recovery path. Always deletes the stale message and reposts; use
  this to recover stale edits that happened while the bot was down.

Publishing is handled by `Roles::MenuSyncPlan`, which accumulates deletes and
posts during the reconcile phase and flushes them after the transaction commits.
Delivery is fire-and-forget. On the subscriber side, failing Results are logged
(they are not silently dropped). If `REDIS_URL` is not set, `Bot::ConfigBus.publish`
logs a warning and drops the event rather than raising.

The dashboard's instant plugin toggle (`Ops::ServerConfiguration::Plugins::Toggle`)
publishes the same `roles_post`/`roles_menu_remove` events via `Roles::MenuToggle`
when the roles plugin is toggled, so the menu-iff-enabled rule holds on both save
paths (config-page Save and dashboard toggle). `Roles::MenuToggle` delegates to
`Roles::MenuSyncPlan` so delivery semantics are identical.

`Roles::MenuReconcile` (a `:ready` event handler) sweeps guilds this shard serves
in both directions:
- **Post missing** — `message_id: nil` sets on enabled plugins (catch-up for saves
  while the bot was offline).
- **Remove lingering** — sets with a non-nil `message_id` on *disabled* plugins
  (catch-up for disables that fired `roles_menu_remove` while the bot was down).
Stale edits from downtime are recovered manually via the Resync button.

Add a new event by publishing a new `type` and adding a branch to
`Bot::ConfigSubscriber#route`.

The bot starts the subscriber only when `REDIS_URL` is set; without it the bot
logs that propagation is off and runs anyway (Solid Queue is Postgres-backed and
doesn't depend on Redis).

## Bot settings vs server configuration

`BotSetting` is the global KV/flags table (e.g. `owner_error_dms`) — bot-wide, string
keys. `ServerConfiguration` is per-server. Don't confuse the two.
