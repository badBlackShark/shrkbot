# Preview mode

How a preview guild demos the web UI without the bot being in a real Discord
server, and how to add a new plugin's demo data.

## The design

Preview fakes the **guild**, never who you are. A signed-in user stays signed in
as themselves and views a real `ServerConfiguration` row that happens to describe
a guild the bot was never added to. Every controller, policy, and view along the
path is the genuine one; only the data underneath is canned.

A **negative `discord_id`** marks the row, and is the only thing that marks it.
Discord snowflakes are always positive, so the two populations can never collide
and there is no ceiling to exhaust. `ServerConfiguration#preview?` derives from
the sign, and the `.real` / `.previews` scopes partition on it. The canonical
preview guild sits at `discord_id: -1`; per-visitor copies take further negative
ids. There is deliberately no `preview` column: a second marker could disagree
with the id, and this one cannot.

Safety does not come from remembering to write `.real`. `Ops::ServerConfiguration::Destroy`
refuses a preview configuration outright, because that operation is the only path
that can destroy one — `Bot::ServerReconciliation` calls it for every guild the
bot is not currently in, which describes every preview guild permanently. A query
that forgets `.real` therefore shows a preview row where it does not belong; it
cannot delete one.

`default_scope` was considered and rejected. It applies to `belongs_to` loads, so
a preview `ServerChannel`'s `.server_configuration` would return `nil` and break
every child-to-parent traversal in the views — `ServerChannel#everyone_visible?`
does exactly that — and it stamps its own condition onto `create`.

## The single source of mock data

`config/preview_data.yml` is the only place preview content is written. It holds
a `guild:` section, `channels:`, `roles:`, and a `plugins:` list — one entry per
toggleable plugin, each carrying that plugin's settings and, where relevant,
records like role sets or LFG pingable roles. `PreviewData` (`app/models/preview_data.rb`)
is the read-only accessor: it parses the file once, memoizes it, and shapes the
channel hashes the way `Ops::ServerConfiguration::ServerChannels::Sync` expects
(`channel_type`, `overwrites: []`).

`Ops::ServerConfiguration::Previews::Create` seeds the file into real rows:

1. `Ops::ServerConfiguration::Ensure` establishes the settings-row and
   activation-row invariants, exactly as it does for a real guild onboarding.
2. The configuration is updated with the rest of the `guild:` attributes. Nothing
   has to flag it as a preview — `Ensure` already created it at the negative
   `discord_id` the file names.
3. `ServerChannels::Sync` and `ServerRoles::Sync` upsert the channels and roles
   verbatim — the same ops guild sync uses for a real Discord guild.
4. `Ops::ServerConfiguration::Previews::ApplyPlugin` runs once per `plugins:`
   entry: writes the settings row, rebuilds any `records:`, and flips the
   `PluginActivation` directly.

Step 4 sets `PluginActivation#enabled` directly rather than going through
`Ops::ServerConfiguration::Plugins::Toggle`. Toggle publishes to `Bot::ConfigBus`,
which would tell the live bot process to sync slash commands for a guild that
does not exist — there is no bot connection to a preview guild, ever.

The whole op is idempotent: `db/seeds.rb` calls it after the `PluginCatalog` loop
(plugin demo data enables plugins that must already exist as `Plugin` rows), and
seeds gets re-run in every environment.

## Adding a plugin's demo data

A new plugin isn't done until it demos. Add an entry to the `plugins:` list in
`config/preview_data.yml`:

```yaml
- plugin: my_plugin
  settings_association: my_plugin_settings   # the ServerConfiguration has_one name
  enabled: true
  settings:
    some_column: some_value
  records:
    some_has_many:
      - some_attribute: value
        another_nested_has_many:
          - nested_attribute: value
```

- `plugin` is the `PluginCatalog` key.
- `settings_association` is the association name on `ServerConfiguration` for
  that plugin's settings row (`Ensure` already created it — `ApplyPlugin` only
  updates).
- `settings` is applied straight onto that row with `update!`.
- `records`, if present, is a hash of association name → array of attribute
  hashes, applied on the settings row. Any attribute value that is itself an
  array of hashes is a nested association on the record just built — `ApplyPlugin`
  walks this recursively, so a new plugin never needs its own loader code. Each
  association is cleared (`destroy_all`) before rebuilding, which is what keeps
  a second seed run idempotent.

Order plugins so prerequisites land before dependents — `logging` before
`moderation`, `moderation` before its `spam_protection`/`image_scanning`
sub-plugins — because `ApplyPlugin` flips each activation immediately after
applying that plugin's settings, and `PluginActivation`'s own validation checks
`PluginCatalog::Definition#prerequisites_met?` against the current DB state.

`spec/models/preview_data_spec.rb` fails if a non-bespoke `PluginCatalog`
definition has no matching entry, and
`spec/operations/server_configuration/previews/create_spec.rb` fails if the demo
data doesn't actually satisfy that plugin's prerequisite chain — both are meant
to catch a plugin shipping without working demo data.

Bespoke plugins (Twilight Struggle) and global, catalog-less features
(reminders) are deliberately absent — bespoke plugins are hidden from any guild
that isn't granted them, and reminders has no settings table, only the
`force_dm_reminders` flag on `guild:`.
