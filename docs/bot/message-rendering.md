# Message rendering (Components V2)

The single seam every Discord message goes through, and the subject-first trick
that keeps push notifications readable.

`Bot::Discord::Components` (`app/bot/discord/`) holds the shared Components V2 primitives —
the `CONTAINER`/`TEXT_DISPLAY`/`SEPARATOR` type ids, the `COMPONENTS_V2` flag, and the
`container`/`text`/`separator` builders — so every sender (role messages, `/info`, the
owner broadcast, the onboarding DM, activity-log entries) renders the same way and the
brand colour lives in one place (`Bot::Config::ACCENT_COLOR`, the container default).
External links on a command response go in link buttons under the message, not inline
markdown: `container(blocks, buttons: [Components.link_button(url:, label:), …])` appends
an action row as a sibling after the container (see `/info` and `/donate`).
`Components.send_to(channel, rendered, allowed_mentions:, subject:)` owns the positional
`channel.send_message` shape (nil content + components + flags), so call sites never
enumerate the discordrb signature; only `Reminders::DeliverJob` sends over raw REST
(no gateway in the jobs process) and keeps its own `create_message` call.
Components V2 messages carry no `content`, so their push notifications have an empty
preview — proactive sends (reminders, the owner broadcast, the onboarding DM) therefore
pass a `subject:`: the wrapper sends it as plain content (the notification fires on
create with that preview), then `convert_to_v2` edits the message into the container
(explicit null content + the `COMPONENTS_V2` flag — Discord only allows this conversion
plain→V2, never back). A failed conversion is logged and leaves the readable plain
message standing; `DeliverJob` shares `convert_to_v2` after its REST `create_message`.

## Mentioning a user

A Discord client resolves `<@id>` against a lazily-filled local member store, and the
user objects in a message payload's `mentions` array are one of the two things that
fill it. `allowed_mentions` decides that array, so a mention posted under
`{parse: []}` renders as `@unknown-user` for every viewer whose client never met the
user — permanently, for a member who was banned before that client ever saw them. A
message that names a user therefore does two things: it allows that user in
`allowed_mentions`, and it prints the name next to the mention
(`Moderation::UserLabel.for` renders `mention (username)`) so the entry still reads
after a rename or a deleted account. Whether the allowed mention also fires a real
ping is the caller's decision to make and to defend: the moderation log allows the
offender because a private log channel delivers no notification to them, while
`Welcomes::JoinAnnouncement` allows the joiner and sets `SUPPRESS_NOTIFICATIONS`
(`1 << 12`) instead, so the mention resolves without a sound.

The subject-first flow makes this two API calls, and **a mention allowed on both of
them can ping twice**. `send_to` therefore splits the allow-list: the plain create
gets the caller's `allowed_mentions` verbatim, and `convert_to_v2` receives only its
`users:` entries. Roles are dropped there because a ping-bearing subject already
mentioned the staff or game role in its own text. User mentions survive into the edit
because they live in the container body, which the create never contained, so the
edit is the first call that can put them in the `mentions` array. When adding a
mention to any message, work out which of the two calls carries it and allow it on
that call alone. Senders that skip the subject (an activity-log entry with no staff
ping, a role message) take the plain `send_message` branch, where the allow-list
applies once, and the three direct `convert_to_v2` callers (`Lfg::PingReply`, the LFG
join refresh, `DeliverJob`) ping from their own create and keep the suppressed default
on the edit.
