# Twilight Struggle integration

The bespoke plugin behind twilight-struggle.com: a token-authenticated JSON API for
tournament and game data, the per-server subscription model, and the rules that
govern how results get posted to Discord.

The full external contract is the OpenAPI document under
`config/api/twilight-struggle/v1/` — schema plus the prose in its `docs/`
directory — published to
[the API docs site](https://badblackshark.github.io/shrkbot/twilight-struggle/v1/)
by CI. See [JSON APIs](../api/openapi.md) for how that validation and publishing
pipeline works in general.

**Namespace and routes:** `Api::TwilightStruggle::V1::{Tournaments,Games}Controller`,
subclassing `Api::TwilightStruggle::BaseController < ActionController::API`. Routes
live in their own file (`config/routes/twilight_struggle.rb`, loaded from
`config/routes.rb` via `draw :twilight_struggle`) rather than inline in the main
`draw do` block, keeping a self-contained external API surface easy to find and
diff separately from the dashboard's routes. Both resources are `only: [:update,
:destroy]`, `param: :external_id` — there is no create action because update is
the upsert.

**Auth:** `ActionController::HttpAuthentication::Token::ControllerMethods`
(`ActionController::API` doesn't include it by default) checks the bearer token
against every key in `TWILIGHT_STRUGGLE_API_KEYS` (comma-separated) via
`ActiveSupport::SecurityUtils.secure_compare`. Multiple simultaneous keys let the
client rotate with overlap (add new, switch, drop old) instead of a hard cutover;
an unset/empty env var means zero keys, so every request is rejected (fail closed).

**Upsert-by-external_id:** both `Tournaments#update` and `Games#update` are
idempotent PUTs keyed on the caller's own id (`external_id`), not ours — the
first PUT creates, every later PUT with the same id updates the same row.
`Ops::TwilightStruggle::Tournaments::Upsert` / `Ops::TwilightStruggle::Games::Upsert`
`find_or_initialize_by(external_id:)`. A `parent_external_id` / `tournament_external_id`
reference that doesn't resolve to an existing row is a 422, never an
auto-created stub — tournaments must be PUT before games that reference them.

**Result data is deliberately not persisted:** the request-validation
middleware (`committee`, wired in `config/initializers/committee.rb`) checks the
whole game body against the OpenAPI contract in `config/api/twilight-struggle/v1/`
(one file per resource, merged at boot) — required fields, `winning_side` enum,
`winning_turn` range, video URL scheme/count — before the controller runs. A
`TwilightStruggleApiAuthentication` Rack middleware runs ahead of committee, so
the bearer-token check fails closed before any schema validation or controller
code. `Games#update` then reads only `external_id` and
`tournament_external_id`; only `external_id` and the resolved `tournament` reach
`Ops::TwilightStruggle::Games::Upsert`. The player names and other result fields
are validated as they pass through the schema and are never read into a record,
so nothing we don't need after the message is posted touches the database.

**Friendly-tournament singleton:** a game PUT with no `tournament_external_id`
is a "friendly" game. `Ops::TwilightStruggle::Games::Upsert` attaches it to the
one `TwilightStruggle::Tournament` row with `friendly: true`, creating it
(`I18n.t("twilight_struggle.friendly_tournament_name")`) on first use and
recovering from a `RecordNotUnique` race via the table's partial unique index
on `friendly`. A friendly tournament has no `external_id` — the model's
check constraint requires `friendly` and `external_id IS NULL` to agree.

## Per-server subscriptions

A tournament is the *site's* data; a destination is a *server's*. They are separate
rows for that reason: `twilight_struggle_destinations` hangs off
`ServerConfiguration` (unique on tournament × server), so several servers can
subscribe to one feed and none of them owns it. `TwilightStruggle::EffectiveConfig.new(tournament, server)`
walks that one server's destinations up the tournament lineage to resolve the
channel, the three templates, and the ping setting.
`EffectiveConfig.new(tournament.parent)` is nil-safe and is the idiom for "what
this tournament would inherit if it set nothing" — the config UI uses it for the
template pre-fill and the ping help line.

**Posted messages key on (game, `server_configuration`), never on the destination.**
The effective destination can be an *ancestor* tournament's row, so keying on it
flips identity the moment a server also subscribes to the child tournament, and
posts a duplicate. Server-keying also makes unsubscribe/resubscribe edit the same
message rather than orphan it.

Destinations carry an `active` flag (default true) rather than being destroyed on
unsubscribe, so the channel, templates and ping setting survive an
unsubscribe/resubscribe cycle. Inactive and absent resolve identically —
`EffectiveConfig#build_chain` and `Tournament#subscribed_servers` just filter on
`active`. `archived_at` is a separate concern ("hide from the list, keep posting");
`Destination#archived?` is the single place that knows an inactive destination's
archive flag is meaningless.

The settings resource is keyed by **tournament**, not by the destination row
(`resources :destinations, param: :tournament_id`), so the page opens whether or
not the server subscribes and the channel and wording can be set up first. Its
header toggle *is* the subscription — subscribe and unsubscribe are their own
`subscriptions` resource, since `destinations#destroy` no longer destroys.

**Pre-filled templates keep inheriting.** The form ships the inherited text in the
field, so you edit one word instead of retyping, and `Destinations::Update` stores
`nil` when the submitted text is byte-identical to what it would have inherited.
Both halves are load-bearing: pre-fill alone freezes a copy on first save and
silently stops a bracket tracking its league.

**The plugin's enable toggle is the per-server kill switch.**
`Ops::TwilightStruggle::Games::Post` needs an enabled plugin *and* a channel. There
is deliberately no `prerequisite:` lambda on the catalog entry — `PluginActivation`'s
validation would turn one into "you must subscribe before you can enable", and the
bespoke grant is already the gate.

## Tournament organisers

Organisers' Discord IDs arrive on an **optional `admins` array** on the tournament
PUT. Present replaces that tournament's whole set; **absent leaves our rows
alone**; `[]` clears them. Strict PUT semantics were rejected: a partial payload
would silently revoke every organiser and look intentional.

Admin IDs come from that field and **nowhere else** — never from the player
`discord_id`s in a game payload, where an organiser who declined to be listed
usually appears anyway. Opt-in by omission is the point. Authority walks the
tournament chain *downward*: an admin of a league runs its brackets
(`TwilightStruggle::AdministeredTournaments`).

Erasure is deliberately unsticky — a later PUT may recreate a deleted admin row.
There is no suppression list, because honouring a deletion request by storing
*more* personal data about the person is worse.

Page access is deliberately tournament-independent, and which tournaments an
organiser may act on is enforced one layer in, on the actions. That split, and why
the plugin toggle stays admin-only, is documented with the rest of the
authorization model in [Web (controllers and views)](../web/controllers-and-views.md).

Accepted residual risk: an organiser who is a member of a granted, enabled server
can subscribe their own tournament there whether or not that server cares. The
brakes are the bespoke grant, the admin-only toggle, unsubscribe, and channel
permissions.

## Posting

**Posting runs in a job, and the payload rides along in it.**
`Ops::TwilightStruggle::Games::Upsert` enqueues `TwilightStruggle::PostJob`
with the saved game and the raw result payload — the enqueue is the operation's
side effect, not the controller's, the same way `Ops::…::Plugins::Toggle`
publishes on the config bus. The job builds a `GameReport` from the payload and
hands both to `Ops::TwilightStruggle::Games::Post`. That op deliberately does not rescue
Discord errors — they propagate so the job's `retry_on` sees them. Permanent
failures (`UnknownChannel`, `NoPermission`, a deleted game) are `discard_on`ed
instead, so they leave no failed-execution row.

**Fan-out is one `PostJob` per subscribing server**, never one job that loops. A
`discard_on NoPermission` triggered by a single misconfigured server would
otherwise kill the whole fan-out.

**Posting logs why it did nothing.** Both quiet exits (no channel, plugin off) log,
as does the success path. Without that, a job that ran and changed nothing is
undiagnosable — which is exactly how the first live test failed.

The alternative — posting inline in the request — was built first and rejected.
It kept the result payload out of Postgres entirely, but bought that with no
retry at all: a Discord blip lost the post silently, the site got a `200`, and
nobody on either side learned the result never appeared. It also put a Discord
round-trip (two, on the ping path) inside the caller's request latency. The
privacy gain was close to zero, because the message we post publishes those
same player names to a Discord channel permanently — that is the whole feature.
Holding them in a job row for the seconds it takes to deliver is not the part
worth optimising.

What that costs, and how it is bounded: player names now sit in
`solid_queue_jobs.arguments`. Solid Queue's global retention would keep a
finished job for a day and a failed one for thirty, so `config/recurring.yml`
sweeps `TwilightStruggle::PostJob` specifically — finished rows hourly,
failed executions after 48 hours (a deliberate debugging window). Both numbers
are stated in the privacy policy; changing either means changing that copy too.

`Bot::Discord::Components` is the single Discord seam. Because the job runs in
`bin/jobs`, which loads discordrb, there is no need for a separate HTTP client
— an earlier `Bot::Discord::MessageApi` written for the web process was deleted
when posting moved to the job. Posting uses its `create_message` /
`edit_content` / `delete_message`; `edit_content` does not rescue, because the
job needs the failure to retry on.

**These messages are plain text, deliberately unlike everything else the bot
sends.** No accent container, no components, no link buttons — the site's own
result announcements are plain text and that is what these players read, so the
convention documented in [Message rendering](../bot/message-rendering.md) does not
apply here. Video URLs go in the message body as bare links and Discord builds its
own embed.

The shape is entirely template-driven, three templates per tournament
(inherited down the bracket chain like the channel): `template_win`,
`template_tie`, and `template_video`. A game with a video always uses the video
template, which is deliberately spoiler-free — both players and the link, no
winner, turn or method. `TwilightStruggle::Message` renders the chosen template
through `TemplateText` and exposes `content`; the token list lives in
`config/api/twilight-struggle/v1/docs/games.md`. A tournament can opt into Discord tags, which
append `(<@id>)` after a player's name and flag rather than replacing the name —
a stale snowflake or a departed player still leaves something readable. Every
send passes `allowed_mentions: {parse: []}`, so no message ever notifies anyone:
the tags are there to identify a player, not to ping them, and a player named
`@everyone` cannot ping the server.

## Data lifecycle

Guild purge is the cascade: destinations and posted messages hang off
`ServerConfiguration` with `dependent:`, so `Ops::ServerConfiguration::Destroy`
carries no Twilight Struggle special case. Tournaments and games stay — they are
the site's data, not the guild's. Organiser rows are per-user and are deleted by
`Ops::Users::Destroy`. See [Privacy](../privacy.md).

## Gotchas

- `discard_on Discordrb::Errors::X` in a job class body resolves the constant at
  **load** time, and the web process enqueues jobs with discordrb unloaded — that
  breaks Puma boot. Use the string form. rspec misses it (another spec file has
  already required discordrb); `rake active_record_doctor` caught it.
- `have_enqueued_job` deserializes each matched job's GlobalID arguments, so
  asserting *two* enqueued jobs trips Prosopite — with an empty app call stack,
  which is the tell that the N+1 is harness-side. Production `perform_later`
  queries nothing. Count via `ActiveJob::Base.queue_adapter.enqueued_jobs` when
  asserting a fan-out.
- `TwilightStruggle::AdministeredTournaments` walks the tournament chain breadth-first,
  which trips Prosopite on the same-shaped `parent_id = $1` query per level.
  Adjudicated false positive, encoded as `Prosopite.allow_stack_paths` in
  `spec/support/prosopite.rb`.
