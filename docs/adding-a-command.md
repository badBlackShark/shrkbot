# Adding a slash command

Commands live in `app/plugins/<plugin>/commands/<verb>.rb` (Zeitwerk-collapsed, so
the file maps to `<Plugin>::<Verb>`). Global commands that aren't part of a plugin
(e.g. `/info`) live in `app/bot/commands/`. Subclass `BaseCommand`, declare metadata
with the class macros, and implement `#execute`. Registration is automatic —
`bin/bot` registers every `BaseCommand.descendants` with a `command_name`.

```ruby
module Reminders
  class Remind < BaseCommand
    command_name :remind
    description "Remind you about something later."
    register_in :global              # :guild (default) or :global
    requires_permissions :moderate_members   # omit for everyone; native Discord bits

    options do |opts|
      opts.string("duration", "How long from now, e.g. 1d2h30m", required: true)
      opts.string("message", "What to remind you about", required: true)
    end

    def execute
      result = Ops::Reminders::Create.call(
        server_id: event.server_id,
        user_id: event.user.id,
        channel_id: event.channel_id,
        duration: event.options["duration"],
        message: event.options["message"]
      )
      return event.respond(content: result.errors.join("\n"), ephemeral: true) if result.failure?

      event.respond(content: "⏰ Reminder set.", ephemeral: true)
    end
  end
end
```

## Macros

- `command_name "x"` — required; the slash command name. A subclass without it is skipped.
- `description "…"` — shown in Discord and reused on the website. Write it well; it's user-facing.
- `register_in :guild | :global` — `:guild` (default) bulk-overwrites per server on
  ready/join/plugin-toggle; a guild command only appears in servers where its plugin
  (and that plugin's parent, if any) is enabled. `:global` is registered once globally
  and works in DMs. See [architecture.md](architecture.md#registration-context).
- `plugin :key` — optional; ties a guild command to a `PluginCatalog` key so it only
  registers in guilds where that plugin is enabled. Omit for always-on guild commands
  (e.g. `/ping`).
- `requires_permissions :a, :b` — native Discord permission symbols; all must be held.
  Omit for an everyone-command. The `OWNER_ID` env var is a global override.
- `owner_only` — restrict to the configured owner.
- `options { … }` — a discordrb `OptionBuilder` block (`string`/`integer`/`boolean`/`user`/`subcommand`/…).
- `command_type :chat_input | :message | :user` — defaults to `:chat_input` (the
  slash command above). `:message`/`:user` register a **context-menu** command: the
  `command_name` becomes the right-click menu label (so it can contain spaces, e.g.
  `command_name "Report as scam"`), and the command carries no description or options
  (both are dropped automatically). Read the target inside `#execute` via
  `event.target` — the selected message for `:message`, the selected user for `:user`.

## The execute contract

- `#execute` runs inside a checked-out AR connection (`BaseCommand` handles pool
  hygiene) and a uniform rescue that logs, DMs the owner, and replies with an error.
- Parse options, call an operation, present the result. Keep logic in the operation —
  commands stay thin.
- `event` exposes `options` (name→value hash), `user.id`, `channel_id`, `server_id`
  (nil in DMs), `respond(...)`, and `bot`.

## Autocomplete

Define `#autocomplete` and it's wired automatically:

```ruby
def autocomplete
  matches = Reminders::Reminder.for_user(event.user.id)
  event.respond(choices: matches.to_h { |r| [r.message, r.id] })
end
```

## Spec it

Put Discord-touching code behind a seam and mock the seam, not discordrb internals.
Drive `#execute` with a fake/`double` event; assert the operation is called and the
response. See existing command specs under `spec/plugins/*/commands/`.
