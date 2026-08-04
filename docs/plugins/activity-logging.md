# Activity logging

How a user action reaches a server's log channel: one toggle per event, one
message per interaction.

`Bot::ActivityLog` (`app/bot/`) is the seam for writing a user action to a server's logging
channel, split into two queries: `Bot::ActivityLog.enabled?(server_configuration, action)` answers
whether an event should be logged (the logging plugin must be enabled *and* the specific
event toggled on), and `Bot::ActivityLog.post(server_configuration, bot:, title:, body:, meta:)`
renders and delivers one entry. The split lets a consumer gate the *parts* of a composite
entry individually while still sending a single message.

One toggle per event, keyed `"<plugin>.<event>"` (e.g. `"roles.role_gained"`) — a plain
string, so there's no separate event→action map to maintain. Toggles live in
`logging_settings.enabled_actions` (a jsonb map, default `{}` = everything off);
`LoggingSetting#action_enabled?` reads it. The Phase 7 web UI gives each plugin a logging
tab listing its events as independent toggles, and greys the lot out when the logging
plugin is off.

Entries render as the shared **accent container** (`Bot::Discord::Components`), one text block in
three parts: a bold **title** (the action), a **body** sentence (who was affected and what
happened), and a muted `-#` **meta** line (who/what triggered it — e.g. `Self-assigned via
the "Pronouns" role menu`). Mention pings are suppressed (`allowed_mentions: {parse: []}`)
so logging a member's action never notifies them. Toggles still gate atomically, but
delivery is composite: one interaction = one entry. A role swap with both toggles on logs a
single "gained X and lost Y" sentence; turn one toggle off and only the other side renders —
so the toggles compose with no "swap logs nothing" gap and no double message.

Message text is `config/locales/activity_log.en.yml`, nested by plugin — the bot is
English-only, so I18n is a string registry here, not localization. Per-plugin entry
builders (e.g. `Roles::ActivityEntry`) look the strings up with `raise: true`, so a bad key
**raises** (surfaces in the consumer's spec; owner-reported in prod via `Bot::BaseEvent`); only
the channel send is rescued, so a delivery failure never breaks the user's action. Welcomes
are excluded by design. Roles assignment is the first consumer —
`Roles::ComponentHandler#log_assignment` diffs gained/lost from the pre-apply roles, drops
any side whose toggle is off via `enabled?`, and posts one entry built by
`Roles::ActivityEntry`.

The enumerable catalog of each plugin's loggable events (so the web tab can render the toggle
list) is a Phase 7 concern — a per-plugin declaration added when that UI is built. The bot
side doesn't need it: the i18n lookup raising on an unknown key covers typos.

## Moderation member log

The three moderation events (`member_banned`, `member_kicked`, `member_timed_out`) are
driven by Discord's `GUILD_AUDIT_LOG_ENTRY_CREATE` gateway event, not by `user_ban`,
`member_leave`, or `member_update`. The moderator and reason exist only in the audit log,
and polling the audit-log REST endpoint on the gateway event loses a race: Discord writes
audit entries asynchronously, so a ban lookup routinely came back empty and logged "an
unknown moderator" with no reason. The pushed audit entry carries the performer, the
reason and the target, so there is nothing to poll and nothing to race.

`Moderation::MemberActionLog` holds the shared pipeline (toggle gate, skip shrkbot's own
actions by comparing `event.user_id` to the bot's profile ID, build, post); the three
subclasses are just an audit action plus an event key. `MemberTimeoutLog` additionally
filters `member_update` entries down to those that set a non-nil
`communication_disabled_until`, which excludes nickname/role edits and timeout removals.

The cost of this design: Discord only delivers audit-log entries to bots holding **View
Audit Log**, so without that permission moderation logging is silent rather than
degraded. That is accepted — the default invite grants Administrator.
