# Operations (`app/operations/`, `Ops::` namespace)

Where writes live, and the rules that let one operation serve both the bot and
the web app.

All writes and business logic live in operations — the shared seam between the bot
and the web app, so a given mutation is written once and called from both.

- Namespaced under the model they primarily mutate: `Ops::<Domain>::<Resource>::<Verb>`
  (e.g. `Ops::Roles::Sets::Create`). Cross-plugin / server-level ops live under
  `Ops::ServerConfiguration::`.
- **Operations take full objects, never record IDs.** The caller loads and
  authorizes the record (anti-spoofing for web requests); Discord snowflakes passed
  as values are fine — the rule targets AR record ids.
- Subclass `Ops::ApplicationOperation`; return its `Result`
  (`success?`/`failure?`/`value`/`errors`/`warnings`).
- Operations run inside the caller's connection context (web request, or the bot's
  `with_connection` wrapper) and wrap their writes in a transaction.
