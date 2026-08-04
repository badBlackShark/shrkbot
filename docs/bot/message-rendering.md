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
