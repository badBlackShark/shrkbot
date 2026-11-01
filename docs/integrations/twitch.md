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
| `Twitch::Channels#for(broadcaster_ids)` | `GET /channels` | `[Twitch::Channel]` |
| `Twitch::Streams#live(user_ids)` | `GET /streams` | `[Twitch::Stream]` |
| `Twitch::Videos#for_user(user_id, type:, first:)` | `GET /videos` | `[Twitch::Video]` |
| `Twitch::Clips#for_broadcaster(broadcaster_id, started_at:, ended_at:, featured:)` | `GET /clips` | `[Twitch::Clip]`, every page |
| `Twitch::Schedule#segments(broadcaster_id, start_time:, first:)` | `GET /schedule` | `[Twitch::Segment]` |
| `Twitch::EventSubSubscriptions#all` | `GET /eventsub/subscriptions` | `[Twitch::EventSubSubscription]` |
| `Twitch::EventSubSubscriptions#create(type:, version:, condition:, callback:)` | `POST /eventsub/subscriptions` | `Twitch::EventSubSubscription` |
| `Twitch::EventSubSubscriptions#destroy(id)` | `DELETE /eventsub/subscriptions` | `nil`, also when Twitch already removed it (404) |

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
