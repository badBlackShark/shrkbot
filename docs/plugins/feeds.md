# Feeds

A server follows a source (today a Steam game) and gets its new posts in a channel.
This page covers the data, polling and posting sides.

## Tables

- `feed_subscriptions` (`Feeds::Subscription`): one row per server and followed watch.
  The `channel_id` to post in, an optional `role_id` to ping, and `body_length`
  (`preview` by default, or `full`). Unique on `[server_configuration_id, watch_id]`.
- `feed_subscribed_events` (`Feeds::SubscribedEvent`): the event types a subscription
  wants, each with an optional `template` override and `subscribed_since`, the moment
  that kind of post was followed (see Following since). Unique on
  `[subscription_id, event_type]`.
- `feed_posts` (`Feeds::Post`): one row per story a subscription posted, holding
  the `story_key`. It is written before the message is sent, so it is the claim that
  keeps a story from posting twice. Unique on `[subscription_id, story_key]`.

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
than delete so each subscription's `subscribed_events` and `posts` go with it. That is the guild
purge; there is no separate path. The watch itself is shared between servers and is
removed by the orphan prune once nothing references it.

## Posting

    RecordObservation -> Bus -> AnnounceJob(event) -> PostJob(subscription, event) -> Posts::Create

- `Feeds::AnnounceJob` is the bus handler for the three Steam news event classes. It
  enqueues one `Feeds::PostJob` per `active` subscription on the event's watch that has
  a `feed_subscribed_events` row for the event's type.
- `Feeds::PostJob` checks, in order, that the subscription is still `active`, that it has
  no `Post` for the story yet, that `Feeds::StoryPick` finds the event eligible (its type
  is followed and it occurred at or after that type's `subscribed_since`), and that no
  better eligible copy of the story exists. Then it calls `Ops::Feeds::Posts::Create`.
- Both jobs serialize with `limits_concurrency`: `AnnounceJob` per watch and `PostJob`
  per subscription. `Dispatch` enqueues a poll's events oldest first, and Solid Queue
  releases blocked jobs in enqueue order, so posts come out in time order. A post that
  fails and retries can land late. One key per subscription also covers two copies of
  one story.
- Both jobs include `ReportsExhaustion`: after 9 failed attempts (about 2.5 hours of
  backoff, so a Discord outage delays a post instead of dropping it) it enqueues
  `ReportExhaustedJob`, which DMs the bot owner the job and its error, and re-raises so
  the failed job stays in Solid Queue and can be retried by hand. `NotifiesOwner` retries
  10 times (about 4 hours), so the DM still arrives after the outage that exhausted the
  job. `discard_on` for a
  deleted event, channel or permission wins over the retry.
- `Ops::Feeds::Posts::Create` is subject-first (see
  [../bot/message-rendering.md](../bot/message-rendering.md)): it sends the subject as
  plain content, allowing only the subscription's own role to ping, then converts the
  message into the card with the default suppressed mentions. The card carries untrusted
  post text, so nothing in it can ping. The `Post` is written first, as the claim, and
  released again if the send fails. When the conversion fails, the plain message is edited
  to `Announcement#fallback`: the subject cut so that the whole link still fits in 2000
  characters.

## Stories

One story can arrive as several events: the same title in two Steam feeds within
15 minutes gets different `subject_key`s but one `story_key`
(`Integrations::Steam::Stories`). A subscription that follows both types must post it
once, by two guards:

- `Feeds::StoryPick` ranks the eligible copies of a story, those that occurred at or
  after their type's `subscribed_since`: a copy that is not `secondary` beats one that
  is, then the earliest `occurred_at`, then the lowest `id`. `secondary` is a class
  attribute on `Integrations::Event`; `ArticlePublished` sets it, because a Steam
  article is second-hand coverage of the first-party post. A job posts only when its
  event is the best eligible copy. A subscription that follows articles only gets the
  article. Ranking applies to the copies already stored when the job runs: a better copy that arrives in a later poll is skipped, because the
  story was already posted.
- The unique `[subscription_id, story_key]` on `feed_posts` and the `exists?` check in
  `PostJob` are the backstop for a retry or a second delivery.

## Following since

`feed_subscribed_events.subscribed_since` is the gate that keeps a server from receiving
posts published before it followed that kind of post. It defaults to the time the row
is created. A post whose `occurred_at` is earlier is never eligible, and `StoryPick`
ignores it when ranking, so a copy the subscription could never have received cannot
displace one it could.

`Ops::Feeds::SubscribedEvents::Resume` resets it to now for the server's subscriptions
when `feeds` is enabled again (all of them) or a source plugin is (the subscriptions on
that source's watches). Off means off: re-enabling must not post what was published
while it was off. Editing a subscription does not reset it.

It replaces priming. A watch stores whatever is fresh and unseen, and the gate decides
what a server gets, so a fresh or long-unpolled watch never replays its backlog.

## What a post looks like

`Feeds::Announcement` renders both messages.

The **subject** is the subscribed event's `template`, or the default for its class,
filled by `TemplateText`, stripped and cut to 2000 characters:

| Event | Default template |
| --- | --- |
| `PatchNotesPublished` | `{role} New {game} patch notes: {title}` |
| `AnnouncementPublished` | `{role} New {game} announcement: {title}` |
| `ArticlePublished` | `{role} {feed}: {title}` |

Tokens: `role` (the role mention, or empty), `game`, `title`, `url`, `author`, `feed`.

The **card** is a container with the title as a heading (cut to 256 characters), the
body excerpt, the post's first image when it has one, and a link button to the original.

**Body length** is a per-subscription setting. `preview` (the default) keeps about 500
characters and `full` about 3500, under Discord's 4000 for the whole message.
`Feeds::Excerpt` takes the body length setting and looks up the limit itself. Past it,
it cuts at the last paragraph break (when that keeps at least half the limit), else the
last line break (same rule), else the last space, and appends "…". A cut that leaves a code fence open closes it
first, with the "…" on the line after.

## Retention

`Ops::Feeds::Posts::Prune` runs daily at 5:40 and deletes posts older than 14 days
(`Ops::Integrations::Prune::RETENTION`), the same age the events they came from are
pruned at. A server's posts are deleted with its subscriptions (`dependent:
:delete_all`).
