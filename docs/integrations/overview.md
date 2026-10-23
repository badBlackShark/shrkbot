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

### Errors

Every failure is an `Integrations::Error` subclass, so a caller can handle failure
without knowing which provider produced it.

| Error | Raised for |
| --- | --- |
| `Unauthorized` | 401, 403. Our credentials, not the source's fault. |
| `NotFound` | 404, 410. |
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

**Resource classes** sit on top, one per API resource (`Steam::News`, `Steam::Apps`).
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
