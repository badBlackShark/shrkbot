# Overview

The runtime shape: which processes exist, why the bot has to be one of its own,
and the `server`-not-`guild` naming rule.

shrkbot is a Discord bot rewritten from Crystal/discordcr to Ruby/Rails/discordrb.
One codebase runs as several processes sharing Postgres and Redis. Per-guild
configuration is moving to a website; the bot reads that configuration and handles
Discord interactions and events.

## Processes

One Docker image, multiple services off it:

- **web** (Puma) — the config website / admin UI and Discord OAuth2 login. ActiveRecord CRUD.
- **bot** (`bin/bot`) — the discordrb gateway connection. Long-lived, blocking. Must be its own process: discordrb is gateway-based, and booting it from a Puma worker would open one gateway connection per cluster worker (duplicate events). At most one bot process is connected at a time — see [Bot leadership](../bot/sharding-and-leadership.md#bot-leadership-single-active-process).
- **jobs** (`bin/jobs`) — Solid Queue worker for background and scheduled work (reminder delivery).
- **postgres** — source of truth.
- **redis** — config-change pub/sub (web → bot); see [Config propagation](config-propagation.md#config-propagation).

discordrb dispatches each handler on its own thread, so any DB work in the bot
process must check out and return its own connection from the AR pool — see
`Bot::WithConnection`, mixed into `Bot::BaseCommand` and `Bot::BaseEvent`.

That dispatch is unbounded — discordrb spawns a bare thread per handler with no
queue or cap — so a single gateway burst (a role reorder fans out one
`GUILD_ROLE_UPDATE` per moved role) can put far more threads in flight than the
web process ever sees. The bot therefore runs a larger AR pool than Puma needs:
`RAILS_MAX_THREADS` is set per-role in `config/deploy.yml`, not globally. A pool
too small for a burst surfaces as `ActiveRecord::ConnectionTimeoutError` storms
rather than slow requests, because handlers hold their connection across
Discord REST calls that block on discordrb's rate limiter.

## Configuration: the web writes, the bot reads

There are no config commands on the bot. All per-guild configuration is written by
the web app; the bot only *reads* `ServerConfiguration` and its plugin settings.
That is what keeps Redis a one-way bus (see
[Config propagation](config-propagation.md)) and why there is no bot↔web write
contention to resolve.

The bot still writes **operational** data — reminders, role-message state,
moderation records, activity-log delivery. The split is configuration versus
things that happen at runtime, not web versus bot.

App-level configuration (env vars, 12-factor — see
[Deployment](../running/deployment.md)) is a separate thing again from per-guild
runtime configuration in the database.

## Credentials

One Discord application, three credentials that must not be confused:

- the **bot token**, held only by the bot and jobs processes;
- the **OAuth2 client id and secret**, held only by the web process, for sign-in;
- a **per-user access token**, obtained at sign-in, used in exactly one place (see
  [Web (controllers and views)](../web/controllers-and-views.md)).

The web process never holds the bot token — which is the reason guild metadata is
synced to Postgres rather than fetched live. See
[Guild sync](../bot/guild-sync.md).

## Terminology: `server`

Our domain uses `server`/`server_id`, following discordrb (`Discordrb::Server`,
`event.server`). `guild` survives only at the Discord REST API boundary, where the
endpoints and gateway events are named `guild_*`.
