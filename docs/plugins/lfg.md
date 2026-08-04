# LFG (Looking for Game)

How LFG keeps every joiner out of Postgres, and the per-message `allowed_mentions`
rules that stop unwanted pings.

LFG stores **no personal data**: who joins a post lives only in the Discord message. State
is split by sensitivity. The **post identity** (creator, start timestamp, role) rides in the
button `custom_id` (`Lfg::CustomId`). The **dynamic content** (joiner list, optional note) is
read live off the message — `Lfg::PostMessage.render` builds a Components V2 container (heading,
optional note block, joiner block last) and `Lfg::PostMessage.parse` reads the joiner mentions
back out of the last text block and the note out of the middle one. The only Postgres rows are
**non-personal message references**: `Lfg::Message` (table `lfg_messages`, off `ServerConfiguration`
with `dependent: :delete_all`) holds `channel_id`, `message_id`, and the ids of the follow-up
messages we post for it (`notify_reply_id`, `start_ping_id`) — all Discord message snowflakes, no
user data. Writes go through `Ops::Lfg::Message::{Post,Update,Destroy}`. Cooldowns live in process
memory (`Lfg::Cooldown`, mirrors `Moderation::SpamTracker`). Both lifecycle jobs (`Lfg::StartJob`,
`Lfg::ExpiryJob`) are scheduled at creation with `set(wait_until:)`, never cancelled, and no-op on
a 404; on close/expiry the follow-up messages are deleted (their ids read from the row) and the row
is destroyed.

**allowed_mentions matrix (security-critical — the feature exists to stop unwanted pings):**
- create the post: role only — `{parse: [], roles: [role_id]}`, carried on the plain-content
  subject (subject-first flow so the ping + push preview fire, then `convert_to_v2` brands it).
- every post edit (joiner-list update): nobody — `convert_to_v2` sends `{parse: []}`.
- rolling notify reply (a join after start): creator only — `{parse: [], users: [creator_id]}`.
- start re-ping (`StartJob`): joiners only — `{parse: [], users: joiner_ids}`, never the role.

Every ping-bearing message uses the subject-first create (`Lfg::PingReply` for the replies)
because V2 edits never ping and have empty push previews.
