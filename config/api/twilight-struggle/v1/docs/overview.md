A JSON API for [twilight-struggle.com](https://twilight-struggle.com) to push
tournament and game-result data into shrkbot. shrkbot renders each game result
into a Discord message in the channels that servers have configured for that
tournament. This page is the full external contract for that integration.

The machine-readable contract is an [OpenAPI 3 document](openapi.json). Request
bodies are validated against it before they reach our code; a body that does not
conform gets a `422` with an `errors` array.

## Base URL

```
https://shrkbot.com/api/twilight-struggle/v1
```

Every path below is relative to it, so a tournament upsert is
`PUT https://shrkbot.com/api/twilight-struggle/v1/tournaments/otsl-2026`.

All requests and responses are JSON. Send `Content-Type: application/json`.

**Types are strict — we do not coerce.** The one non-string field is
`winning_turn`; send it as a JSON number (`7`), not a string (`"7"`). A string
there is a `422`.

## Authentication

Every request needs a bearer token:

```
Authorization: Bearer <key>
```

Several keys can be valid at the same time. To rotate a key: add the new key to
our configuration, switch your integration over to it, then have us drop the old
one. Nothing rotates automatically and nothing expires on a timer — a key works
until it is removed on our side.

A missing or invalid token gets a `401` with no body.

## Idempotent upserts

Both resources are `PUT` to a URL whose id you choose. There is no separate
create call — the first `PUT` with a given id creates the row, every later `PUT`
with the same id updates that same row in place. Safe to retry.

`DELETE` is idempotent too: deleting an id that never existed still answers
`204`.

## Ordering

A tournament must be `PUT` before any game that references it, and a parent
tournament before its children. Referencing an id we do not know about is a
`422` — we never auto-create a stub tournament from a game payload.

## Status codes

| Code | Meaning |
| --- | --- |
| `201` | Created (first `PUT` for this id) |
| `200` | Updated (id already existed) |
| `204` | Deleted (`DELETE`, including deleting an id that never existed) |
| `401` | Missing or invalid bearer token |
| `422` | Validation failure or unknown reference — body has an `errors` array |
