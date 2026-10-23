# Feeds

A server follows a source (today a Steam game) and gets its new posts in a channel.
This page covers the data, polling and posting sides.

## Tables

- `feed_subscriptions` (`Feeds::Subscription`): one row per server and followed watch.
  The `channel_id` to post in, an optional `role_id` to ping, and `body_length`
  (`preview` by default, or `full`). Unique on `[server_configuration_id, watch_id]`.
- `feed_subscribed_events` (`Feeds::SubscribedEvent`): the event types a subscription
  wants, each with an optional `template` override. Unique on
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
- `Feeds::PostJob` skips the event when the subscription already has a `Post` for its
  story, or when `Feeds::StoryPick` says another subscribed copy of the story is better.
  Otherwise it calls `Ops::Feeds::Posts::Create`. Retries and discards mirror
  `TwilightStruggle::PostJob`, and `limits_concurrency` is keyed by subscription and
  story so two copies of one story never post at once.
- `Ops::Feeds::Posts::Create` is subject-first (see
  [../bot/message-rendering.md](../bot/message-rendering.md)): it sends the subject as
  plain content, allowing only the subscription's own role to ping, then converts the
  message into the card with the default suppressed mentions. The card carries untrusted
  post text, so nothing in it can ping. It then records the `Post`.

## Stories

One story can arrive as several events: the same title in two Steam feeds within
15 minutes gets different `subject_key`s but one `story_key`
(`Integrations::Steam::Stories`). A subscription that follows both types must post it
once, by two guards:

- `Feeds::StoryPick` ranks the subscribed copies of a story: a copy that is not
  `ArticlePublished` beats one that is, then the earliest `occurred_at`, then the lowest
  `id`. A job posts only when its event is the best copy. A subscription that follows
  articles only gets the article. Ranking applies to the copies already stored when
  the job runs: a better copy that arrives in a later poll is skipped, because the
  story was already posted.
- The unique `[subscription_id, story_key]` on `feed_posts` and the `exists?` check in
  `PostJob` are the backstop for a retry or a second delivery.

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
`Feeds::Excerpt` takes the limit as a number. Past it, it cuts at the last paragraph
break (when that keeps at least half the limit), else the last line break (same rule),
else the last space, and appends "…". A cut that leaves a code fence open closes it
first, with the "…" on the line after.

## Retention

`Ops::Feeds::Posts::Prune` runs daily at 5:40 and deletes posts older than 14 days
(`Ops::Integrations::Prune::RETENTION`), the same age the events they came from are
pruned at. A server's posts are deleted with its subscriptions (`dependent:
:delete_all`).
