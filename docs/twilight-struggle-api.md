# Twilight Struggle API

A JSON API for twilight-struggle.com to push tournament and game-result data
into shrkbot. shrkbot renders each game result into a Discord message; this
document is the full external contract for that integration.

Base URL: `https://shrkbot.com/api/twilight-struggle/v1`

All requests and responses are JSON. Send `Content-Type: application/json`.

The machine-readable request contract is an OpenAPI 3 document,
`config/api/twilight-struggle/v1/` (one file per resource; ask us for a copy).
Request bodies are
validated against it before they reach our code; a body that doesn't conform
gets a `422` with an `errors` array. The field tables below mirror it in prose.

## Authentication

Every request needs:

```
Authorization: Bearer <key>
```

Several keys can be valid at the same time. To rotate a key: add the new key
to our configuration, switch your integration over to it, then have us drop
the old one. Nothing rotates automatically and nothing expires on a timer —
a key works until it's removed on our side.

A missing or invalid token gets a `401` with no body.

## Idempotent upserts

Both endpoints are `PUT` to a URL you choose the id for. There is no separate
create call — the first `PUT` with a given id creates the row, every later
`PUT` with the same id updates that same row in place. Safe to retry.

## Ordering requirement

A tournament must be `PUT` before any game that references it, and a parent
tournament before its children. Referencing an id we don't know about is a
`422` — we never auto-create a stub tournament from a game payload.

## Status codes

| Code | Meaning |
| --- | --- |
| `201` | Created (first `PUT` for this id) |
| `200` | Updated (id already existed) |
| `204` | Deleted (`DELETE`, including deleting an id that never existed) |
| `401` | Missing or invalid bearer token |
| `422` | Validation failure or unknown reference — body has an `errors` array |

## Tournaments

### `PUT /tournaments/:external_id`

`:external_id` is your own id for the tournament — whatever you use as the
primary key on your side.

Request body:

```json
{
  "tournament": {
    "name": "Online Twilight Struggle League",
    "parent_external_id": null,
    "status": null
  }
}
```

Fields:

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | yes | |
| `parent_external_id` | string | no | Your id of an already-`PUT` parent tournament. Groups a sub-event under a larger tournament. Unknown id → `422`. |
| `status` | string | no | Free text; not currently interpreted by shrkbot. |

Response (`201` or `200`):

```json
{
  "id": "tst_01ABC...",
  "external_id": "your-id-here"
}
```

`id` is shrkbot's internal id, returned for your reference — you never need
to send it back to us.

### `DELETE /tournaments/:external_id`

Deletes the tournament and its games. Idempotent — deleting an unknown id
still returns `204`. This never touches Discord: any result messages already
posted for those games stay up.

## Games

### `PUT /games/:external_id`

`:external_id` must be your `game_results.id` (your bigint primary key) —
**not** `game_code`. `game_code` is a separate, display-only field (e.g.
`"R1"`) that's only unique within one tournament, so it can't identify a game
on its own.

Request body:

```json
{
  "game": {
    "tournament_external_id": "your-id-here",
    "game_code": "R1",
    "game_date": "2026-07-20",
    "reported_at": "2026-07-24T10:00:00Z",
    "winning_side": "usa",
    "winning_turn": 6,
    "winning_method": "defcon",
    "usa": { "name": "Alice", "flag": "🇺🇸" },
    "ussr": { "name": "Bob", "flag": "🇷🇺" },
    "video_urls": ["https://example.com/video"]
  }
}
```

Field table:

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `tournament_external_id` | string | no | Omit for a friendly (non-tournament) game — see below. Unknown id → `422`. |
| `game_code` | string | no | Display-only, max 60 characters. |
| `game_date` | datetime | no | When the game was played. |
| `reported_at` | datetime | yes | When the result was reported. |
| `winning_side` | string | yes | One of `usa`, `ussr`, `tie` — send these exact names, not your internal `1`/`2`/`3` side codes. |
| `winning_turn` | integer | no | `1`–`11`. |
| `winning_method` | string | yes | Free text, max 60 characters (e.g. `"defcon"`). |
| `usa` | object | yes | The US player — see the Player fields below. |
| `ussr` | object | yes | The USSR player — see the Player fields below. |
| `video_urls` | array of strings | no | Max 5. Each must be `http://` or `https://` — any other scheme (including `javascript:`) is rejected. |

Each player (`usa`, `ussr`) is an object:

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | yes | Max 100 characters. |
| `flag` | string | no | Max 8 characters — meant for a flag emoji. |
| `discord_id` | string | no | The player's Discord user ID, as a string (snowflakes exceed JSON's safe integer range). If sent, we may render their name as a Discord mention in the posted result; we never store it. |

**Friendly games:** omit `tournament_external_id` entirely and the game is
grouped under shrkbot's internal "Friendly games" tournament instead of being
rejected.

**Everything except the identifiers is render-only.** Player names, flags,
the winning side/method/turn, and the video URLs are used once to build the
Discord message and are then discarded — shrkbot does not store them. Only
the game's own id, its tournament link, and (once posted) the Discord
channel/message id of the posted result are kept. See the privacy policy for
the full data inventory.

Response (`201` or `200`):

```json
{
  "id": "tsg_01ABC...",
  "external_id": "your-id-here"
}
```

### `DELETE /games/:external_id`

Idempotent — deleting an unknown id still returns `204`. Deleting a game also
deletes the Discord message shrkbot posted for it, so a `DELETE` is the way to
retract a published result. (Deleting the game's tournament does not — only a
game `DELETE` removes the message.)

## Posting results to Discord

A game `PUT` renders the result into a Discord message when the game's
tournament, or any tournament above it in the parent chain, has a destination
channel configured. Until a destination is configured, the game is stored and
nothing is posted; once one is configured, the next `PUT` for that game posts it.

A repeat `PUT` for the same game re-renders the existing message in place
rather than posting a new one. `DELETE /games/:external_id` also deletes the
posted Discord message; `DELETE /tournaments/:external_id` never touches
Discord.

Posting happens in a background job, so the response comes back without
waiting on Discord and never carries a posting error — a `PUT` that answers
`200`/`201` means the game was stored, not that the message is up yet. If
Discord is unreachable or rate-limits us the job retries with backoff; if the
destination channel is gone or the bot was kicked it gives up, because
retrying cannot fix either. Nothing is reported back to you in that case.

The result payload lives only for as long as that job does. It is never
written to the game record, so the only way to change a posted message is to
send the game again.
