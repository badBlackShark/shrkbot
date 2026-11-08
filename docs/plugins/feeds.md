# Feeds

A server follows a source (today a Steam game) and gets its new posts in a channel.
This page covers the data, polling and posting sides.

The plugin group is "Integrations" (`:integrations`, one sub-plugin per provider such as `:steam`).
`Feeds::` is the capability that posts a source's news into a channel, so its code, tables and this
doc keep the Feeds name; the provider layer is `Integrations::` (see `docs/integrations/`).

## Pages

Two catalog entries make the plugin group: `:integrations` (the parent) and `:steam`
(`parent: :integrations`). A new source is another sub-plugin entry, its `Feeds::`
source module (see Sources) and its own page.

- **Integrations** (`Servers::IntegrationsController`): the overview. It renders
  `Components::SubPluginDirectory` with one row per sub-plugin
  (`SubPluginStatus.rows(config, parent: :integrations)`), and `Components::SubPluginToggleForms`
  after the page so a row's toggle can submit from the overview. A row toggle posts the
  sub-plugin's own `PATCH` with `from_overview=1` and the controller redirects back to
  the Integrations page.
- **Steam** (`Servers::SteamController`, a `Views::Servers::SubPluginShow`):
  lists the games the server follows, with Add, Edit and Stop following (see Config UI).
  `Finders::Feeds::SourceSubscriptions` returns the server's subscriptions on that
  source, ordered by game name, and `Components::Feeds::SubscriptionList` builds the
  channel and role lookups once for all rows. A row shows the game's header image, the
  channel, the pinged role, the followed event types, and a warning when the watch is
  broken (`Integrations::Watch#broken?`).
- Turning Integrations off or on goes through `Ops::ServerConfiguration::Plugins::Toggle`
  like any plugin. A sub-plugin cannot be turned on while Integrations is off.
- Demo data: `config/preview_data.yml` enables both and follows two games, each through a
  shared `Integrations::Watch`, see [../web/preview.md](../web/preview.md).

## Sources

A source is a module under `Feeds::` (`Feeds::Steam`) that answers `plugin_key`,
`watchers`, `event_types` (in UI order), `default_event_types` and `template_tokens`,
plus the settings contract: `settings_association` (the `Subscription` association that
holds its provider settings, which the list finder preloads),
`role_id_for(subscription, event_type)`, `accepts?(subscription, event)`,
`post_type(event_type)`, `announced_types`, `retract?(subscription, event)` (true when the post is deleted instead of
edited; Steam never, Twitch for `StreamEnded` in `delete` mode and for a switched-away
stream in `delete` mode) and `revive?(subscription, event)` (true when a post shrkbot
deleted may be sent again; Steam never, Twitch for a live event in a chosen category). Each source
with settings adds its own `has_one` on `Feeds::Subscription` (`steam_settings`), so the
foreign key and the guild purge follow the subscription. `Subscription#settings` reads
that row and `#build_settings` builds it; the row is built once, with the subscription,
and reading never builds one. Shared code reads settings through the source, except
the Steam config components (list, row, fields, cards), which read the Steam row directly
until they split per source with Twitch.
A source also answers `announcement(event:, subscription:)`: it builds the source's
renderer and does the I/O that renderer needs (Steam: the padded thumbnail via
`Feeds::Steam::Thumbnail`; Twitch: `Feeds::Twitch::LiveImage`).
`Feeds.sources` lists them; a new source adds a module and one entry there. The
contract is duck-typed with no base class: a shared mixin is extracted when two sources
share code. `spec/models/feeds_spec.rb` enforces the contract.

## Config UI

Routes live under `resource :steam` as `resources :subscriptions` (`new`, `create`,
`edit`, `update`, `destroy`), served by `Servers::Steam::SubscriptionsController`. Real
servers only: the preview list renders no Add, Edit or Stop following controls, and there
are no preview routes for these pages.

- **Lookup -> form.** `new` without `app` shows the lookup field. With `app`,
  `Feeds::TargetLookup` calls the watcher's `resolve` and returns the target or one error
  (`invalid_reference`, `not_found`, `unavailable`). A game the server already follows
  links to its edit page; otherwise the follow form renders for the resolved target, with
  Patch notes and Announcements on and Articles off (`Feeds::Steam.default_event_types`).
  `create` resolves the game again from the hidden `external_id` rather than trusting
  anything the form carries.
- **Ops.** `Ops::Feeds::Subscriptions::Create` checks the cap, finds or builds the shared
  watch (refreshing its name and `image_url` from the target), refuses a game the server
  already follows, validates the subscription with its events, then saves the watch and
  the first subscription in one transaction, so the daily orphan prune cannot take a
  fresh watch before its subscription exists. `Update` saves the settings, deletes
  event types that were switched off and adds the new ones; a kept type keeps its
  `subscribed_since` and `template`. `Destroy` removes the subscription and leaves the
  watch for the prune.
- **All post types off is allowed.** It pauses a game without losing its channel, role and
  length; turning a type back on starts from that moment (`subscribed_since`).
- **Paths.** `Feeds::SubscriptionPaths` builds the add, edit and subscription paths from
  the source's plugin key (`new_server_<key>_subscription_path`), so a new source adds a
  nested `resources :subscriptions`, not new path code.
- **Cap.** A server follows at most `Feeds::Subscription::MAX_PER_SOURCE` (25) things per
  source: 25 Steam games don't block a Twitch channel. The cap protects each provider's
  request budget, so it counts per source. The list disables Add at the cap and says why
  (`Subscription.cap_message`, one locale key per source under
  `operations.feeds.subscriptions.cap`).
- **Images.** The pages load each game's header image straight from Steam, so the CSP
  `img_src` lists the two Steam image hosts and the privacy policy says Steam sees the
  viewer's IP address. A watch without an `image_url` shows a neutral placeholder.
- **Custom messages.** Each post type has a collapsed "Custom message" disclosure
  (`Components::Feeds::EventTypeSetting`, opens with the toggle through
  `disclosure#sync`) holding the optional lead-line text (empty by default, no reset), a
  placeholder list and a live preview (`feed-preview` controller,
  `lib/feed_template.js`). `Feeds::Templates.custom` stores `nil` when the text is
  blank, and any text is allowed. Turning a post type off drops its event row, so its custom message goes too.
- **Volume line.** Under "What to post" a lazy Turbo frame (`feed-volume`) loads
  `Servers::Steam::VolumesController#show`, which shows how many of the last 20 news
  items were each post type (`Integrations::Steam::NewsWatcher.volume`,
  `Feeds::VolumeLookup`). The follow and edit pages and saving never call Steam. When Steam
  fails the lookup returns `nil` and the frame stays empty.

### Twitch

`Feeds::Twitch` is the second source: plugin key `:twitch`, watcher
`Integrations::Twitch::ChannelWatcher`, five event types (`StreamStarted`, the live post,
then `HighlightPublished`, `UploadPublished`, `FeaturedClipPublished` and `ClipCreated`,
in the order the UI lists them). A new follow subscribes to Live and Highlights. Template
tokens are `streamer`, `category`, `title` and `clipper`; a token a card has no value for
(`clipper` on a live card, `category` on a video) renders empty
(`Feeds::Announcement#blank_tokens`). Its settings live in `feed_twitch_settings`
(`Feeds::Twitch::Settings`, `twitch_settings` on the subscription): one role column per
post type (`live_role_id`, `highlights_role_id`, `uploads_role_id`,
`featured_clips_role_id`, `clips_role_id`), `show_viewers` (true by default) and
`live_end_mode` (see below). `role_id_for` maps an event type to its role column.
`categories` (jsonb array of `{id, name}`, name kept so the UI needs no API call) limits
a follow to chosen categories; empty means every category. `accepts?` checks the
category id for streams and clips; videos have none and always pass. A stream that
starts outside the filter and switches in posts (and pings) at the switch. Without the
bot's Twitch credentials the Twitch jobs return early, so nothing posts.

`post_type(event_type)` maps an event type to the post type it counts as, and
`announced_types` lists every type that can produce a post. Twitch counts
`StreamUpdated` as a Live post, so a switch into the filter posts. `AnnounceJob`
(who is subscribed), `StoryPick` (since when, which copies compete) and the card's
template and role all go through it. `AnnounceJob` subscribes to every source's
`announced_types`, so the two lists cannot drift.

The Live card shows `<name> · Live on Twitch` as the eyebrow, the stream title as the
heading and `Streaming **<category>**` when the channel has a category, followed by a
stats line, `N watching · started <relative time>` (viewers only with `show_viewers` and
a sampled count, else `Started <relative time>`; Discord renders the relative time live,
so the card needs no edit for uptime), with the
channel's profile picture (`watch.image_url`) as the section thumbnail. The image slot
holds the stream preview when Twitch already has a frame, else the category's box art,
else nothing (`Feeds::Twitch::LiveImage`). The preview check is shared per stream for a
minute, so every server following the channel gets the same URL and Discord fetches it once. The accent is Twitch purple and the button
reads "Watch on Twitch". The default notification text is `<name> is live: <title>`.

The video card (`Feeds::Twitch::VideoAnnouncement`, highlights and uploads) shows
`<name> · New highlight on Twitch` or `<name> · New upload on Twitch` as the eyebrow, the
video title as the heading and the length (`About 2 h 36 min`) as the details line, with
the channel's profile picture as the section thumbnail and the video thumbnail as the
image. Videos carry no category and the description is mostly empty or a link, so the card
shows neither. The accent is Twitch purple and the button reads "Watch on Twitch". The
default notification text is `<name> posted a highlight: <title>` or
`<name> uploaded a video: <title>`.

The clip card (`Feeds::Twitch::ClipAnnouncement`, featured and new clips) shows
`<name> · Featured clip on Twitch` or `<name> · New clip on Twitch` as the eyebrow, the
clip title as the heading, `Clipped by <creator> from **<category>**` (without `from` when
the category is unknown) and a stats line, `<seconds> s · made <relative time>`, with the
clip thumbnail as the image. The button reads "Watch the clip". The default notification
text is `New featured clip from <name>: <title>` or `New clip from <name>: <title>`. The
category comes from `Feeds::Twitch::GameLookup`, one cached `/games` call per category for
a day, shared with the Live card's box art; a failed lookup is cached as nil for 10
minutes.

Both cards subclass `Feeds::Twitch::MediaAnnouncement`, which holds what they share
(accent, profile header, eyebrow from the subclass's `LABELS`, thumbnail image, link).

A clip that is both new and featured posts once. `ClipCreated` is secondary, so
`StoryPick` prefers the featured copy. A clip featured after it already posted as new
stays a "New clip" card.

`PostJob` skips an expired event (`Integrations::Event#expired?`, false by default):
a `StreamStarted` or `StreamUpdated` whose session is no longer the watch's open one
(`StreamEvent#expired?`). Only announced types reach `PostJob`, so `StreamSampled` and
`StreamEnded` never ask. The card is
refreshed with title, category, preview or box art and viewers on every `StreamUpdated`
and `StreamSampled`, and edited once more on `StreamEnded` (see Revising a post).

### Switching away

A follow with a category filter can see a stream leave the chosen categories and come
back. `switched_away` (`Feeds::Twitch::Settings`) decides what the live post does while the
stream is outside them, independent of `live_end_mode`:

- `summary` (default): the post is edited into a grey card
  (`Feeds::Twitch::SwitchedAnnouncement`): `<name> · Live on Twitch`, the stream title,
  `Switched to **<category>**` (or `Switched away from the chosen categories` without a
  category) and `Started <relative time>`. No ping line, profile picture kept, the
  "Watch on Twitch" button stays as the stream is still live.
- `delete`: shrkbot deletes the message (`retract?`) and sets the post's `retracted_at`.

Back in a chosen category the live card returns by a normal edit. If shrkbot deleted the
message, `revive?` lets `Posts::Revise` send the card again without a ping and clear
`retracted_at`. A message a moderator deleted, or one lost to a missing channel or
permission, has no `retracted_at` and stays gone; a re-post that hits a missing channel
or permission clears `retracted_at`, so it is not retried on every sample. When the
stream really ends,
`live_end_mode` applies as usual, and a retracted post is not sent again: `revive?` is
false for `StreamEnded`, so the end event does nothing to it.

### How a stream ends

`live_end_mode` decides what happens to the live post when the stream ends
(`Feeds::Twitch::Ending` builds the card):

- `keep`: the live card re-rendered from the story's last live event (ping line and custom
  message kept) plus a last block, `-# Stream ended <relative time>`. Twitch has no frame
  by then, so the image becomes the category box art.
- `delete`: the Discord message is deleted (`retract?`), and the post's `message_id` is cleared
  and `retracted_at` set.
- `mark_ended`: the ended card (`Feeds::Twitch::EndedAnnouncement`): no ping line or custom
  message, grey accent, no image, profile picture kept, no button.
- `mark_ended_with_vod` (default): the ended card with a "Watch the VOD" button when a VOD
  exists, otherwise no button.

The ended card says `<name> · Was live on Twitch`, then either the stream title with
`Streamed **<category>** for about <duration>`, or, with a title history,
`Streamed for about <duration>` and one line per title. A stats line follows:
`At least N viewers at the peak · ended <relative time>` (peak only with `show_viewers`
and a known peak, else `Ended <relative time>`). Every duration reads `about 3 h 12 min`,
rounded to the minute, at least `about 1 min` (`Duration.about`).

Title history (`Feeds::Twitch::TitleHistory`): the go-live title plus every title or
category change, in stream order; a change made after the stream went offline (during the
grace window) is ignored. An entry held for under 5 minutes is dropped, and
consecutive entries with the same title and category merge. It shows only when at least 2
entries remain, at most 15 lines, then `and N more`. A line shows the category only when
the title does not already name it (`Feeds::Twitch::TitleMatch`: the category's words appear
in the title, in order and as whole words, after both are lower-cased, accent-folded,
punctuation turned into spaces, Roman numerals II to XX turned into digits and `&` read as
`and`). There is no typo tolerance: a wrongly hidden category would lose information,
while a redundant one only reads clumsily.

VOD lookup (`Feeds::Twitch::Vod`): one `Videos#for_user` call for the channel's 20 most
recent archives, then the archive of the first session stream id that has one, cached per
session for a day. Only `mark_ended_with_vod` looks. Errors are not rescued: the end edit
is the only chance to add the button, so `RevisePostJob` retries.

## Tables

- `feed_subscriptions` (`Feeds::Subscription`): one row per server and followed watch.
  The `channel_id` to post in. Unique on `[server_configuration_id, watch_id]`.
- `feed_steam_settings` (`Feeds::Steam::Settings`): the Steam-only settings of a
  subscription, 1:1 (unique `subscription_id`). An optional `role_id` to ping,
  `body_length` (`preview` by default, or `full`) and `languages` (empty means every
  language). Check constraints limit `body_length` to its two values and `languages` to
  the model's codes. The row outlives a pause: switching every post type off keeps it.
- `feed_twitch_settings` (`Feeds::Twitch::Settings`): the Twitch-only settings of a
  subscription, 1:1 (unique `subscription_id`). An optional `live_role_id`,
  `show_viewers` and `switched_away` (`summary` or `delete`, check-constrained).
- `feed_subscribed_events` (`Feeds::SubscribedEvent`): the event types a subscription
  wants, each with an optional `template` override and `subscribed_since`, the moment
  that kind of post was followed (see Following since). Unique on
  `[subscription_id, event_type]`.
- `feed_posts` (`Feeds::Post`): one row per story a subscription posted, holding
  the `story_key`. It is written before the message is sent, so it is the claim that
  keeps a story from posting twice. `channel_id` and `message_id` are set after the send
  (null while it is in flight, and on rows from before they were recorded).
  `retracted_at` is set when shrkbot deletes the message, which tells that deletion apart
  from a lost message. Unique on `[subscription_id, story_key]`.

`watch_id` points at `integration_watches`; see
[../integrations/overview.md](../integrations/overview.md) for what a watch is.

## `Subscription.active`

A subscription is **active** when its server is real (not a preview) and has both the
`integrations` plugin and the source's sub-plugin enabled. Each source in
`Feeds.sources` names its watcher classes and its sub-plugin key (`Feeds::Steam`:
`Integrations::Steam::NewsWatcher`, `:steam`), so a new source is one module and one
entry there. `Feeds::Subscription` is registered as a demand source in
`config/initializers/integrations.rb`, and a watch is polled only while an active
subscription points at it.

Turning a plugin off keeps the subscription rows: the server's choices survive, the
subscription goes inactive, and the watch stops being polled once no active
subscription is left.

`Subscription.demanding(event_types)` narrows `active` to subscriptions that follow any of
those event types; `AnnounceJob` and `Watch.demanding` build on it.

## Purge

`ServerConfiguration has_many :feed_subscriptions, dependent: :destroy`. Destroy rather
than delete so each subscription's `subscribed_events` and `posts` go with it; its
`steam_settings` row goes with it too (`dependent: :delete`). That is the guild
purge; there is no separate path. The watch itself is shared between servers and is
removed by the orphan prune once nothing references it.

## Posting

    RecordObservation -> Bus -> AnnounceJob(event) -> PostJob(subscription, event) -> Posts::Create

- `Feeds::AnnounceJob` is the bus handler for the three Steam news event classes. It
  enqueues one `Feeds::PostJob` per `active` subscription on the event's watch that has
  a `feed_subscribed_events` row for the event's post type and no `Post` for its story
  yet (a stream's title edits would otherwise queue one dead job per follow each).
- `Feeds::PostJob` checks, in order, that the subscription is still `active`, that it has
  no `Post` for the story yet, that `Feeds::StoryPick` finds the event eligible (its type
  is followed and it was published at or after that type's `subscribed_since`), and that no
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
  plain content, allowing only the role the source names (`role_id_for`) to ping, then converts the
  message into the card with the default suppressed mentions, all through
  `Components.create_with_subject` with `fallback: announcement.fallback`. The card
  carries untrusted post text, so nothing in it can ping. The `Post` is written first, as
  the claim, and released again only if the create raises; once the message exists the
  claim is kept. When the conversion fails, the plain message is edited to
  `Announcement#fallback`: the subject cut so that the whole link still fits in 2000
  characters.

## Revising a post

    Twitch::Streams::Transition -> Events::Record -> Bus -> ReviseJob(event) -> RevisePostJob(post, event) -> Posts::Revise

- `Feeds::ReviseJob` is the bus handler for `StreamUpdated`, `StreamSampled` and
  `StreamEnded`. It
  enqueues one `Feeds::RevisePostJob` per sent post (`message_id` set) or retracted post
  (`retracted_at` set) of the event's story on an `active` subscription of the event's watch.
- `Ops::Feeds::Posts::Revise` edits only when the event is the story's latest, so a
  retried older refresh never overwrites a newer one. The end edit runs on
  `RevisePostJob`'s per-post key, so a refresh that passed `latest?` finishes before it.
  It re-renders through the source's `announcement` and edits with mentions suppressed,
  so nothing pings again (`Components.edit`). When the source `retract?`s the event, it
  deletes the message, clears `message_id` and sets `retracted_at` instead. A post with no
  `message_id` but a `retracted_at` is sent again (`Feeds::AnnouncementMessage`, the same
  send `Posts::Create` uses, with mentions suppressed) when the source `revive?`s the event.
- A message that can no longer be edited (a human deleted it, the channel is gone or the
  bot lost its permission) clears `message_id`, so later refreshes skip the post.

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
is created. A post published earlier (`Integrations::Event#published_at`: `occurred_at`,
or a stream's `started_at` for every event of that stream) is never eligible, so a server
that follows a channel mid-stream waits for its next stream instead of being pinged at
the next title edit. `StoryPick`
ignores it when ranking, so a copy the subscription could never have received cannot
displace one it could.

`Ops::Feeds::SubscribedEvents::Resume` resets it to now for the server's subscriptions
when `integrations` is enabled again (all of them) or a source plugin is (the subscriptions on
that source's watches). Off means off: re-enabling must not post what was published
while it was off. Editing a subscription does not reset it.

It replaces priming. A watch stores whatever is fresh and not yet stored, and the gate decides
what a server gets, so a fresh or long-unpolled watch never replays its backlog.

## Language

A copy is eligible only if its subscription accepts its language
(`source.accepts?`, which for Steam checks `Settings#accepts_language?`; a copy of
unknown language always passes). The check lives in `StoryPick`, not `AnnounceJob`, so a story's copy in an accepted language
still wins when its primary copy is filtered out.

## What a post looks like

`Feeds::Announcement` is the shared base: subject, fallback, lead line, mentions and the
card frame with the source's accent colour and link button. `Feeds::Steam::Announcement`
and `Feeds::Twitch::Announcement` fill in tokens, headline, blocks, url and link label.
The rest of this section describes the Steam renderer, which builds both messages.

The **subject** is the plain first message, so it is also the push-notification text.
It is the role mention plus the subscription's custom message, or, when there is no
custom message, the headline `<game> · <type>: <title>`, stripped and cut to 2000
characters. The custom message is optional and empty by default. It is the subscribed
event's `template` filled by `TemplateText`, with the tokens `game`, `author` and
`feed`. A stored template that still has `{title}` or `{url}` from before those tokens
were removed renders them literally.

The type in the eyebrow and headline comes from `Feeds::Steam::Announcement::TYPE_LABELS`
(`Patch notes`, `Announcement`). Articles fall back to their feed label, such as
`Team Fortress 2 · Rock Paper Shotgun`.

The **card** replaces the subject message. When there is a role mention or a custom
message, they sit on a lead line above the container, outside it. The container holds a
section with the eyebrow (`-# <game> · <type>`) and the title as a heading (cut to 256
characters), with the game's artwork as the section thumbnail (plain texts when there is
none), then the body excerpt, the post's first image when it has one, and a link button to
the original below it.

The thumbnail is the game's Steam hero capsule
(`Integrations::Steam::StoreItems#hero_capsule_url`), downloaded through
`Steam::Client#get_bytes`. Discord crops thumbnails to a square, so `Feeds::SquareImage`
pads it to a transparent square WebP. `Feeds::Steam::Thumbnail` caches the URL for a day
per game and the padded image for a day per URL (Steam's URL carries a hash that changes
with the art), so a story followed by many servers is fetched once. A failed lookup or
download is cached as nil for 10 minutes under its own key (`Feeds::CachedFetch`, shared
with the Twitch box art). libvips runs with untrusted loaders blocked
(`config/initializers/vips.rb`). `Feeds::Steam::Announcement#attachments` uploads the image
with the message as `thumbnail.webp`, which the section references as `attachment://thumbnail.webp`. On any
failure the card posts without a thumbnail. The web preview shows no thumbnail.

**Body length** is a per-subscription setting. `preview` (the default) keeps about 500
characters and `full` about 3500, under Discord's 4000 for the whole message.
The lead line, eyebrow and heading share Discord's 4000-character text budget
(`Feeds::Steam::Announcement::TEXT_LIMIT`) with the excerpt: `Feeds::Steam::Announcement` passes `Excerpt` the room
left after those three, and the excerpt shrinks to fit.
`Feeds::Excerpt` takes the body length setting and looks up the limit itself. Past it,
it cuts at the last paragraph break (when that keeps at least half the limit), else the
last line break (same rule), else the last space, and appends "…". A cut that leaves a code fence open closes it
first, with the "…" on the line after.

## Retention

`Ops::Feeds::Posts::Prune` runs daily at 5:40 and deletes posts older than 14 days
(`Ops::Integrations::Prune::RETENTION`), the same age the events they came from are
pruned at. A server's posts are deleted with its subscriptions (`dependent:
:delete_all`).
