# Twitch

Channel lookups, live streams, videos, clips, schedules and EventSub webhook
subscriptions, all on Helix (`https://api.twitch.tv/helix`). Every call needs an app
access token; none needs a user's login. The provider layer (see
[overview.md](overview.md)) stores nothing.

## Client

`Integrations::Twitch::Client` is the one home for the host and the credentials.
`Client.configured?` is true when `TWITCH_CLIENT_ID` and `TWITCH_CLIENT_SECRET` are both
set; a caller checks it before building anything else. Its `get_json`, `post_json` and
`delete` add `Client-Id` and `Authorization: Bearer <token>` and hand off to `Http`.
`get_all` calls `get_json` once per page, following `pagination.cursor` through the
`after` parameter until the cursor is absent, and joins what the block returns.

**A Helix 403 is not a token problem.** Only a 401 means the token is invalid. A 403
means the app lacks an authorization (an EventSub create without the broadcaster's
consent answers 403 "subscription missing proper authorization"). `Client` maps 403 to
`Error` under every endpoint's own `status_errors`, so a 403 never drops the token.

`Twitch::AppToken` fetches the token with the client-credentials grant (a form POST to
`https://id.twitch.tv/oauth2/token`, where 400 and 403 mean bad credentials, so both map to
`Unauthorized`). The token is cached in `Rails.cache` under
`integrations/twitch/app_token` with a TTL of `expires_in` minus one day (half of
`expires_in` for a token that lives less than two days), and each `AppToken` instance
memoizes it. A 401 from Helix invalidates the token and retries the call once with a
fresh one; a second 401 raises `Unauthorized`. A failed token fetch raises at once.

| Resource | Endpoint | Returns |
| --- | --- | --- |
| `Twitch::Users#find_by_login(login)` | `GET /users` | `Twitch::User`; `NotFound` for an unknown login, `InvalidReference` for a malformed one (400) |
| `Twitch::Users#for(user_ids)` | `GET /users` | `[Twitch::User]`, 100 ids per call |
| `Twitch::Channels#for(broadcaster_ids)` | `GET /channels` | `[Twitch::Channel]` |
| `Twitch::Streams#live(user_ids)` | `GET /streams` | `[Twitch::Stream]` |
| `Twitch::Games#find(id)` | `GET /games` | `Twitch::Game` (box art at 285x380), `nil` for an unknown id |
| `Twitch::Videos#for_user(user_id, type:, first:)` | `GET /videos` | `[Twitch::Video]` |
| `Twitch::Clips#for_broadcaster(broadcaster_id, started_at:, ended_at:, featured:)` | `GET /clips` | `[Twitch::Clip]`, every page |
| `Twitch::Schedule#segments(broadcaster_id, start_time:, first:)` | `GET /schedule` | `[Twitch::Segment]` |
| `Twitch::EventSubSubscriptions#all` | `GET /eventsub/subscriptions` | `[Twitch::EventSubSubscription]` |
| `Twitch::EventSubSubscriptions#create(type:, version:, condition:, callback:)` | `POST /eventsub/subscriptions` | `Twitch::EventSubSubscription`, `nil` when it already exists (409) |
| `Twitch::EventSubSubscriptions#destroy(id)` | `DELETE /eventsub/subscriptions` | `nil`, also when Twitch already removed it (404) |

## Channel input

`Twitch::ChannelReference.parse(input)` turns what a user types into a lowercase login
and raises `InvalidReference` otherwise. It accepts a bare login (`shroud`), `@shroud`,
and a `twitch.tv/<login>` URL with or without scheme, `www.` or `m.`, with a sub-path or
query (`https://www.twitch.tv/shroud/videos`). Logins are 1 to 25 letters, digits or
underscores. A reserved first path segment (`twitch.tv/videos/123`, `/directory`) parses
as that login and then comes back `NotFound` from `/users`, which is the right answer.
`Twitch::ChannelWatcher` has `resolve` (input to `Target`) and `refresh`
(ids to `Target`s); it has no `observe`, because media polling is not built yet.

## Live state

A channel's live state lives in `integration_watches.state` (jsonb, default `{}`), one
session per watch. `Twitch::Session` is the pure rule set: it takes the state and `now`,
applies one observation and returns an `Outcome` (new state, unsaved events,
`went_offline`). `Ops::Integrations::Twitch::Streams::Transition` runs it under the
watch's row lock, saves the state, hands the events to `Ops::Integrations::Events::Record`
and, when the stream just went offline, schedules `Twitch::CloseSessionJob` for
`Session::GRACE` (5 minutes) later. The close job asks `/streams` about that one channel
first: live again (a reconnect, often with a new stream id) continues the session, still
offline ends it. If Twitch fails the check, the session stays open and the stale rule
below ends it.

State keys: `session` (the first stream id of the session), `stream_ids`, `title`,
`category_id`, `category_name`, `started_at`, `last_live_at` (the latest live sighting),
`login`, `display_name`, `viewer_count` (the last sampled count, nil until the first
`/streams` sighting), `peak_viewers`, `titles_pushed` (set by the first
`ChannelUpdate`) and, while the stream is down, `offline_at`.
Every stream event carries `viewer_count`. `StreamSampled` is emitted once per `/streams`
sighting of an open session (every 10 minutes through the reconcile), with subject key
`stream-sample:<session>:<epoch>` and story key `stream:<session>`. A push go-live has no
count.
Keys are strings and times are ISO 8601 strings, because jsonb hands both back that
way: symbol keys would make a fresh state differ from the reloaded one. An ended
session keeps only `login`, `display_name` and `ended_stream_ids` (its `stream_ids`).

A session is **stale** when its `last_live_at` is more than `Session::STALE_AFTER`
(20 minutes: the grace period, one 10-minute reconcile and slack) old. That covers our
downtime and a channel nobody followed for a while, whose state froze: the session ends
at `last_live_at`, so its duration stays true.

| Observation | State | Result |
| --- | --- | --- |
| `Live` | no session, a stream id in `ended_stream_ids` | nothing (a lagging `/streams` or a replayed push) |
| `Live` | session, a known stream id, less than `GRACE` after `offline_at` | nothing (a lagging `/streams` after a pushed offline) |
| `Live` | no session | start; `StreamStarted` at the stream's `started_at` |
| `Live` | stale session, a stream id it has not seen | end at `last_live_at`, then start; `StreamEnded` + `StreamStarted` |
| `Live` | session otherwise | continue: stamp `last_live_at`, add the stream id (a reconnect with a new id merges), drop `offline_at`, raise the peak; `StreamUpdated` when title or category changed, unless `titles_pushed` (then push owns them and a lagging poll cannot undo a pushed title); `StreamSampled` when the observation carries a viewer count (a `/streams` sighting) |
| `Offline` | no session | nothing |
| `Offline` | stale session | end at `last_live_at` |
| `Offline` | session, no `offline_at` | set `offline_at = now`, schedule the close check; no event |
| `Offline` | otherwise | nothing |
| `Close(offline_since)` | session, `offline_at == offline_since` | end at `offline_at` |
| `Close(offline_since)` | back live, already ended or a stale time | nothing |
| `ChannelUpdate` | session | `StreamUpdated` when title or category changed; no sighting stamp |
| `ChannelUpdate` | no session | nothing |

A stale session that sees its own stream id again continues: the stream never ended, we
only missed it.

End: `StreamEnded` is stamped with the time the session closed (`occurred_at`), so it sorts
after a title change made during the grace window; `ended_at` is when the stream went
offline. It carries `ended_at`, `duration` (seconds from `started_at`),
`stream_ids` (every stream id the session merged) and `peak_viewers`, which is nil when no `/streams` sighting came before the end (a push
go-live that ended within the first reconcile interval).

**Subject keys:** `stream:<session>` (started), `stream-update:<session>:<now unix>`
(updated), `stream-sample:<session>:<now unix>` (sampled), `stream-end:<session>` (ended).
**Story key:** `stream:<session>` on every stream event, so all four belong to one story.
`StreamUpdated` fires on a title or category change only; a name change never emits. `Events::Record` skips
an event whose type and subject key the watch already stored, so a closed session that
reopens on the same stream id does not break on the unique index.

`Twitch::StreamReconcileJob` runs every 10 minutes. It asks `Streams#live` for every
Twitch watch in `ChannelWatcher.followed_for_live` (watches some active subscription follows
Live for) in one batch (100 ids per call), then transitions each watch with `Live` or
`Offline`. A transition that would drop an invalid
event raises and rolls back, so the state never claims a session whose event was lost.
With EventSub push (below) an end is noticed at once; only the poll path lags: the close
check runs 5 minutes after the first offline reconcile, so up to 15 minutes late.

The reconcile writes no watch health: `failing_since`, `last_error` and `polled_at` belong
to the per-watch poll, so its failures are not cleared every 10 minutes by the live
check. A failed live call is logged. After 24 hours of failed live calls
(`Watch::BROKEN_AFTER`, counted from a job-level "failing since" in the cache that a
successful call clears) `Twitch::ReportLiveCheckBrokenJob` DMs the owner, at most once a
day: without the check, live cards stop updating and only EventSub notices an end. Like a
watch's `failing_since`, the stamp lapses after `Watch::DORMANT_AFTER` without a run, so an
old outage never counts toward a new one. A `RateLimited` also DMs the owner through
`ReportRateLimitJob`, at most once a day (`NotifiesOwner.claim`). An `Unauthorized`
(Twitch rejected the app credentials, say after a leak) DMs at once through
`Twitch::ReportUnauthorizedJob`, at most once a day; nothing retries its way out of a
revoked secret. An `Integrations::Error` from one watch's transition is logged and the
next run retries it. Any other exception from a transition is logged with its backtrace
and DMs through `ReportPollBugsJob`, at most once a day per watch and error class; the
other watches still transition. Nothing creates Twitch watches yet, so in production the
job finds no live watch and does nothing.

## EventSub

Twitch pushes `stream.online`, `stream.offline` and `channel.update` (v2) for every
channel followed for Live (`ChannelWatcher.followed_for_live`) to `POST /api/twitch/eventsub` (`Api::Twitch::EventSubsController`).
`Twitch::EventSub.verified?` checks every request first: the signature is
`sha256=` plus the HMAC-SHA256 of message id + timestamp + raw body under
`TWITCH_EVENTSUB_SECRET`, compared in constant time, and the timestamp must be within 10
minutes of now in either direction. A failed check answers 403 and does nothing else.

| Message type | Answer | Effect |
| --- | --- | --- |
| `webhook_callback_verification` | 200, the `challenge` as plain text | none |
| `notification` | 204 | `Twitch::NotificationJob` |
| `revocation` | 204 | warning log, `Twitch::EventSubReconcileJob` |
| anything else, or an unparsable body | 400 | none |

`NotificationJob` finds the watch in `ChannelWatcher.followed_for_live` by `broadcaster_user_id` (anything else is
dropped) and maps the event onto a Session observation. `stream.online` becomes `Live`
from the event plus a `/channels` lookup for title and category; viewers stay nil until the
stream reconcile samples them. `stream.offline` becomes `Offline`. `channel.update`
becomes `ChannelUpdate`, which changes title and category of an open session (a
`StreamUpdated` when they differ) and never stamps `last_live_at`. A Twitch failure in
the job is logged; the stream reconcile catches up. A duplicate delivery changes nothing,
because every Session rule is idempotent, so there is no Message-Id ledger. A late
duplicate `stream.online` after the end at worst reopens the session until the next
stream reconcile ends it again; `Events::Record` skips the already stored start and end,
so nothing posts twice. `Twitch::EventSub` is the one home for the webhook secret:
`Client` holds the app credentials, `EventSub` the secret that signs Twitch's calls to us.

`Twitch::EventSubReconcileJob` runs every 5 minutes. It needs the Twitch credentials,
`TWITCH_EVENTSUB_SECRET` and an `https` `WEB_BASE_URL`; otherwise it does nothing.
`Twitch::EventSubDiff` decides the work. A subscription is kept when its status is
`enabled` or `webhook_callback_verification_pending`, its callback is the receiver URL,
and its type, version and channel are wanted (all three types for every
followed channel). Everything else is deleted: other statuses, another callback, an old version,
a channel nobody follows for Live, and duplicates beyond the first. Missing ones are created; a 409
counts as already there. Twitch keeps disabled webhook subscriptions listed for at least
10 days, so the reconcile sees every revocation.

Statuses `notification_failures_exceeded`, `version_removed` and
`webhook_callback_verification_failed` DM the owner (`ReportEventSubJob`); other disabled
statuses are recreated silently. The revocation DM is claimed before any delete, so a
failure later in the run cannot lose it. A create failure DMs, grouped by error, only
when the same error also failed the run before (a cache mark for `REPEAT_WINDOW`, 11
minutes); a passing blip stays quiet. Each status or error DMs at most once a day (a
cache key per message). A `RateLimited` stops the run and sends the rate-limit DM, also
once a day.

Rotating the secret: set the new `TWITCH_EVENTSUB_SECRET`, deploy, then run
`bin/rails runner 'Integrations::Twitch::EventSubReconcileJob.perform_now(rebuild: true)'`.
Between the deploy and the rebuild notifications fail the signature check and the stream
reconcile covers live state. A rebuild rate-limited while it deletes enqueues itself
again with `rebuild: true` once the limit resets (a minute at the earliest); it has
created nothing yet, so it loses nothing. Rate-limited while it creates, every old
subscription is already gone, so the regular runs create the rest and keep the new ones.
A resumed rebuild that comes due while a regular run holds the concurrency key is
discarded; the old-secret subscriptions then fail their notifications until Twitch
revokes them (`notification_failures_exceeded`, which DMs) and the reconcile recreates
them. After a rotation, run the rebuild again if that DM arrives.

In development no subscriptions get created (the callback must be https on 443). With
`TWITCH_EVENTSUB_SECRET` set, the receiver can be exercised with the Twitch CLI:
`twitch event trigger stream.online -F http://localhost:3000/api/twitch/eventsub -s <secret>`.

## Mapping notes

Recorded live on 2026-10-30 (see Fixtures); the absent-value forms come from Twitch's
Helix reference, because no recorded item had them.

- **Ids are strings**, including user, video and stream ids. Keep them as strings.
- **Absent values are `""` or `null`.** `game_id` and `game_name` (no category) and a
  clip's `video_id` are `""`; a video's `stream_id` is `null` unless it is an archive.
  `.presence` maps both to `nil`.
- **Batches.** `Channels` and `Streams` send at most 100 ids per call (Helix's limit) and
  concatenate the slices; an empty list makes no request. The ids go as a repeated key
  (`user_id=1&user_id=2`), which is how `URI.encode_www_form` encodes an array and how
  Helix reads it.
- **Stream thumbnails** keep their `{width}x{height}` template; the card that shows one
  fills it in.
- **Video thumbnails** carry `%{width}x%{height}`; `Videos` substitutes `320x180`, the one
  size Twitch serves for them.
- **Video durations** are `1h4m35s`, `3m21s` or `45s`; `Videos` reads them to integer
  seconds. Anything else raises `Unavailable`.
- **Clips** come sorted by views, highest first, not by time. **Without `ended_at`, Twitch
  ends the window one week after `started_at`**, and the low-view clips of a longer
  window drop off the first page. Checked live on 2026-10-31: `started_at` 30 days back
  returned a full page whose clips all came from the first week; with `ended_at`, the same
  call reached the day before. `Clips` always sends `ended_at` (default:
  now) and reads every page at 100 per page. `is_featured` is sent only when `featured:`
  is not `nil`. A clip's `duration` is a number of seconds that can be fractional. Clip
  thumbnails are already sized.
- **Schedule.** A channel without a schedule answers 404, which `Schedule#segments` turns
  into `[]`. `segments` can be `null`. A segment's `category` is `null` when none is set,
  `end_time` is `null` for open-ended segments, and `title` can be `""`. `canceled_until`
  is `null` unless that occurrence is canceled.
- **EventSub.** `#create` signs with `TWITCH_EVENTSUB_SECRET`. `#all` reads every page
  through `get_all`. `#destroy` of an id Twitch already removed answers 404, which
  counts as deleted. `condition` stays a string-keyed hash; `callback` is read from
  `transport.callback`.

## Images

Box-art URLs can't be built from the id: some categories use an `<id>_IGDB` path, and the
plain id redirects to `404_boxart`. So `Games#find` asks `/games`, and Feeds caches the
result per category for a day. `ChannelWatcher.preview_url(login)` HEADs the static-cdn
preview, which redirects (302) to `404_preview` until the stream's first frame exists
(checked 2026-11-02: still the placeholder 4 minutes in), and costs no Helix point.

`ChannelWatcher.vod_url(user_id, stream_ids)` finds a session's VOD with one
`/videos?type=archive` call: the archive of the first stream id that has one.

## Rate limit

Helix allows 800 points per minute for an app token; most reads cost 1. A 429 carries
`Ratelimit-Reset`, the unix time the bucket refills. `Client` reads it from
`RateLimited#headers` and sets `retry_after` to the seconds until then (never negative)
when `Http` found no `Retry-After`. The rule stays in `Client` because the IETF draft
header of the same name counts seconds, not a unix time.

## Fixtures

Recorded live on 2026-10-30 in `spec/fixtures/integrations/twitch/`, trimmed to two or
three items:

- `users_twitchdev.json`, `channels_twitchdev.json`, `videos_twitchdev.json`: TwitchDev.
- `streams.json`: two channels that were live (caedrel, riotgames).
- `clips_lirik.json`: LIRIK's last 30 days.
- `schedule_criticalrole.json`: a schedule with categories. `schedule_lirik.json`: segments
  with no category, no end time and an empty title.
- `eventsub_subscriptions.json`: an app with no subscriptions.
- `games_minecraft.json`: recorded 2026-11-03, with an `_IGDB` box-art path.

Not recorded:

- `eventsub_subscription_created_documented_example.json` is the example response from
  Twitch's "Create EventSub Subscription" reference, because creating one needs a public
  callback.
- `eventsub_subscriptions_handwritten.json` is written by hand in the documented shape, so
  the mapping runs against an enabled subscription.

## Feeds

Twitch's Feeds source is `Feeds::Twitch` (see [../plugins/feeds.md](../plugins/feeds.md)). The Live card is described there.
