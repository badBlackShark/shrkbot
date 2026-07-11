# Adding a plugin

A plugin is a per-guild toggleable feature with its own namespace, settings model,
and (optionally) commands and events. Three toggleable plugins exist today (logging,
roles, welcomes); reminders is a global always-on feature, not a catalog plugin.

## 1. Directory and namespace

```
app/models/<plugin>/
  settings.rb            # <Plugin>::Settings — the per-server settings AR model
  <noun>.rb              # additional record models, named as nouns
app/jobs/<plugin>/
  <name>_job.rb          # <Plugin>::<Name>Job
app/plugins/<plugin>/
  <domain>.rb            # plugin-internal domain logic — POROs, value objects, service objects
  commands/<verb>.rb     # collapsed → <Plugin>::<Verb>
  events/<name>.rb       # collapsed → <Plugin>::<Name>
```

The shared, cross-seam layers each live in their own top-level directory, namespaced
by plugin — models in `app/models/<plugin>/`, jobs in `app/jobs/<plugin>/`, the same
way operations (`app/operations/<plugin>/`), components (`app/components/<plugin>/`) and
presenters already are. `app/plugins/<plugin>/` holds only the bot-facing behavior
(`commands/`, `events/`) and the feature's internal domain logic.

`app/models`, `app/jobs`, and `app/plugins` are all autoloaded. The per-plugin namespace
(`Welcomes::`, `Roles::`) is the collision boundary, so there's no outer `Plugins::`
wrapper; that namespace spans the roots above (Zeitwerk resolves it), so a file's constant
depends only on its plugin folder, not which root it sits in. `commands/` and `events/`
are collapsed in `config/application.rb`.

## 2. Settings model

Use a dedicated typed table, not a JSON blob — we want real columns and validations.
Name the model `Settings` and set the table explicitly:

```ruby
module Welcomes
  class Settings < ApplicationRecord
    self.table_name = "welcome_settings"
    belongs_to :server_configuration
  end
end
```

Wire the association on `ServerConfiguration` with explicit `class_name` (and
`dependent:` to cascade on server removal). The migration uses a prefixed-UUID PK
default — see [architecture.md](architecture.md#primary-keys). Mirror model
validations with DB constraints (CI enforces this via `active_record_doctor`).

Keep every column nullable or defaulted, then add a line to
`Ops::ServerConfiguration::Ensure#ensure_settings` so the row is pre-created for
every server:

```ruby
config.welcome_settings || config.create_welcome_settings!
```

This upholds the invariant that a server's settings rows always exist (see
[architecture.md](architecture.md#server-onboarding)), so operations update the row
directly instead of build-or-update. Forgetting this line means the plugin's
settings operations hit `nil` for servers onboarded before the line was added.

## 3. Register in the catalog

Add a `Definition` to `PluginCatalog` (`app/models/plugin_catalog.rb`) — the single
source of plugin metadata. `db:seed` syncs the `Plugin` table from it.

```ruby
Definition.new(
  key: :welcomes,
  name: "Welcomes",
  description: "Join and leave messages.",   # user-facing; reused on the website
  channel_setting: :welcome_settings          # the assoc holding channel_id; nil if not channel-backed
)
```

A `channel_setting` makes the plugin **channel-backed**: it can't be enabled until that
channel is set. `TogglePlugin` enforces this and a `PluginActivation` validation
backstops it. `key` is read back as a symbol; branch on `:welcomes` in code.

`requires_plugin:` names another plugin that must be enabled first (a hard dependency).
`parent:` marks the plugin as a member of a plugin group; the parent must be enabled
before a child can enable. Both are folded into `prerequisites_met?` and backstopped by
the `PluginActivation` validation. Example: the moderation group's sub-plugins set
`parent: :moderation`, and `:moderation` sets `requires_plugin: :logging`.

## 4. Writes go through operations

All settings writes and runtime mutations are operations under
`Ops::<Plugin>::<Resource>::<Verb>` (server-level concerns under
`Ops::ServerConfiguration::`). Operations take full objects, never record ids, and
return a `Result`. See [architecture.md](architecture.md#operations-app-operations-ops-namespace).

## 5. Commands and events

Add slash commands ([adding-a-command.md](adding-a-command.md)) and event handlers
([adding-an-event.md](adding-an-event.md)). A command-less plugin (welcomes, logging)
is purely event-driven + web-configured; its enable flag gates the event handler at
runtime (a DB read), since handlers aren't hidden the way guild commands are.

## 6. Spec everything

Every non-trivial unit ships with a spec (RSpec + FactoryBot). Test our logic, not
discordrb. Factories never set `id`. Run `bundle exec rspec`, `bundle exec standardrb`,
and `bundle exec rake active_record_doctor` before pushing.

## 7. Privacy & data

Any new stored data must be reflected **in the same chunk** in three places:

1. **Privacy policy** (`config/locales/legal.en.yml`): describe what is stored, why,
   and how long it is retained.
2. **`Ops::Users::Destroy`**: if the data is per-user (keyed by a Discord user ID),
   add deletion there so a user's data is purged on request.
3. **Guild purge**: if the data is guild-scoped, it must cascade when the guild
   configuration is destroyed.

For guild-scoped data, hang the table off `ServerConfiguration` with a `dependent:`
option on the association so `Ops::ServerConfiguration::Destroy` cascades automatically.
Data keyed by raw Discord snowflakes without an Active Record association (like
reminders, which use a bare `server_id` column) must be handled explicitly inside that
operation.

The privacy policy's promises are binding constraints on implementation, not aspirational
copy. For example, the moderation section commits to in-memory scanning with no message
retention — that constraint must hold in any implementation of that plugin.

The guild purge runs in two places: the `server_delete` event (`ServerCleanup`) and a
REST-confirmed reconciliation at startup (`ServerReconciliation`, which catches kicks
that happened while the bot was offline). Purge logic must therefore live entirely in
`Ops::ServerConfiguration::Destroy` — never duplicated in the event handlers themselves.
