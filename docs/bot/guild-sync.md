# Guild sync and onboarding

How a guild's channels and roles get into Postgres, and what happens the first
time — or the next time — the bot sees a server.

## Guild metadata sync

A user's OAuth token can list their guilds but generally can't enumerate a guild's
channels/roles (those are bot-token endpoints). So the bot syncs guild metadata to
Postgres on guild events, and the web app reads our own DB. The web never holds the
bot token.

Models (`belongs_to :server_configuration`; snowflakes as bigint): `ServerChannel`
(discord_id, name, channel_type — not `type`, which AR reserves), `ServerRole`,
`ChannelOverwrite` (full raw `allow`/`deny` bits + target_id/target_type). Sync ops
(`Ops::ServerConfiguration::ServerChannels::Sync`/`ServerRoles::Sync`) take plain data (arrays of
hashes), not discordrb objects, so they stay unit-testable; the discordrb→hash
extraction lives in `Bot::GuildMetadata` (the bot-layer boundary). Each sync is a full
upsert + prune of stale rows.

`Bot::GuildMetadata.sync` ensures the config, then syncs channels and roles, then
reconciles deleted channels — in one method, because the `server_create` handler
order isn't fixed and the populate ops always need a config to attach to. It also
caches guild display metadata (name, icon hash, member count) on `server_configurations`
via `Ops::ServerConfiguration::Metadata::Sync`, so the web UI can render server identity
without a live Discord API call when the API is temporarily unreachable.

`ServerChannel#everyone_visible?` is the @everyone-visibility heuristic behind the
logging-channel warning. The @everyone role's id equals the guild id. It checks the
channel-level overwrite only and ignores category inheritance, so it's advisory.

## Channel-delete handling

Two paths, kept as separate handlers:

- Live: `Bot::ChannelCleanup` (on `:channel_delete`) handles channel-backed plugins whose
  channel was deleted.
- Startup: `Ops::ServerConfiguration::Channels::Reconcile` catches channels deleted
  while the bot was offline (no live event fired). It runs after a metadata sync, so
  `server_channels` reflects what still exists, and delegates each stale channel to
  the same handler.

Both paths call `Ops::ServerConfiguration::Channels::HandleDeletion`, which: clears
the setting's `channel_id` (nulls it), keeps the plugin **enabled**, creates a
`channel_deleted` notification, and DMs the guild owner. The plugin stays enabled so
the config page stays accessible; `enabled && channel_id.nil?` is the "channel lost"
signal. The config page shows an inline warning banner until the owner picks a new
channel.

## Server onboarding

A server's config + activation rows are ensured from two triggers, because discordrb
**suppresses `server_create` for guilds the bot is already in at startup** (its
GUILD_CREATE handler returns before raising the event when `unavailable` is `false`):

- `Bot::ServerSetup` (on `:server_create`) — a genuine live join.
- `Bot::ServerBackfill` (on `:ready`) — sweeps `bot.servers` once, covering guilds joined
  while the bot was down.

`Ops::ServerConfiguration::Ensure` is add-only and idempotent (race-safe via the
unique `discord_id` index), so both triggers can call it freely. Activation rows seed
disabled; the admin enables plugins via the web UI, which enforces prerequisites.

Ensure also creates each plugin's settings row (empty — all columns are nullable or
defaulted). This establishes the invariant that **a server's config and its plugin
settings rows always exist**, so settings operations can update the row directly
instead of build-or-update. (Event handlers reading config for an arbitrary guild
still guard against a nil config — a server seen before its Ensure has run.)

`Bot::GuildMetadata.sync` then calls `Bot::ServerOnboarder.notify`, which DMs the guild owner a
welcome once and stamps `ServerConfiguration#onboarded_at`. Because it runs inside the
shared sync path, it fires from both triggers — so every server is onboarded exactly
once, including servers that were already present when the rewrite first goes live
(the `:ready` sweep). The `onboarded_at` stamp is what keeps it once-per-server rather
than once-per-boot, and a send failure (owner blocks DMs) is swallowed and left
un-stamped so a later boot retries. The DM links the owner to `WEB_BASE_URL/servers/:discord_id`
(their guild's dashboard); the link is omitted when `WEB_BASE_URL` is unset.
