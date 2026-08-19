# Changelog

All notable user-facing changes to shrkbot are documented here. Internal
refactors, tooling, and CI changes are omitted; see the git history for those.

This project follows [Semantic Versioning](https://semver.org).

## [3.8.2] - 2026-08-20

### Fixed
- A Twilight Struggle tournament sent with the status `Closed` is treated as closed. The check compared against the exact lowercase text `closed`. A site that capitalises its status names left every finished tournament in the active part of the subscription list. It carried no closed badge, and there was no way to tidy it away. The check now ignores capitalisation and surrounding spaces. `Registration Closed` still counts as open, and the API reference says so. ([#275](https://github.com/badBlackShark/shrkbot/pull/275))

## [3.8.1] - 2026-08-19

### Fixed
- The production image does not build in 3.8.0. That release dropped Active Storage, which removed the `storage` directory from the repository, but the Dockerfile still changed that directory's owner, so the build stopped with `chown: cannot access 'storage': No such file or directory`. This affects self-hosting only; the hosted bot is unaffected. ([#273](https://github.com/badBlackShark/shrkbot/pull/273))

## [3.8.0] - 2026-08-19

### Added
- Preview mode. `/preview` and `/preview/<plugin>` render the real plugin config pages against a demo server, with no bot invite and no sign-in required. Every field, dropdown and Discard button works; only saving is off, refused in the UI and again server-side. A banner on each preview page says nothing is saved. There is one entry point per state: the foot of the landing page when signed out, the empty server list, and the "Don't see a server?" card under your server grid. ([#246](https://github.com/badBlackShark/shrkbot/pull/246), [#247](https://github.com/badBlackShark/shrkbot/pull/247), [#249](https://github.com/badBlackShark/shrkbot/pull/249), [#250](https://github.com/badBlackShark/shrkbot/pull/250))
- Welcomes can skip the leave message for a member who was kicked or banned, so a server no longer announces the departure of someone staff removed. Off by default. Discord's member-remove event carries no reason, and it has no ordering guarantee against the audit-log entry that does, so shrkbot notes kicks and bans in a 30-second in-memory ledger and holds the leave message for 3 seconds before checking it. This needs the View Audit Log permission, which the default invite grants. Discord's prune is not covered, because its audit entry is a bulk count with no per-user target. ([#239](https://github.com/badBlackShark/shrkbot/pull/239))
- The Twilight Struggle results API takes an optional `rating_before` and `rating_after` per player on `PUT /games/{external_id}`. Both are validated as numbers between -100000 and 100000; fractional and negative ratings are accepted, because rating systems produce both. Twelve new template tokens render them: `{usa_rating_before}`, `{usa_rating_after}` and `{usa_rating_change}`, plus the same three for `ussr`, `winning` and `losing`. The change token is the difference between the two ratings, rounded to 2 decimals and always signed, such as `+12`. A rating shrkbot did not receive renders empty, as `{winning_method}` does. No shipped template uses the new tokens, so put them in your own template to see them. Ratings are rendered into the Discord message and never stored, exactly like a player's name or flag. ([#240](https://github.com/badBlackShark/shrkbot/pull/240))

### Changed
- Bespoke plugins granted to your server sort into their own section at the top of the dashboard, above a separator line, each carrying the copper puzzle-piece badge the bespoke plugins page already uses. The section and the line appear only when your server has one. Sorting stays alphabetical within each section, and plugins you cannot manage still come last. ([#242](https://github.com/badBlackShark/shrkbot/pull/242))
- Moderation log entries name the offender as a mention followed by their username, instead of a bare mention with all notifications suppressed. Suppressing a mention strips the user from the message payload, so a client that never cached the member rendered `@unknown-user`, which is every client once the member is banned. The offender's mention is now allowed through, so the user object rides along and the mention always resolves. A member who can still see the log channel gets a real ping; after a ban or a kick, nothing is delivered. ([#244](https://github.com/badBlackShark/shrkbot/pull/244))
- The plugin marquee on the landing page can be scrolled by hand. It is a horizontally scrollable region with a hidden scrollbar, the mouse wheel is mapped to it, and touch drag works. The wheel offset wraps at half the track width, where the duplicated card row repeats, so the scroll never reaches an end. Hover still pauses the animation. While the pointer is over the banner, the wheel scrolls the banner rather than the page. Under `prefers-reduced-motion` the scrollbar stays visible, because no animation runs there to show that the row moves. ([#270](https://github.com/badBlackShark/shrkbot/pull/270))
- Every badge variant carries a 1px border in its own hue. Only the copper badge had one, so on a bespoke plugin row a copper badge and a status badge sat side by side and read as different components. The success, warning and danger borders are mixed at 34% of their own colour in the light theme and 22% in the dark one. Badges are 2px larger as a result. ([#243](https://github.com/badBlackShark/shrkbot/pull/243))
- The welcome message placeholders copy on click, the same as the Twilight Struggle template tokens. Click `{user}`, `{username}`, `{displayname}` or `{membercount}` under the message boxes to copy it. Each chip is a real button, so it takes keyboard focus and activation, and the confirmation is announced to screen readers. Copying needs a secure context, so a dashboard self-hosted over plain HTTP reports "Copy failed" rather than going quiet. ([#240](https://github.com/badBlackShark/shrkbot/pull/240))
- The Twilight Struggle template tokens are grouped into five labelled rows by what each one describes: the game, the USA player, the USSR player, the winner and the loser. Reading one row teaches the naming of the other four. Click a token to copy it. ([#240](https://github.com/badBlackShark/shrkbot/pull/240))
- The Twilight Struggle results API no longer requires `winning_method` on a game. A site that does not record how a game ended can leave it out, and `{winning_method}` then renders empty, as `{turn}` already did without a `winning_turn`. Templates keep the punctuation around the token, so `in {turn} ({winning_method})` reads `in Turn 7 ()` for a game sent without one. ([#229](https://github.com/badBlackShark/shrkbot/pull/229))

### Fixed
- Bans logged "was banned by an unknown moderator. No reason was given." even when Discord's audit log held both, and kicks logged nothing at all. shrkbot polled the audit-log endpoint the moment the gateway event arrived, and Discord writes the entry afterwards, so the poll routinely came back empty. Ban, kick and timeout logs now read the audit-log entry Discord pushes, which carries the performer, the reason and the target. This also drops an audit-log request that fired on every member departure, voluntary ones included. It needs the View Audit Log permission, which the default invite grants. Without it, moderation logging stays silent instead of naming an unknown moderator. ([#238](https://github.com/badBlackShark/shrkbot/pull/238))
- Reordering roles or channels no longer makes the bot rewrite every role and channel in the server. Discord fires one event per role or channel whose position changed, so dragging one role to the top of a 60-role server sent 60 events, and each one triggered a full resync of roughly 3600 row writes. Channels were heavier still, because every channel's permission overwrites were rebuilt on each pass. The bursts exhausted the bot's database connections and set off a run of error DMs to the bot owner. Each event now writes only the role or channel it names. ([#233](https://github.com/badBlackShark/shrkbot/pull/233), [#234](https://github.com/badBlackShark/shrkbot/pull/234))
- Revoking a role's access to a channel could leave the old permission overwrite in shrkbot's copy of your server, so its view of who can see a channel drifted from Discord's. Stale overwrites are pruned now. ([#234](https://github.com/badBlackShark/shrkbot/pull/234))
- One burst of errors no longer sends the bot owner minutes of repeat DMs. Repeats of the same error from the same source within 5 minutes are counted rather than sent, and the next report says how many it stands for, so a storm still reads as a storm. The bot process also runs a database pool sized for gateway bursts rather than the web default, which is what the storms were reporting. ([#232](https://github.com/badBlackShark/shrkbot/pull/232))
- Toggling a plugin from the dashboard re-rendered its row with the locked and manageable flags reset to their defaults instead of the row's real state. ([#242](https://github.com/badBlackShark/shrkbot/pull/242))
- Alert and notice toasts are readable in the dark theme. Their background was a 14% tint over transparency, and a toast floats above the page rather than sitting on a card, so the content behind it showed through the message. The same 14% tint is now mixed into the card surface, which keeps the intended appearance and leaves callouts, badges and hover tints on the translucent tokens they need. ([#248](https://github.com/badBlackShark/shrkbot/pull/248))
- A tooltip no longer stays on screen after you click what it belongs to. The bubble revealed on focus, and a mouse click focuses the trigger, so clicking a template token, a welcome placeholder or a reset button left its tooltip up until focus moved elsewhere, where it could sit on top of the next tooltip you hovered. It reveals on keyboard focus only now, and hover still covers the mouse. ([#240](https://github.com/badBlackShark/shrkbot/pull/240))

## [3.7.0] - 2026-07-27

### Added
- A public page at `/bespoke-plugins` describing bespoke plugin work: how a commission goes, the Twilight Struggle plugin as an example, and how to get in touch. shrkbot itself stays free; a bespoke plugin may carry a small fee agreed up front. Linked from the top bar for both signed-out visitors and dashboard users. ([#227](https://github.com/badBlackShark/shrkbot/pull/227))
- Public API documentation at [badblackshark.github.io/shrkbot](https://badblackshark.github.io/shrkbot/), generated from the OpenAPI schema. Covers the base URL, key auth, idempotent upserts and status codes, plus per-field descriptions and response bodies for the Twilight Struggle API, so the machine-readable contract no longer has to be requested by mail. ([#226](https://github.com/badBlackShark/shrkbot/pull/226))

### Fixed
- Signing in with Discord did nothing in Safari and Chromium browsers: the site's Content Security Policy blocked the form submission once it redirected to Discord, with no visible error. Firefox was unaffected, which made it look like a mobile-only problem. ([#225](https://github.com/badBlackShark/shrkbot/pull/225))

## [3.6.0] - 2026-07-27

### Added
- Bespoke plugins: plugins the bot owner activates for one specific server, rather than shipping to everyone. A bespoke plugin stays invisible on every other server (no plugin card, no sidebar entry, no config page, no slash commands), and revoking the grant switches it off. Managed from a new owner-only admin page. ([#215](https://github.com/badBlackShark/shrkbot/pull/215))
- First bespoke plugin: Twilight Struggle, built for twilight-struggle.com and available only to servers the bot owner grants it to. Tournament and game results from the site are posted into a Discord channel of your choice, as plain text matching the site's own announcements. Each tournament gets a channel, three message templates (win, tie, video) with a live preview, a ping control, and an archive toggle; bracket tournaments inherit anything you leave blank from their league. Several servers can subscribe to the same tournament, each with its own channel and wording, and games with a video always use the spoiler-free template. ([#213](https://github.com/badBlackShark/shrkbot/pull/213), [#216](https://github.com/badBlackShark/shrkbot/pull/216), [#217](https://github.com/badBlackShark/shrkbot/pull/217), [#218](https://github.com/badBlackShark/shrkbot/pull/218))
- Tournament organisers listed on twilight-struggle.com can configure that plugin, including subscribing servers to their tournament, without being a Discord admin of those servers. A server admin still has to switch the plugin on once, which is that server's consent. ([#220](https://github.com/badBlackShark/shrkbot/pull/220))
- The results API those tournaments arrive on (`/api/twilight-struggle/v1`) is key-gated and issued by the bot owner, not open for general use. Result payloads (player names, flags, winning side and method) are validated and rendered into the Discord message, never stored. ([#213](https://github.com/badBlackShark/shrkbot/pull/213))

### Changed
- Plugins you can see but not configure now render as locked: a disabled configure button on the plugin card and a non-navigable sidebar entry, instead of an error page after the click. ([#219](https://github.com/badBlackShark/shrkbot/pull/219))

### Fixed
- Welcome messages with "Ping on join" off no longer render the new member as `@unknown-user` for anyone who was offline when they joined. The mention now resolves for everyone, and the joiner still gets no notification sound or push. A template containing `@everyone` is also no longer pingable on that path. ([#212](https://github.com/badBlackShark/shrkbot/pull/212))

## [3.5.2] - 2026-07-24

### Fixed
- Enabling a plugin from its own config page, rather than from the dashboard plugin card, left its slash commands unregistered on Discord until the next bot restart. Turning Looking for Game on from the LFG page enabled it everywhere except Discord's command list, so `/lfg` never showed up. Every plugin config page now registers and unregisters its commands as the enable switch changes. ([#210](https://github.com/badBlackShark/shrkbot/pull/210))

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
