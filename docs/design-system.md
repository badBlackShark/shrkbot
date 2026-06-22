# Design system

The web UI is built from the design system delivered in `docs/design/` (the
`tokens/*.css` + `tailwind/theme.css` are the production spec; the HTML mockups
under `ui_kits/` are throwaway CDN-wired prototypes). This doc records how that
system is wired into the app. Views are Phlex; styling is Tailwind v4; behaviour
is Stimulus.

## Accessibility (standing rule)

Be mindful of accessibility in every aspect of the UI. Contrast is enforced now:
every text/background pairing must stay legible in **both** themes. The common
trap is the inverting `ink` ramp — a muted step like `ink-400` is a faint grey in
light mode but inverts to a near-black `#484f58` in dark mode, vanishing on a dark
card. For secondary text that must read in both, use `ink-500`/`ink-600`, not
`ink-400`; for accent text on a tint use the theme-aware `text-accent-soft-fg`.
Check both themes when adding UI. Reduced motion is honoured throughout (keep it);
keyboard and screen-reader passes are deferred but don't regress them.

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
a user menu with Log out) and yields the page body into `<main>`. The view passes
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
`.dropdown-chevron` points left when closed, rotates down when open, and rotates
back the moment a close starts (keyed off the panel's `.is-closing` via `:has`,
so it turns with the fade-out rather than after it). Reduced motion drops both
directions.

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
`Components::Toggle` fields). The instant path's mechanics — `render turbo_stream:`
with `turbo_stream.replace`/`append` of Phlex components via `render_to_string(...,
layout: false)`, toasts appended into the always-present `#toasts` container — are
reused by the config-page Save. The remaining config-form controls (segmented
control, enable-gate, Tom Select wrapper) are built with the pages that consume
them.

## Where it lives

- `app/assets/tailwind/application.css` — the single stylesheet. Holds the
  `@font-face` block, the design tokens, the Tailwind `@theme`, and the motion
  patterns. Compiled to `app/assets/builds/tailwind.css` by `tailwindcss-rails`
  (gitignored; `bin/rails tailwindcss:build`, or the `css` process in
  `Procfile.dev`).
- `app/assets/fonts/` — the self-hosted woff2 files.
- `app/components/icon.rb` — inline-SVG icon component.
- `app/javascript/controllers/theme_controller.js` — the dark-mode toggle.

## Fonts

Self-hosted, no CDN: Space Grotesk (display, variable 300-700), IBM Plex Sans
(body, 400/500/600/700), IBM Plex Mono (mono, 400/500). The `@font-face` rules
come from `docs/design/tokens/fonts.css`; the `url()`s use bare filenames
(e.g. `url("space-grotesk-variable.woff2")`) which Propshaft rewrites to digested
asset paths at serve time. Exposed as `font-display` / `font-sans` / `font-mono`.

## Tokens and Tailwind theme

Two layers:

1. **Raw channel variables** (plain custom properties in `:root` and
   `[data-theme="dark"]`): `--brand-*`, `--ink-*`, the semantic colors, plus a
   few aliases for raw CSS (`--accent-hover`, `--surface-sunken`, `--focus-ring`)
   and the motion tokens (`--dur-*`, `--ease-standard`).
2. **`@theme inline`** maps the Tailwind color utilities at those channel vars
   (`--color-ink-600: var(--ink-600)`), plus the static font / radius / shadow
   tokens.

Using `@theme inline` means utilities reference the raw var directly
(`.text-ink-600 { color: var(--ink-600) }`), so they respond to the active theme
with **no `dark:` variants anywhere**. Use the token utilities — `bg-ink-0` for
card surfaces, `bg-ink-50` for the page, `text-ink-900/700/600`, `border-ink-*` —
not Tailwind's built-in `white`/`slate`, which don't theme.

For accent text/icons sitting on a soft brand tint (badges, the avatar initials),
use `text-accent-soft-fg`, not a raw `brand-*` step: a fixed brand step can't read
on both a light tint and a dark one, so this token flips (`brand-700` light /
`brand-300` dark). Mind contrast generally — pair foreground/background tokens so
both themes stay legible (we already honour reduced motion; full screen-reader and
keyboard-navigation passes are deferred).

Tailwind v4 must scan the Phlex `.rb` files or utilities used only in Ruby string
literals get purged; `@source "../../views"` and `@source "../../components"`
handle that.

## Dark mode

`[data-theme="dark"]` on `<html>` swaps the channel variables. The brand accent
(`--brand-500` = `#39afe5`) is constant across themes; the neutral `ink` ramp
inverts (light surfaces ↔ dark surfaces, dark text ↔ light text). The soft brand
tints (`brand-50/100/200`) become translucent sky in dark mode rather than solid
dark hex — a solid dark tint disappears against the dark card, whereas a
translucent one reads as a raised chip on any surface.

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

CSS-only patterns from `docs/design/tokens/motion.css`: `btn-fill`
(hover fill left-to-right via a `::after`), `card-lift`, and the `anim-menu` /
`anim-toast` / `anim-fade` animation classes. Durations 120/180/260ms, ease
`cubic-bezier(.2,0,0,1)`. A `prefers-reduced-motion: reduce` block neutralises
them — keep it.

## Layout: flex, not grid

Use flexbox for layout. Reach for CSS grid only when a layout genuinely can't be
done with flex — in practice that's a responsive multi-column **card grid** with
equal tracks (e.g. the server picker's `grid-cols-1 sm:grid-cols-2
lg:grid-cols-3`), where the flex equivalent needs fragile `calc()` basis values.
Never use grid to centre a single item (`flex items-center justify-center`, not
`grid place-items-center`) or to stack/overlap elements (`relative` + `absolute
inset-0`).

## Icons

Heroicons v2 (the `heroicons` gem), inline SVG, outline variant by default (set
in `config/initializers/heroicons.rb`). `Components::Icon` renders one by its
Heroicon name. Pass a `class:` for sizing/colour (defaults to `size-5`):

```ruby
render Components::Icon.new("clock", class: "size-5 text-ink-500")
```

The mockups used Lucide names, but Lucide was never adopted; use Heroicon names
directly (the [Heroicons site](https://heroicons.com) lists them).
