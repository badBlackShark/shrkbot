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

## Kept on purpose

Copy that breaks a rule above and stays. Recorded so it does not get "fixed"
later.

| Copy | Rule it breaks | Why it stays |
| --- | --- | --- |
| `Your server's aegis: automated moderation beyond Discord's AutoMod.` | Colon reveal, and a word some readers will look up. | The personality is the point, and no plainer wording carried it. Deliberate. |
| `...for you it lives right alongside the functionality you know and love.` | Stock phrase. | The bespoke-plugins page is written in the developer's own voice, first person throughout. It is the one page where personality outranks the rules. |
| `♥` in the site footer | ASCII over glyphs. | One glyph, one place, load-bearing for the line it sits in. |

## Standing rule

Copy changes land in this file in the same chunk that makes them. A rewritten
string adds a row to "Weak to better"; a new rule that came out of the rewrite
adds itself to the right section. Reviewing copy and then losing the reasoning is
how the same correction gets made twice.
