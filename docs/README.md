# shrkbot docs

Design and how-to documentation for the Ruby/Rails rewrite of shrkbot.

- [architecture.md](architecture.md) — system overview: processes, persistence, the operations layer, plugin model, command/event registration, guild metadata sync, activity logging, sharding.
- [adding-a-plugin.md](adding-a-plugin.md) — how to add a new plugin.
- [adding-a-command.md](adding-a-command.md) — how to add a slash command.
- [adding-an-event.md](adding-an-event.md) — how to add a gateway event handler.
- [design-system.md](design-system.md) — how the design system (fonts, tokens, dark mode, motion, icons) is wired into the web UI.

## Public API docs

The APIs we expose to partner sites are documented at
[badblackshark.github.io/shrkbot](https://badblackshark.github.io/shrkbot/),
published by the `api_docs` CI job on every push to `main`.

Their source is the OpenAPI document itself, not a parallel prose doc: schema
fragments in `config/api/twilight-struggle/v1/*.yaml`, long-form prose (overview
and per-resource narrative) in `config/api/twilight-struggle/v1/docs/*.md`, and
the index page listing the APIs in [site/index.html](site/index.html). Anything
an integrator needs to know belongs in one of those — edit them together with
the endpoint they describe.

## Standing rule

Non-obvious architectural decisions live here, not in code comments. When you make
such a decision, document it in the relevant doc; when it changes, update the doc.
Code comments are reserved for future-step markers (removed when the work lands).
