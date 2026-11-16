# Server Shield (moderation)

The moderation plugin group — cross-channel spam guard and scam-image detection —
and the invariants that constrain how harshly it is allowed to act.

Server Shield is a plugin *group* with no switch: the `moderation` `PluginCatalog::Group`
holds the shared settings page, and two protections, `spam_protection` (Cross-Channel
Spam Guard) and `image_scanning` (Scam Image Detection), each turn on from their own
page. Each protection requires Logging enabled (with its log channel) and a staff role.
The relationships are declared on the `PluginCatalog::Definition`s (`parent`,
`requires_plugin`, `prerequisite`), and `Ops::ServerConfiguration::Plugins::Toggle`, the
one path that changes an activation, enforces them: Logging cannot turn off while a
protection is on. `Ops::Moderation::Settings::Update` refuses clearing the staff role the
same way, through `Toggle.dependent_refusal`. See
[Plugins](overview.md) for the catalog model and
[Design system](../design/design-system.md) § Plugin groups for the UI shell.

## Content-signal lock

A flag or a removal requires a **content signal**: either a positive OCR score or
a phash match. Metadata alone — account age, links, roles — can only *amplify* a
score that already has a content signal behind it. `Classifier.decide` returns
`:allow` outright when `content_signal` is false, whatever the accumulated risk.

Rationale: a new account posting a link is not evidence of anything. Punishing on
metadata alone means punishing normal new members.

## Own-guild confirmation gates harsh action

**Hard invariant, not configurable:** an automated removal may only be driven by a
phash that this guild's own staff confirmed. A hash confirmed only in *other*
guilds (`:foreign_confirmed`) caps the verdict at `:flag_for_review`, no matter how
high the risk score climbs.

This is Sybil defence. Without it, anyone who can stand up guilds and confirm
images in them can teach every other guild to auto-remove content of their
choosing. There is deliberately no setting that relaxes it.

## Privacy

Scanning is **in-memory only**. No message content, image, or extracted text is
stored anywhere — including the OCR sidecar. What persists is a perceptual hash and
its staff confirmations. Stale hashes are pruned by
`Ops::Moderation::Phashes::Prune` (recurring, daily): hashes unseen for 180 days
and hashes left with no confirmations are deleted, with `global_scam: true` rows
exempt. Guild-scoped moderation data is purged by the `ServerConfiguration`
cascade. These promises are stated in the privacy policy and are binding — see
[Privacy](../privacy.md).

## SSRF invariant

External and embedded images are fetched via Discord's **`proxy_url` only**, never
the raw origin `url` (`Moderation::ImageScanning::ScannableImages` filters on it).
The bot must never issue an HTTP request to an attacker-controlled host. This binds
any future non-attachment image source.

Message creates scan attachments, Discord-CDN links in the content, and everything
inside a forwarded message (`message_snapshots`: its attachments, links and embeds).
A snapshot never changes, so create is the only event that carries it. Message
updates scan the message's own embeds (`Moderation::EmbedScan` on `MESSAGE_UPDATE`).
Within one event an image is scanned once: `ScannableImages` drops URLs that point at
the same file, ignoring the host, the query string, the fragment and percent-encoding.
Nothing dedupes across events, so an image that a later update carries again is
scanned again.

## Every image is scanned

**Hard invariant:** no per-message image cap, no sampling, no trust shortcut. Any
rule that skips an image is a bypass as soon as someone reads it. A cap of four was
beaten by four harmless images with the scam as the fifth. Discord bounds attachments
and embeds at 10 each per message. Links are bounded only by the message length, so
the per-author queue below keeps one author from starving the rest.

One message is one `ScanQueue` job (`ScanMessage`). Its images are scanned in order
and the scan stops at the first `:remove` verdict, so a message is removed and its
author punished once. A crash on one image never skips the rest. Every flagged image
gets its own log entry with its own verdict buttons. The first entry of a message
pings staff; the later ones are sent with `SUPPRESS_NOTIFICATIONS`.

A forwarded message scores like the message it forwards: the link amplifier reads the
forwarded text as well as the forwarder's own.

`ScanQueue` is fair per author. Each author has a lane, the workers take one job per
lane in turn, and one author never holds two workers. A flood delays the flooder's
own scans, and everyone else waits for at most the job each worker already runs. A
lane holds 500 waiting messages. Past that the scan is dropped with an error line,
which fails open; the bound protects memory and nothing else.

## OCR sidecar

PaddleOCR `PP-OCRv5_mobile` only, and **x86_64 only** — the aarch64 wheels segfault
and Rosetta hangs during init, so a Mac cannot run the sidecar locally. `paddlepaddle`
is pinned to `==3.2.2`; 3.3.x breaks CPU inference (Paddle #77340). The pin and its
reason live in `ocr/requirements.txt`.
