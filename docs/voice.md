# Voice

How shrkbot's copy sounds. Read this before you write or change a user-facing
string: Discord messages and command descriptions, website copy, release notes,
and PR descriptions.

Every example is a string that ships today. Square brackets in an example mark
a control: `Require at least [2] matching keywords`.

## The four surfaces

Each surface has a different reader, so each has a different register. Copy
that fits one is usually wrong on another.

**Discord** - largely non-technical readers, mid-task, often on a phone. Say
the minimum that answers "what happened and what do I do now".

**Website** - readers who can set up a Discord bot but are not software
engineers. People judge the project by this surface, so the prose has to be
clean. Technical, but no word a competent server admin would have to look up.

**Release notes** - `CHANGELOG.md` and the GitHub release body built from it.
One short line per change, saying what a user notices: no mechanism, reasons,
timings or limits, because the linked PR carries those. The page is public, so no
internal class or constant names, and each bullet reads on its own without the
diff beside it. Releases up to 3.14.0 used a long, detailed register and are
left as a record. The release title takes the ` - `
joiner. Releases up to 3.8.1 used an em dash and are left as a record.

**PR descriptions** - written for software engineers, usually exactly one
reader. The most technical surface, and the one where an awkward sentence costs
least. Optimise for a reviewer who has to make a decision.

## Write less

The cheapest fix for a weak string is to delete it. Check that a sentence has a
job before you polish it: several rows in the ledger below record a sentence
that was improved first and deleted later.

**Say nothing the page already says.** A label, a heading, a control, a
placeholder, a preview, and a breadcrumb all speak. Text that repeats one of
them is deleted, not reworded.

```
Act when the same message appears in [4] different channels within [15] seconds
```

That row has no help text. The sentence it used to carry restated the two
steppers and hardcoded their defaults, so it would have lied as soon as a
server changed either one.

**Help text carries a fact the reader cannot guess.** If the help only explains
the label, fix the label and delete the help.

```
Only filters Live and Clips, as Highlights and Uploads don't have a category.
Messages like "???" or "123" all count as the same message.
```

**A title carries the fact.** Not a slogan, a category, or a teaser for the
body. The body then holds only the fix or the consequence.

```
Detection can be wrong
This role can't use "Report as scam".
Tournament result posting is currently disabled
```

**Say it once per screen.** A badge, a caption, or a count earns its place only
when it says something the row does not. A dashboard row has no "Enabled" badge
beside its toggle, a role card with no extra restrictions shows no count, and a
caveat that holds for eleven placeholders is one line above them:

```
All following placeholders are empty on a tie.
```

**No puffery, and no promise without a date.** "Tidy", "the smoothest
experience", and "more plugins are on the way" give the reader nothing to check
or act on.

## Vocabulary

One term for one thing, on every surface. A second word for the same thing
makes the reader look for a difference.

| Say | Never | Notes |
| --- | --- | --- |
| `enabled` / `disabled`, for a plugin | on, off, switched on | `Only a server admin can enable or disable this plugin.` |
| `on` / `off`, for an option inside a plugin | enabled, disabled | `of %{total} on` under a Logging event group |
| `Subscribed` / `Not subscribed`, for a tournament on the Twilight Struggle page | Enabled / Disabled | A tournament is followed, not switched on like a plugin. |
| `Server Shield` | Moderation | Its old name. One exception, under "Kept on purpose". |
| `Protections` | sub-plugins, group | The code's words for a plugin inside a group and for the group. Neither is ever shown. |
| `delete` | purge | `Delete the messages`, `Cross-channel spam deleted` |
| `Only alert staff` | Notify only, Flag only, dry run | One spelling on both protection pages. |
| `Looking for Game` in prose, `/lfg` for the command | LFG, an LFG | `Make your Looking for Game roles non-mentionable` |
| `member` | user | `The member was banned.` |
| `placeholder` | token | `Placeholders (click to copy)` |
| `restrictions` | gates | "Gate" is the code's name for the check, and stays in the code and in `docs/`. |
| `server` | server configuration | |
| `preview` | preview server | The fake server is only the vehicle: `Preview features`. |
| `parent tournament` | the tournament above | |
| `preview frame` | stream preview, screenshot, still | The image of the live stream on a live post. `Show a preview frame` |

The same holds for verbs. The Roles tooltip says `Repost` because the toast
already said `Reposting the role menu…`, both sign-in buttons on the home page
say `Sign in with Discord`, and every role picker prompts `Pick a role`.

## Rules for every surface

**State what happened, never that it succeeded.** No "Successfully", no "has
been". If nothing went wrong, the outcome is the message.

```
Timeout cleared for %{user}.
Now following %{name}.
```

**Add the consequence when the reader would otherwise have to ask.**

```
Confirmed as a scam by %{actor} - the bot will remember this image.
The member was kicked; a kick can't be undone.
Unsubscribed. New results in this tournament won't be posted.
```

**Every failure names a cause or a fix, and names everything that is missing at
once.**

```
I couldn't understand that duration. Try something like `1d2h30m`.
Could not post the role message - check the channel.
%{plugin} needs Logging enabled, and a staff role set on the Server Shield overview.
```

**Say what the reader notices, not how it works.** No error codes, class names,
"validation failed", "invalid input", or "an error occurred". The same goes for
mechanism that reads like English: a description promises what the reader gets,
and help text names the consequence of a setting.

```
Detects messages spammed across multiple channels without storing message content.
When off, the mention makes no sound and sends no push notification.
```

**Check every claim against the code.** Copy is a claim, and it goes stale
without a failing test. A warning said shrkbot cannot undo a ban while the
alert carried an `Undo punishment` button. A help text said emoji-only messages
are ignored while the matcher kept them. A claim about external data has to hold
for every variant, or name the majority it covers:

```
Most developers write their Steam posts in English, so leaving English out usually drops patch notes and announcements.
```

**Interpolate the real number or name.** Never "some", "several", "a while".

```
the account is only %{days} days old
matched %{count} custom keywords
```

**The verb must match what the reader gets.** A command that links to the
repository shows where the code lives, not the code. A post that comes back
when the stream does is not simply deleted.

```
Show shrkbot's tech stack, where its code lives, and how you can add it to your server.
Delete until it switches back
```

**Quote a label or a command when you name it.** The quotes mark it as the
thing the reader can find on the page.

```
To get every update, keep both "Patch notes" and "Announcements" on.
The message was left in place - Scam Image Detection is set to "Only alert staff".
```

**Second person for what the reader must do, and for the one thing you want
them to do.** Use it sparingly. If every clause is "you", none of them stand
out.

```
You need the staff role or the Manage Messages permission to do that.
```

**Never "we".** shrkbot is one developer. Name shrkbot when something acts, use
the passive when no actor matters, and use "I" only where the developer speaks
personally, as on the bespoke-plugins page.

```
shrkbot couldn't reach Discord to load your servers. Try again in a moment.
Your Discord sign-in couldn't be refreshed. Please sign in again.
Tell me your idea and I'll tell you if it fits.
```

**Advice reads as advice.** When the reader has a choice, recommend. Do not
phrase it as a rule the product does not enforce.

```
Keeping it spoiler-free is highly recommended.
```

**Apologise only for harm the bot actually caused.** Routine failure is not
harm. There is exactly one apology in the codebase, and it is for a member the
bot punished by mistake:

```
Sorry - you were automatically moderated in %{server} by mistake, and a staff member has reversed it.
```

**The joiner is ` - `.** Never an em dash, anywhere, on any surface.

**ASCII over glyphs.** `->` for a UI path or a transformation, `:)` over an
emoji. The ellipsis `…` is allowed: it marks a prompt or work in progress.

```
In Server Settings -> Integrations -> shrkbot, limit the /lfg command to the channels and roles that should use it.
Reposting the role menu…
```

**Serial comma.** Lists of three or more take it: `patch notes, announcements,
and press coverage`. Strings older than the rule are fixed when they are next
touched.

## Rules for Discord

**One sentence.** A second sentence earns its place only as a constraint, an
example, or a consequence.

```
Cancel one of your reminders.
Set a reminder to be sent to you after a delay (e.g. 1d2h30m).
```

**Command descriptions lead with an imperative verb.** Constraints are appended
as a fragment.

```
List your active reminders.
Broadcast a message to the owner of every server shrkbot is in. Bot owner only.
```

**"I" only when the bot itself failed.** Everywhere else the bot is "shrkbot"
or the sentence is passive. The bot never narrates its own successes in first
person.

```
I couldn't reverse that - I may be missing permissions.
```

**Fragments that compose into a larger sentence stay lowercase and take no
terminal period.** Check how the string is interpolated before you punctuate
it.

```
on cooldown (%{time} left)
that role isn't set up for Looking for Game
```

**An alert says what happened to the message,** not the name of the mode that
caused it.

```
This is only an alert, no messages were deleted.
```

## Rules for the website

Everything above applies. The component behind each rule is described in
[design/design-system.md](design/design-system.md); this section covers the
words.

### Labels and options

**A label reads into its control.** Where the value completes a sentence, write
the sentence.

```
Treat accounts as new for [30] days
Require at least [2] matching keywords
Members can pick [One | Several]
```

**A label is the question the reader answers, not the name of the column.**
`Who can post`, `Who can't post`, and `Wait between posts` replaced "Required
roles", "Excluded roles", and "Cooldown".

**An option names its outcome.** If each option needs a help line to say what
it does, the labels are wrong.

```
Delete the messages / Only alert staff
Summary with VOD link / Summary / Leave as is / Delete the post
```

**The recommendation sits on the option it recommends:** `Standard
(recommended)`. A stepper with a default shows a reset segment while the value
differs (`Reset to %{value}`), so no line prints the default.

**Values read the way people say them.** A duration is a number and a unit, and
opens on the largest unit that fits: 5 minutes, not 300 seconds.

**A picker prompt says "Pick" and ends without "…".** `Pick a channel`,
`Pick roles`. An ellipsis marks something in progress (`Checking recent
posts…`); a prompt is waiting for the reader.

**One description per plugin.** `PluginCatalog` holds it, and the dashboard,
the page header, and the home page read it. It is one line that says what the
plugin does for the reader.

### Help text

**Help goes below the control**, never between the label and the control.

**Describe only the selected option.** Help that covers some options of a
control shows only while one of them is picked.

```
Missing tags fall back to player names. Tags don't ping.
```

**Help that decides whether to turn an option on shows while it is off.**

```
Big channels get dozens to hundreds of clips per stream, and each one is a post.
```

**Name the trade-off, do not grade it.**

```
Stricter catches more scams and more innocent images.
100% matches exact copies only. Lower values also catch lightly edited copies, but can catch real messages that look alike.
```

**Say what a setting does, not how it is stored.** A tournament "uses" a delay,
it is not "set to" one. When the value is an option label, quote it.

```
%{parent} uses a %{count}-minute delay.
%{parent} uses "%{setting}".
No parent tournament sets a delay, so results post immediately.
```

**Sibling help texts share a shape.** If the hints around yours all open "The
USA player's...", yours does too.

### Empty, required, and inherited

**No "Leave empty to...", in help or in a placeholder.** A placeholder says
what empty means, and only where empty has more than one plausible meaning:

```
Everyone
No one
Every channel
Every language
```

**A required field carries the red asterisk and nothing else.** Labels never
say "(required)" or "(optional)", and the asterisk has no tooltip.

**An override is named an override and shows what it falls back to.**

```
Channel override    ->  Same as above
Role override       ->  Same as above
Channel override    ->  Same as every role
```

A number override shows the inherited number, and an inherited tournament
setting names its source: `%{parent} posts in %{channel}.`

**A default message is real text in the box,** editable, with `Reset to
default` beside the label. An empty box sends nothing and says so with one
phrase, in the box and in the preview:

```
Nothing will be sent.
```

### Warnings and prerequisites

**A standing limitation goes before the choice. A live warning goes below the
control it watches.** A limitation that holds whatever the reader picks sits
above the controls and is always visible, like the `Detection can be wrong` box
or the Steam note about untagged patch notes. A warning that depends on a
field's value appears the moment the value makes it true, directly below that
field, so the field does not move under the cursor.

**A title is true in every state it shows in.** A box that stays on the page
after the plugin is enabled cannot be titled "Before you turn this on".

```
Before you enable %{plugin}
Required settings missing
```

**Show every missing step at once, each with a link to where it is fixed.**

```
Set up a log channel so shrkbot has a place to post alerts.    [Open Logging]
Pick a staff role on the Server Shield overview.               [Open Server Shield]
```

### Structure

**No heading that names the layout.** "Where to post" and "What to post" named
two groups of cards, not a setting.

**Nothing goes behind "Advanced" or "Settings".** Disclose only when a page has
three or more rare tuning controls, name the disclosure by its content, and
never hide a setting that currently changes behaviour.

**Link the noun, never "click here".** The link sits on the name of the place
it leads to.

```
Alerts go to #mod-log. You can change this in Logging.
shrkbot also supports bespoke plugins that do exactly what you need, exclusively for your server.
```

**A dialog's title asks the question, its body states the consequence, and its
button repeats the verb.**

```
Delete your account?
This cannot be undone.
[Delete account]
```

**A toast that is not plain good news does not look like one.** `Saved.
%{plugin} is still disabled.` is a warning toast that stays until dismissed,
because the change does nothing yet.

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

Strings that were rewritten, and the fault each one had. The pairs teach more
than the rules do, and they are the record of what was already decided: check a
string here before you "fix" it.

Each "Better" cell is the string that ships today. A row is grouped under the
rule it broke. The ledger was rebuilt after the 2026-11 copy overhaul, which
reviewed every page; `git show 3.14.0:docs/voice.md` has the rows from before.

### Said by something else on the page

| Weak | Better | Fault |
| --- | --- | --- |
| `Trigger threshold` + `Triggers when the same message appears in 4 different channels within 15 seconds.` | `Act when the same message appears in`, no help | The two steppers are the real controls. The sentence restated them and hardcoded their defaults. The label now reads into them. |
| `Two optional Discord settings we recommend` + `Neither is required, but we recommend both for the smoothest Looking for Game experience:` | Deleted. | The card title `Recommended setup` says it. An earlier pass only fixed the "we" and the puffery. |
| `Mention the staff role at the top of every moderation log entry. Turn it off for a quieter log staff check on their own.` | Deleted. | The label `Ping staff on alerts` says it. An earlier pass repaired the grammar of a sentence that had no job. |
| `Where join and leave messages are posted.` / `Sent when a member joins. Leave empty to send nothing.` / `Pick which events shrkbot writes to the log channel.` / `Pick a server to configure shrkbot.` / `Each role set posts here unless it has its own channel override.` / `Where this server posts this tournament's results and how they read. ...` / `Paste a Steam store link and pick a channel. shrkbot posts the game's news there from then on.` | Deleted. | Each restated the label, the heading, or the cards beside it. |
| Card `Stop following %{name}` + `No more posts for this game. Posts already in Discord stay.` + button `Stop following and delete settings` | Button `Stop following %{name}`, dialog body `This deletes your settings for this game.` | Title, body, and button said one thing three times. "Posts already in Discord stay" is what any reader assumes. |
| `Members set their own reminders with /remind. This plugin can't be disabled.` | `Members set their own reminders with /remind.` | Said three times on one dashboard row: the sentence, the `Always on` badge, and the locked toggle. |
| `Enabled` / `Disabled` badges on dashboard rows | Deleted. `Needs setup` stays. | The toggle and the tile already show the state. |
| `Twitch user %{id}` under the channel name | No line. | The numeric id is never visible on Twitch. `Steam app %{id}` stays, because an app id is something a reader looks up. |
| `Part of Feeds.` under every plugin title | Deleted. | The breadcrumb above the title names the parent. |
| `0 extra restrictions` | Nothing at zero. | A count of nothing is noise in a summary line. |
| `2,481 members · 20 channels and 18 roles synced` | `2,481 members` | Sync counts describe shrkbot's copy of the server. Nobody who configures a plugin acts on them. |
| `... Empty on a tie.` on eleven placeholder hints | `All following placeholders are empty on a tie.`, once | One caveat said eleven times. |
| `Recommended default: %{value}` under every stepper | Deleted. Reset segment with the tooltip `Reset to %{value}`. | The line made the reader compare two numbers by eye, and printed even when the value was the default. |
| `About 500 characters, then a link to the full post.` | `About 500 characters.` | Every Steam post links to the full post. A detail that is true of both options describes neither. |
| Cookie notice: `shrkbot only sets technical cookies to make the site work. ... It will remember that you've seen this, though - with a cookie, of course. :)` | Deleted. | Technical cookies need no consent. The banner set the site's only non-essential cookie to remember that it was dismissed. |

### Titles

| Weak | Better | Fault |
| --- | --- | --- |
| Eyebrow `Bespoke plugins` + headline `shrkbot can do it all, even if it's only for you` | Title `Bespoke Plugins` | The eyebrow named the page and the headline was a slogan. |
| `Before you turn this on` + `Deletion is on by default, and detection is automated and imperfect. ... Staff are pinged on every action and can mark a decision as wrong with one click in Discord.` | `Detection can be wrong` + `Images are deleted automatically. Screenshots of scams that members post as warnings can be caught too. Staff are alerted to every action and can mark it as incorrect.` | The box stays after the plugin is enabled, so its title went stale. "Pinged on every action" became false when staff pings became optional. "Wrong" also reads as a moral judgement. |
| `This role can't see staff commands.` + `It doesn't have the Manage Messages permission, so its members won't see staff-only commands like Report as scam. ...` | `This role can't use "Report as scam".` + `Give it Manage Messages, or allow it under Server Settings -> Integrations -> shrkbot.` | "Staff commands like" generalised from the one staff command there is. The title names it, and the body is only the fix. |
| `The plugin is disabled` + `Twilight Struggle is switched off for this server, so nothing is posted anywhere yet.` | `Tournament result posting is currently disabled` | The title now says what stopped. The body repeated it with a second word for the same state. |
| `Before you enable %{plugin}`, also on an enabled protection | `Required settings missing` while it is enabled | "Before you enable" is false for a plugin that is already on. |
| `Delete your account and all associated data? This cannot be undone.` as the whole dialog | Title `Delete your account?`, body `This cannot be undone.`, button `Delete account` | The dialog has a title, so the question moved there. The body keeps only the consequence. |
| Heading `Twilight Struggle` with the tournament in a badge | The tournament's name as the heading, `Switch tournament` on the menu | The heading named the plugin, which the sidebar already names. |
| Page title, admin page title and admin menu entry `Bespoke plugins` | `Bespoke Plugins` | The top-bar link to the page says `Bespoke Plugins`. One name gets one spelling, everywhere it is a name. |

### Labels and options

| Weak | Better | Fault |
| --- | --- | --- |
| `Required roles` / `Excluded roles` / `Minimum membership` / `Cooldown`, each with a help ending `Leave empty ...` | `Who can post` (`Everyone`) / `Who can't post` (`No one`) / `Minimum membership time` / `Wait between posts` | A label is the question the reader answers. Where empty has two readings, the placeholder names the one that applies. |
| `Defaults` + `Server-wide Looking for Game settings. The per-role cards below add extra restrictions on top of these.` | `Rules for every role` | "Defaults" left the reader asking "of what". The subtitle already lists what the card holds. |
| `Pingable roles` + `The roles members can ping with /lfg, each with its own extra restrictions. Only configured roles appear in the command.` | `Roles members can ping with /lfg` | The heading was a coined word, and the sentence under it explained the word. |
| `Selection type` / `Single` / `Multi` | `Members can pick` / `One` / `Several`, badge `Pick one` / `Pick several` | "Single" and "Multi" were the code's values. The badge has no label beside it, so it carries the verb. |
| `New account age` + `How recently a Discord account must have been created to count as new. ... Anywhere from 1 to 365 days.` | `Treat accounts as new for` [30] `days` + `New accounts are judged more strictly.` | The label named a number the reader had to turn into a rule. The stepper enforces the range. |
| `Relaxed` / `Standard` / `Strict`, each with a description | `Relaxed` / `Standard (recommended)` / `Strict` + `Stricter catches more scams and more innocent images.` | Three descriptions told one trade-off from three ends. |
| `Require at least [2] matching keywords before shrkbot acts` + `1 is aggressive - a single matched word can delete an image. ...` | `Require at least` [2] `matching keywords` | Every threshold means "before shrkbot acts". The help did arithmetic the reader can do. |
| `Ended, with VOD` / `Ended` / `Keep live card` / `Delete`, each with a help | `Summary with VOD link` / `Summary` / `Leave as is` / `Delete the post` | The preview under each option shows the result. The labels now name it. |
| `Live` / `Highlights` / `Uploads` | `Going live` / `New highlight` / `New upload` | Plain nouns read as page sections. The new labels name the moment a post is made. |
| `Enabled` / `Disabled` beside the tournament toggle | `Subscribed` / `Not subscribed` | The toggle sets whether this server follows the tournament. The plugin switch keeps `Enabled`. |
| `Decided game` + `Used when one player won.` | `A player won` | The label now says when the template is used. |
| `Game with a video` + `... Keep it spoiler-free - no winner, turn or method.` | `Result with a video` + `If a result comes with a video, this template is used over the other two. Keeping it spoiler-free is highly recommended.` | It is a result, not a game. The spoiler advice is advice, not a rule the form enforces. |
| `Steam link or app ID` + subtitle `Paste the game's Steam store page, its community hub, or its SteamDB page. An app ID works too.` | One label: `Paste a link to the game's Steam store page, community hub, or SteamDB page. An app ID works too.` | The label named the field and the subtitle explained it. |
| `Notification text` + `What push notifications say. Leave it empty for the default.` | `Push notification text`, with `Reset to default` beside it | The label names what it controls, and the reset does what "leave it empty" promised. |
| `If confirmed as a scam on this server` + two sentences of help | `Punishment if confirmed by staff on this server` | The label says what it sets and who confirms. Its `Same as above` option carries the inheritance. |
| `Force reminder delivery via DM` + `Deliver every reminder in DMs, ignoring channel preferences set by members.` | `Always send reminders by DM` | "Always" carries what the help explained. |
| `Global` badge on Reminders | `Always on` | "Global" reads as a scope, and the admin page uses it that way. |
| `Example plugins` | `Plugins` | The grid shows every public plugin, so it is not a sample. |
| `Feeds` / `Steam News` | `Integrations` / `Steam` | The group holds more than feeds, and a provider is named for its platform. |
| Bare number on the account page | `Discord ID: %{id}` | An unlabelled 18-digit number. |
| `Choose a role` on the Looking for Game role cards | `Pick a role` | The staff role picker already said `Pick a role…`. Two verbs for one prompt. |
| `Choose a channel` / `Choose roles` / `Choose a server` / `Choose a new channel below` / `%{plugin_name} was affected - choose a new channel` | `Pick a channel` / `Pick roles` / `Pick a server` / `Pick a new channel below` / `%{plugin_name} was affected - pick a new channel` | The same rule, for the remaining pickers and the channel-deleted notification. |
| `Choose roles members can pick` | `Pick roles` | With "Pick", the prompt said "pick" twice. The label `Assignable roles` already says which roles. |

### Help text

| Weak | Better | Fault |
| --- | --- | --- |
| `The duration the "Looking for Game" post remains visible after it starts. For scheduled posts, this time only starts with the actual session, not during the "gathering interest" period.` | `How long a post stays up. For scheduled posts, the timer starts with the session.` | The label names the post. "Not during the gathering interest period" restated "starts with the session". |
| `How similar two messages must be to count as the same message. 100% only catches exact copies; lower values also catch spam with small edits - swapped words, extra characters - but can mistake similar real messages for spam. ...` | `100% matches exact copies only. Lower values also catch lightly edited copies, but can catch real messages that look alike.` | The first sentence restated the label, and the last one restated the matching explainer. |
| `Words or phrases that mark an image as a scam when they show up in its text - on top of shrkbot's built-in scam rules. ...` (five sentences) | `Extra words or phrases that mark an image as a scam; close misspellings count. Longer phrases cause fewer false matches.` | Five sentences for a tag field. "Extra" says they add to the built-in rules. |
| `Shared by every Moderation sub-plugin, and exempt from spam detection. Pick one before enabling any sub-plugin.` | `Exempt from all checks and optionally pinged for alerts.` | The asterisk marks the field required, so the instruction went and what the role does stayed. |
| `Off delivers silently - the mention badge still shows, but no sound or push.` | `When off, the mention makes no sound and sends no push notification.` | "Delivers silently" and "push" were shorthand for Discord's notification flag. |
| `How players appear in posted results. Tag only keeps a player's real name out of the channel, ...` | `Missing tags fall back to player names. Tags don't ping.`, only while a tag option is picked | It explained three options at once. Only the tag options need a word. |
| `How long shrkbot waits after a result is reported before posting it, so it can't spoil a stream ...` (four sentences) | `Wait this long after a result is reported before posting, to avoid spoiling live streams.` | The edge cases behave as a reader expects without being told. |
| `OTSL 2026 is set to 30 minutes.` / `No tournament above sets a delay, ...` | `%{parent} uses a %{count}-minute delay.` / `No parent tournament sets a delay, so results post immediately.` | "Is set to" and "above" describe how the settings are stored. |
| `Hides it from this server's list. It is not an off switch - a result that still arrives is still posted here.` | `Hides this tournament from the list. Results will still be posted; unsubscribe to stop.` | It said what archive is not, without naming what is. |
| `Leave empty to post every language. shrkbot can't tell the language of very short posts, so those always go through.` | `Posts whose language can't be detected, like very short ones, are posted anyway.` | The placeholder `Every language` covers empty. The rest is one sentence about the exception. |
| `Leave it empty to post every category. Clips follow the same filter. Highlights and uploads have no category, so they always post.` | `Only filters Live and Clips, as Highlights and Uploads don't have a category.` | The placeholder `Every category` says what empty means. The help keeps the one fact the reader cannot guess. |
| Callout `Grayed-out roles can't be assigned. shrkbot can only assign roles below its own highest role, and never Discord-managed ones.` | Help line `shrkbot can't assign roles above its highest one, or roles managed by Discord.` | A yellow callout in every role set for a fact about the picker. "Grayed-out" described the styling. |
| `Above shrkbot - it ranks below this role.` / `Managed by Discord - bots can't assign integration roles.` | `This role is higher than shrkbot's highest role.` / `This role is managed by Discord.` | "It ranks below this role" made the reader resolve "it". |
| `In Server Settings, turn off "Allow anyone to @mention this role" for every role you list below. shrkbot pings them for members, so you can switch off general-purpose role pings entirely.` | `Turn off "Allow anyone to @mention this role" for the roles you set up here, as shrkbot automatically pings them.` | The second half was advice for the whole server, not for these roles. |
| `Some developers don't tag their patch notes, so their updates arrive as announcements. To get every update, keep Patch notes and Announcements both on.` | `Some developers don't tag their patch notes, so shrkbot posts them as announcements. To get every update, keep both "Patch notes" and "Announcements" on.` | "Their updates arrive" hid who files them. The quotes mark the two toggles. |
| The clip-volume warning and the 48-hour note, inside the settings of a clip type | `Big channels get dozens to hundreds of clips per stream, and each one is a post.` / `Only clips featured within 48 hours of being made get posted.`, as each card's help | Both help decide whether to turn the type on, so hiding them until it was on defeated them. |
| `Works, but has not been tested widely yet. Report problems to @%{owner} on Discord.` | `You might experience some bugs. Please report them to @%{owner} on Discord or via %{email}.` | It hedged twice around a plain warning. |
| `Where the post comes from, such as Community Announcements or a news site.` | `Where the post comes from, e.g. Community Announcements or a news site.` | A token hint is read in passing. `e.g.` is the short form of the same thing. |

### Empty, required, and inherited

| Weak | Better | Fault |
| --- | --- | --- |
| `Channels where members can post an LFG. Leave empty to allow every channel.` + placeholder `Choose channels` | Placeholder `Every channel`, no help | The placeholder says what empty means. "An LFG" used the command's name as a noun. |
| `Channel (optional)` with the placeholder `Same as "Where to post"` | `Channel override` with `Same as above` | An override says it is one. |
| `Role to ping (optional)` / `No ping` on every Twitch post type | `Role to ping` in the top card, `Role override` / `Same as above` on each type | Five types meant five picks of the same role. |
| `Additional required roles` / `Additional excluded roles` / `Minimum membership override`, placeholders `Inherit allowed channels` / `Inherit default` | `Also requires` / `Also excludes` / `Minimum membership time override`, and `Channel override` shows `Same as every role` | "Additional" and "on top of the defaults" said one thing twice. An override shows what it falls back to. |
| `Use plugin default (%{channel})` / `no default set` | `Same as above` | The channel picker above is in view. |
| `Channel (required)` / `Message (optional)` / `Role to ping (optional)` | `Channel` with the asterisk / `Message` / `Role to ping` | Every other page marked a required field with the asterisk. A field without one is optional. |
| `This setting is required to enable the plugin.` on the asterisk | Deleted. | The asterisk is the convention on its own. |
| Prefilled `New {game} patch notes: {title}`, then the placeholder `Shown above the card. Leave it empty to post the card alone.` | Empty box, placeholder `Shown above the card.` | The card carries the game, the type, and the title. A box that posts the card alone when empty surprises nobody. |
| `Welcome {user}, you're member {membercount}!` as the placeholder of an empty box | The same text as the box's editable default, and `Nothing will be sent.` in an empty box | The placeholder looked like a message shrkbot would send, but an empty box sent nothing. |
| `This message is off.` / `Nothing would be posted.` / the inherited template as a placeholder | `Nothing will be sent.` | Three ways to show an empty message. One phrase serves every box and preview. |
| `%{parent} uses a %{count}-minute delay. Leave the field empty to use the same here.` / `... Leave empty to use %{channel}, inherited from the tournament above.` | `%{parent} uses a %{count}-minute delay.` / `%{parent} posts in %{channel}.` | The box already shows the inherited value. |
| `No results found` under the custom keywords box | Placeholder `Type a word or phrase, then press Enter` | The box adds keywords. It does not search a list. |
| `300 seconds, which is 5 minutes` / `Reset to 300` | A unit select in the stepper (`seconds` / `minutes` / `hours`), reset `Reset to 5 minutes` | The reader had to convert. A bare number is ambiguous once the unit can change. |

### Claims

| Weak | Better | Fault |
| --- | --- | --- |
| `A ban is permanent until a mod lifts it, and shrkbot can't undo it. Pick this only if you're confident your thresholds never catch real members.` | Deleted. | False: `Undo punishment` on the alert lifts the ban. |
| `Also match symbol-only messages` + `Messages with no matchable text - only emoji, punctuation or digits - are ignored by default. ...` | `Also match messages with only punctuation or numbers` + `Messages like "???" or "123" all count as the same message.` | The matcher keeps emoji, so emoji-only messages already matched as text. |
| `Record moderation events to a channel of your choice.` / `Record moderation events to a private staff channel: role changes, joins, leaves.` | `Records what's happening on your server.` | Logging also records role changes and Looking for Game denials, and it never recorded joins or leaves. Four copies made three claims. |
| `Steam sends developer posts in English, so leaving English out also drops patch notes and announcements.` | `Most developers write their Steam posts in English, so leaving English out usually drops patch notes and announcements.` | Checked against Western games only. Chinese studios write Chinese into the English slot: 11 of 20 posts for one game. |
| `Caches, background-job records and logs are cleared automatically (at most 60 days, 30 days and briefly, respectively).` | `... (at most 60 days, 30 days and 7 days, respectively).` | "Briefly" sat beside two real numbers, and nothing enforced it. The policy binds the implementation. |
| `... and it looks like its role is at the very bottom. Please move shrkbot's role up if you want it to be able to assign roles.` | `... and its role sits at the very bottom. Move it up in Server Settings so shrkbot can assign roles.` | The check is a definite position check, so "it looks like" hedged on a known fact. |
| `Polling hit a bug in shrkbot:` | `Polling hit an unexpected error:` | Deadlocks and statement timeouts land in this report too. |
| `Posts news from the platforms you follow, like Steam, in the channels you pick.` | `Posts updates from other platforms to your server.` | "Like Steam" dated the line once Twitch shipped. |
| `Delete the post` when the stream switches category | `Delete until it switches back` | The post comes back when the category does. |

### Failures and prerequisites

| Weak | Better | Fault |
| --- | --- | --- |
| `requires the Logging plugin enabled with a log channel set` / `requires a staff role set on the Server Shield overview` | `%{plugin} needs Logging enabled, and a staff role set on the Server Shield overview.` | Fragments with no subject, shown alone in a callout. One refusal now names everything the protection needs. |
| `A staff role is required while a sub-plugin is enabled.` / `can't be turned off or lose its channel while Server Shield is enabled` | `%{dependents} needs a staff role. Disable %{dependents} first.` / `%{dependents} needs Logging enabled, with a log channel. Disable %{dependents} first.` | Neither named the plugin that blocked the change, so the reader could not find the way out. |
| `%{plugin} can't be enabled until its required settings are configured.`, shown for a missing channel | `%{plugin} needs a channel.` | A missing channel got the generic message. |
| `Moderation needs the Logging plugin` + `... Enable Logging and pick a log channel, then come back.`, one requirement per page | `Set up a log channel so shrkbot has a place to post alerts.` / `Enable Logging so shrkbot has a place to post alerts.` / `Pick a staff role on the Server Shield overview.`, all at once | One requirement per page sent the reader through three pages in a fixed order. The first step has two variants because a reader who had picked a channel was told to set one up. |
| `Complete setup before enabling this plugin.` | `Required settings missing` | An instruction with no object: the row cannot say which setup. The page marks the missing fields. |
| `Could not delete the server configuration - it's a preview configuration.` | `Could not delete this server - it is a preview, not a real Discord guild.` | The cause repeated the noun instead of explaining it. |
| Card `Don't see a server?` + `You need Manage Server permissions and shrkbot must be present. Invite it, then refresh.` | `Missing a server? You need the Manage Server permission there.` | A server without shrkbot already has its own invite card. A fallback does not need a card that competes with the servers. |
| `Welcomes settings saved.` after saving a disabled plugin | `Saved. %{plugin} is still disabled.`, as a warning toast that stays | A green tick that disappears reads as "done". |
| `You need Manage Server permissions` | `You need the Manage Server permission` | Discord has one permission with that name. |

### We, filler, and puffery

| Weak | Better | Fault |
| --- | --- | --- |
| `We couldn't reach Discord to load your servers.` | `shrkbot couldn't reach Discord to load your servers.` | "We" is one developer. Six strings took one of three fixes: name shrkbot, use the passive, or delete the clause. |
| `Show information about shrkbot - its code, stack, and how to add it to your server.` | `Show shrkbot's tech stack, where its code lives, and how you can add it to your server.` | "Show information about" is filler, and the command links to the repository instead of showing code. |
| `Find out what it costs to run shrkbot and how you can support the project.` | `Show what it costs to run shrkbot and how to support it.` | "Find out" says what "Show" says in less. Donating is a soft sell, so it loses the second person. |
| `shrkbot is designed to help you where Discord doesn't. It respects your members' privacy, and it gets out of your way when you don't need it. It is highly configurable and geared towards technical users ...` | `shrkbot is designed for people like you who want more power than Discord gives them, while respecting your members' privacy.` | Four sentences about shrkbot in the abstract. The new line names the reader and keeps the two promises. |
| `... but only for your server. Click here to find out more.` | `... exclusively for your server.`, with the link on `bespoke plugins` | "Click here" names an action instead of the destination. "But only" read as a limitation. |
| `More plugins are on the way.` | Deleted. | A promise with no date and nothing to act on. |
| `Your server's aegis: automated moderation beyond Discord's AutoMod.` | `Automated moderation that goes further than Discord's AutoMod.` | Was kept on purpose for its personality. In a list the reader is scanning, "aegis" sent some of them to a dictionary. |
| `Detects the same message blasted across multiple channels within seconds and purges it before it spreads. Matching is fingerprint-based - message content is never stored.` | `Detects messages spammed across multiple channels without storing message content.` | Two sentences of mechanism in a one-line slot. The privacy promise is what the reader gets, so it stayed. |
| `Let members self-assign roles from a tidy menu you post in a channel.` | `Let members give themselves roles from a menu.` | "Tidy" is self-praise the reader discounts. |
| `If you're enjoying the general usefulness of shrkbot but have an idea that needs custom work - or you plain don't want another bot in your ecosystem - I can build a bespoke plugin just for you. ... it lives right alongside the functionality you know and love.` | `Need something shrkbot doesn't do, or don't want another bot on your server? I can build it as a plugin that only your server gets. It sits in your dashboard next to the regular plugins, and no other server sees it.` | Was kept on purpose as the developer's own voice. The same offer without the stock phrases says where the plugin shows up instead of how it feels. |
| `How it works` with three numbered cards (`Talk to me!` / `I build it` / `I ship and maintain it`) | `Tell me your idea and I'll tell you if it fits. If it does, I build it, switch it on for your server, and keep it running.` | Three cards held three steps of one sentence. |
| `I offer shrkbot for free and for everyone, but I might charge a little fee for custom work that's only for you. ... and I'll do my best to keep prices affordable.` | `Small things, and anything every server would get, are usually free. For bigger custom work I charge a small fee. Running it afterwards is free, unless it needs a paid API.` | Leads with what is free and states the fee once. "I'll do my best" promised nothing. |
| `Preview a server` / `You're looking at a preview server - nothing you change here is saved.` | `Preview features` / `You're looking at a preview - nothing you change here is saved.` | Nothing about the preview is server-specific. "A server" offered the reader something they already have. |
| `Tokens` + `Anything in braces is replaced when the message is built. A token shrkbot doesn't know is left exactly as you typed it. Click a token to copy it.` | `Placeholders (click to copy)` | Two words for one thing, and a paragraph that restated what the chips and the preview show. The one action that is not obvious moved into the heading. |
| `Your account and all associated data have been deleted.` | `shrkbot deleted your account and all data tied to it.` | "Associated" is filler for "tied to", and the flash names the actor. |

### Discord

| Weak | Better | Fault |
| --- | --- | --- |
| `Notify-only - no messages were deleted.` / `Flagged for review - no automatic action taken.` | `This is only an alert, no messages were deleted.` / `This is only an alert, the image was not deleted.` | The alert says what happened to the message, in the words of the `Only alert staff` setting. |
| `The message was left in place - automatic removal is turned off.` | `The message was left in place - Scam Image Detection is set to "Only alert staff".` | Names the setting the reader can find on the site instead of describing it. |
| `User was banned.` / `Cross-channel spam purged` | `The member was banned.` / `Cross-channel spam deleted` | The vocabulary holds on Discord too. |

### Punctuation

| Weak | Better | Fault |
| --- | --- | --- |
| `The title of the stream, video or clip.` / `... case, punctuation, extra spacing and invisible characters are ignored ...` / `(try 30m, 2h or 1d, up to 30 days)` | `The title of the stream, video, or clip.` / `... case, punctuation, extra spacing, and invisible characters are ignored ...` / `(try 30m, 2h, or 1d, up to 30 days)` | Three items, no serial comma. |
| `operating, securing and debugging`, plus 19 more lists in the privacy policy and the terms | `operating, securing, and debugging` | Three items, no serial comma. |
| `localStorage — your theme` / `Discord's retention — we never store` | `localStorage - your theme` / `Discord's retention - we never store` | The joiner is ` - `, as everywhere else. |
| `Pick a role…` | `Pick a role` | The ellipsis said the prompt was in progress. |

### Structure

| Weak | Better | Fault |
| --- | --- | --- |
| `Where to post` / `What to post` | Deleted. | The headings named the layout, not a setting. |
| Disclosure `Custom message`, renamed `Message and notification`, renamed `Settings` | No disclosure. Each post type is a card that opens with its toggle. | The label was renamed every time the disclosure gained a field, because it named a container. One word hid every setting of a type. |
| `Alerts post to #mod-log through the Logging plugin.` | `Alerts go to #mod-log. You can change this in Logging.`, with `Logging` as the link | The line named the place to change the channel but did not lead there. |
| `One that already exists` + `Game results posted on twilight-struggle.com get posted straight to Discord, ...`, with the plugin name linked | `An example` + `Posts game results from twilight-struggle.com to Discord, in the channel and format each server picks.`, with the site linked | The link goes to the site, so it sits on the site's name. |

## Kept on purpose

Copy that breaks a rule above and stays. Recorded so it does not get "fixed"
later.

| Copy | Rule it breaks | Why it stays |
| --- | --- | --- |
| `♥` in the site footer | ASCII over glyphs. | One glyph, one place, load-bearing for the line it sits in. |
| `Moderation`, the event group on the Logging page | Server Shield, never Moderation. | It means Discord's own mod actions (bans, kicks, timeouts), not the plugin group. |

## Standing rule

Copy changes land in this file in the same chunk that makes them. A rewritten
string adds a row under the rule it broke, and a row that fits no heading means
a rule is missing: add it to the right section. When a "Better" string is
rewritten again, update its row instead of adding a second one, so every
"Better" cell stays true. Reviewing copy and then losing the reasoning is how
the same correction gets made twice.
