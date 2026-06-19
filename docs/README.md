# shrkbot docs

Design and how-to documentation for the Ruby/Rails rewrite of shrkbot.

- [architecture.md](architecture.md) — system overview: processes, persistence, the operations layer, plugin model, command/event registration, guild metadata sync, sharding.
- [adding-a-plugin.md](adding-a-plugin.md) — how to add a new plugin.
- [adding-a-command.md](adding-a-command.md) — how to add a slash command.
- [adding-an-event.md](adding-an-event.md) — how to add a gateway event handler.

## Standing rule

Non-obvious architectural decisions live here, not in code comments. When you make
such a decision, document it in the relevant doc; when it changes, update the doc.
Code comments are reserved for future-step markers (removed when the work lands).
