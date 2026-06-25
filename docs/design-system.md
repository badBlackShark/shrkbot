# Design system

The web UI is built from the design system delivered in `docs/design/` (the
`tokens/*.css` + `tailwind/theme.css` are the production spec; the HTML mockups
under `ui_kits/` are throwaway CDN-wired prototypes). This doc records how that
system is wired into the app. Views are Phlex; styling is Tailwind v4; behaviour
is Stimulus.

## Accessibility (standing rule)

Be mindful of accessibility in every aspect of the UI. Contrast is enforced now:
every text/background pairing must stay legible in **both** themes. The way to
stay legible is to use the **semantic** tokens for anything theme-responsive —
`text-text-primary`/`-secondary`/`-muted`, `bg-surface-*`, `border-border-*`,
`text-accent-soft-fg` — because those flip with the theme. The trap is reaching
for a raw `ink-*` or `brand-*` step for text or a surface: those ramps are now
**fixed** (sand stays sand, teal stays teal in both themes), so a raw `ink-700`
as body text is dark-on-cream in light and dark-on-espresso (invisible) in dark.
Raw ramp steps are only for the rare element that must stay one literal colour in
both themes. Check both themes when adding UI. Reduced motion is honoured
throughout (keep it); keyboard and screen-reader passes are deferred but don't
regress them.

## Copy (I18n)

All user-facing web copy goes through Rails I18n — keep strings out of the views
so they can be edited and reused (and so a second locale stays possible; the bot
itself stays English). `Components::Base` includes the phlex translate helper, so
views/components call `t(".key")` with a **relative** key scoped to the class
name (`Views::Servers::Index` → `views.servers.index.*`); controllers use the
absolute key (e.g. `t("sessions.signed_in")`). Copy lives in
`config/locales/web.en.yml`. Use I18n pluralisation (`one`/`other` with `count:`)
rather than hand-rolled `count == 1` ternaries; pass a separate `formatted:`
interpolation when the displayed number needs delimiting. Brand marks (the
`shrkbot` wordmark) and slash-command names stay literal.

`i18n-tasks` lints the locale files; CI runs `missing` (used-but-undefined keys)
and `check-normalized` (files sorted/formatted — run `i18n-tasks normalize` to
fix). `unused` is deliberately not enforced: it can't see dynamic `t("#{…}")`
calls (e.g. the bot's `activity_log.<plugin>.<event>`). Phlex's class-name key
scoping is configured in `config/i18n-tasks.yml` (`relative_roots: [app]` +
`relative_exclude_method_name_paths: [app]`).

## App shell

Authed pages render their content inside `Components::AppShell`, which draws the
sticky top bar (mascot wordmark linking to the picker, the dark-mode toggle, and
a user menu with Log out) and yields the page body into `<main>`. The bar carries
the chamfer (cut bottom corners) via the `.app-bar` utility, which paints the
surface + chamfer on a `::before` layer rather than `clip-path`-ing the header
itself — clipping the header would slice off the switcher/user-menu dropdowns that
hang below it. The view passes
the user in explicitly — `render Components::AppShell.new(user:) { … }` — rather
than reaching for `helpers.current_user` (phlex-rails warns on the raw `helpers`
proxy). The login and re-auth pages are not authed, so they sit outside the shell
and centre themselves.

Flash messages render as dismissable toasts (`Components::Toasts`, rendered once
from the layout so every page gets them). Small dropdowns (the user menu) are the
standard pattern: a native `<details>` with the `dropdown` Stimulus controller.
The panel (`.dropdown-menu`, a `menu` target) fades/slides in via CSS on `[open]`
and fades/slides back out on close — the controller intercepts the close
(`click->dropdown#toggle`, plus outside-click and Escape) so the exit animation
finishes before the panel is removed, then sets `open = false`. The trigger's
`.dropdown-chevron` points down when closed, rotates up when open, and rotates
back down the moment a close starts (keyed off the panel's `.is-closing` via
`:has`, so it turns with the fade-out rather than after it). Reduced motion drops
both directions.

The top bar also gains a **server switcher** when a page is scoped to one server
(the dashboard passes `current_server:` + `servers:` to `AppShell`): a `dropdown`
disclosure listing the user's configured servers as links to their dashboards,
the current one marked, plus a link back to the picker. It has no search box —
the list is a user's handful of admin servers; add filtering only if that stops
being true.

`Components::Toggle` is the reusable on/off switch: a visually-hidden `peer`
checkbox with a Tailwind `peer-checked:` track (no custom CSS), so it stays a real
form control. It has two modes. **Standalone** (`url:` given) owns its own form;
with `submit_on_change: true` the `toggle` Stimulus controller submits it the
moment it flips, and the action responds with a **Turbo Stream** that re-renders
the control in place plus a toast — no page reload (the dashboard's plugin-enable
and `force_dm_reminders` toggles). **Field** (no `url:`) renders just the switch to
sit inside a larger form that saves explicitly.

For a control that needs a "why" on hover (a locked toggle, later a
disabled-with-reason select option), wrap it in `Components::Tooltip` rather than
a native `title`: it fades in instantly with our surfaces and fonts, where the
native tooltip is slow, tiny, and system-font. The reminders dashboard row uses
it on its always-on (locked) toggle.

That split is the save model: standalone settings save instantly; **the plugin
config pages do not auto-save** — they batch all edits behind an explicit Save
button so a configuration can be staged before going live (toggles there are
`Components::Toggle` fields). Both paths render through a Turbo Stream view
template (`action.turbo_stream.erb`, see architecture.md "Web"): the template's
`turbo_stream.replace`/`append` lines render our Phlex components as the content, so
the stream markup stays in the view layer. Success re-renders the control plus a
toast; a config-form failure re-renders the form region with inline errors — just
more `turbo_stream.*` lines. The remaining config-form controls
(segmented control, enable-gate, Tom Select wrapper) are built with the pages that
consume them.

## Core components

Reach for these before hand-rolling markup — more small components beats
duplicated class strings:

- **`Components::Button`** — `variant:` (`:primary` chamfered CTA, `:secondary`
  bordered, `:ghost`, `:danger`), `size:` (`:sm`/`:md`/`:lg`), `icon:` /
  `trailing_icon:`, `full:`. Renders an `<a>` when `href:` is given, else a
  `<button>` (`type:` defaults to `"button"`; pass `"submit"` for forms). A form
  helper that needs the look without the component (the OAuth `button_to`) borrows
  `Components::Button.css(...)`.
- **`Components::Card`** — the standard warm surface. `enabled:` swaps to the teal
  border, `padding:` (`:none`/`:sm`/`:md`/`:lg`), `href:` renders a link card,
  `lift:` adds the hover-raise, `dashed:` is the placeholder/add affordance.
- **`Components::Badge`** — status pill or tag. `variant:` (`:success`/`:warning`/
  `:danger`/`:neutral`/`:brand`/`:copper`), `dot:`, `shape:` (`:pill`/`:chip`).
  Copper is for wayfinding/personality, never status.
- **`Components::PluginTile`** — the chamfered identity tile (icon on teal when
  `enabled:`, muted sand otherwise). `size:` (`:sm`/`:md`/`:lg`).
- **`Components::Callout`** — tinted bordered notice. `variant:` (`:info`/
  `:neutral`/`:warning`/`:danger`/`:success`) sets colour + default icon.

## Where it lives

- `app/assets/tailwind/` — the stylesheet, split into focused partials that
  `application.css` imports: `fonts.css` (`@font-face`), `tokens.css` (the design
  tokens — `:root` + `[data-theme="dark"]`), `theme.css` (the Tailwind `@theme`
  bridge), `utilities.css` (chamfer geometry, motion patterns, dropdown/theme
  choreography), and `tom-select.css` (the Tom Select skin). Compiled to
  `app/assets/builds/tailwind.css` by `tailwindcss-rails` (gitignored;
  `bin/rails tailwindcss:build`, or the `css` process in `Procfile.dev`).
- `app/assets/fonts/` — the self-hosted woff2 files.
- `app/components/icon.rb` — inline-SVG icon component.
- `app/javascript/controllers/theme_controller.js` — the dark-mode toggle.

## Fonts

Self-hosted, no CDN: Space Grotesk (display, variable 300-700), **Exo 2** (body,
variable — split into a latin and a latin-ext face so accented server/member
names render in-face), IBM Plex Mono (mono, 400/500). The `@font-face` rules live
in `app/assets/tailwind/fonts.css`; the `url()`s use bare filenames
(e.g. `url("exo2-variable.woff2")`) which Propshaft rewrites to digested asset
paths at serve time. Exposed as `font-display` / `font-sans` / `font-mono`.

## Tokens and Tailwind theme

Two conceptual layers (in `tokens.css`):

1. **Fixed reference ramps** — `--brand-*` (teal), `--ink-*` (sand), `--copper-*`.
   These never change with theme. Use them only for an element that must stay one
   literal colour in both themes.
2. **Semantic aliases** — `--text-*`, `--surface-*`, `--border-*`, `--accent*`,
   `--accent-2*` (copper), `--nav-active`, `--eyebrow`, plus motion tokens. These
   are redefined under `[data-theme="dark"]`, so anything built on them flips.

`theme.css` maps both onto Tailwind utilities with **`@theme inline`**, which
emits `var(--token)` references rather than resolved values — so a utility on a
semantic alias responds to the active theme with **no `dark:` variants anywhere**.

Use the **semantic** utilities for theme-responsive UI: `bg-surface-card` for card
surfaces, `bg-surface-page` for the page, `bg-surface-sunken` for washes,
`text-text-primary`/`-secondary`/`-muted`, `border-border-subtle`/`-default`/
`-strong`, `bg-accent-fill` for solid teal buttons (white-text-safe — **not**
`bg-brand-500`, which fails white-on-teal contrast), `bg-accent-soft` +
`text-accent-soft-fg` for soft-tint chips/avatars, `text-accent` for a teal icon.
Copper is `text-accent-2-text` / `bg-accent-2-soft` / `bg-accent-2-fill` and owns
warmth/wayfinding (donate, OSS badge, the wordmark "bot") — **never** status.
Reach for a raw `brand-*`/`ink-*` step only when you genuinely need a fixed colour.

Tailwind v4 must scan the Phlex `.rb` files or utilities used only in Ruby string
literals get purged; `@source "../../views"` and `@source "../../components"`
handle that.

## Dark mode

`[data-theme="dark"]` on `<html>` redefines the **semantic aliases** (text /
surface / border / accent / copper); the reference ramps stay fixed. Dark is a
**warm espresso** palette (`surface-page #1a130d`), the teal softens to an aged
"patina" (`--accent #46817a`) so it harmonises with the warm field, and copper is
used liberally — active-nav (`--nav-active`) and section eyebrows (`--eyebrow`)
both go copper in dark. Because surfaces are espresso (not an inversion of the
sand ramp), views must use the semantic surface/text/border tokens, not raw
`ink-*`, or they won't theme. The semantic soft tints (`success/warning/danger
-soft`) are re-mixed as low-alpha washes so they read on espresso.

The toggle is `theme_controller.js` (flips the attribute, persists to
`localStorage` under `shrk-theme`). To avoid a flash of the wrong theme, an
inline script in the `<head>` (see `layouts/application.html.erb`) sets
`data-theme` before first paint from `localStorage`, falling back to the OS
`prefers-color-scheme`. The toggle lives in the app-shell top bar.

Two things animate on a theme switch. The toggle's sun/moon icons share a grid
cell (`.theme-morph`) and rotate/scale/fade past each other, so the icon morphs
between states. And surface colours ease rather than snap: the controller adds
`.theme-switching` to `<html>` for the duration, which turns on a
`background-color`/`border-color`/`color` transition — scoped to exclude the
morphing icons, so it doesn't replace their transform/opacity transition. Both
are skipped under reduced motion.

## Motion

CSS-only patterns in `app/assets/tailwind/utilities.css`: `card-lift`, the
`anim-menu` / `anim-toast` / `anim-fade` classes, the dropdown/chevron and
theme-morph choreography, and the chamfer geometry helpers (`chamfer-tile`,
`chamfer-tile-sm`, `chamfer-cta`, `chamfer-bar` — for brand-forward surfaces
only). Durations 120/180/260ms; `--ease-standard cubic-bezier(.2,0,0,1)` for
entering, `--ease-exit cubic-bezier(.4,0,1,1)` for leaving. A
`prefers-reduced-motion: reduce` block neutralises them — keep it. Buttons
darken on hover (`hover:bg-accent-fill-hover` for primary, a sand wash for the
rest) rather than the old fill-wipe, which has been removed.

## Layout: flex, not grid

Use flexbox for layout. Reach for CSS grid only when a layout genuinely can't be
done with flex — in practice that's a responsive multi-column **card grid** with
equal tracks (e.g. the server picker's `grid-cols-1 sm:grid-cols-2
lg:grid-cols-3`), where the flex equivalent needs fragile `calc()` basis values.
Never use grid to centre a single item (`flex items-center justify-center`, not
`grid place-items-center`) or to stack/overlap elements (`relative` + `absolute
inset-0`).

## Icons

Phosphor (the `phosphor_icons` gem), inline SVG (inherits `currentColor`).
`Components::Icon` renders one by its Phosphor name; pass a `class:` for
sizing/colour (defaults to `size-5`) and an optional `weight:`. The one-tone rule:
`:regular` is the workhorse, `:bold` marks active/emphasis, `:fill` is the white
glyph inside a filled teal tile — never two-tone (teal and copper vibrate inside a
small glyph). No initializer; an unknown name raises `IconNotFoundError`, so typos
surface loudly.

```ruby
render Components::Icon.new("bell-ringing", class: "size-5 text-text-secondary")
render Components::Icon.new("users-three", weight: :fill, class: "size-5 text-white")
```

Plugin icons: roles → `users-three`, welcomes → `hand-waving`, logging → `scroll`,
reminders → `bell-ringing`. Browse names at [phosphoricons.com](https://phosphoricons.com).
