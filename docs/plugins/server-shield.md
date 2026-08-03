# Server Shield (moderation)

The moderation plugin group — cross-channel spam guard and scam-image detection —
and the invariants that constrain how harshly it is allowed to act.

Server Shield is a plugin *group*: the `moderation` parent (which requires the
logging plugin and a configured log channel) plus two sub-plugins,
`spam_protection` (Cross-Channel Spam Guard) and `image_scanning` (Scam Image
Detection). Both sub-plugins additionally require a staff role to be configured.
The relationships are declared on the `PluginCatalog::Definition`s (`parent`,
`requires_plugin`, `prerequisite`), so every enable path — the generic toggle, the
sidebar UI, and the Configure operations — agrees. See
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

Message creates scan attachments; message updates scan embeds (`Moderation::EmbedScan`
on `MESSAGE_UPDATE`). They are separate sources, so nothing is scanned twice.

## OCR sidecar

PaddleOCR `PP-OCRv5_mobile` only, and **x86_64 only** — the aarch64 wheels segfault
and Rosetta hangs during init, so a Mac cannot run the sidecar locally. `paddlepaddle`
is pinned to `==3.2.2`; 3.3.x breaks CPU inference (Paddle #77340). The pin and its
reason live in `ocr/requirements.txt`.
