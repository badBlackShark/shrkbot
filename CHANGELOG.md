# Changelog

All notable user-facing changes to shrkbot are documented here. Internal
refactors, tooling, and CI changes are omitted; see the git history for those.

This project follows [Semantic Versioning](https://semver.org).

## [3.5.1] - 2026-07-23

### Fixed
- The Looking for Game config page silently discarded every save on the live bot. The `lfg` plugin row was missing from the production database (seeds only ran when the database was first created), so saves returned 404 and the page reloaded with nothing persisted. Plugin seeding now runs on every boot. ([#208](https://github.com/badBlackShark/shrkbot/pull/208))
- The minimum-membership-age fields on the Looking for Game config page showed the browser's default spinner arrows instead of the site's +/- stepper controls. ([#208](https://github.com/badBlackShark/shrkbot/pull/208))

## [3.5.0] - 2026-07-23

### Added
- New plugin: Looking for Game. `/lfg` posts a group-up call that pings a configured role, with a Join button other members press to sign up, an optional start time that re-pings the joiners when it arrives, and a "Done looking" button for the creator. Posts store nothing in shrkbot's database; the state lives in the Discord message itself, and the post is deleted when it expires. ([#201](https://github.com/badBlackShark/shrkbot/pull/201), [#202](https://github.com/badBlackShark/shrkbot/pull/202))
- A Looking for Game config page on the website: which roles can be pinged, which channels allow posts, required and excluded role gates, a minimum-membership age, a cooldown, and how long a post stays up. Each pingable role can add its own role gates and override the channel list and membership age, and denied `/lfg` attempts can be surfaced on the logging page. ([#204](https://github.com/badBlackShark/shrkbot/pull/204))

### Fixed
- Welcome messages no longer render `@unknown-user` on servers with membership screening. The member is still pending when Discord announces the join, so the mention never resolved and stayed broken on the posted message; the welcome is now held until onboarding completes. On those servers the welcome now lands after Discord's own join message instead of before it. ([#206](https://github.com/badBlackShark/shrkbot/pull/206))

## [3.4.0] - 2026-07-18

### Added
- A one-time dismissible cookie notice on the website, clarifying that shrkbot only sets technical cookies and nothing third-party. ([#185](https://github.com/badBlackShark/shrkbot/pull/185))
- The roles config page now shows a callout recommending you raise shrkbot's role when it still sits at the bottom of the role list, where it can't assign any role. ([#192](https://github.com/badBlackShark/shrkbot/pull/192))

### Changed
- `/remind` confirmations now echo the reminder text back, so you can verify the reminder saved what you meant. ([#189](https://github.com/badBlackShark/shrkbot/pull/189))
- External links on `/info` and `/donate` (GitHub, invite, server settings, donation) moved from inline text links to proper link buttons under the message. ([#190](https://github.com/badBlackShark/shrkbot/pull/190))
- The onboarding DM for new servers now includes a direct contact for setup help. ([#191](https://github.com/badBlackShark/shrkbot/pull/191))

### Fixed
- Push notifications for proactive messages (like a reminder arriving in your DMs) no longer show an empty preview; they now carry the message text. ([#187](https://github.com/badBlackShark/shrkbot/pull/187))
- Security: a reminder delivered to a channel can no longer ping other users or roles through mentions in its text; mentions only resolve for the reminder's recipient, and reminder durations are bounded. ([#175](https://github.com/badBlackShark/shrkbot/pull/175))
- Security: web config forms now verify that submitted channels and the staff role actually belong to the server being configured, instead of accepting any snowflake. ([#174](https://github.com/badBlackShark/shrkbot/pull/174), [#183](https://github.com/badBlackShark/shrkbot/pull/183))
- Security: dashboard access is re-verified against Discord before every config write, so an admin demoted or removed on Discord loses access immediately instead of when their cached session expires. ([#176](https://github.com/badBlackShark/shrkbot/pull/176))
- Security hardening from a full audit: an enforcing Content Security Policy on the website, session rotation on sign-in, runtime re-checks of declared command permissions, a byte cap on attachment downloads during image scanning, rate limiting on the live server list, and leave messages that can never ping. ([#177](https://github.com/badBlackShark/shrkbot/pull/177), [#182](https://github.com/badBlackShark/shrkbot/pull/182), [#181](https://github.com/badBlackShark/shrkbot/pull/181), [#179](https://github.com/badBlackShark/shrkbot/pull/179), [#178](https://github.com/badBlackShark/shrkbot/pull/178), [#184](https://github.com/badBlackShark/shrkbot/pull/184))

## [3.3.0] - 2026-07-13

### Added
- Owner-curated global scam-image blocklist. A right-click "Toggle global scam block" command lets the bot owner mark an image's fingerprint as a known scam across every server, without shipping a build. Matches are treated like a normally-detected scam: each server's own dismissal still wins, and the owner's list never applies the harsher confirmed-punishment escalation reserved for a server's own confirmations. ([#160](https://github.com/badBlackShark/shrkbot/pull/160))
- Welcome messages gain a per-server "Ping on join" toggle, so the member mention can still render as a clickable pill without firing a notification. On by default, so existing servers keep pinging. ([#166](https://github.com/badBlackShark/shrkbot/pull/166))
- Open Graph and Twitter card meta tags, so a shared shrkbot link shows a proper title, description, and preview image. ([#164](https://github.com/badBlackShark/shrkbot/pull/164))

### Changed
- Single-selection role menus can now toggle a role off: clicking the role you already hold removes it without replacement, instead of doing nothing, so you can return to holding none of the set. ([#167](https://github.com/badBlackShark/shrkbot/pull/167))
- The manual "Report as scam" and global-scam commands now inspect link-preview embeds and pasted CDN image links, not just attachments, matching the automatic scan. The per-source image cap is also raised from 3 -> 4. ([#163](https://github.com/badBlackShark/shrkbot/pull/163))
- Confirmed scam-image fingerprints are now retained for 180 days instead of 30, so a moderator's confirmation survives a scam campaign going quiet for a month or more. ([#171](https://github.com/badBlackShark/shrkbot/pull/171))
- The "Report as scam" action is now surfaced as an info callout under the consent warning on the Image Scanning page, instead of a small footer note. ([#170](https://github.com/badBlackShark/shrkbot/pull/170))
- Scam-text keyword weights retuned for the current scam wave: added crypto-casino and bonus-offer terms, and lowered "withdraw" so it no longer flags on its own in legitimate messages. ([#171](https://github.com/badBlackShark/shrkbot/pull/171))

### Fixed
- shrkbot no longer double-posts its own kicks, bans, and timeouts to the moderation log. ([#169](https://github.com/badBlackShark/shrkbot/pull/169))
- Toggling image scanning from the Server Shield overview page no longer wipes the confirmed-punishment settings on a config whose image-scanning options were never edited. ([#165](https://github.com/badBlackShark/shrkbot/pull/165))
- The public site header logo now links to the home page. ([#168](https://github.com/badBlackShark/shrkbot/pull/168))

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
