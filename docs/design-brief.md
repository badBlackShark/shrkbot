# Web config UI — design brief (Phase 7)

For a design pass on the shrkbot web app (Claude Design has repo access — read
`CLAUDE.md`, `docs/architecture.md`, and the `Gemfile` for the stack; this brief covers
*intent*, information architecture, and the patterns we want designed).

## What this is
A configuration website for **shrkbot**, a Discord bot. Server owners/admins log in with
Discord and configure the bot per server: which plugins are on, and their settings. The bot
itself runs separately; this site is the control panel. Auth (Discord OAuth) and the Phlex
view layer already exist — the landing page is the only built screen and is intentionally
bare.

## Users & context
- **Who:** Discord server owners and admins. Not necessarily technical.
- **When:** Infrequent, task-focused visits — "turn on welcomes," "add a role menu,"
  "change the log channel." Often triggered by an onboarding DM the bot sends when it joins
  a server (deep-links to that server's config).
- **What they value:** Clarity and low friction. They should never wonder whether a change
  saved, or why an option is disabled. Trust matters — it's their server.

## Stack constraints (so mockups are buildable)
- **Phlex components + Tailwind v4 + Hotwire (Turbo + Stimulus).** Tailwind v4 picks up
  classes from Phlex `.rb` views (confirmed).
- **Deliver static HTML + Tailwind mockups**, not Figma — they port ~1:1 into our Phlex
  components. Stimulus for behavior; **Tom Select** is planned for searchable dropdowns.
- No heavy JS framework, no new runtime CSS deps. English-only (no i18n in copy).
- Brand accent today is a single colour, **`#39afe5`** (a light blue, also the bot's accent
  in Discord). Expanding it into a proper palette is welcome.
- Responsive: desktop-first, but usable on a phone (owners do configure on mobile).
- Accessibility basics: real labels, visible focus, sufficient contrast, keyboard paths.

## What's configurable (the domain)
Three per-server **plugins**, each independently enable/disable-able, each with settings that
only matter when it's on:

- **Roles** — self-assignable roles. A server has multiple **role sets**; each set is either
  *single* (pick one, exclusive) or *multi* (pick any). Each set has a channel (plugin default
  or per-set override) and posts a public message members interact with. Per-message
  **force-repost** action (re-posts if the message/channel was deleted). The role picker must
  **grey out roles the bot can't assign** — roles above the bot's highest role, or
  bot/integration-managed roles — with a clear "why disabled" explanation. This is the richest
  screen and the best stress-test for the design.
- **Welcomes** — a channel plus **join** and **leave** message templates, with placeholders
  like `{user}` and `{membercount}`. Authors need to know which placeholders exist and,
  ideally, preview the result.
- **Logging** — a log channel plus a matrix of **per-event toggles** (e.g. "role gained,"
  "role lost"), grouped by plugin, all off by default. The whole matrix is inert when the
  Logging plugin is off.

Plus:
- **Server-level setting:** force reminder delivery via DM (boolean).
- **Owner-only admin page** (the bot owner, not server admins): a global toggle. Gate it
  clearly as a different scope from per-server config.
- **Reminders** are driven by Discord slash commands, **not** configured here — no screen.

## Screen inventory & flow
1. **Login** (built, minimal) — one "Sign in with Discord" action.
2. **Server picker** — the user's manageable servers (they're owner/admin **and** the bot is
   present). Needs a strong **empty state** (no manageable servers / "invite the bot").
3. **Server dashboard** — for the chosen server: the three plugins with enable toggles and
   at-a-glance status; entry points into each plugin's config. Home base after login.
4. **Plugin config pages** — one per plugin (Roles, Welcomes, Logging). Consistent template;
   Roles is the complex one (list of sets → set editor).
5. **Server settings** — the server-level toggle(s).
6. **Owner admin** — owner-gated global settings.

Flow: login → server picker → server dashboard → a plugin page → tweak settings (auto-saved)
→ back to dashboard or switch server.

## Core patterns to design (highest leverage — these repeat everywhere)
1. **App shell** — top bar with logo, a **server switcher**, and a user/logout menu; content
   region. This frames every authenticated screen.
2. **Plugin config page template** — header (plugin name, one-line description, the enable
   toggle) over a settings body.
3. **The enable-gate** — when a plugin is off, its settings are visibly inert (not hidden)
   with an obvious "enable to configure" affordance. Used on every plugin page; for Logging it
   also gates the whole event-toggle matrix.
4. **Setting row** — label + control + help text + room for an inline, non-blocking **warning**
   (e.g. "this log channel is visible to @everyone").
5. **Controls** — a switch/toggle (plugin enable, logging events, booleans); single and
   **multi-select** dropdowns for channels and roles (Tom Select).
6. **Disabled-with-reason** — the roles grey-out: an option that's present but unselectable,
   with a tooltip/affordance explaining why (bot can't assign it).
7. **Save feedback** — settings **auto-save on change** via Turbo; show a quiet, trustworthy
   "saved" confirmation and a clear error state. (Assume no explicit Save buttons for most
   settings.)
8. **Empty states** — no manageable servers, no role sets yet, etc.
9. **Notifications / flash** — success/error/info toasts.

## What we'd love back
- A **token system**: palette built out from `#39afe5`, type scale, spacing, radius, and
  interactive states (hover/focus/active/disabled).
- The **app shell** + server switcher.
- The **core patterns** above as static HTML+Tailwind snippets.
- A few representative **screens** assembled from those: the server picker, the dashboard, and
  the **Roles** plugin page (set editor with the grey-out) as the hard case.

## Open questions for the designer
- Light only, or light + dark from the start?
- Density — airy and friendly, or compact and dense? (Leaning friendly, given infrequent
  non-technical users.)
- How much to invest in mobile beyond "usable."
- How far to expand the single accent into a full brand palette.

## Non-goals / guardrails
- Don't design the **in-Discord** experience (the bot's messages are Discord Components V2 —
  a separate surface).
- No new heavy front-end dependencies; stay within Hotwire + Tom Select.
- Use **sample/placeholder data** in mockups — no real Discord user or server data.
