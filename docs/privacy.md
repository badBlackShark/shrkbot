# Privacy and data handling

What personal data shrkbot stores, how it is erased, and the rules a chunk that
stores new data has to satisfy.

The privacy policy (`config/locales/legal.en.yml`) is not marketing copy — every
promise in it is a binding implementation constraint. If a feature can't be built
within a promise, the policy changes in the same PR, and the doc's "Last updated"
date is bumped with it.

## The hard rule for new data

Any chunk that stores NEW data (a column, table, cache, or log line) must, in the
same chunk:

- update the **privacy policy** (`config/locales/legal.en.yml`) — what is stored,
  why, and for how long;
- extend **`Ops::Users::Destroy`** if the data is per-user (keyed by a user's
  Discord ID);
- cover the data in the **guild purge** — guild-scoped tables hang off
  `ServerConfiguration` with `dependent:` so the cascade *is* the purge;
  snowflake-keyed data with no association (reminders) gets explicit handling in
  `Ops::ServerConfiguration::Destroy`.

## Erasure paths

There are exactly two, and both live in an operation. No deletion logic goes in an
event handler.

**Account deletion** — `Ops::Users::Destroy`. Website-only; there is deliberately
no bot-side delete command (`/unremind` already covers bot-only users). It deletes
the user's reminders, their `TwilightStruggle::TournamentAdmin` rows, and the
`User` record.

**Guild purge** — `Ops::ServerConfiguration::Destroy`. Immediate on kick, no grace
period; discordrb already drops outage-flagged `GUILD_DELETE`, so handlers need no
unavailable-guard. Two callers, and only two:

- the `server_delete` event handler, and
- `Bot::ServerReconciliation`, the startup sweep, which REST-confirms each
  apparent kick before purging (discordrb's 10s ready timeout can fire `:ready`
  with an incomplete guild cache).

Everything guild-scoped is destroyed by the `ServerConfiguration` cascade.
Reminders are the one exception, because they are keyed on a snowflake rather than
associated, so the op handles them explicitly:

- channel-bound reminders are deleted;
- DM-bound reminders are kept, with `server_id` nulled — a DM reminder is the
  *user's* data, not the guild's;
- on a guild with `force_dm_reminders` set, channel-bound reminders are flipped to
  DM rather than deleted, because that guild had already elected DM delivery.

"Delete everything on leave" is deliberately not literal, for that reason.

## Standing decisions

- **OAuth scope is `identify guilds`.** Email was dropped from the scope and is
  never stored.
- **`channel_overwrites` member snowflakes are not scrubbed on account deletion.**
  They mirror live Discord permission state and a re-sync recreates them
  immediately; this is legitimate-interest processing, it is stated in the policy,
  and the rows are erased with the guild.
- **Moderation scans in memory only.** No message content, image, or
  extracted text is stored anywhere, including the OCR sidecar. Moderation log
  entries go to a Discord channel (stored by Discord, not by us) and dashboard
  records stay content-free. See [Server Shield](plugins/server-shield.md).
- **LFG stores no personal data.** Who joined a post lives only in the Discord
  message; the Postgres rows are message snowflakes. See [LFG](plugins/lfg.md).
- **Twilight Struggle result payloads are never written to a record.** They ride in
  a Solid Queue job's arguments and are swept out on a schedule; both retention
  windows are quoted in the privacy policy. See
  [Twilight Struggle](integrations/twilight-struggle.md).

See also [Adding a plugin](plugins/adding-a-plugin.md) § Privacy & data.
