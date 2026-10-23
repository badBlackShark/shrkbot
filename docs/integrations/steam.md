# Steam

Game news and store lookups. Neither endpoint needs an API key or any authentication.
The provider layer (see [overview.md](overview.md)) stores nothing; the news watcher
below keeps what it fetched as events.

`Integrations::Steam::Client` is the one home for Steam's two hosts (`:api` for
`api.steampowered.com`, `:store` for `store.steampowered.com`) and is where a Web API
key would go. Two resources use it:

| Resource | Endpoint | Returns |
| --- | --- | --- |
| `Steam::News#for_app(app_id, count: 20)` | `api` `/ISteamNews/GetNewsForApp/v2/` | `[Steam::NewsItem]` |
| `Steam::Apps#find(app_id)` | `store` `/api/appdetails` | `Steam::App` |

## News

Parameters sent: `appid`, `count`, and `maxlength=0`. **`maxlength=0` means the full
body**; any other value truncates `contents`.

The body format follows `feed_type`: **BBCode** (`[p]`, `[list]`, `[*]`, `[url]`,
`[img]`, `[table]`, ...) for `feed_type 1`, **HTML** (`<p>`, `<ul>`, `<li>`,
`<br>`, ...) for every `feed_type 0` feed. Neither is Markdown. Checked live on
2026-10-22 over 120 items from 1086940, 413150 and 730 plus the TF2 fixture, with
no exception.

Mapping notes:

- `gid` is a string; keep it as one.
- `author` can be `""` (the `tf2_blog` mirror); it becomes `nil`.
- `date` is unix seconds, mapped with `Time.zone.at`.
- `tags` is **absent** on untagged items, not an empty list; it becomes `[]`.
- `feed_type` is `1` for Steam community posts and `0` for everything else.

### The 403 quirk

Steam answers an unknown app id with **403 and `{}`**, not 404. `Http` maps 403 to
`Unauthorized`, which would look like our credentials failing, so `News` passes
`status_errors: {403 => NotFound}`. It lives in `News`, not `Client`, because on
Steam's keyed endpoints a 403 does mean a bad key: the meaning is per endpoint.

Checked live on 2026-10-22: an unknown id, `0` and a non-numeric `abc` all get 403
`{}`, and this endpoint ignores a `key` parameter (a bogus one still gets 200). On
this endpoint a 403 has only ever meant an unknown app.

### What the feeds contain

Sampled live on 2026-10-22 across ten games (440, 570, 730, 105600, 413150, 553850,
892970, 1086940, 1145360, 1172470).

- **`feed_type 1` is only ever `steam_community_announcements`**: the developer's own
  posts. The tag `patchnotes` marks patch notes **when the developer tags them**.
  Hades has 7 announcements with 1 tagged; Stardew has 2 with none. The other tags
  (`workshop`, `vo_marketing_message`, `mod_reviewed`, `ModAct_*`, `hide_*`) are
  Steam-internal and mean nothing to us.
- **`feed_type 0` is everything else, and open-ended**: press (PC Gamer, PCGamesN,
  Rock Paper Shotgun, VG247, Eurogamer, GamingOnLinux, SteamDB, Gamemag.ru,
  PlayGround.ru), game blogs (`tf2_blog`) and Valve's legacy `steam_updates`. Feed
  names are inconsistent: Rock Paper Shotgun appears as both `rps` and `Rock, Paper,
  Shotgun`. Press dominates popular games: Baldur's Gate 3 had 40 of its last 40
  items from press, Stardew Valley 38 of 40.
- **Duplicates exist only across feeds.** TF2 posted each update three times
  (community announcement, `steam_updates`, `tf2_blog`) within a minute, and its
  community posts are mirrored to `tf2_blog` within 0 to 9 minutes with differently
  formatted bodies. `spec/fixtures/integrations/steam/news_440.json` is exactly that
  triple.
- **Within one feed, identical titles are distinct items.** Counter-Strike 2 has 24
  posts titled "Counter-Strike 2 Update", and TF2's five different updates share their
  title and the first 80 normalised characters of their body. Matching on title or
  body prefix is only safe across feeds.

## Store lookup

`appdetails` is keyed by the app id as a string:
`{"1145360": {"success": true, "data": {...}}}`. `filters=basic` trims the answer to
`type`, `name`, `steam_appid`, `header_image` and a few other basic fields. `type` is
`game`, `dlc`, `music`, and so on; `App` carries it as-is and does not filter by it.

An unknown id is **HTTP 200 with `success: false`**, which `Apps#find` raises as
`NotFound`.

`Apps` passes `status_errors: {403 => Unavailable}`. The endpoint takes no key, so a
403 there can't be about our credentials; the likely cause is the store refusing a
busy IP for a while, which is transient.

These store endpoints are **unofficial and rate-limited**: Steam does not document
them, and a 429 surfaces as `RateLimited`. Call them when a person gives you a game,
never from a recurring poll. `store.steampowered.com/api/storesearch/?term=...`
searches by name and returns images; it was checked live but no resource wraps it,
and the same caveats apply.

## News watcher

`Integrations::Steam::NewsWatcher` follows one app's news (see Watchers in
[overview.md](overview.md)).

**Inputs.** `resolve` takes what a person pastes. `Steam::AppReference.parse` reads a
bare id or `/app/<id>` anywhere in a store, community hub or SteamDB URL, and raises
`NotFound` for zero or anything else (`/sub/123`, a game name). `Apps#find` then
names the app.

**Categories to event classes.**

| Item | Event |
| --- | --- |
| `feed_type 0` | `ArticlePublished` |
| tagged `patchnotes` | `PatchNotesPublished` |
| anything else | `AnnouncementPublished` |

All three are `NewsEvent`s.

**Payload.** `title`, `url`, `author`, `feed_name`, `feed_label`, `body` (Markdown),
`image_urls` and `story_key`. `url` is the API's `url` as-is. For community posts it
redirects to the right steamcommunity announcement. The store's
`/news/app/<id>/view/<gid>` form is a single-page app that answers 200 for a made-up
gid, so it can't be verified and isn't built.

**Images.** Every image is lifted out of the body into `image_urls`, in order. 94 of
187 sampled community posts carry images (median 2, max 58); 203 of 213 press items
carry exactly one, 172 of them at the top.

**Story links.** One update arrives through several feeds (see above), so
`Steam::Stories` gives them a shared `story_key` for the feed to collapse later.

- Rule: same normalised title (downcased, non-alphanumerics to one space), within 15
  minutes, and never two items of the same feed in one story.
- Algorithm: events go in `[occurred_at, subject_key]` order. A re-observed item
  copies its stored key. Otherwise the candidates are recent and already-assigned
  events with the same title inside the window; the first of their stories without a
  member from this event's feed is joined, else the event starts its own story keyed
  by its `subject_key`.
- Ceiling: a mirror that lands in a later poll than the item it mirrors still links
  through the persisted event. One that lands more than 15 minutes later stays a
  separate story.

**BBCode.** `Steam::Bbcode.to_html` converts `feed_type 1` bodies before
`HtmlToMarkdown`.

| BBCode | HTML |
| --- | --- |
| `p b i u s h1`-`h5` | same name |
| `strike` / `list` / `olist` / `*` | `s` / `ul` / `ol` / `li` |
| `quote=author` / `code` / `expand` | `blockquote` / `pre` / `div` (attributes dropped) |
| `spoiler table tr th td` | same name |
| `hr` | `hr` |
| `url`, `img` | `a href`, `img src`; `[url]U[/url]` and `[img]U[/img]` are rewritten to the attribute form first |

`{STEAM_CLAN_IMAGE}` and `{STEAM_CLAN_LOC_IMAGE}` expand to
`https://clan.akamai.steamstatic.com/images`. `previewyoutube`, `video` (mp4, else
webm) and `dynamiclink` become a link paragraph: embeds are links, not players.
Tags are matched in lowercase only, so `[PC]`, `[Corrupted]` and unknown tags stay as
literal text.

**Interval.** The poll runs every 10 minutes for every due watch; one request per
watch, serial. Steam's weekly Tuesday maintenance (up to an hour) shows up as a batch of
failures and dropped ticks, then heals on the next good poll. Posts published in the
meantime still arrive, as long as the outage stays inside the 24-hour freshness window.

## Fixtures

Recorded live on 2026-10-22 in `spec/fixtures/integrations/steam/`:

- `news_440.json`: the TF2 triple (a `patchnotes`-tagged community post, the untagged
  `steam_updates` item, the untagged `tf2_blog` mirror with a blank author).
- `appdetails_1145360.json`: Hades, trimmed to the basic fields.
