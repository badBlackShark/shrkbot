# Notifications

The dashboard's cross-server notification centre: who writes the records, and how
reads stay scoped to the servers you administer.

Notifications are written by bot-side ops (`Ops::Notifications::Create`) when a
Discord event invalidates plugin configuration (e.g. a watched channel is deleted).
The web side reads them cross-server, scoped to the session's authorized server ids.

**Routes:** `resources :notifications, only: [:index, :update]` + a nested
`namespace :notifications { resource :read, only: :create }`. No server nesting
— notifications span all manageable servers.

**Auth scope:** `NotificationsController` and `Notifications::ReadsController`
include `SetsVisibleServers`. The query object `Finders::AuthorizedNotifications`
(app/presenters/) joins `server_configurations` and filters by
`managed_server_ids` from the session — the narrower of the two sets, so a
tournament organiser who can open a server's dashboard still doesn't read its
activity — preventing cross-server data leaks.
An optional `server_id` param narrows to one server ("this server" scope).

**Ops:** `Ops::Notifications::Dismiss` sets `dismissed_at` on a single
notification. `Ops::Notifications::MarkRead` bulk-updates `read_at` via
`update_all` for the caller-supplied `ServerConfiguration` objects (never raw
ids — the controller loads and authorizes them first).
