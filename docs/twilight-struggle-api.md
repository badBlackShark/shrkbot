# Twilight Struggle API

A JSON API for twilight-struggle.com to push tournament and game-result data
into shrkbot. shrkbot renders each game result into a Discord message; this
document is the full external contract for that integration.

Base URL: `https://shrkbot.com/api/twilight-struggle/v1`

All requests and responses are JSON. Send `Content-Type: application/json`.

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
    "name": "Ameritash 2026",
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
still returns `204`.

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
    "winning_method": "Objectives",
    "usa_player": "Alice",
    "usa_flag": "🇺🇸",
    "ussr_player": "Bob",
    "ussr_flag": "🇷🇺",
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
| `winning_method` | string | yes | Free text, max 60 characters (e.g. `"Objectives"`, `"Final scoring"`). |
| `usa_player` | string | yes | Max 100 characters. |
| `usa_flag` | string | no | Max 8 characters — meant for a flag emoji. |
| `ussr_player` | string | yes | Max 100 characters. |
| `ussr_flag` | string | no | Max 8 characters. |
| `video_urls` | array of strings | no | Max 5. Each must be `http://` or `https://` — any other scheme (including `javascript:`) is rejected. |

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

Idempotent — deleting an unknown id still returns `204`. This only removes
shrkbot's reference to the game; it does **not** delete any Discord message
already posted for it. Delete the message yourself in Discord if that's what
you want.
