# Voice

How shrkbot's copy sounds. Read this before writing or changing any user-facing
string: Discord messages and command descriptions, website copy, and PR
descriptions.

Rules are derived from the Discord copy already in the repo, which is the
surface that has had the most correction passes. Examples are real strings, not
invented ones.

## The four surfaces

Each has a different reader, so each has a different register. Copy that fits one
surface is usually wrong on another.

**Discord** - largely non-technical readers, mid-task, often on a phone. The
least technical surface and the cleanest one. Say the minimum that answers "what
happened and what do I do now". Detail the reader did not ask for is noise.

**Website** - readers who can set up a Discord bot but are not software
engineers. This is the surface people judge the project by, so the prose has to
be clean. Technical, but no engineering vocabulary that a competent server admin
would have to look up.

**PR descriptions** - written for software engineers, usually exactly one
reader. The most technical surface, and the one where an awkward sentence costs
least. Optimise for a reviewer making a decision.

**Release notes** - `CHANGELOG.md` and the GitHub release body built from it.
Sits between the website and a PR description. Every technical detail a PR body
would carry is allowed: the Discord event that fires, the API field and its
bounds, the numbers that made the bug bite. The prose is held to website
standard, because the release page is public and read by people who never see
the repository. So: full sentences, no shorthand, no internal class or constant
names, and one bullet that reads on its own without the diff beside it.
The GitHub release title takes the same ` - ` joiner as every other surface.
Releases up to 3.8.1 used an em dash and are left as a record.

## Rules for every surface

**State what happened, never that it succeeded.**

```
Roles updated.
Timeout cleared for %{user}.
```

No "Successfully", no "has been". If nothing went wrong, the outcome is the
message.

**Add the consequence when the reader would otherwise have to ask.**

```
Confirmed as a scam by %{actor} - the bot will remember this image.
The member was kicked; a kick can't be undone.
```

**Every failure names a cause or a fix.**

```
I couldn't understand that duration. Try something like `1d2h30m`.
Could not post the role message - check the channel.
```

**No internals.** No error codes, class names, "validation failed", "invalid
input", "an error occurred". The reader cannot act on any of it.

**Internal vocabulary stays internal, even when it reads like English.** The code
calls a precondition a gate, a plugin group a group, a server a server
configuration. Only the last one is obviously a leak; the first two look like
plain words and slip through. Name the thing the reader is actually setting -
roles, requirements, restrictions - not the mechanism that enforces it.

```
The per-role cards below add extra restrictions on top of these.
```

"Gate" in particular is a word almost nobody uses for a rule they configured
themselves. Its plain-English senses are a fence and a boarding point, and
neither is what the setting does.

**Second person for what the reader must do, and for the one thing you want them
to do.** Use it sparingly. If every clause is "you", none of them stand out.

```
You need the staff role or the Manage Messages permission to do that.
Show shrkbot's tech stack, where its code lives, and how you can add it to your server.
```

**The joiner is ` - `.** Never an em dash, anywhere, on any surface.

**ASCII over glyphs.** `->` for a UI path or a transformation, `:)` over an
emoji. The design guidelines lean the same way. The one deliberate exception is
the `♥` in the site footer.

```
In Server Settings -> Integrations -> shrkbot, limit the /lfg command to the channels and roles that should use it.
Stylized and lookalike characters are folded to their plain form (ⓕⓡⓔⓔ, ｆｒｅｅ -> free), so disguises don't help.
```

**Serial comma.** Lists of three or more take the serial (Oxford) comma:
`announcements, and press coverage`, never `announcements and press coverage`.

**Never "we".** shrkbot is one developer. Name shrkbot when something acts, use
the passive when no actor matters, and use "I" only where the developer speaks
personally, as on the bespoke-plugins page. "We" is correct in exactly one case:
when it means the developer and the reader together.

```
A token shrkbot doesn't know is left exactly as you typed it.
Two optional but recommended Discord settings
Let me know what your general idea is, and we'll figure out together if and how shrkbot can work for you.
```

**Say nothing the controls already say.** A form field that reads
`4 different channels within 15 seconds` needs no help text repeating it, and
help text that hardcodes a default goes stale the moment a server changes it.
Delete it rather than restate it.

**Don't restate a heading in the text under it.** A card subtitled "Two optional
but recommended Discord settings" does not open with "Neither is required, but
we recommend both".

**Offer, don't instruct, when the reader has a choice.** "a quieter log that
staff can check on their own" leaves it optional. Dropping "can" turns the same
sentence into an order.

**Interpolate the real number or name.** Never "some", "several", "a while".

```
the account is only %{days} days old
matched %{count} custom keywords
```

**Apologise only for harm the bot actually caused.** Routine failure is not
harm. There is exactly one apology in the codebase, and it is for a member the
bot punished by mistake:

```
Sorry - you were automatically moderated in %{server} by mistake, and a staff member has reversed it.
```

**The verb must match what the reader actually gets.** A command that links to
the repository shows where the code lives. It does not show the code.

## Rules for Discord

**One sentence.** A second sentence earns its place only as a constraint, an
example, or a consequence.

```
Cancel one of your reminders.
Change the text of one of your reminders.
Set a reminder to be sent to you after a delay (e.g. 1d2h30m).
```

**"I" only when the bot itself failed.** Everywhere else the bot is "shrkbot" or
the sentence is passive. The bot never narrates its own successes in first
person.

```
I couldn't reverse that - I may be missing permissions.
```

**Fragments that compose into a larger sentence stay lowercase and take no
terminal period.** Check how the string is interpolated before you punctuate it.

```
on cooldown (%{time} left)
that role isn't set up for Looking for Game
```

**Command descriptions lead with an imperative verb.** Constraints are appended
as a fragment.

```
List your active reminders.
Broadcast a message to the owner of every server shrkbot is in. Bot owner only.
```

## Rules for the website

Everything under "every surface" applies. Three more, all from settings pages:

**Sibling help texts share a shape.** If the fields around yours all open "How
long a member must...", yours does too. A single field that switches to a
noun-phrase register reads as though someone else wrote it.

**Say what a setting does, not how it is stored.** A tournament "uses a
30-minute delay", not "is set to 30 minutes". A tournament higher up the chain
is a "parent tournament", not one "above". When the value is an option label,
quote it so it reads as the label: `OTSL 2026 uses "Name and tag".`

**Warn before the setting, and say what it costs.** Put the limitation ahead of
the control it applies to, and name the trade-off rather than grading it.

```
1 is aggressive - a single matched word can delete an image. 2 or more keeps one stray word from triggering.
Acts only on unmistakable scams. Fewest false positives; more scams slip through.
A ban is permanent until a mod lifts it, and shrkbot can't undo it.
```

## Rules for PR descriptions

As short as possible while carrying every fact a reviewer needs to decide. Cut
anything the diff already says. Applies to every repository, not only this one.

**Default budget is 15 lines.** Going over is fine when the change earns it, but
then the body opens with one line saying why it is long. The overrun is a
deliberate act, not drift.

**Controlled English** (the writing rules of ASD-STE100, without its restricted
dictionary): one idea per sentence; active voice; simple present or simple past;
keep articles and full sentences; one term for one thing, never a synonym for
variety; no gerund used as a verb; noun clusters of three words maximum;
procedural sentences of 20 words or fewer, descriptive 25 or fewer; write a
warning or a limitation before the thing it applies to.

**Cut the patterns that bite in a PR body:** importance puffery, `-ing` clauses
pretending to explain, fake-strong verbs, binary contrasts, colon reveals,
summary-recap endings, decorative em dashes.

**A refactor body owes two things, and they come first in the budget.** One: the
invariant and the check that proves it - example counts with the delta accounted
for, or the constant that no longer resolves. Two: a "deliberately not done"
line naming what you found, left, and recorded, so the omissions read as
decisions. When one PR is based on another, name the base branch in line one.

Everything else is what gets cut to fit. Before/after tables, a tour of the old
code, and a recap of the reasoning are the first to go: the diff carries them.
The budget is not waived for a large refactor. A long body means the change
should have been more than one PR.

**Show, do not claim.** Paste the failing command, the error line, the test
counts, the measured numbers. A reviewer should be able to check every claim
without trusting the author.

## Weak to better

Strings that were rewritten, and the fault each one had. Add to this list
whenever copy is corrected - the pairs teach more than the rules do.

| Weak | Better | Fault |
| --- | --- | --- |
| `Show information about shrkbot - its code, stack, and how to add it to your server.` | `Show shrkbot's tech stack, where its code lives, and how you can add it to your server.` | "Show information about" is a filler verb phrase, and the command shows a link to the repository rather than the code. |
| `Find out what it costs to run shrkbot and how you can support the project.` | `Show what it costs to run shrkbot and how to support it.` | "Find out what it costs" says what "Show what it costs" says in less. Donating is a soft sell, so it keeps the lighter "how to support it" while the invite string above keeps the second person. |
| `Triggers when the same message appears in 4 different channels within 15 seconds.` | Deleted. The unit label became `different channels`. | The two steppers beside it are the real controls. The sentence restated them and hardcoded their defaults, so it would have lied as soon as a server changed either one. |
| `Neither is required, but we recommend both for the smoothest Looking for Game experience:` | Deleted. | It restated the card's own subtitle, and "the smoothest ... experience" is puffery. |
| `Two optional Discord settings we recommend` | `Two optional but recommended Discord settings` | "We" is one developer. The compound modifier takes no internal commas. |
| `shrkbot can only assign roles below its own, and it looks like its role is at the very bottom. Please move shrkbot's role up if you want it to be able to assign roles.` | `shrkbot can only assign roles below its own, and its role sits at the very bottom. Move it up in Server Settings so shrkbot can assign roles.` | `bot_at_bottom?` is a definite position check, so "it looks like" hedged on a known fact. The old second sentence restated the first. |
| `Turn it off for a quieter log staff check on their own.` | `Turn it off for a quieter log that staff can check on their own.` | Missing relative pronoun made a garden path ("log-staff-check"). "Can" keeps it an option rather than an order. |
| `300 seconds, which is 5 minutes` | `300 seconds (5 minutes)` | "Which is" is filler around a conversion. |
| `The duration the "Looking for Game" post remains visible after it starts. For scheduled posts, this time only starts with the actual session, not during the "gathering interest" period.` | `How long the "Looking for Game" post stays visible. For scheduled posts, the clock starts with the session, not while it gathers interest.` | Its two sibling fields both open "How long a member must...", so the noun-phrase register was the odd one out. Second sentence ran 24 words. |
| `We couldn't reach Discord to load your servers.` | `shrkbot couldn't reach Discord to load your servers.` | Six strings across the site said "we". Each took one of three fixes: name shrkbot where something acts, use the passive where no actor matters (`Your Discord sign-in couldn't be refreshed.`), or delete the clause where the heading already said it (`Please stand by - this only takes a moment.`, under a page titled "Signing you back in"). |
| `Your members' privacy is a priority and a guarantee: moderation happens in memory, your messages are never stored.` | `Your members' privacy is guaranteed, and it stays that way: moderation happens in memory, and your messages are never stored.` | A guarantee outranks a priority, so leading with the weaker word read as a hedge on the stronger one. The rewrite keeps the ongoing commitment without discounting the promise. |
| `Could not delete the server configuration - it's a preview configuration.` | `Could not delete this server - it is a preview, not a real Discord guild.` | The cause repeated the noun instead of explaining it, so the reader learns nothing after the dash. "Server configuration" is also the internal name for what every other string calls a server. |
| `Preview a server` | `Preview features` | The verb has to match what the reader gets. Nothing about the preview is server-specific - the fake guild is only the vehicle for showing what shrkbot does, and offering to preview "a server" promises something the reader already has. |
| `You're looking at a preview server - nothing you change here is saved.` | `You're looking at a preview - nothing you change here is saved.` | Same fault as the button above: "preview server" reads as a kind of server rather than as a demonstration of the product. |
| `The per-role cards below add extra gates on top of these.` | `The per-role cards below add extra restrictions on top of these.` | "Gate" is the internal name for the check, not a word a server admin would use for the rule they set. "Restrictions" covers both halves of what the cards hold - required roles and excluded roles - where "requirements" would only cover the first. |
| `%{count} extra gate` / `Server-wide gates, allowed channels, cooldown and post lifetime` / `each with its own extra gates` / `Enable the plugin to configure pingable roles and gates.` | Same swap, `gates` -> `restrictions`. | Five sites, one word. `gate` stays in the code and in `docs/`, where it names the mechanism for people who maintain it. |
| `the leave message waits a few seconds while shrkbot reads the audit log` | `the leave message waits 3 seconds while shrkbot reads the audit log` | The real number was in the code (`Welcomes::GracePeriod::DURATION`). "A few seconds" is the same fault as "a while": the reader cannot plan around it, and a changelog is no more exempt from the rule than a settings page. |
| `Steam sends developer posts in English, so leaving English out also drops patch notes and announcements.` | `Most developers write their Steam posts in English, so leaving English out usually drops patch notes and announcements.` | Checked against Western games only. Chinese studios write Chinese into Steam's primary (English) slot, and Steam's feed passes that text on unchanged: 11 of 20 posts for one game. A claim about external data has to hold for every variant, or name the majority it covers. |
| `Caches, background-job records and logs are cleared automatically (at most 60 days, 30 days and briefly, respectively).` | `... (at most 60 days, 30 days and 7 days, respectively).` | "Briefly" sat beside two real numbers, and nothing enforced it: the logs had no time limit at all. A retention promise needs the number the host is configured to, because the policy binds the implementation. |
| `Tokens` + `Anything in braces is replaced when the message is built. A token shrkbot doesn't know is left exactly as you typed it. Click a token to copy it.` | `Placeholders (click to copy)` | The page called the same thing "tokens" and "placeholders" depending on the card, and the paragraph restated what the chips and the live preview already show. One word, and the one action that is not obvious, in the heading. |
| `Placeholders (click one to copy):` | `Placeholders (click to copy)` | "Click one" counts what cannot be miscounted, and the trailing colon introduced a run that now sits under the heading instead of inline. |
| `A custom message would post nothing. Add some text, or pick a role to ping.` / `This message would post nothing. Add some text, or pick a role to ping.` | `A custom message needs some text besides placeholders that can be empty, such as {author}.` / `This message needs some text besides placeholders that can be empty.` | The role mention is added automatically now, so "pick a role to ping" no longer rescues an empty message. The rewrite names the actual cause and the one example a reader can act on. |
| `Adds a player's Discord tag in brackets after their name, for players whose Discord ID twilight-struggle.com sends with the result. Everyone else just gets their name. Tags never notify anyone - they are there so you can see who a result belongs to, and they survive a player leaving the server.` | `How players appear in posted results. Tag only keeps a player's real name out of the channel, but falls back to it for anyone whose Discord ID twilight-struggle.com doesn't send. Tags never notify anyone, and they survive a player leaving the server.` | The old text narrated one toggle's two states, so it had no room for a third mode, and "everyone else just gets their name" was a per-mode aside rather than the rule it actually is. |
| `...falls back to it for anyone whose Discord ID twilight-struggle.com doesn't send. Tags never notify anyone, and they survive a player leaving the server.` | `...falls back to it for anyone who isn't on this server or whose Discord ID twilight-struggle.com doesn't send. Tags never notify anyone.` | A tag for someone who isn't on the server renders as `@unknown-user`, so shrkbot now shows those players by name, and the help names the second fallback next to the first. "They survive a player leaving" promised a tag that, once the player is gone, reads as `@unknown-user` - a promise the code no longer tries to keep. |
| `Each result is posted this long after it was reported, so it can't spoil a stream that runs behind. Everyone sees results that much later. Changes to a result that is already posted appear immediately.` | `How long shrkbot waits after a result is reported before posting it, so it can't spoil a stream that's still running. Edits to a result that is already posted show up immediately. Changing the delay doesn't affect results that are already waiting.` | Its sibling opens "How players appear...", so the passive "is posted this long after" was the odd one out. "Runs behind" is broadcast jargon for what "still running" says plainly. The old text also never warned that results already waiting keep their delay. An admin who set a week by mistake and then lowered it would expect them to come out. |
| `OTSL 2026 is set to 30 minutes.` / `No tournament above sets a delay, ...` | `OTSL 2026 uses a 30-minute delay.` / `No parent tournament sets a delay, so results post immediately.` | "Is set to" and "above" describe how the settings are stored and resolved. "Uses" and "parent tournament" describe what the reader sees. The note also used to name the nearest subscribed tournament whether or not it set the value, so it pinned a default on a tournament that never chose it. The same fixes went into the player-names card. |
| `OTSL 2026 is set to Name and tag.` | `OTSL 2026 uses "Name and tag".` | Same swap as the delay note. Without the quotes, "uses Name and tag" reads as two things the tournament uses. The quotes mark the option label the reader picks in the control above. |
| `Polling hit a bug in shrkbot:` | `Polling hit an unexpected error:` | Deadlocks and statement timeouts land in this report too, and calling them a bug is wrong. |
| `Server Shield group is disabled` / `Open Server Shield overview` / `Enable the Server Shield group first - its master switch is off.` | `Server Shield is off` / `Go to Server Shield` / `Turn Server Shield on first.` | Every sub-plugin carried its own copy of the group-gate strings, with the parent named three ways ("group", "master switch", "Moderation"). One shared set now names the parent by its catalog name. |
| `Part of Moderation. Shared settings - staff role and alerts - live on the Moderation overview.` | `Part of Server Shield.` plus, on Server Shield sub-plugins, `Shared settings like the staff role and alerts live on the overview.` | "Moderation" was an old name for Server Shield. The shared-settings aside belongs to Server Shield only, so it is a separate sentence instead of living in the shared subline. |
| `Delete your account and all associated data? This cannot be undone.` | Title `Delete your account?`, body `shrkbot deletes your account and all data tied to it. This cannot be undone.` | The dialog has a title, so the question moved there and the body says what happens. "Associated" is filler for "tied to", and the body names the actor. |
| `Your account and all associated data have been deleted.` / `Permanently deletes your account and all data associated with it.` | `shrkbot deleted your account and all data tied to it.` / `Permanently deletes your account and all data tied to it.` | Same filler as the confirm body beside them. The flash names the actor. |
| `Revoke this plugin? The server loses the page and its commands, and the plugin is switched off.` | Title `Revoke this plugin?`, body `The server loses the page and its commands, and the plugin is switched off.` | Same split: the question is the title, the body states the consequence without repeating it. |
| `Posts new patch notes, announcements and press coverage of the Steam games you follow.` | `Posts new patch notes, announcements, and press coverage of the Steam games you follow.` | Three items, no serial comma. Only this string was fixed when the rule was written. |
| `Up to about 3,500 characters. Long patch notes fill the channel.` | `Up to about 3,500 characters.` | The second sentence was a warning the reader can see for themselves from the number. |
| `shrkbot deletes this server's settings for this game. Posts already in Discord stay.` / `Stop following and delete settings` | `This deletes your settings for this game.` / `Stop following` | The dialog title already names the game and the action, and the button repeats it. "Posts already in Discord stay" is what any reader assumes, and the button needs no clause explaining what the title promised. |
| `Stop following %{name}` card with `No more posts for this game. Posts already in Discord stay.` | Button only, labelled `Stop following %{name}`. | The card title, body, and button said the same thing three times. The button now carries the name, so nothing else is needed. |
| `Paste a Steam store link and pick a channel. shrkbot posts the game's news there from then on.` | Deleted. | The empty state sits beside an "Add a game" button and the page it opens explains the steps. The sentence restated both. |
| `Part of Feeds.` (subline under every sub-plugin title) | Deleted. | The breadcrumb above the title already names the parent. |
| `Feeds` / `Steam News` (plugin names) | `Integrations` / `Steam` | The group will hold more than feeds of posts and each provider is named for the platform, so `Steam` is the name now and `Steam News` would repeat itself under `Integrations`. |
| `Steam link or app ID` with the subtitle `Paste the game's Steam store page, its community hub, or its SteamDB page. An app ID works too.` | One label: `Paste a link to the game's Steam store page, community hub, or SteamDB page. An app ID works too.` | The label named the field and the subtitle explained it, one screen apart. The label now carries the instruction and the page heading stands alone. |
| `New {game} patch notes: {title}` (prefilled default in the custom-message box) | Empty box with the placeholder `Shown above the card. Leave it empty to post the card alone.` | The card now carries the game, the post type and the title, so the prefilled line repeated it. The placeholder says where the text lands and that leaving it empty is fine. |
| `Some developers don't tag their patch notes, so their updates arrive as announcements. To get every update, keep Patch notes and Announcements both on.` | `Some developers don't tag their patch notes, so shrkbot posts them as announcements. To get every update, keep both "Patch notes" and "Announcements" on.` | "Their updates arrive" hid who files them; shrkbot does. The toggle names in quotes read as the two switches below, not as kinds of post. |
| `Custom message` (disclosure summary) | `Message and notification` | The disclosure now holds both the custom message and the notification text, so the label names both. |
| `Works, but has not been tested widely yet. Report problems to @%{owner} on Discord.` | `You might experience some bugs. Please report them to @%{owner} on Discord or via %{email}.` | "Works, but has not been tested widely" hedged twice around a plain warning, and the report path had no email fallback. |
| `Notification text` + `What push notifications say. Leave it empty for the default.` | `Push notification text`, help line deleted, reset button beside the label. | The label now names the thing it controls. The help line restated the label, and the reset button does what "leave it empty" promised. |
| `Live` / `Highlights` / `Uploads` (Twitch post types) | `Going live` / `New highlight` / `New upload` | Plain nouns read as page sections. The new labels name the moment a post is made, so the one-line subtitles under them could go. |
| `Featured clips` / `All clips` with `When the streamer features a clip, within 48 hours of it being made.` / `Every clip viewers make.` | Labels kept, help lines deleted. | The labels carry the meaning. The 48-hour window moved to an info note inside the featured-clips settings, where it explains a behaviour rather than a toggle. |
| `The game or category. Empty for highlights and uploads.` / `Who made the clip. Empty for other posts.` / `The post's title.` (shared by Steam and Twitch) | `The game or category.` / `Who made the clip.` / `The title of the stream, video or clip.` | Placeholders now list only the tokens a post type can fill, so the "empty for" caveats described tokens the reader no longer sees. The Twitch title hint named a post, which a stream is not. |
| `Twitch user %{id}` (under the channel name) | No line. | The numeric id is never visible on Twitch, so it tells the reader nothing, and "Twitch channel" under a Twitch avatar would only restate the page. A caption earns its place only when it carries something, like Steam's app id. |
| `Message and notification` (disclosure summary on a Steam post type) | `Settings` | The disclosure also holds the type's channel now, so naming two of its fields no longer described it. Twitch already said `Settings`; both sources share one key. |
| `Record moderation events to a channel of your choice.` (dashboard, page header) / `Record moderation events to a private staff channel: role changes, joins, leaves.` (home) | `Records what's happening on your server.` | Logging also records role changes and Looking for Game denials, so "moderation events" covered a third of it, and the home card promised joins and leaves, which Logging does not record. Four copies made three claims; `PluginCatalog` now holds the one text every page reads. |
| `Your server's aegis: automated moderation beyond Discord's AutoMod.` / `Automated moderation beyond Discord's AutoMod: catch cross-channel spam and unwanted images.` (home) | `Automated moderation that goes further than Discord's AutoMod.` | Was kept on purpose for its personality. In a list of plugins the reader is scanning, and "aegis" sent some of them to a dictionary. The home variant listed the sub-plugins, which the Server Shield page shows anyway. |
| `Detects the same message blasted across multiple channels within seconds and purges it before it spreads. Matching is fingerprint-based - message content is never stored.` | `Detects messages spammed across multiple channels without storing message content.` | Two sentences of mechanism in a one-line slot. "Fingerprint-based" is how it works; the privacy promise is what the reader gets, so that part stays. "Purges" also broke delete-not-purge. |
| `Reads the text inside posted images and checks it against known scam patterns and previously confirmed scam images. Staff confirm or dismiss every catch, and the bot remembers.` | First sentence only. | The second sentence describes the review flow, which the page itself shows. |
| `Let members find people to play with, on the fly or scheduled. Only shrkbot pings - so you can turn off general-purpose role pings.` (page header) / `Let members rally a group with a role ping, instantly or scheduled. Others join with one click.` (home) | `Let members find people to play with, on the fly or scheduled.` | The dashboard wording, now everywhere. The ping advice is setup guidance and lives in the page's recommended-setup card. |
| `Posts news from the platforms you follow, like Steam, in the channels you pick.` | `Posts updates from other platforms to your server.` | "Like Steam" dated the line once Twitch shipped, and "in the channels you pick" is true of every plugin that posts. |
| `Members set their own reminders with /remind.` (dashboard) / `... This plugin can't be turned off.` (page header) / `Let members set personal reminders, delivered in the channel or by DM.` (home) | `Members set their own reminders with /remind. This plugin can't be disabled.` | Plugins are enabled and disabled; on and off are for options inside them. The dashboard row carries the second sentence too, since its locked toggle is what it explains. |
| `Let members give themselves roles from a menu you post in a channel.` (page header) / `Let members self-assign roles from a tidy menu you post in a channel.` (home) | `Let members give themselves roles from a menu.` | The dashboard wording, now everywhere. "Tidy" is self-praise the reader discounts. |
| `Greet new members with a custom message, and say goodbye when they leave.` (home) | `Greet new members and say goodbye when they leave.` | The dashboard wording, now everywhere. |
| `Tournaments pushed to shrkbot by twilight-struggle.com. Subscribe to the ones you want posted in this server.` (page header) / `Posts results from twilight-struggle.com as they are reported. Subscribe to a tournament, pick its channel, and write the message however you like.` (admin) | `Post results from twilight-struggle.com as they are reported.` | The dashboard wording, now everywhere. The header was instructions for the list below it, which the subscribe buttons and empty state already give. |
| `Posts new patch notes, announcements and press coverage of the Steam games you follow.` (Steam page header) | `Posts new patch notes, announcements, and press coverage of the Steam games you follow.` | The earlier serial-comma fix reached only the catalog copy. The page header now reads the catalog. |
| `Complete setup before enabling this plugin.` (dashboard toggle tooltip) | `Required settings missing` | An instruction with no object: the row cannot say which setup. The page marks the missing fields with the asterisk, so the tooltip names the state and stops. |
| `2,481 members · 20 channels and 18 roles synced` (dashboard header) | `2,481 members` | Sync counts describe shrkbot's copy of the server. Nobody configuring a plugin acts on them. |
| `%{count} plugins on` (server switcher) | `%{count} plugins enabled` | The server list said "enabled" for the same number. Plugins are enabled and disabled; options are on and off. |
| `Pick a server to configure shrkbot.` (server list subtitle) | Deleted. | A grid of servers under "Your servers" says it. |
| `Don't see a server?` / `You need Manage Server permissions and shrkbot must be present. Invite it, then refresh.` (dashed card with Invite and Preview buttons) | `Missing a server? You need the Manage Server permission there.` with only Preview features under it | A managed server without shrkbot already has its own invite card, so half the text and the second invite button repeated it. A fallback does not need a card that competes with the servers. |
| `Sign in to add shrkbot to your servers` (home hero button) | `Sign in with Discord` | The header button beside it said "Sign in with Discord". Two labels for one action make the reader look for a difference. |
| `shrkbot is designed to help you where Discord doesn't. It respects your members' privacy, and it gets out of your way when you don't need it. It is highly configurable and geared towards technical users that feel like Discord doesn't give them enough power.` | `shrkbot is designed for people like you that want more power than Discord gives them, while respecting your members' privacy.` | Four sentences about shrkbot in the abstract. The new line names the reader and keeps the two promises: more power, privacy kept. |
| `... but only for your server. Click here to find out more.` (link on "here") | `... exclusively for your server.` with the link on "bespoke plugins" | "Click here" names an action instead of the destination, so the link sits on the noun now. "But only" read as a limitation. |
| `More plugins are on the way.` | Deleted. | A promise with no date and nothing to act on. |
| `Where join and leave messages are posted.` / `Sent when a member joins. Leave empty to send nothing.` / `Sent when a member leaves. Leave empty to send nothing.` / `{user} is a Discord mention in join messages.` / `{user} is a plain @username in leave messages.` | Deleted. | The labels say the first three. No help says "leave empty" any more. The `{user}` notes repeated the placeholder's own tooltip. |
| `Off delivers silently - the mention badge still shows, but no sound or push.` | `When off, the mention makes no sound and sends no push notification.` | "Delivers silently" and "push" were shorthand for Discord's notification flag. The new line says what the member notices. |
| `Where moderation events are recorded.` / `Pick which events shrkbot writes to the log channel.` | Deleted. | Logging also records role changes and Looking for Game denials, so "moderation events" was wrong. The second line restated the "Logged events" heading and its toggles. |
| `3/3 enabled` (Logging event group) | `3 of 3 on` | Events are options inside a plugin, so they are on or off. The count stays because it shows state while the group is collapsed. |
| `Alerts post to #mod-log through the Logging plugin.` | `Alerts go to #mod-log. You can change this in Logging.` with "Logging" as a link | The line named the place to change the channel but did not lead there. |
| `Shared by every Moderation sub-plugin, and exempt from spam detection. Pick one before enabling any sub-plugin.` / `Required. Every sub-plugin stays off until a staff role is picked.` | `Exempt from all checks and optionally pinged for alerts.`, warning deleted | "Moderation" is Server Shield's old name and "sub-plugin" is the code's word. The asterisk marks the field required, so both instructions went and what the role does stayed. |
| `Mention the staff role at the top of every moderation log entry. Turn it off for a quieter log that staff can check on their own.` | Deleted. | The label "Ping staff on alerts" says it. This reverses the earlier fix to the same line: the better sentence was still one too many. |
| `This role can't see staff commands.` + `It doesn't have the Manage Messages permission, so its members won't see staff-only commands like Report as scam. Give the role Manage Messages, or grant it access under Server Settings -> Integrations -> shrkbot.` | `This role can't use "Report as scam".` + `Give it Manage Messages, or allow it under Server Settings -> Integrations -> shrkbot.` | "Staff commands like Report as scam" generalised from the one staff command there is. The title names it, and the body is only the fix. |
| `Sub-plugins` (Server Shield overview heading) | `Protections` | "Sub-plugin" is the code's word for a plugin inside a group. The heading now names what the list holds. |
| `Moderation needs the Logging plugin` / `Every Moderation sub-plugin needs ...` / `Moderation overview` | `Server Shield ...` in each | The old name for Server Shield. |
| `Trigger threshold` | `Act when the same message appears in` | The label now reads into its controls: "Act when the same message appears in 4 different channels within 15 seconds". "Threshold" made the reader translate. |
| `How similar two messages must be to count as the same message. 100% only catches exact copies; lower values also catch spam with small edits - swapped words, extra characters - but can mistake similar real messages for spam. Case, punctuation, digits and disguised characters are ignored either way.` | `100% matches exact copies only. Lower values also catch lightly edited copies, but can catch real messages that look alike.` | The first sentence restated the label, and the last restated the matching explainer on the overview. Two dash asides went with them. |
| `Also match symbol-only messages` + `Messages with no matchable text - only emoji, punctuation or digits - are ignored by default. When on, they all count as the same message, so blasting any symbol noise across channels triggers.` | `Also match messages with only punctuation or numbers` + `Messages like "???" or "123" all count as the same message.` | Emoji were wrong: the matcher keeps them, so emoji-only messages already match as text. Two examples replace "no matchable text". |
| `Purge the messages` / `Notify only` + `Notify only is a dry run - staff get the alert, nothing is deleted.` (Spam Guard) and `Flag only` + `Flag only leaves the image up and pings staff to review it.` (Scam Image Detection) | `Delete the messages` / `Only alert staff`, and `Only alert staff`, no help on either page | Delete, never purge. One option had two names on two pages; the new label says what both helps explained. |
| `Applies on top of the purge.` (timeout duration) | Deleted. | It answered a question nobody asks at a duration picker, and it said "purge". |
| `A ban is permanent until a mod lifts it, and shrkbot can't undo it. Pick this only if you're confident your thresholds never catch real members.` | Deleted. | False: "Undo punishment" on the alert lifts the ban. |
| `Before you turn this on` + `Deletion is on by default, and detection is automated and imperfect. Screenshots of scams - the kind well-meaning members post as warnings - can be detected and deleted too, so tell your community not to post scam screenshots. Staff are pinged on every action and can mark a decision as wrong with one click in Discord.` | `Detection can be wrong` + `Images are deleted automatically. Screenshots of scams that members post as warnings can be caught too. Staff are alerted to every action and can mark it as wrong.` | The box stays on the page after the plugin is on, so a title about turning it on went stale. The title now carries the fact. "Pinged on every action" was false once staff pings became optional. |
| `Anyone with the staff role can right-click any message with images -> Apps -> shrkbot -> Report as scam. Works whether or not automated scanning catches it.` | `Staff can report any message with images: right-click -> Apps -> shrkbot -> "Report as scam".` | "Any message" already covers messages the scan missed. The command name is quoted so it reads as the menu item. |
| `Words or phrases that mark an image as a scam when they show up in its text - on top of shrkbot's built-in scam rules. Close misspellings count too, ... digits kept.` | `Extra words or phrases that mark an image as a scam; close misspellings count. Longer phrases cause fewer false matches.` | Five sentences for a tag field. The matching rules live in the matching explainer; "extra" says they add to the built-in rules. |
| `If confirmed as a scam on this server` + `Sets the punishment for images a moderator has confirmed as scam on this server, ...` | `Punishment if confirmed by staff on this server`, no help | The label now says what it sets and who confirms. Its "Same as above" option explains the inheritance the help spelled out. |
| `Defaults` + `Server-wide Looking for Game settings. The per-role cards below add extra restrictions on top of these.` | `Rules for every role`, sentence deleted | "Defaults" left the reader asking "of what". The subtitle already lists what the card holds. |
| `Required roles` / `Excluded roles` / `Minimum membership` / `Cooldown`, each with a help ending `Leave empty ...` / `Leave blank ...` | `Who can post` (placeholder `Everyone`) / `Who can't post` (`No one`) / `Minimum membership time` (shows 0) / `Wait between posts` | Labels are now the question the reader answers. Where empty has two readings the placeholder names the one that applies, so the "leave empty" helps went. |
| `Channels where members can post an LFG. Leave empty to allow every channel.` + placeholder `Choose channels` | placeholder `Every channel`, help deleted | Same rule. "An LFG" was the command's name used as a noun. |
| `How long the "Looking for Game" post stays visible. For scheduled posts, the clock starts with the session, not while it gathers interest.` | `How long a post stays up. For scheduled posts, the timer starts with the session.` | The label names the post, and "not while it gathers interest" restated "starts with the session". |
| `The roles members can ping with /lfg, each with its own extra restrictions. Only configured roles appear in the command.` | `Members can ping these roles with /lfg.` | The cards below show the restrictions, and the second sentence restated the first. |
| `0 extra restrictions` (role card summary) | Nothing at zero. | A count of nothing is noise in a summary line. |
| `Additional required roles` / `Additional excluded roles` / `Minimum membership override`, helps `On top of the defaults above, ...` / `Restrict this role to these channels, overriding ...` / `Overrides the default minimum ...`, placeholders `Inherit allowed channels` / `Inherit default` | `Also requires` / `Also excludes` / `Minimum membership time override`, helps deleted, `Channel override` shows `Same as every role`, the number shows the inherited value | "Additional" and "on top of the defaults" said the same thing twice. An override names itself and shows what it falls back to, so "inherit" left the copy. |
| `Two optional but recommended Discord settings` (setup card subtitle) | Deleted. | The card title "Recommended setup" says it. This reverses the earlier rewrite of the same line. |
| `In Server Settings, turn off "Allow anyone to @mention this role" for every role you list below. shrkbot pings them for members, so you can switch off general-purpose role pings entirely.` | `Turn off "Allow anyone to @mention this role" for the roles you set up here, as shrkbot automatically pings them.` | One sentence with the reason attached. The second half was advice for the whole server, not for these roles. |
| `... That's your first line of control over who posts.` | Sentence deleted. | Puffery; the instruction before it is the point. |
| `Selection type` / `Single` / `Multi` (also the badge) | `Members can pick` / `One` / `Several` | The label reads into the choice. "Single" and "Multi" were the code's values. |
| `Resync menu` (tooltip) | `Repost` | The toast already said "Reposting the role menu…". One verb for one action. |
| Callout `Grayed-out roles can't be assigned. shrkbot can only assign roles below its own highest role, and never Discord-managed ones.` | Help line `shrkbot can't assign roles above its highest one, or roles managed by Discord.` | A yellow callout in every set for a fact about the picker. A help line under the picker is enough, and "grayed-out" described the picker's styling. |
| `Above shrkbot - it ranks below this role.` / `Managed by Discord - bots can't assign integration roles.` (option tooltips) | `This role is higher than shrkbot's highest role.` / `This role is managed by Discord.` | "It ranks below this role" made the reader resolve "it". Full sentences, one fact each. |
| `Use plugin default (%{channel})` / `no default set` (per-set channel) | `Same as above` | Overrides show what they fall back to. The channel picker above is in view. |
| `Each role set posts here unless it has its own channel override.` | Deleted. | Each set's "Channel override" says it. |
| `Reminders are triggered by members using /remind - there's nothing more to configure here.` | Deleted. | The page header names /remind, and the one setting below shows there is something to configure. |
| `Force reminder delivery via DM` + `Deliver every reminder in DMs, ignoring channel preferences set by members.` | `Always send reminders by DM`, no help | "Always" carries what the help explained. |
| `Leave empty to post every language. shrkbot can't tell the language of very short posts, so those always go through.` | `Posts whose language can't be detected, like very short ones, are posted anyway.` | The placeholder "Every language" covers empty. The rest is now one sentence about the exception. |
| `About 500 characters, then a link to the full post.` | `About 500 characters.` | Every Steam post links to the full post, whatever its length. |
| `Ended, with VOD` / `Ended` / `Keep live card` / `Delete` with a help under each, and `Show it switched` / `Delete it` with helps | `Summary with VOD link` / `Summary` / `Leave as is` / `Delete the post`, and `Show the switch` / `Delete the post`, no helps | The preview under each option shows the result. The labels now name it, so the helps restated them. |
| `Only post while the stream is in (optional)` / `Search Twitch categories` / `Leave it empty to post every category. Clips follow the same filter. Highlights and uploads have no category, so they always post.` | `Only post when streaming one of these categories` / `Every category` / `Only filters Live and Clips, as Highlights and Uploads don't have a category.` | The placeholder says what empty means. The help keeps the one fact the reader cannot guess. |
| Bare Discord ID on the account page | `Discord ID: %{id}` | An unlabelled 18-digit number. |
| `Permanently deletes your account and all data tied to it. Role assignments and server settings belong to their servers and are not affected. This cannot be undone.` | Deleted. | The dialog says it at the moment it matters. |
| Dialog body `shrkbot deletes your account and all data tied to it. This cannot be undone.` / button `Delete my account` | `This cannot be undone.` / `Delete account` | The title already asks "Delete your account?"; the body keeps only the consequence, and the button matches the card title. |
| `User was banned.` / `User was kicked.` / `User was timed out until %{until}.` (Discord alerts) | `The member was banned.` / `The member was kicked.` / `The member was timed out until %{until}.` | Member, not user. The scam alert beside it already said "The member was kicked". |
| `Notify-only - no messages were deleted.` / `Cross-channel spam purged` (Discord alerts) | `This is only an alert, no messages were deleted.` / `Cross-channel spam deleted` | The alert says what the setting did without quoting a label that may change. Delete, never purge. |
| `Example plugins` (home, above a moving strip of six plugins) | `Plugins` | The grid now shows every plugin a server can enable, so the list is no longer a sample and "Example" undersold it. |

## Kept on purpose

Copy that breaks a rule above and stays. Recorded so it does not get "fixed"
later.

| Copy | Rule it breaks | Why it stays |
| --- | --- | --- |
| `...for you it lives right alongside the functionality you know and love.` | Stock phrase. | The bespoke-plugins page is written in the developer's own voice, first person throughout. It is the one page where personality outranks the rules. |
| `♥` in the site footer | ASCII over glyphs. | One glyph, one place, load-bearing for the line it sits in. |

## Standing rule

Copy changes land in this file in the same chunk that makes them. A rewritten
string adds a row to "Weak to better"; a new rule that came out of the rewrite
adds itself to the right section. Reviewing copy and then losing the reasoning is
how the same correction gets made twice.
