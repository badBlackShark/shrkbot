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

When a plugin's domain logic grows large, group it into sub-namespaced subdirs rather
than a flat pile — e.g. moderation splits its `app/plugins/moderation/` internals into
`image_scanning/` (`Moderation::ImageScanning::*`), `member_log/` and `interaction/`,
leaving only genuinely shared helpers at the plugin root. Keep cross-cutting helpers
(used by more than one subgroup) at the root so subgroups never reach into each other.

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
default — see [Primary keys](../architecture/persistence.md). Mirror model
validations with DB constraints (CI enforces this via `active_record_doctor`).

Keep every column nullable or defaulted, then add a line to
`Ops::ServerConfiguration::Ensure#ensure_settings` so the row is pre-created for
every server:

```ruby
config.welcome_settings || config.create_welcome_settings!
```

This upholds the invariant that a server's settings rows always exist (see
[Guild sync and onboarding](../bot/guild-sync.md#server-onboarding)), so operations update the row
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
channel is set. `Ops::ServerConfiguration::Plugins::Toggle` enforces this and a `PluginActivation` validation
backstops it. `key` is read back as a symbol; branch on `:welcomes` in code.

`requires_plugin:` names another plugin that must be enabled and set up (its own
prerequisites met) before this one can enable.
`parent:` marks the plugin as a member of a `PluginCatalog::GROUPS` group (a `Group` is
just a key and a name). A group is not a plugin: it has no activation and no toggle, its
dashboard row has no toggle or badge and is lit while any member is on, and its overview
page subclasses `Views::Servers::GroupShow`. A member's `prerequisite` is typically a
shared group setting, linked from the member page's step list. Example: the Server
Shield protections set `parent: :moderation` and `requires_plugin: :logging`, with a
staff-role `prerequisite`. A member's page subclasses `Views::Servers::SubPluginShow`, and
its group's overview renders `Components::SubPluginDirectory` (rows from
`SubPluginStatus.rows`) plus `Components::SubPluginToggleForms`, so the row toggles post to
`Servers::PluginsController` from the overview. Integrations (`:integrations` with
`:steam`) is the minimal example; Server Shield adds its own settings on top.

`Definition#blockers` returns every unmet reason in the order `:not_granted`,
`:requires_plugin`, `:channel_missing`, `:prerequisite`;
`prerequisites_met?` is `blockers.empty?`. `Ops::ServerConfiguration::Plugins::Toggle` is
the only writer of `PluginActivation#enabled` (except `Ensure` creating disabled rows
and preview seeding, see `docs/web/preview.md`). It refuses an enable while any blocker
remains (`operations.server_configuration.plugins.requires.<key>` when present - add the
key to `ignore_unused` group 7 - else `requires_settings`), and refuses any change that
leaves an enabled plugin from `PluginCatalog.dependents_of(key)` with a blocker
(`PluginCatalog.unmet_dependent`, message `still_needed`). `Ops::Moderation::Settings::Update`
asks the same question about the group's shared settings. A settings op
(`Ops::<Plugin>::Settings::Update`) assigns its settings,
then calls `save_with_activation`, so Toggle checks the submitted values before anything saves. The
`PluginActivation` validation stays as the backstop.

`bespoke: true` marks a plugin as bot-owner-granted: it's hidden from every server's
dashboard and its guild commands aren't registered until the bot owner grants it to
that server from the admin panel (`BespokePluginGrant`). The grant is folded into
`Definition#blockers` alongside the other checks.

A bespoke plugin still gets an ordinary `/servers/:server_id/<plugin>` page like every
other plugin — `RequiresManageableServer` works the same way, and `Components::PluginNav#plugin_config_path`
just returns that path. What makes it bespoke is the grant check, and it's automatic:
`PluginCatalog.visible_for` drops ungranted bespoke plugins from the catalog, so
`app/policies/plugin_access.rb`'s `PluginAccess#manage?`/`#visible?` (built by
`RequiresManageableServer`'s `require_plugin_access` before_action) already deny access
without the controller doing anything extra — no separate concern to include.
Twilight Struggle is the reference: `Servers::TwilightStruggleController` and
`Servers::TwilightStruggle::DestinationsController` rely on that same gate like every
other plugin controller. The plugin's own enable toggle stays the per-server kill switch
on top of the grant; check it wherever the plugin acts on a server
(`Ops::TwilightStruggle::Games::Post`).

`added_on:` (the `Date` the plugin ships) shows the New badge and the sidebar sparkle for
`PluginCatalog::NEW_FOR` (30 days). A new sub-plugin also marks its parent New (the
dashboard row and the sidebar group's own line), because the dashboard lists no
sub-plugins and the group starts closed. `beta: true` shows the Beta badge until the
plugin has been tested widely; remove the flag then. Beta never rolls up to the parent.

## 4. Writes go through operations

All settings writes and runtime mutations are operations under
`Ops::<Plugin>::<Resource>::<Verb>` (server-level concerns under
`Ops::ServerConfiguration::`). Operations take full objects, never record ids, and
return a `Result`. See [Operations](../architecture/operations-layer.md).

## 5. Commands and events

Add slash commands ([adding-a-command.md](adding-a-command.md)) and event handlers
([adding-an-event.md](adding-an-event.md)). A command-less plugin (welcomes, logging)
is purely event-driven + web-configured; its enable flag gates the event handler at
runtime (a DB read), since handlers aren't hidden the way guild commands are.

## 6. Spec everything

Every non-trivial unit ships with a spec (RSpec + FactoryBot). Test our logic, not
discordrb. Factories never set `id`. Run `bundle exec rspec`, `bundle exec standardrb`,
and `bundle exec rake active_record_doctor` before pushing.

Add an entry to `config/preview_data.yml` too, so the plugin has working demo data —
see [Preview mode](../web/preview.md).

## 7. Privacy & data

Any new stored data must be reflected **in the same chunk** in three places:

1. **Privacy policy** (`config/locales/legal.en.yml`): if the data is personal, or free
   text that can hold personal data, describe what is stored, why, and how long it is
   retained. Plain server settings (channels, roles, toggles) stay out of the policy.
2. **`Ops::User::Destroy`**: if the data is per-user (keyed by a Discord user ID),
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
