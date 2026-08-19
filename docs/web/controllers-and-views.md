# Web (controllers and views)

Controller and component conventions, and the authorization model that
re-verifies against live Discord on every server-scoped request.

- **Standard CRUD controllers.** Reach for a new resource controller with the
  conventional actions before adding bespoke/custom actions to an existing one —
  an extra controller (including nested/namespaced, e.g. `Servers::PluginsController#update`
  for toggling a server's plugin) is better than one crammed with custom actions
  and a pile of private helpers. When a controller starts sprouting helpers, that
  usually means a resource, or a read-side query/presenter object, wants extracting.
- **Small, single-purpose view components.** Prefer many focused Phlex components
  over a few that each do several things — one more component that does exactly one
  thing beats a large multi-purpose one, *even when it is only used once*. Read-side
  derivations (e.g. computing each plugin's enabled/needs-setup/disabled status)
  belong in a small query/presenter object (`PluginStatus`), not inlined into a fat
  controller or view.
- **Booleans from forms.** Let ActiveRecord cast checkbox values — assign the raw
  param to the model attribute (`"1"`/`"0"` → `true`/`false`) rather than coercing
  in the controller.
- **Server-scoped authorization** lives in two concerns, not in individual
  controllers. We don't persist which servers a user manages (it's a Discord fact,
  fetched per the metadata-sync design, not a DB relationship), so authorization is
  re-verified against live Discord on every server-scoped request.
  `SetsVisibleServers` (included by the picker, dashboard, notifications, and
  `RequiresManageableServer`) owns that lookup: `Finders::VisibleServers.for` returns every
  guild the user may reach, and `#live_access` maps each to whether the user also
  *manages* it, exposed as `visible_now?` / `manages_now?`. `RequiresManageableServer`
  (included by every server-scoped controller) **applies `before_action
  :require_manageable_server` on include** — so a controller can't forget to
  authorize — which checks `visible_now?` and sets `@server_configuration`. A demoted
  admin loses access on their very next request rather than up to two weeks later.
  Two session sets back the outage fallback and the endpoints that don't re-verify:
  `visible_server_ids` (servers you may open) and `managed_server_ids` (…and may
  administer). They differ because a plugin can be manageable for a non-Discord-admin
  reason — see the tournament-organiser input below — and anything scoped to "your
  servers" as an admin (notifications) must read the narrower set. Discord being
  unreachable
  (`UserGuilds::Error`) falls back to the session cache rather than locking admins
  out during an outage; a bad/expired token (`UserGuilds::Unauthorized`) is not
  caught here — it propagates to `DiscordReauth`.
- **Re-authentication is centralized in the `DiscordReauth` concern**, included by
  both `ServersController` and `RequiresManageableServer` (every server-scoped
  controller), since the user's Discord token is now read on every server-scoped
  request, not just the picker/dashboard. It `rescue_from`s
  `Bot::Discord::UserGuilds::Unauthorized`, stashes the current path in
  `session[:return_to]`, and renders `Views::Reauth`; a second consecutive failure
  resets the session and bounces to the root page. `SessionsController#create`
  redirects to `session[:return_to]` (falling back to the picker) and clears the
  reauth flag, so re-auth returns the user to where they were instead of always
  landing on the picker.
- **`app/policies/` holds authorization policies.** `PluginAccess` is the single
  answer to "may this user configure this plugin on this server", built from
  Manage Server plus the bespoke grant (`PluginCatalog.visible_for` already drops
  ungranted bespoke plugins, so the grant check is subsumed). `RequiresManageableServer`
  enforces it per request via `plugin_key`, **applying
  `before_action :require_plugin_access` on include** for the same
  can't-forget-to-authorize reason, and redirects when the answer is no.
- **Manage Server is not the only input.** A Twilight Struggle tournament organiser
  manages that one plugin on any server that holds the bespoke grant, has the
  plugin enabled, and the organiser is a member of — regardless of which
  tournament the server subscribes to, so `PluginAccess` falls back to
  `administered_keys` when the user doesn't manage the server. Page access is
  deliberately tournament-independent: it only asks whether the user
  administers *some* tournament at all (`Finders::TwilightStruggle::OrganiserServers`),
  which is what lets an organiser create the server's first subscription
  themselves. Which specific tournaments they may act on is enforced one layer
  in, on the actions rather than the page — `Finders::TwilightStruggle::AdministeredTournaments`
  (admin rows + descendants) backs the `AuthorizesTournaments` controller
  concern, which 404s an organiser out of a tournament they aren't named on.
  The membership half of the page-access rule is free: Discord already tells us
  every guild the user is in, and `Finders::VisibleServers.for` admits a guild when the
  user manages it *or* administers a tournament. Someone who leaves the guild
  drops out of the candidate set, so there is no revocation path to build.
  The plugin's enabled/disabled switch stays admin-only regardless
  (`PluginAccess#toggle?`) — flipping it is the organiser's own access gate, so
  letting them flip it off would lock every organiser on the server out at
  once and need a Discord admin to undo.
- **Snowflakes submitted from the web are scoped to the guild in the controller.**
  A channel/role id posted by a user is untrusted input: the controller verifies it
  belongs to `@server_configuration` (e.g. `VerifiesGuildChannels#guild_channels?`
  against `server_channels`) and returns 404 on a foreign reference, before handing
  the value to the op. Ops trust the values they receive — scoping is the caller's
  job (same anti-spoofing rule as loading records). Assignability *rules* beyond mere
  ownership (managed/above-bot role filtering in `Roles::AssignableServerRoles`) stay
  in the op as business logic.
- **Turbo Stream responses live in a view template**, not in controller helpers —
  the standard Rails `action.turbo_stream.erb` (e.g.
  `app/views/servers/plugins/update.turbo_stream.erb`). The controller sets its
  instance variables and `respond_to { |f| f.turbo_stream; f.html { redirect_back … } }`;
  the template uses the `turbo_stream` tag builder with our Phlex components as the
  content: `turbo_stream.replace "plugin-#{@plugin.key}", html: render(Components::PluginRow.new(…))`,
  `turbo_stream.append "toasts", html: render(Components::Toast.new(**@toast))`. This
  is how auto-saving controls re-render in place: success re-renders the control
  plus a toast, and (for the config forms) failure re-renders the form region with
  inline errors — just more `turbo_stream.*` lines with different components and
  targets. (These response templates are ERB; the Phlex-for-views convention is
  about page/component views — the stream wrapper is a thin format template.)

## Abstract Phlex base views take no stubs

Abstract base views (`Views::Servers::PluginConfigShow`,
`Views::Servers::Moderation::SubPluginShow`) deliberately omit
`AbstractMethodError` stubs for their subclass hooks, unlike the ops and bot base
classes.

Two reasons. An unreachable `raise` line can never satisfy the undercover
changed-line gate, and a spec poking it through `send` is a gate contortion rather
than a test. And a subclass that forgets a hook already fails loudly, as
`NoMethodError`, at the first render. `Ops::PluginConfiguration` and
`Bot::BaseCommand` do keep their stubs — those raises are reachable through public
call paths and are spec'd there.

When adding an abstract Phlex view, also add its relative-key scope
(`views.….<base_view>.*`) to `ignore_missing` in `config/i18n-tasks.yml`:
i18n-tasks resolves `t(".key")` by file path, while at runtime it resolves by
subclass.
