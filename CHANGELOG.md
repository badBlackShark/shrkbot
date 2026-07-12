# Changelog

All notable user-facing changes to shrkbot are documented here. Internal
refactors, tooling, and CI changes are omitted; see the git history for those.

This project follows [Semantic Versioning](https://semver.org).

## [3.2.0] - 2026-07-12

### Added
- Server Shield now scans images that arrive via link-preview embeds, closing the "post a bare link" evasion where the scam image was never attached to the message. ([#152](https://github.com/badBlackShark/shrkbot/pull/152))
- Server Shield now scans Discord CDN image links pasted as message text, closing the "paste the link instead of attaching" evasion. ([#153](https://github.com/badBlackShark/shrkbot/pull/153))
- Server Shield now scans the first frame of GIF images, covering both uploaded `.gif` files and `.gif` CDN links. ([#154](https://github.com/badBlackShark/shrkbot/pull/154))
- The moderation "new account" age cutoff is now a per-server setting on the Server Shield page (1 to 365 days), and its default is raised from 7 -> 30 days to better catch throwaway scam accounts. ([#150](https://github.com/badBlackShark/shrkbot/pull/150))
- Moderation flag verdicts are now reversible: after confirming or dismissing a flagged image, an "Undo verdict" button lets staff re-decide. ([#157](https://github.com/badBlackShark/shrkbot/pull/157))
- Removal mod-logs now carry an "Undo punishment" button that reverses a reversible action (clears a timeout or lifts a ban) and sends the affected member a best-effort apology DM. Kicks and deleted messages can't be undone. ([#158](https://github.com/badBlackShark/shrkbot/pull/158))

### Changed
- Landing page refresh: a shared footer with a provenance line, updated hero copy, and a version badge in the header linking to the release notes. ([#149](https://github.com/badBlackShark/shrkbot/pull/149))
- Spam attachments are now fingerprinted by file content, so re-posting an identical file under different names across channels is caught instead of slipping past the per-channel threshold. ([#155](https://github.com/badBlackShark/shrkbot/pull/155))

### Fixed
- The bot no longer responds twice to commands and events while a deploy is in flight. Only one bot process is active at a time; expect a few seconds of unresponsiveness at deploy cutover instead. ([#148](https://github.com/badBlackShark/shrkbot/pull/148))
- The Cross-Channel Spam Guard now shows why a save failed instead of silently rejecting an out-of-range value (for example a window over 60 seconds). ([#151](https://github.com/badBlackShark/shrkbot/pull/151))

## [3.1.0] - 2026-07-11

### Added
- Member timeouts, kicks and bans are logged to the activity log, as toggleable events under a new Moderation group on the logging page. Each entry shows the affected user, the moderator, and the reason (via the guild audit log). ([#126](https://github.com/badBlackShark/shrkbot/pull/126))
- Server Shield can apply a distinct, harsher punishment to images matching a scam confirmed on your own server, overriding the general image-scan punishment. Defaults to reusing the general punishment. ([#135](https://github.com/badBlackShark/shrkbot/pull/135))
- Per-server "Ping staff on alerts" toggle on the Server Shield page. On by default; when off, alerts still post to the log channel without pinging. ([#134](https://github.com/badBlackShark/shrkbot/pull/134))
- The moderation page warns when the configured staff role lacks Manage Messages, which would silently hide staff commands from its members. ([#129](https://github.com/badBlackShark/shrkbot/pull/129))

### Changed
- Command permissions now defer to Discord's native permission system. A Server Settings → Integrations override granting a role access to a command is respected at runtime, instead of being vetoed. ([#128](https://github.com/badBlackShark/shrkbot/pull/128))
- The server switcher now appears on every plugin config page, not just the dashboard. ([#133](https://github.com/badBlackShark/shrkbot/pull/133))

### Fixed
- Guild commands (`/ping`, the "Report as scam" context menu) now register on real servers, filtered by each server's enabled plugins. Previously they only registered on the dev test server, so no guild command existed in production. ([#127](https://github.com/badBlackShark/shrkbot/pull/127))
- Inviting shrkbot from the website now grants its permissions and creates its managed role, deferring to the app's configured install settings. ([#125](https://github.com/badBlackShark/shrkbot/pull/125))
- Config changes saved on the website no longer fail during a Redis outage, and the bot resubscribes to the config bus automatically after Redis drops. ([#131](https://github.com/badBlackShark/shrkbot/pull/131))
- Fixed the vertical alignment of the "within" connector between the spam-guard number steppers. ([#130](https://github.com/badBlackShark/shrkbot/pull/130))

## [3.0.0] - 2026-07-10

Full rewrite from Crystal/discordcr to Ruby 4 / Rails 8.1 / discordrb. The bot
now runs as three processes (web, bot, job worker) on a shared Postgres + Redis
instead of a single monolith.

### Added
- A website alongside the bot. Per-server configuration now lives on the website: log in with Discord, pick your server, and configure everything from there.
- A shared operations layer for all writes, so the bot and the website run the exact same business logic.
- Full test suite with a changed-line coverage gate in CI. The Crystal version had no tests.
- Server Shield, a moderation suite with in-memory message scanning and zero message retention.

### Changed
- Ported plugins: Welcomes, Roles (self-assignment, role sync), and Logging.

### Removed
- All stock market functionality, for now. Not enough users to justify porting it.

## Earlier releases

- [2.0.0](https://github.com/badBlackShark/shrkbot/releases/tag/2.0.0) - 2020-08-19 — Crystal rewrite.
- [v1.3.1](https://github.com/badBlackShark/shrkbot/releases/tag/v1.3.1) - 2018-05-10 — Mutes, reminders, fixes and improvements.
- [1.3.0](https://github.com/badBlackShark/shrkbot/releases/tag/1.3.0) - 2017-11-21 — The original Ruby bot.
