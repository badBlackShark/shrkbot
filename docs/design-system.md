# Design system

The web UI is built from the design system delivered in `docs/design/` (the
`tokens/*.css` + `tailwind/theme.css` are the production spec; the HTML mockups
under `ui_kits/` are throwaway CDN-wired prototypes). This doc records how that
system is wired into the app. Views are Phlex; styling is Tailwind v4; behaviour
is Stimulus.

## App shell

Authed pages render their content inside `Components::AppShell`, which draws the
sticky top bar (mascot wordmark linking to the picker, the dark-mode toggle, and
a user menu with Log out) and yields the page body into `<main>`. The view passes
the user in explicitly — `render Components::AppShell.new(user:) { … }` — rather
than reaching for `helpers.current_user` (phlex-rails warns on the raw `helpers`
proxy). The login and re-auth pages are not authed, so they sit outside the shell
and centre themselves.

Flash messages render as dismissable toasts (`Components::Toasts`, rendered once
from the layout so every page gets them). Small dropdowns (the user menu) use a
native `<details>` element plus the `dropdown` Stimulus controller, which just
closes it on an outside click or Escape. The panel fades in with `anim-menu`, and
the trigger's chevron points left when closed and rotates down when open (via
`group-open`).

The server switcher and the reusable config-form controls (switch, segmented
control, enable-gate, setting row, Tom Select wrapper, save-feedback) are built
alongside the pages that consume them (the dashboard and plugin config pages),
not up front.

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

The toggle's sun/moon icons share a grid cell (`.theme-morph`) and rotate/scale/
fade past each other when the theme flips, so the icon morphs between states
(skipped under reduced motion). Surface colours swap instantly — a global colour
transition would have to override the morph's transition to apply, so it was
dropped in favour of the morph.

## Motion

CSS-only patterns from `docs/design/tokens/motion.css`: `btn-fill`
(hover fill left-to-right via a `::after`), `card-lift`, and the `anim-menu` /
`anim-toast` / `anim-fade` animation classes. Durations 120/180/260ms, ease
`cubic-bezier(.2,0,0,1)`. A `prefers-reduced-motion: reduce` block neutralises
them — keep it.

## Icons

Heroicons v2 (the `heroicons` gem), inline SVG, outline variant by default (set
in `config/initializers/heroicons.rb`). `Components::Icon` renders one by its
Heroicon name. Pass a `class:` for sizing/colour (defaults to `size-5`):

```ruby
render Components::Icon.new("clock", class: "size-5 text-ink-500")
```

The mockups used Lucide names, but Lucide was never adopted; use Heroicon names
directly (the [Heroicons site](https://heroicons.com) lists them).
