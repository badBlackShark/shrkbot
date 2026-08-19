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

## Naming

The namespace is how you find an operation, so it follows rules rather than taste.

- **The verb is CRUD**: `Create`, `Update`, `Destroy` (plus the domain verbs that
  genuinely aren't CRUD — `Sync`, `Reconcile`, `Ensure`). A bespoke verb like
  `Configure` reads as a *different* thing from the CRUD name, which is how three
  plugins ended up with the real behaviour in `Ops::<Plugin>::Configure` and an
  uncalled draft under `Ops::<Plugin>::Settings::Update`.
- **One namespace per table.** `Ops::ServerConfiguration::Channels` and
  `::ServerChannels` both wrote `server_channels`; the op is named for the model it
  mutates, so `ServerChannels` won and the other directory went away.
- **Model-named domains are singular**, matching the constant they mirror:
  `Ops::User`, `Ops::Notification`, `Ops::BotSetting`, `Ops::ServerConfiguration`.
  The plural was accidentally hiding the shadowing trap below.
- **Plugin-named domains keep the plugin's own spelling** — `Ops::Roles`,
  `Ops::Welcomes`, `Ops::Reminders`, `Ops::Logging` match `app/plugins/<name>/` and
  are not model names.
- **A resource segment carries the plurality the resource actually has.**
  `Ops::Roles::Messages` posts several; `Ops::Lfg::Message` posts one. That is
  meaning, not inconsistency.
- **Two verbs for one job is a naming bug**, even when both are CRUD-shaped —
  `Ops::Notification::Read` (one) beside `MarkRead` (many) is on the backlog.

## The shadowing trap

Namespacing an operation under a module named after a model **shadows that model
inside the operation**. `Ops::ServerConfiguration` shadows `::ServerConfiguration`;
`Ops::Roles::Settings` shadows `::Roles::Settings`. Reference the real one with a
leading `::`:

```ruby
::ServerConfiguration.find_or_create_by!(discord_id:)
::Roles::AssignableServerRoles.new(server_configuration)
```

It bites one level deeper every time the namespace deepens, and it fails as a
confusing `NoMethodError` on a module rather than a `NameError`. `Finders::` has the
same problem — see [finders.md](finders.md).
