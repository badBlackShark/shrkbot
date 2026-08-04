# Plugins (`app/plugins/<plugin>/`)

How a plugin's files are laid out across the app roots, and how `PluginCatalog`
drives what is enabled where.

`app/plugins` is an autoloaded app dir. Each plugin gets a per-plugin namespace
(`Welcomes::`, `Roles::`, `Reminders::`) — that already prevents cross-plugin
collisions, so there is no outer `Plugins::` wrapper.

Layout — the plugin's shared, cross-seam layers live in their own top-level dir
(namespaced by plugin), same as operations/components/presenters; `app/plugins/`
holds only bot behavior and feature-internal domain logic:

```
app/models/<plugin>/
  settings.rb            # <X>::Settings (AR model; sets self.table_name)
  <noun>.rb              # record models, named as nouns
app/jobs/<plugin>/
  <name>_job.rb          # <X>::<Name>Job
app/plugins/<plugin>/
  <domain>.rb            # plugin-internal domain logic (POROs, value/service objects)
  commands/<verb>.rb     # Zeitwerk-collapsed → <X>::<Verb>
  events/<name>.rb       # Zeitwerk-collapsed → <X>::<Name>
```

The `<X>::` namespace spans those roots — a file's constant depends on its plugin
folder, not which root it lives in. `config/application.rb` collapses
`app/plugins/*/commands` and `*/events` so a file maps to `<X>::<Verb>`, not
`<X>::Commands::<Verb>`. Namespaced AR models set `self.table_name` explicitly. Naming
convention to avoid collisions: the settings model is always `Settings`, records are
nouns, commands are verbs.

Settings models are dedicated typed tables (not a JSON blob) so we get real columns
and validations (e.g. the @everyone-visibility check on a logging channel).

## Plugin catalog and activation

`PluginCatalog` (`app/models/plugin_catalog.rb`) is the single source of plugin
metadata — a frozen list of `Definition`s (key, name, description, channel_setting).
Don't hardcode the plugin list anywhere else. It drives the
`db:seed` of the `Plugin` table, prerequisite checks, and the channel-backed registry.

`Plugin#key` is exposed as a **symbol** (stored as text); call sites read `:welcomes`.
AR casts symbols to text in queries, so `find_by(key: :welcomes)` and `"welcomes"`
both work. (The unrelated `Setting`/`BotSetting` KV table keeps string keys.)

`ServerConfiguration has_many :plugins, through: :plugin_activations`. A plugin is
enabled per-server via the `PluginActivation#enabled` flag (toggled, never
created/destroyed — settings survive a disable→enable cycle). `Plugin.enabled` scopes
to `enabled: true` activations. Activation rows are ensured per server×plugin when a
server is first seen.

A **channel-backed** plugin (its `channel_setting` is set) can't be enabled until
that channel is configured. This is enforced in two places:
`Ops::ServerConfiguration::Plugins::Toggle` gives the friendly failure, and a
`PluginActivation` validation backstops any write that skips the op.

A **bespoke** plugin (`Definition#bespoke`) is hand-activated by the bot owner per
server rather than self-serve. `bespoke_plugin_grants` (guild ↔ plugin key, cascaded
off `ServerConfiguration`) records the grant; `PluginCatalog.visible_for` is the filter
the dashboard/sidebar uses to hide ungranted bespoke plugins entirely, and
`Bot::GuildCommandSet` requires a grant before registering a bespoke plugin's guild
commands. `prerequisites_met?` gates on the grant first, so the enable path is
backstopped the same way as the other prerequisite checks.
