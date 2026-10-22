# Steam

Game news and store lookups. Neither endpoint needs an API key or any authentication.
Everything here is the provider layer (see [overview.md](overview.md)); it stores
nothing.

`Integrations::Steam::Client` is the one home for Steam's two hosts (`:api` for
`api.steampowered.com`, `:store` for `store.steampowered.com`) and is where a Web API
key would go. Two resources use it:

| Resource | Endpoint | Returns |
| --- | --- | --- |
| `Steam::News#for_app(app_id, count: 20)` | `api` `/ISteamNews/GetNewsForApp/v2/` | `[Steam::NewsItem]` |
| `Steam::Apps#find(app_id)` | `store` `/api/appdetails` | `Steam::App` |

## News

Parameters sent: `appid`, `count`, and `maxlength=0`. **`maxlength=0` means the full
body**; any other value truncates `contents`. The body is **BBCode** (`[list]`,
`[*]`, ...), not Markdown or HTML.

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

These store endpoints are **unofficial and rate-limited**: Steam does not document
them, and a 429 surfaces as `RateLimited`. Call them when a person gives you a game,
never from a recurring poll. `store.steampowered.com/api/storesearch/?term=...`
searches by name and returns images; it was checked live but no resource wraps it,
and the same caveats apply.

## Fixtures

Recorded live on 2026-10-22 in `spec/fixtures/integrations/steam/`:

- `news_440.json`: the TF2 triple (a `patchnotes`-tagged community post, the untagged
  `steam_updates` item, the untagged `tf2_blog` mirror with a blank author).
- `appdetails_1145360.json`: Hades, trimmed to the basic fields.
