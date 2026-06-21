# shrkbot Design System

A design system for **shrkbot** — *a modular Discord bot* by [badBlackShark](https://github.com/badBlackShark). shrkbot lets server owners turn features (plugins) on or off and configure them per server. Its tagline in spirit: **turn features on, or off.** Clean, minimalist, UX-first; simple and intuitive.

> The mascot is a tool-jawed mechanical shark biting a wrench, on a sky-blue field — playful engineering. That single blue, **`#39afe5`**, is the brand's one true accent (it's literally the bot's `BotConfig::ACCENT_COLOR`, the border color of its Discord messages).

---

## Sources this was built from

Everything here was derived from the product's own code and brief — explore them to go deeper:

- **GitHub:** [`badBlackShark/shrkbot`](https://github.com/badBlackShark/shrkbot) — the bot + web app (Ruby on Rails 8.1, mid-rewrite from Crystal).
  - `docs/design-brief.md` — the Phase-7 web-config-UI design brief (intent, IA, patterns). The dashboard UI kit follows it.
  - `BUILD_PLAN.md` — phased build plan; the plugin/domain model.
  - `app/bot/commands/*.rb`, `app/bot/discord/components.rb` — real bot copy + the accent-container message format.
  - `app/bot/bot_config.rb` — `ACCENT_COLOR = 0x39afe5`.
- **Uploaded asset:** `uploads/shrkbot_square_bg.png` → `assets/shrkbot-mascot.png` (the mascot/logo).

*The reader is assumed not to have access; links are recorded in case they do. Reading the repo — especially `docs/design-brief.md` — will let you design shrkbot surfaces far more accurately.*

### Stack constraints (these shaped every decision)

shrkbot's web app is **Ruby on Rails 8.1 · Phlex views · Tailwind CSS v4 · Hotwire (Turbo + Stimulus) · Tom Select**. **No React, no heavy front-end frameworks.** Deliverables are static **HTML + Tailwind** (port \~1:1 to Phlex) with **Stimulus** for behavior. This design system is authored to match: tokens are plain CSS custom properties (+ a Tailwind v4 `@theme` mirror), and every mockup is HTML + Tailwind + minimal vanilla JS.

---

## Content fundamentals — how shrkbot writes

The voice is the maintainer's: **warm, transparent, modest, a little playful.** It reads like a solo open-source dev talking to you directly — never corporate.

- **Person:** The **bot speaks as "I"** in Discord ("I was written in Ruby by badBlackShark", "Want me on your server?"). The **web UI speaks to "you"** ("Pick a server to configure", "the servers you can manage"). Don't mix the two on one surface.
- **Tone:** honest and unpushy. The donate copy literally says it's *"completely free and open source… You are never obligated to donate"* and lists real monthly hosting cost (10.60€) for transparency. Carry that candor everywhere.
- **Casing:** **shrkbot is always lowercase**, even at the start of a sentence. Headings are sentence case, not Title Case. UI labels are Title Case ("Log Channel", "Add Role Set").
- **Punctuation:** Never use em dashes. Single dashes are fine - like this. Friendly text emoticons appear in long-form bot copy: `:)` and `<3`. These are **typed emoticons, not emoji** - see Iconography. Keep them to warm, personal moments (donate, thanks); never in dense config UI.
- **Length:** short and concrete. One-line plugin descriptions ("Greet new members and say goodbye when they leave."). Tell users *why*, not just *what* - especially for disabled/blocked states ("shrkbot can only assign roles below its own highest role").
- **Technical terms:** Discord vocabulary is used plainly and correctly — server, channel, role, plugin, slash command, `@everyone`. Slash commands render in mono: `/remind`, `/donate`.
- **Vibe in one line:** *a trustworthy, low-friction control panel made by someone who clearly cares.*

**Example copy (real + in-voice):**

> "Turn plugins on or off and set them up - all from one place." "shrkbot only ever reads the servers you can manage. Free & open source." "Reminders themselves are set with the `/remind` slash command in Discord — there's nothing to configure here."

---

## Visual foundations

**Overall:** light, airy, friendly, low-chrome. One bright accent on a calm cool-grey canvas. Minimalist — whitespace and a clear hierarchy do the work; nothing decorative competes with the controls. Density is **friendly, not compact** (infrequent, non-technical users).

### Color

- **One accent:** sky **`#39afe5`** (= `--sky-500` / `brand-500`), expanded into a 50–900 ramp for hovers, tints, and text-on-tint. Hover = one step darker (`brand-600`); pressed = `brand-700`.
- **Neutrals:** a custom **cool slate** ramp (`--slate-*` / `ink-*`), slightly blue-grey so it sits under the sky accent without going warm. Page = `slate-50`, cards = white, text = `slate-900`/`600`/`400`.
- **Semantic** (used sparingly): success `#2faf6b`, warning `#e8a13a`, danger `#e0533d`, each with a soft tint background for callouts/badges. Info reuses the brand sky.
- **Imagery vibe:** the only brand image is the mascot — flat, hand-drawn, black-outlined cartoon on saturated sky. Not photographic, not gradient-y. If imagery is ever needed, keep it flat, friendly, cool-toned.

### Type

- **Display — Space Grotesk** (500–700): headings, plugin names, wordmark. Slightly techy/mechanical, echoing the shark-and-wrench engineering theme. Tight tracking (−0.02em).
- **Body/UI — Hanken Grotesk** (400–700): all prose, labels, controls. Clean, friendly, neutral, highly legible at small sizes.
- **Mono — JetBrains Mono** (400–500): slash commands, channel `#`, role IDs, durations, technical strings.
- Scale: 12 / 14 / 16 / 18 / 22 / 28 / 36 / 48px. Body line-height 1.55; headings 1.12–1.3.
- ⚠️ **Font note (please confirm):** the codebase ships **no custom fonts** (it uses Tailwind defaults). This type system is a *proposal*, not a recreation. All three are free Google Fonts and are loaded from the Google Fonts CDN here (binaries are **not** self-hosted). If you'd like to lock the brand to specific faces or self-host the files, send them and I'll wire them in.

### Spacing, radius, elevation

- **4px grid** (`--space-1…16`). Generous padding inside cards (20–24px).
- **Radii:** moderate and friendly — inputs/buttons `10px` (md), cards `14px` (lg), pills full. Nothing sharp; nothing balloon-round.
- **Shadows:** soft, cool, restrained (`shadow-sm` for resting cards, `shadow-md` on hover, `shadow-lg` for menus/overlays). No hard or colored drop shadows except the optional brand-tinted CTA glow. Borders are 1px `slate-100/200`; the brand uses a faint `brand-200` border to mark "enabled/active" cards.

### Cards & surfaces

White, 1px border, `shadow-sm`, `radius-lg`. Header (display-font title + secondary subtitle + optional right-aligned actions), body, optional tinted footer. **Enabled** plugin cards swap the neutral border for `brand-200`. Avoid the colored-left-border + rounded-corner cliché — borders are full and even.

### Motion, interaction states

- **Motion:** quick and calm. `120–260ms`, ease `cubic-bezier(.2,0,0,1)`. Fades and short slides; **no bounce, no infinite/decorative loops.** The switch knob slides; menus/toasts fade-and-rise a few px.
- **Hover:** buttons darken one brand step; secondary/ghost get a `slate-50/100` wash; cards lift to `shadow-md` and gain a `brand-200` border. Links → `brand-700`.
- **Focus:** visible `3px` brand ring at \~30% opacity plus a brand border. Always keyboard-reachable.
- **Pressed:** primary buttons nudge down 1px; no shrink/scale gimmicks.
- **Disabled / blocked:** \~50% opacity, `not-allowed` cursor. The signature pattern is **disabled-with-reason**: an option stays *visible but unselectable* with a lock icon and a tooltip/explanation (roles shrkbot can't assign).
- **Enable-gate:** when a plugin is off, its settings stay **visible but inert** (dimmed + non-interactive) under a soft overlay with an "Enable to configure" affordance — never hidden.

### Backgrounds, transparency, blur

- Flat `slate-50` page; flat white surfaces. **No gradients, no textures, no patterns.**
- Transparency/blur used only functionally: the enable-gate overlay is a translucent `slate-50/70` with a 1px backdrop blur. Menus/toasts are solid.
- Layout: centered, max-width content columns (≈760–1024px) on the canvas; a fixed top app-bar frames authed screens. Desktop-first but usable on a phone.

---

## Iconography

- **Recommended set: [Lucide](https://lucide.dev)** — clean, consistent 2px-stroke line icons that match the minimalist, friendly tone. Used throughout the mockups via the Lucide CDN (`<i data-lucide="…">` + `lucide.createIcons()`).
- ⚠️ **Substitution flag:** the codebase has **no icon set wired into views yet** (the web UI is unbuilt). Lucide is a *recommendation*. If you'd prefer the Rails-native default, **Heroicons** (also a clean line/solid set, ships as a gem) is a great alternative — say the word and I'll switch the kit over.
- **Sizing/usage:** 16px inline with text, 18–22px in buttons/plugin tiles. Stroke icons sit in neutral `slate-400/500`, or white inside a filled brand tile. One icon per plugin (Roles = `users-round`, Welcomes = `hand`, Logging = `scroll-text`, Reminders = `alarm-clock`).
- **Emoji vs emoticons:** shrkbot does **not** use emoji as UI. It *does* use typed **emoticons** (`:)`, `<3`) in warm long-form bot copy — that's a voice trait, not an icon system. Don't introduce emoji into the UI.
- **The mascot** (`assets/shrkbot-mascot.png`) is the one brand image — app icon, login mark, server-list placeholder. Always on white or its native sky; never stretched or recolored.

---

## What's in here (index / manifest)

**Root**

- `styles.css` — global entry point; `@import`s the token files only. Consumers link this one file.
- `README.md` — this guide.
- `SKILL.md` — portable skill manifest (works as an Agent Skill in Claude Code).

**`tokens/`** — CSS custom properties (the source of truth)

- `colors.css` · `typography.css` · `spacing.css` · `fonts.css` (Google Fonts `@import`).

**`tailwind/`**

- `theme.css` — Tailwind **v4 `@theme`** block mirroring the tokens (`brand-*`, `ink-*`, semantic, fonts, radius, shadows). Drop into the app's stylesheet so views get `bg-brand-500`, `text-ink-600`, `font-display`, etc.

**`foundations/`** — specimen cards (Design System tab): sky & slate & semantic colors; display/body/mono type + scale; spacing, radii, elevation; mascot lockup; the Discord accent-container motif.

**`components/`** — component specimen cards in HTML + Tailwind

- `controls.card.html` — buttons, badges, switch, checkbox, inputs, channel/role selects.
- `patterns.card.html` — callouts, setting row + inline warning, plugin row, enable-gate.

**`assets/`**

- `shrkbot-mascot.png` — mascot / logo.

**`ui_kits/dashboard/`** — the web config dashboard (interactive HTML + Tailwind + vanilla JS)

- `index.html` — login → server picker → app shell → server dashboard → **Roles config page** (the hard case). See its `README.md`.

---

## Using this system

1. Link `styles.css` (tokens + fonts) **or** copy `tokens/*` into your app.
2. Add `tailwind/theme.css` after `@import "tailwindcss";` to get brand utilities.
3. Build screens as HTML + Tailwind; reuse the patterns in `components/` and the dashboard kit. Behavior → Stimulus; dropdowns → Tom Select; auto-save → Turbo.
4. Keep the voice (lowercase shrkbot, sentence case, explain *why*) and the one accent.
