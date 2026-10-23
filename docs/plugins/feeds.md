# Feeds

A server follows a source (today a Steam game) and gets its new posts in a channel.
This page covers the data and polling side; nothing posts yet.

## Tables

- `feed_subscriptions` (`Feeds::Subscription`): one row per server and followed watch.
  The `channel_id` to post in, an optional `role_id` to ping, and `body_length`
  (`preview` by default, or `full`). Unique on `[server_configuration_id, watch_id]`.
- `feed_subscribed_events` (`Feeds::SubscribedEvent`): the event types a subscription
  wants, each with an optional `template` override. Unique on
  `[subscription_id, event_type]`.

`watch_id` points at `integration_watches`; see
[../integrations/overview.md](../integrations/overview.md) for what a watch is.

## `Subscription.active`

A subscription is **active** when its server is real (not a preview) and has both the
`feeds` plugin and the source's sub-plugin enabled. `Feeds::SOURCE_PLUGINS` maps a
watcher class name to its sub-plugin key (`Integrations::Steam::NewsWatcher` ->
`:steam_news`), so a new source is one entry there. `Feeds::Subscription` is registered
as a demand source in `config/initializers/integrations.rb`, and a watch is polled only
while an active subscription points at it.

Turning a plugin off keeps the subscription rows: the server's choices survive, the
subscription goes inactive, and the watch stops being polled once no active
subscription is left.

## Purge

`ServerConfiguration has_many :feed_subscriptions, dependent: :destroy`. Destroy rather
than delete so each subscription's `subscribed_events` go with it. That is the guild
purge; there is no separate path. The watch itself is shared between servers and is
removed by the orphan prune once nothing references it.
