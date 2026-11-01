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
| `Twitch::Videos#for_user(user_id, type:, first:)` | `GET /videos` | `[Twitch::Video]` |
| `Twitch::Clips#for_broadcaster(broadcaster_id, started_at:, ended_at:, featured:)` | `GET /clips` | `[Twitch::Clip]`, every page |
| `Twitch::Schedule#segments(broadcaster_id, start_time:, first:)` | `GET /schedule` | `[Twitch::Segment]` |
| `Twitch::EventSubSubscriptions#all` | `GET /eventsub/subscriptions` | `[Twitch::EventSubSubscription]` |
| `Twitch::EventSubSubscriptions#create(type:, version:, condition:, callback:)` | `POST /eventsub/subscriptions` | `Twitch::EventSubSubscription` |
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
`login`, `display_name`, `peak_viewers` and, while the stream is down, `offline_at`.
Times are ISO 8601 strings. An ended session keeps only `login` and `display_name`.

A session is **stale** when its `last_live_at` is more than `Session::STALE_AFTER`
(20 minutes: the grace period, one 10-minute reconcile and slack) old. That covers our
downtime and a channel nobody followed for a while, whose state froze: the session ends
at `last_live_at`, so its duration stays true.

| Observation | State | Result |
| --- | --- | --- |
| `Live` | no session | start; `StreamStarted` at the stream's `started_at` |
| `Live` | stale session, a stream id it has not seen | end at `last_live_at`, then start; `StreamEnded` + `StreamStarted` |
| `Live` | session otherwise | continue: stamp `last_live_at`, add the stream id (a reconnect with a new id merges), drop `offline_at`, raise the peak; `StreamUpdated` when title or category changed |
| `Offline` | no session | nothing |
| `Offline` | stale session | end at `last_live_at` |
| `Offline` | session, no `offline_at` | set `offline_at = now`, schedule the close check; no event |
| `Offline` | otherwise | nothing |
| `Close(offline_since)` | session, `offline_at == offline_since` | end at `offline_at` |
| `Close(offline_since)` | back live, already ended or a stale time | nothing |

A stale session that sees its own stream id again continues: the stream never ended, we
only missed it.

End: `StreamEnded` carries `ended_at`, `duration` (seconds from `started_at`) and
`peak_viewers`.

**Subject keys:** `stream:<session>` (started), `stream-update:<session>:<now unix>`
(updated), `stream-end:<session>` (ended). **Story key:** `stream:<session>` on every
stream event, so the three belong to one story. `StreamUpdated` fires on a title or
category change only; viewer counts and name changes never emit. `Events::Record` skips
an event whose type and subject key the watch already stored, so a closed session that
reopens on the same stream id does not break on the unique index.

`Twitch::StreamReconcileJob` runs every 10 minutes. It asks `Streams#live` for every
demanded Twitch watch in one batch (100 ids per call), stamps `polled_at` and clears the
failure fields (`RecordPolls`: Twitch answered, so the watches are readable), then
transitions each watch with `Live` or `Offline`. A transition that would drop an invalid
event raises and rolls back, so the state never claims a session whose event was lost.
Without push, an end is noticed by the close check 5 minutes after the first offline
reconcile, so up to 15 minutes late.

Failures map onto the shared machinery (`RecordsWatchFailures`, shared with `PollJob`).
An `Integrations::Error` from the live call records `RecordFailure` on every watch,
which feeds the 24-hour broken-watch report (a persistent `Unauthorized`, say). A
`RateLimited` also enqueues `ReportRateLimitJob`, unless any watch already says
`Integrations::RateLimited`. An exception from one watch's transition is recorded on
that watch and reported through `ReportPollBugsJob` only when its last error was
something else, so a persistent bug reports once; the other watches still transition.
Nothing creates Twitch watches yet, so in production the job finds no demanded watch
and does nothing.

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

Not recorded:

- `eventsub_subscription_created_documented_example.json` is the example response from
  Twitch's "Create EventSub Subscription" reference, because creating one needs a public
  callback.
- `eventsub_subscriptions_handwritten.json` is written by hand in the documented shape, so
  the mapping runs against an enabled subscription.
