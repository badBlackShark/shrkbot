# Adding a gateway event handler

Event handlers live in `app/plugins/<plugin>/events/<name>.rb` (Zeitwerk-collapsed to
`<Plugin>::<Name>`), or `app/bot/` for bot-level handlers. Subclass `Bot::BaseEvent`,
declare the discordrb event(s) with `on`, and implement `#handle`. Registration is
automatic — `bin/bot` registers every `Bot::BaseEvent.descendants` that declares an event.

```ruby
module Welcomes
  class MemberJoin < Bot::BaseEvent
    on :member_join

    def handle
      setting = Settings.active_for(event.server.id)
      return unless setting&.channel_id.present?
      return if setting.join_message.blank?

      content = Message.render(
        setting.join_message,
        user: event.user.mention,
        member_count: event.server.member_count
      )
      event.bot.send_message(setting.channel_id, content)
    end
  end
end
```

## Notes

- `on :a, :b` accepts multiple events; the handler is registered for each. The names
  are discordrb `Bot` event methods (`member_join`, `channel_create`, `server_role_update`, …).
- `#handle` runs inside a checked-out AR connection and a rescue that logs and DMs the
  owner. There's no interaction to reply to, so a failure is swallowed after logging —
  a silently-failing event write surfaces only in the bot log.
- Multiple handlers can subscribe to the same event (e.g. `:channel_delete` has both
  metadata pruning and plugin-disable handlers); keep distinct concerns in distinct classes.
- For plugins gated by an enable flag, check it at the top of `#handle` (a DB read) —
  event handlers aren't hidden the way guild commands are. See `Settings.active_for`.

## Mirroring guild state (roles, channels, …)

When an event exists to keep a local table in step with Discord, handle **the one
entity the event names** — never re-read the whole guild. Discord fires one event per
entity that changed, so a reorder of N roles or channels arrives as N events; answering
each with a full-guild resync makes it N² writes, which exhausts the bot's AR pool and
turns one drag into a storm of `ActiveRecord::ConnectionTimeoutError`.

The shape, established by roles and channels:

- An abstract base (`Bot::RoleEvent`, `Bot::ChannelEvent`) resolves the guild's
  `ServerConfiguration` via `Bot::FindsServerConfiguration`, returns when there is none,
  and delegates to an abstract `#apply(config)`. It calls no `on`, so `EventRegistrar`
  (which filters on `registrable`) never registers it.
- One subclass per direction: `…Upsert` for create/update, `…Removal` for delete. They
  are separate classes because discordrb's create/update events carry the full object
  while the delete event carries only a snowflake — a single handler would have to
  branch on event shape.
- Single-entity operations (`Ops::…::{Upsert,Destroy}`) alongside the bulk `Sync`, with
  the attribute mapping shared through an `Attributes` module so the two paths can't drift.

Keep the bulk `Sync` op. `Bot::GuildMetadata.sync` still calls it on `ready` and
`server_create`, and that reconciliation is the backstop that heals anything a dropped
event missed — including deletions, via its prune of rows Discord no longer reports.
Do **not** implement `Sync` by looping the single-entity op: its preloaded `index_by`
is what keeps it off an N+1, and Prosopite (`raise = true` in every spec) will catch you.

## Component interactions (buttons, selects)

`on` forwards keyword attributes to the discordrb handler, so component events filter
by `custom_id`: `on :button, custom_id: /\Aroles:pick:/` or
`on :string_select, custom_id: /\Aroles:select:/`. discordrb routes each interaction to
the handler whose `custom_id` regexp matches, so one custom-id namespace can fan out to
several handler classes. The event exposes `custom_id`, `values` (selects), `user`,
`server`, and `respond`/`update_message` (acknowledge the interaction — `respond` for a
new ephemeral reply, `update_message` to edit the message the component is on). See
`app/plugins/roles/events/`, where a thin `Roles::ComponentHandler` base shares the
set lookup, member resolution, and role-diff application across the manage/pick/select
handlers.

## Spec it

Drive `#handle` with a fake/`double` event and assert the effect (a send, a DB write).
Mock the Discord seam, not discordrb internals. See `spec/plugins/welcomes/events/`.
