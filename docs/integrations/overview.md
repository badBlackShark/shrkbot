# Integrations: the provider layer

`Integrations::<Provider>` is how shrkbot talks to a third-party service as an API
**consumer**. Steam is the first provider. Twilight Struggle is the inverse (the site
pushes to us) and keeps its own code: see [twilight-struggle.md](twilight-struggle.md).

The provider layer knows how to reach a service and what its answers mean. It knows
nothing about what shrkbot does with them.

## The dependency rule

Nothing under `Integrations::` references a capability namespace. Code that uses a
provider depends on `Integrations::`; `Integrations::` never depends back. Keep it
one-directional and a provider can be read, tested and replaced without knowing who
calls it.

## Placement

`app/integrations/` is pushed with `namespace: Integrations`, declared in
`config/application.rb` next to `Ops`, `Bot` and `Finders`, so path and constant agree:

    app/integrations/http.rb              -> Integrations::Http
    app/integrations/steam/news.rb        -> Integrations::Steam::News

Models are the exception, because models stay in `app/models`: `Integrations::Watch`,
`Integrations::Event` and every provider's event subclasses live under
`app/models/integrations/`. The `Integrations` namespace spans both roots.

**Not collapsed to top-level `Twitch::` / `Steam::`.** Provider gems own those
constants (`twitch-api` defines `Twitch::Client`), and a collapsed directory would
collide with them or shadow them. Inside `Integrations::Twitch`, reach a gem with a
leading `::`, as in `::Twitch::Client`. For the same reason, inside
`Integrations::Steam` the bare name `App` is the Steam value object; the Rails
application module is `::App`.

**Not `lib/`.** `lib/` holds app-agnostic plumbing. These classes read our ENV and
return our types, which makes them application code.

## Transport: `Integrations::Http`

One class every provider goes through. It is stdlib `Net::HTTP` with a 5 s open
timeout, a 15 s read timeout, `User-Agent: shrkbot (+https://shrkbot.com)` and
`Accept: application/json`.

```ruby
Integrations::Http.get_json(url, params: {}, status_errors: {}) do |body|
  body.fetch("items").map { |item| Item.new(name: item.fetch("name")) }
end
```

`params:` is the whole query string: pass every parameter through it, never in `url`.

Net::HTTP's automatic retry of idempotent requests is off (`max_retries: 0`), so a
failed call fails once and retrying stays the calling job's decision.

**The block is mandatory.** `get_json` parses the JSON, yields it, and returns the
block's value. The block is where the provider's JSON becomes our value objects, and
a `KeyError`, `TypeError` or `NoMethodError` raised inside it means the provider
changed its response shape (`NoMethodError` covers a `null` where an object was).
Http turns that into `Unavailable`, so the failure surfaces at the transport boundary
as one error type instead of a `KeyError` or `NoMethodError` deep in a caller. Map
with `fetch`, never `[]`, so a missing key fails loudly.

**Keep the block to mapping.** The rescue can't tell a provider's `null` from a typo
of ours: a misspelt method in the block also comes out as `Unavailable`, with the
original message kept. The resource specs run every mapping line against a recorded
response, so a typo fails there before it ships. Anything that isn't mapping, such
as a query or a write, belongs after `get_json` returns.

`Integrations::Http.get_bytes(url)` downloads a binary body (an image), reached through
the provider's `Client#get_bytes`. It follows the same error mapping as `get_json` and
rejects a body over `Http::MAX_BYTES` (5 MB) with `Unavailable`. The check runs after the
download, so it keeps an oversized image away from the decoder, not out of memory.

### Errors

Every failure is an `Integrations::Error` subclass, so a caller can handle failure
without knowing which provider produced it.

| Error | Raised for |
| --- | --- |
| `Unauthorized` | 401, 403. Our credentials, not the source's fault. |
| `NotFound` | 404, 410. |
| `InvalidReference` | A `NotFound` subclass: the user's input does not name anything on the source (`Steam::AppReference.parse`), so no request was made. |
| `RateLimited` | 429. `retry_after` is the `Retry-After` header in seconds, or `nil` when the header is absent or an HTTP date. |
| `Unavailable` | 5xx, timeouts, socket and system-call errors, dropped connections, TLS errors, a malformed HTTP response or header, a corrupt compressed body, a body that is not JSON, a response missing a key or shaped differently from what the mapping expects. Transient. |
| `Error` | Anything else (other 4xx, 3xx; redirects are not followed). |

A status error reads `"<host> responded <status>"`; a transport failure reads `"<host>: <exception class>: <message>"`. Both name the host, because the message is what ends up in logs and wherever a failure is shown.

### `status_errors`: per-endpoint meaning

The defaults are a guess about what a status means across providers. An endpoint that
means something else passes `status_errors:`, merged over the defaults:

```ruby
Integrations::Http.get_json(url, status_errors: {403 => Integrations::NotFound})
```

Steam's news endpoint answers an unknown app id with 403 and `{}`, so `Steam::News`
maps 403 to `NotFound`. The override belongs to the endpoint, never the provider's
client: on a keyed endpoint the same 403 means a bad key. 429 is handled before the
lookup and cannot be overridden.

## Clients and resources

Every provider has a `Client`: the one place for its hosts and credentials. Its only
job is to build the URL (and, once a provider has credentials, authenticate) and hand
off to `Http`. `Integrations::Steam::Client` holds Steam's two hosts and has no
credentials.

**Resource classes** sit on top, one per API resource (`Steam::News`, `Steam::Apps`,
`Steam::StoreItems`, which resolves a game's store artwork URL).
They take the client as a keyword with a default, call it, and return the provider's
own `Data` value objects (`Steam::NewsItem`, `Steam::App`):

```ruby
class News
  def initialize(client: Client.new)
    @client = client
  end
end
```

A new endpoint is a new method or a new resource class. The `Client` is never touched
for it.

Resources hold no state beyond the client, so they are plain objects built where
they're used.

## Watchers

A watcher turns one provider's answers into events for one followed thing (a Steam
app, later a channel). The contract is duck-typed, three members:

- `.resolve(input)` returns an `Integrations::Target` (`external_id`, `name`,
  `image_url`) from what a person typed, for the add-form.
- `#initialize(watch)` takes the `Integrations::Watch` row.
- `#observe` returns unsaved `Integrations::Event`s for everything the provider shows
  right now. It reads the provider and the watch's stored events and writes nothing.

There is **no base class**. One watcher exists, so a base would be a guess at what a
second one shares. The shared machinery already sits in layers every watcher goes
through: writes in `Ops::Integrations::Watches::*`, scheduling in
`Integrations::*Job`. Extract a base when the second watcher shares code.

`Integrations::Watch` stores the watcher's class name, so `PollJob` reaches it with
`watch.watcher_class`.

## Polling

    recurring.yml -> PollJob(watcher) -> for each Watch.due: observe -> RecordObservation

Each tick runs one `PollJob` per watcher class, which polls that watcher's due watches
one at a time. A provider is never hit in parallel, and a slow provider slows its own
batch instead of queueing more work behind it.

`limits_concurrency` is keyed by the watcher class with `on_conflict: :discard`, so a
tick that finds the previous batch still running is dropped. During a provider outage
every request can take its full timeout (about 20 s), batches run long, and ticks are
dropped. Nothing is lost: the next good poll sees the same list, and the ledger sorts
out what is new. The concurrency `duration` (1 hour) must outlast the slowest batch or
two batches overlap; at 20 s per request that is 180 watches per watcher.

A watch deleted by the orphan prune while the batch runs is skipped, whether its poll
failed or its write hit the missing row: it is logged, not recorded, and never reported
as a bug. The batch moves on.

A failure stays with its watch: the batch records it and moves on. `RateLimited` also
stops the batch, so the rest of the list does not keep hitting a provider that asked
us to back off; the next tick starts over. It DMs the owner at once through
`ReportRateLimitJob`, because a rate limit means our request volume needs a look, and
the 24-hour report would come far too late. Like a bug (see Bugs), it is reported when
the watch's last error was something else, so a limit that persists across ticks DMs
once. Every error is recorded, ours included: a
bug in a mapping or converter is a failure like an outage, so it reaches the owner DM
(see Failures) instead of only the logs.

## Demand

A watch is polled only while something wants it. The wanting side registers itself in
one place, `config/initializers/integrations.rb`:

```ruby
Rails.application.config.to_prepare do
  Integrations::Watch.demanded_by(Feeds::Subscription)
end
```

That is the only file that names a capability next to `Integrations::`; the dependency
rule holds because `Watch` knows a list of sources, not what they are. A source is
duck-typed: a model with a `watch_id` column and an `active` scope. `to_prepare`
re-registers it after every code reload, and `demand_sources` resets with the reloaded
`Watch`.

- `Watch.demanded` is every watch that some source's `active` rows point at. `PollJob`
  polls `Watch.due.demanded`, and `ReportBrokenWatchesJob` reports
  `Watch.broken.unreported.demanded`: a watch nobody polls is not worth a DM. With no
  registered source it is `none`.
- `Watch.referenced` is every watch any source row points at, active or not. It is the
  keep side of the orphan prune.

`Ops::Integrations::Watches::PruneOrphans` runs daily at 5:35 and destroys each watch
that is not `referenced`, taking its seen items and events with it. With no registered
source it deletes nothing: an empty registry means the wiring failed, not that nothing
is followed. A server that switches a plugin off keeps its rows, so its watch stays
and is simply not polled.

**Ceiling.** The prune deletes each watch in its own transaction. A subscription or poll
writing to a watch at the instant it is deleted fails its foreign key. That stops the
run, watches already deleted stay deleted, and the next day's run continues.

## The list strategy

`RecordObservation` is the strategy for sources that answer with a list of recent
items.

- **Ledger.** Every item's `subject_key` goes into `integration_seen_items`. An item
  already there is skipped.
- **Storing.** A watch saves whatever is fresh and unseen as events, its first poll
  included. Before saving, each event gets `Event#enrich`, a no-op on the base class
  that a provider's event overrides to derive stored fields (`Steam::NewsEvent` detects
  its language). Capabilities decide what to announce; Feeds gates on `subscribed_since`.
- **Freshness.** An item older than 48 hours is ignored before the ledger: not
  recorded, not saved. A watch that was down, or an item that surfaces late, does not
  announce old news, and the old items every list repeats cost no writes.
- **Invariant.** `Event::FRESHNESS_WINDOW` (48 h) must stay below `Prune::RETENTION` (14 d).
  The ledger has to outlive the window, or a pruned item could look unseen and fresh.

Events and ledger rows are written in one transaction; `unique [:watch_id, :type,
:subject_key]` on events is the backstop against a double write.

## Failures

A watch is **broken** after 24 hours of failures (`failing_since` older than
`Watch::BROKEN_AFTER`), not after a count: a count means a different outage length for each polling
interval. `BROKEN_AFTER` stays below the 48-hour freshness
window, so the owner hears of a broken watch while the posts from the start of the
outage can still be delivered. A failing watch is polled normally until it
breaks. A broken one is retried on the first tick of every clock hour (its last poll
was in an earlier hour), so retries stay on :00 instead of drifting by however long the
batch ran. The first success clears `failing_since` and `last_error`, so it heals by
itself. `last_error` holds the error's class and message; it is what the DM shows. A
failure after a gap of more than `Watch::DORMANT_AFTER` (3 hours) starts a new
`failing_since`: a followed watch is polled hourly, and 3 hours tolerates one dropped
tick (a batch that overran into the next hour), so only a watch nobody followed has
such a gap, and its old outage must not count toward the 24 hours. A jobs outage longer
than 3 hours restarts the clock too, which only delays the DM.

`ReportBrokenWatchesJob` runs hourly and sends the bot owner **one DM** listing every
newly broken watch (ten at most, then "and N more"), then stamps them
`broken_reported_at`. A watch counts as reported while that stamp is newer than its
`failing_since`, so a watch that stays broken is not reported again, one that heals and
breaks again is, and nothing has to clear the stamp. Clearing it on success raced the
report job and could leave a stamp on a healthy watch, which then hid its next outage.

### Bugs

A failure that is not an `Integrations::Error` is a bug in our own mapping or watcher,
not a provider outage, and 24 hours is too long to wait for it. The batch
collects one line for such an error and, after the loop, enqueues `ReportPollBugsJob`,
which DMs the owner once per batch (ten lines at most, then "and N more"). It is
reported when its class differs from the watch's last error, so a bug that follows an
outage is reported at once, and one that repeats is not. The DM header says "unexpected
error" because a deadlock or timeout lands here too. The 24-hour report still covers a
watch that never heals.

## Events

`Integrations::Event` is a single table with STI. The envelope is `watch_id`,
`subject_key` (the provider's id for the item), `occurred_at` and `type`; everything
else is `payload` jsonb, exposed per subclass with `store_accessor`. The base class is
never instantiated. The `secondary` class attribute (default `false`) marks a subclass
as second-hand coverage of a story another subclass reports first
(`Steam::ArticlePublished`); capabilities that pick one copy of a story rank it last.
A provider's subclasses are models too and live with the base
under `app/models/integrations/<provider>/` (`Integrations::Steam::NewsEvent`).

## The bus

Events leave the provider layer through `Integrations::Bus`. A capability subscribes a
handler job to event classes in the same initializer that registers demand:

```ruby
Integrations::Bus.subscribe(Feeds::AnnounceJob, to: [Integrations::Steam::PatchNotesPublished, ...])
```

`Bus.handlers_for(event)` returns every handler subscribed to the event's class or a
superclass of it (`is_a?`). `app/integrations/` never names the handlers; only the
initializer does. The registry is module state on a reloadable module, so it resets on a
code reload and `to_prepare` fills it again.

`RecordObservation` hands the events it saved to `Ops::Integrations::Events::Dispatch`
in `ActiveRecord.after_all_transactions_commit`, so a handler never runs before the
event row is visible. Dispatch sorts the events by `occurred_at`, builds one job per
handler, enqueues them all with `ActiveJob.perform_all_later` (one transaction, so a
batch is enqueued whole or not at all) and then stamps `dispatched_at`. A failed
dispatch leaves the stamp unset. Handlers that serialize per key (`limits_concurrency`)
then process a poll's events oldest first.

**An event with no handler is not stamped.** An empty handler list means nobody is
wired to it, not that nobody cares. Stamping it would hide the event from the sweeper
for good. An event class with no handler is a code-only failure, so
`spec/integrations/bus_spec.rb` fails CI for it; at runtime the event stays unstamped
for the sweeper.

**The sweeper.** `Ops::Integrations::Events::Dispatch` also runs every 5 minutes over
`Event.stranded`: undispatched events created inside `Event::FRESHNESS_WINDOW`
(48 hours) and more than a minute ago, that also occurred inside the window. It catches
a crash between the commit and the enqueue, and a wiring fix that lands late. The window
keeps a late fix from posting old news: an undispatched event that occurred more than
48 hours ago is never sent. A partial index on `created_at WHERE dispatched_at IS NULL`
keeps the sweep cheap.

Delivery is at least once: a handler can see an event twice (the sweeper racing the
commit hook), so handlers must be idempotent. `Feeds::PostJob` is, through its
`feed_posts` ledger.

## Markup

Provider text arrives as HTML (or BBCode converted to HTML) and leaves as Discord
Markdown through `Integrations::HtmlToMarkdown.call(html)`, which returns `markdown`
and the lifted `image_urls`.

| HTML | Markdown |
| --- | --- |
| text | whitespace runs become one space |
| `br` | newline |
| `p div section article header footer figure ul ol blockquote pre table hr` | block, blank lines around |
| `h1`-`h3` | `#`, `##`, `###` |
| `h4`-`h6` | bold |
| `b strong` / `i em` / `u` / `s strike del` / `spoiler` | `**` / `*` / `__` / `~~` / `\|\|` around the stripped text, whitespace kept outside |
| `a` with an http(s) href | a Markdown link (text, then href), or the bare URL when the text is the URL; empty text drops it |
| `img` with an http(s) src | removed from the text, appended to `image_urls` (deduped) |
| `ul` / `ol` | `- ` / `1. `, nested items indented by the marker width |
| `blockquote` | every line prefixed `> `; blank lines inside are dropped, because Discord shows a bare `>` literally |
| `pre` / `code` | fenced block of the raw text / inline backticks; `br` inside is a line break (a space inline) |
| `table` | fenced block, columns padded, no header separator; `br` in a cell is a space, a link keeps its text only |
| `script style template head` | dropped |
| anything else | its children |

**Not escaped.** Text is not Markdown-escaped, so a literal `*` or `_` in a post can
format. Escaping `_` would break bare URLs, so the converter leaves it. That is the
known ceiling.

## Language detection

`Integrations::Language.detect(text)` returns a fastText lid.176 code or `nil`. The
input is the event's posted title plus converted Markdown, so there is no second
fetch. Link and image targets, URLs and Markdown punctuation are stripped first. Text
under 50 characters or a prediction under 0.5 confidence returns `nil` (unknown), and
unknown always passes a subscription's language filter.

Detection runs only for events `RecordObservation` is about to store (it calls
`Event#enrich`, which `Steam::NewsEvent` overrides), so the ~20 already-seen items per
poll are never re-detected. A detection failure logs, DMs the owner through
`ReportPollBugsJob` (once a day per error class) and returns `nil` (unknown), so the
feed keeps posting.

The benchmark it rests on (2026-10-28, 5,093 Steam items, 11 languages): 100% on
English and Russian news, 99.3% on localized announcements, about 250 µs per item,
+6 MB RSS. With the gates, 26 items came out unknown and the only wrong answer was a
mislabelled source.

The model lives in `vendor/fasttext/` with its CC BY-SA 3.0 `NOTICE`, and its SHA-256
is pinned in the spec. It is frozen upstream (2017, repo archived 2024), so it is
vendored and never downloaded at build. `CODES` mirrors the model's labels, also
spec-pinned.

The fasttext gem compiles with `-march=native` by default, so a compiled bundle only
runs on CPUs with the build machine's instruction set. Anywhere a bundle can move
between machines (the CI cache, `Dockerfile.prod`), `BUNDLE_BUILD__FASTTEXT` is set to
`--with-optflags=` for a portable build; otherwise the gem dies with SIGILL at
`require`.

## Retention

`Ops::Integrations::Prune` runs daily and deletes events and seen items created more
than 14 days ago: one policy across the integrations log tables (`Ops::Feeds::Posts::Prune`
reuses its `RETENTION` for the post ledger). Watches themselves
are deleted by the orphan prune (see Demand).

## Testing

Each layer stubs the one beneath it, and only `Http`'s own spec touches `Net::HTTP`:

- `spec/integrations/http_spec.rb` stubs `Net::HTTP.start` and covers every status
  branch, the override, both `Retry-After` forms, network failures, invalid JSON and
  the shape-change rule.
- A client spec stubs `Integrations::Http.get_json` and asserts the URL it builds.
- A resource spec injects an `instance_double` of the client whose `get_json` stub
  calls the block it was handed with a **recorded real response**, so the mapping
  actually runs. It asserts the host, path, params and any `status_errors`.

Fixtures live in `spec/fixtures/integrations/<provider>/`. Record them from the live
API (trimmed to the fields the mapping reads, never hand-written), so the specs
describe what the provider really sends. Re-record when a provider's shape changes.

Watcher and operation specs stub the layer beneath: a watcher spec injects a resource
double (or a client double, as above) and runs the real mapping; a job spec stubs
`<Watcher>.new` to return an `instance_double` whose `observe` returns events and runs
the real operations against the database. Discord-touching jobs stub
`Bot::Discord::Components`.
