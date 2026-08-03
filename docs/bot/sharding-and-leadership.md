# Sharding and leadership

How the bot runs N shards in one process, and how exactly one bot process stays
connected across a deploy.

## Sharding

Static only (`SHARD_COUNT`, floored at 1). discordrb is one shard per `Bot` instance,
so `bin/bot` builds N `Bot` instances in one process. Because they share a process,
the presence total is summed in-process (no Redis needed). Only the first shard
defines the application-global commands; every shard attaches handlers. Shard starts
are staggered by 5s — Discord rate-limits IDENTIFY to roughly one per 5s, and a burst
drops later shards into reconnect backoff.

Each `Bot` only knows the servers on its own shard, so anything that spans **all**
servers (e.g. `/announce`, which DMs every unique server owner) must read every
shard, not just `event.bot`. `bin/bot` registers the bot array with `Bot::Registry`
at boot; `Bot::OwnerBroadcast.call(bots:, …)` unions every shard's servers, dedupes owners
across shards, and DMs through any one bot (DMs are REST, so the shard doesn't
matter). This works because all shards share one process — no cross-process
coordination needed.

## Bot leadership (single active process)

During a Kamal deploy the old and new bot containers overlap for the new one's
entire boot, and both would answer every event. kamal-proxy can't help — it only
drains inbound HTTP and has no concept of the outbound gateway WebSocket — so
exclusion lives in the app: every bot process blocks on a Redis leader lock
(`Bot::LeaderLock`, key `shrkbot:bot:leader`, 6 s TTL renewed every second)
**before** connecting to the gateway. At most one process is ever connected, so
nothing downstream needs gating and READY-time work (server reconciliation,
command setup, onboarding) runs with full fidelity on every takeover.

Two orderings are load-bearing:

- Signal traps install **after** acquire. A SIGTERM while still waiting for the
  lock hits Ruby's default handler and kills the lock-less waiter — nothing to
  clean up.
- On shutdown the gateway stops **before** the lock is released. The successor
  can't act before its own READY, so overlap is structurally impossible.

A leader that dies without releasing (SIGKILL, crash) is covered by the TTL.
The lock is fail-open: renewal errors log and re-acquire but never demote a
serving bot — a Redis outage must not mute the bot. The worst case (a deploy
overlap and a Redis outage at the same time) degrades to the pre-lock
behaviour, brief doubles. Don't reuse this primitive where mutual exclusion is
correctness-critical.

The chosen trade is **silence over doubles** at cutover: a few seconds of
unresponsiveness (failed interactions are visible and retryable) instead of
double command executions, double punishments and double DMs (irreversible).
The gap is disconnect + reconnect + READY, so it grows with server count and
especially with shard count (5 s IDENTIFY stagger per shard). Measure it as the
log delta between the old process's "shutting down" and the new one's "all N
shard(s) up". When it exceeds roughly 10 s, the upgrade is a warm standby:
every process connects immediately and the lock gates dispatch instead of
connection, shrinking handover to about a second. That costs promotion hooks —
a standby's READY fires while it isn't leader, so reconciliation, command setup
and onboarding must re-run on promotion — and per-shard-group locks once shards
split across processes.

## REST vs gateway token

The gateway `Bot` prefixes the auth header itself, but direct `Discordrb::API` calls
(e.g. reminder delivery from the jobs process) need the header as `Bot <token>` or
Discord returns 401. `Bot::Config.rest_token` provides the prefixed form.
