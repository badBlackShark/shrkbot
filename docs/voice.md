# Voice

How shrkbot's copy sounds. Read this before writing or changing any user-facing
string: Discord messages and command descriptions, website copy, and PR
descriptions.

Rules are derived from the Discord copy already in the repo, which is the
surface that has had the most correction passes. Examples are real strings, not
invented ones.

## The three surfaces

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

Everything under "every surface" applies. Two more, both from settings pages:

**Sibling help texts share a shape.** If the fields around yours all open "How
long a member must...", yours does too. A single field that switches to a
noun-phrase register reads as though someone else wrote it.

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
