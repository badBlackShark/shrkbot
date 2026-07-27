A game is one reported result. Its `external_id` must be your
`game_results.id` (your bigint primary key) — **not** `game_code`. `game_code` is
a separate, display-only field (e.g. `"R1"`) that is only unique within one
tournament, so it cannot identify a game on its own.

**Friendly games:** omit `tournament_external_id` entirely and the game is
grouped under shrkbot's internal "Friendly games" tournament instead of being
rejected.

**Everything except the identifiers is render-only.** Player names, flags, the
winning side/method/turn, and the video URLs are used once to build the Discord
message and are then discarded — shrkbot does not store them. Only the game's own
id, its tournament link, and (once posted) the Discord channel/message id of each
subscribing server's posted result are kept — one pair per server. See the
[privacy policy](https://shrkbot.com/privacy) for the full data inventory.

## Posting results to Discord

A game `PUT` fans out to every server subscribed to the game's tournament, or to
any tournament above it in the parent chain — several servers may subscribe to
the same tournament feed. For each subscribing server, the result renders into a
Discord message when that server has a channel configured (on the tournament
itself or inherited from an ancestor) *and* the Twilight Struggle plugin is
enabled for that server. A server missing either is skipped; the others still get
posted. One background job runs per subscribing server.

Subscribing and configuration happen in shrkbot's dashboard, not through this
API: the bot owner grants the plugin to a server, an admin of that server
subscribes to the tournament, then picks the channel and templates for that
server. Disabling the plugin stops every post for that server without losing any
configuration; it has no effect on other subscribed servers.

A repeat `PUT` for the same game re-renders each server's existing message in
place rather than posting a new one, tracked per server. `DELETE
/games/{external_id}` deletes the posted Discord message in every subscribing
server it went to; `DELETE /tournaments/{external_id}` never touches Discord.

Posting happens in a background job per server, so the response comes back
without waiting on Discord and never carries a posting error — a `PUT` that
answers `200`/`201` means the game was stored, not that any message is up yet. If
Discord is unreachable or rate-limits us, that server's job retries with backoff;
if the destination channel is gone or the bot was kicked for that server it gives
up, because retrying cannot fix either — other servers' jobs are unaffected.
Nothing is reported back to you in that case.

The result payload lives only for as long as each job does. It is never written
to the game record, so the only way to change a posted message is to send the
game again.

## What the message looks like

Plain text, matching the announcements the site already produces:

```
OTSL 2026 - Season 8: G372 - M B 🇵🇱 (USA) has defeated L S 🇦🇷 in Turn 7 (VP Track (+20))
RATS Cup 2026: C204 - M N 🇦🇩 (USA) tied with D C 🇰🇷 in Turn 10 (Wargames)
OTSL 2026 - Season 8: S378 - T B 🇵🇱 vs A S 🇸🇪 https://youtu.be/videolink
```

Each tournament has three templates, inherited from its parent tournament when
unset: one for a decided game, one for a tie, and one for a game with a video. **A
game with `video_urls` always uses the video template, which is spoiler-free** —
both players and the link, no winner, turn or method. Video URLs are posted as
bare links so Discord builds its own embed.

Templates are written with `{token}` placeholders. Unknown tokens are left alone,
so a stray brace renders literally rather than breaking the message.

| Token | Renders |
| --- | --- |
| `{tournament_name}` | the tournament's name |
| `{game_id}` | the `game_code` you sent |
| `{turn}` | `Turn 7`, or `Final Scoring` at turn 11 |
| `{winning_method}` | the `winning_method` you sent |
| `{winning_player}` / `{losing_player}` | name and flag; empty on a tie |
| `{winning_side}` / `{losing_side}` | `USA` or `USSR`; empty on a tie |
| `{usa_player}` / `{ussr_player}` | name and flag for that side |
| `{usa_name}` / `{ussr_name}` / `{winning_name}` / `{losing_name}` | name, no flag |
| `{usa_flag}` / `{ussr_flag}` / `{winning_flag}` / `{losing_flag}` | flag only |
| `{videos}` | the video URLs, space separated |

A tournament can be set to show Discord tags. Then every token that carries a
player's name also carries their tag in brackets after it — `Alice 🇺🇸 (@alice)` —
for anyone whose `discord_id` you sent; players without one just get their name.
The name is never replaced, so a snowflake that has gone stale, or a player who
has left the server, still reads correctly.

**No posted message ever notifies anyone.** Tags identify a player and link to
their profile; they do not ping. A player named `@everyone` cannot ping the server
either.
