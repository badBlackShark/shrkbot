# Design system

This doc records how shrkbot's design system is wired into the app. The
production spec is `app/assets/tailwind/` — `tokens.css` holds the tokens and
`theme.css` bridges them onto Tailwind. Views are Phlex; styling is Tailwind v4;
behaviour is Stimulus.

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
both themes. Check both themes when adding UI.
Small text needs 4.5:1. `text-text-muted` is the lightest text token that
holds it on every surface; don't go lighter. Reduced motion is honoured
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
from the layout so every page gets them). The `warning` level (a save that leaves a plugin disabled) is sticky: it
stays until dismissed. A toast rises 8px as it fades in, and the `toast`
controller plays `toast-leave` (the toast stops taking clicks from then on), then
collapses the toast's grid row from `1fr` to `0fr` (`toast-collapse`, `--dur-slow`,
linear) before it removes the element on `transitionend` or `transitioncancel`, with a
timer as a fallback. The toast's gap is its card's top margin, inside the collapsing
row, so the toasts above it slide down instead of dropping. A toast is
`data-turbo-temporary`: Turbo drops it from the page cache, so Back never
replays one. Small dropdowns (the user menu) are the
standard pattern: a native `<details>` with the `dropdown` Stimulus controller.
The panel (`.dropdown-menu`, a `menu` target) fades/slides in via CSS on `[open]`
and fades/slides back out on close — the controller intercepts the close
(`click->dropdown#toggle`, plus outside-click and Escape) so the exit animation
finishes before the panel is removed, then sets `open = false`. The trigger's
`.dropdown-chevron` points down when closed, rotates up when open, and rotates
back down the moment a close starts (keyed off the panel's `.is-closing` via
`:has`, so it turns with the fade-out rather than after it). The `dropdown`
controller is for menus that float above the page and nothing else. A menu
that renders already open (a Turbo Frame reloads the notification bell in place)
must not replay its entrance, which reads as a flicker: the controller adds
`.no-enter` on connect, and the next close clears it.

A section that opens inside the page is a native `<details>` with the
`disclosure` controller (`click->disclosure#toggle` on the `<summary>`). It is
the one home for that concept: logging groups, role set and pingable role
cards, the Server Shield explainers, the remembered cards, sidebar groups and
feed type cards all use it. `lib/reveal.js` animates the height of the
`<details>` itself between the summary height and the full height, so the
content stays put and padding needs no wrapper. One Web Animations API
animation plays forward to open and backward at 1.5x to close; a click while it
runs only flips the playback rate, which is what turns a moving section around.
The `<details>` carries `data-closing` while it closes, and the chevron CSS keys
off it. Options: `data-disclosure-key-value` remembers the state in
`localStorage` (restored on connect with no animation), and
`change->disclosure#follow` on a checkbox makes the section follow it. A click
on a link, button, input or label inside the summary does not toggle, the same
as the platform. Durations come from the CSS tokens through `lib/motion.js`,
which reads both `180ms` and the `.18s` the minifier rewrites it to.

A new summary holds no control: a screen reader reads a `<summary>` as one
button and can lose what is nested in it. A control that belongs in the header
sits beside the `<details>`, and the controller moves to their shared wrapper
with the `<details>` as its `details` target (the feed type card and its
toggle). On `turbo:before-cache` the controller settles a reveal in flight, so
a cached page never comes back half closed.

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

**Every tooltip uses `Components::Tooltip` — never a native `title`.** Whenever a
control needs a "why" on hover (a locked toggle, a disabled-with-reason select
option), wrap it in the component: it fades in instantly with our surfaces and
fonts, where the native tooltip is slow, tiny, and system-font. The reminders
dashboard row uses it on its always-on (locked) toggle. The one exception is the
assignable-role picker, whose tooltip sits inside a native `<select>` dropdown
where the component can't render — that stays a native `title`.

That split is the save model: standalone settings save instantly; **the plugin
config pages do not auto-save** — they batch all edits behind an explicit save
(the global `SaveBar`, below) so a configuration can be staged before going live
(toggles there are `Components::Toggle` fields). The exception is a page whose
only control is the enable toggle (the Steam, Twitch and Twilight Struggle
overviews): it has no edits to batch, so its toggle is standalone (see below).
Both paths render through a Turbo Stream view template (`action.turbo_stream.erb`, see [Web (controllers and views)](../web/controllers-and-views.md)): the template's
`turbo_stream.replace`/`append` lines render our Phlex components as the content, so
the stream markup stays in the view layer. Success re-renders the control plus a
toast; a config-form failure re-renders the form region with inline errors — just
more `turbo_stream.*` lines. The one config-form control still unbuilt (the
segmented control) ships with the Roles page that consumes it.

## Config pages

A plugin config page is assembled by **`Components::ConfigPage`**, not by the
per-plugin form. ConfigPage owns the single `form_with` and renders, in order: a
header (`PluginTile` + title + description + an inline **enable `Toggle`**), the
body, and the global `SaveBar` (none, and no SaveBar, when the toggle is
instant). The
per-plugin `Components::<Plugin>::ConfigForm` is **body-only** — it renders just
the cards, with no form tag and no enable control of its own — and its root `div`
carries the `#<plugin>-config` id that the Turbo Stream replaces on a failed save,
so inline errors re-render in place. Keep that split when adding a page: layout in
ConfigPage, fields in the body form.

Pass `channel_lost: true` to `ConfigPage` when the plugin is enabled but its
configured channel is gone (`enabled && setting.channel_id.nil?`). ConfigPage
renders a warning `Callout` banner above the form body so the owner sees the prompt
to pick a replacement channel.

The enable toggle is **staged** wherever the page has other settings: flipping it
stages an `enabled` field in the same batch as the rest of the form, and nothing
persists until Save. A page whose only control is the toggle passes
`toggle: {instant: true}` instead: ConfigPage drops the form and SaveBar, the
toggle saves on flip like the dashboard's, and on a preview server it renders
locked with the preview tooltip. There is no overlay: a disabled plugin's body stays fully
editable, and the Enabled/Disabled label beside the toggle is a CSS
`group-has-[:checked]` pair, so it follows the staged toggle with no JS. Saving a
disabled plugin succeeds and toasts "Saved. X is still disabled."
(`ConfiguresPlugin#saved_message`). A locked toggle submits its current state
through a hidden field. `prerequisites:` takes a `Components::PrerequisiteSteps`
callout rendered above the editable body (a protection with unmet prerequisites;
the Twilight Struggle tournament page while the plugin is off). A setting the plugin can't be enabled without (the channel
picker on Welcomes/Logging) carries a danger `*` marker next to its label; the
operation enforces the requirement server-side and the form re-renders with the
inline error if it's missing. ConfigPage also has a plain path for
always-on plugins: pass no `toggle:` and it drops the enable toggle,
optionally rendering a copper `badge:` ("Always on") next to the title instead —
Reminders is the one consumer.

On config pages the app shell also renders a left **`Components::PluginSidebar`**
(passed to `AppShell` via `sidebar:`, which switches the shell to a sidebar+main
layout). It lists the plugins that have a config page — resolved through the
shared `Components::PluginNav` mixin (plugin→icon and plugin→config-path, shared
with `PluginRow` so the two can't drift) — with a status dot, an active highlight
(`aria-current="page"`). It's `hidden md:block`; the breadcrumb on every config
page is the way back to the dashboard. Catalog plugins join the
list automatically once they have config routes; Reminders has no activation to toggle, so it sits in `PluginCatalog::GLOBALS`, outside
`DEFINITIONS` — `PluginCatalog::GLOBAL_KEYS` names it and
`PluginStatus.rows` appends it as a locked, always-enabled row, which both the
dashboard and the sidebar render.
With a plugin sidebar the footer renders inside the scrolling main pane, so a
page never scrolls by just the footer height — that would rob the sticky sidebar
of headroom and make it slide out of view.

`Components::SaveBar` is the commit affordance: a fixed bottom bar, hidden until
the form differs from its initial state. The `save-bar` Stimulus controller (on
the form) snapshots the form on connect and compares on
every `input`/`change`, revealing or hiding the bar. Its Save button is a plain
`type="submit"` — there's no JS save path; Discard reloads the saved state via a
Turbo visit. A dirty form **blocks navigation**: `turbo:before-visit` is
cancelled (the bar does a copper shake instead) and `beforeunload` warns, so
edits can't be lost by clicking away. The bar re-baselines only on a **successful**
save — config controllers return **422** (not 200) when a save fails validation,
which is both the correct status and the signal (`turbo:submit-end` reports
`success: false`) that tells the bar to stay dirty.

A warning that depends on a field's value reacts to the form, not to the last save: a member who
saves and leaves never sees a warning that only appears after saving. `Components::LiveWarning`
renders a warning `Callout` that the `live-warning` Stimulus controller shows or hides on every
`change` in the surrounding form. It takes the watched field names (`fields:`), a rule
(`includes-any`: a picked value is in `list:`; `excludes-all`: something is picked and none of
it is in `list:`), and `shown:`, the answer for
the saved values so the first paint is right. The Ruby `shown:` and the JS rule must state the same
predicate, so derive `shown:` from the same `list:` where possible. Warnings about server state (a deleted channel, a
missing bot permission) stay plain `Callout`s. A live warning goes below the control it watches, so
it appearing never pushes that control away from the cursor. Advice that would have to sit above
what it is about stays a plain `Callout` that is always shown (the Steam note about untagged patch
notes), so nothing moves under the cursor. A live warning announces itself through a
`role="status"` region that is always in the page, with the `hidden` callout inside it.

The header is a `Components::ConfigPageHeader` value: icon, title, description,
and optionally `badge`, `media` and `aside`. The leading visual is the `PluginTile`
unless `media` is set (Steam News' edit page passes the game's header image, and
passes no `media` when the game has none, so the tile shows). `aside` renders
beside the title, e.g. the Twilight Struggle tournament switcher.

### Plugin groups

A plugin *group* is a `PluginCatalog::Group` (key, name and description): the parent of every
definition with `parent:` set. A group is not a plugin, so it has no activation and no
toggle. Server Shield (`:moderation`) and Integrations (`:integrations`) are the current
ones. A group's page subclasses `Views::Servers::GroupShow` (no header toggle,
plus the stub forms for its rows). Its dashboard row has no toggle or status badge, and
its tile and sidebar icon are lit while any member is on. A member page subclasses
`Views::Servers::SubPluginShow` (supplying `plugin_key`, `icon` and `body`) and links
the group back through `parent_crumb`. Where a member has unmet prerequisites, its
page shows **`Components::PrerequisiteSteps`**: one callout above the editable form with a `Step` per unmet
prerequisite, each deep-linking to where it is fixed (`:requires_plugin` to that
plugin, `:prerequisite` to the group page), and the header toggle stays locked with the
dashboard's needs-setup hint. In the sidebar every group renders as
**`Components::SidebarGroup`**: a native `<details>` disclosure (persisted per user,
auto-expanded on an active member) whose group row is a chevron toggle and whose
sub-items are plain nav links on an indent rail. The group's overview lists the
members with `Components::SubPluginDirectory` and `Components::SubPluginRow`;
the row's toggle posts only `enabled` to `Servers::PluginsController#update` (the
dashboard's toggle endpoint), through the stub forms `Components::SubPluginToggleForms`
renders after the page's own form (forms cannot nest), and the controller redirects a
member back to its group's overview. A member can't be enabled until its prerequisites
are met — that requirement lives in `PluginCatalog::Definition#requires_plugin` and
`#prerequisite`, and `Ops::ServerConfiguration::Plugins::Toggle`, which every enable
path goes through, enforces it.

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
  `:danger`/`:neutral`/`:brand`/`:copper`/`:beta`), `dot:`, `shape:` (`:pill`/`:chip`).
  Copper is for wayfinding/personality, never status. `:beta` (plum) marks a beta
  plugin and nothing else. Every variant is a soft fill
  inside a 1px border of the same hue (`*-soft-bd`), so badges of different tones
  sit next to each other as one family; a new variant supplies a border colour too.
- **`Components::PluginBadges(key:)`** — the New and Beta badges for a plugin, read
  from `PluginCatalog`; the Beta tooltip names the bot owner. Renders nothing when
  neither applies. New rolls up to a parent from a new sub-plugin; Beta does not.
  **`Components::NewSparkle`** is the sidebar's icon-only New marker, with
  screen-reader text, on an item and on a group's own line.
- **`Components::BespokeBadge`** — the copper Bespoke pill (filled puzzle-piece icon)
  on a bespoke plugin's dashboard row and on the bespoke plugins page.
- **`Components::PluginTile`** — the chamfered identity tile (icon on teal when
  `enabled:`, muted sand otherwise). `size:` (`:sm`/`:md`/`:lg`).
- **`Components::Callout`** — tinted bordered notice. `variant:` (`:info`/
  `:neutral`/`:warning`/`:danger`/`:success`) sets colour + default icon.
- **`Components::NumberStepper`** — integer field as one joined 32px control
  `[- | n | +]` with hairlines between segments, `min:`-clamped, and a `unit:` label
  outside the group. An optional `default:` adds a reset segment
  (`Components::ResetButton` `shape: :segment`, tooltip "Reset to n") shown only
  while the value differs, and only when the default lies within `min..max`; no
  default, no reset. A stepper with `default:` must be left-anchored, because the
  reset segment grows the control to the right. `Components::ResetButton` takes `shape:` (`:standalone` bordered
  square, `:segment` inside a joined control). No UI cap (`max:` is optional, for the
  dynamic keyword-count limit); submits as a plain number field.
- **`Components::DurationStepper`** — `NumberStepper` subclass for durations. `base:`
  (`:seconds` / `:minutes`) is the unit the hidden field submits. The unit picker is the
  shared `TomSelect` (`tom_select_fixed_value: true`) skinned as a segment (`.ts-segment`
  in `tom-select.css`): lowercase plural units at or above `base`, between plus and reset.
  It opens on the largest unit that divides the value (the base unit for 0 or empty). The
  form converts client side (like `RangeSlider`), so params and storage keep their unit.
  Reset names the unit ("Reset to 5 minutes"). Above the base unit the input takes
  decimals (`1.5` hours submits 90 minutes, rounded to the base unit); in the base unit it
  stays whole.
- **`Components::RangeSlider`** — native `<input type="range">` styled with tokens;
  shows a percent readout but submits a hidden `0.75`–`1.0` float (converted once).
- **`Components::RadioCardGroup`** — stacked radio options as bordered cards with a
  title + one-line description; native radios, so selection is reactive with no JS.
- **`Components::PrerequisiteSteps`** (a title plus one `Step` per unmet prerequisite) / **`Components::SidebarGroup`** — see *Plugin groups*.
- **`Components::FieldLabel`** / **`Components::FieldHelp`** — the shared label
  and help-text styling for a form field (`<label>` and `<p>` respectively); no
  parameters, block content only. Help goes under the control via `FieldHelp`,
  never between label and control.
- **Option help** — a help line that describes some options of a `SegmentedControl` shows only while one of them is pressed: the card is a named group (`group/setting`), and a wrapper around the `FieldHelp` under the control carries `hidden group-has-[[data-value=<value>][aria-pressed=true]]/setting:block` per option, with `_` in a value written `\_`. It sits under the control so the options do not move when it appears. CSS only (`TwilightStruggle::PlayerDisplayCard`).
- **`Components::RequiredMarker`** — the red asterisk after a required field's
  label; the only required marker. Labels never say "(required)" or "(optional)".
- **`Components::ConfigSections`** — the config-page section stack: renders the
  `<key>-config` div Turbo targets, the vertical `gap-5` rhythm, and the
  danger callout every plugin form was repeating (`enable_error:`).
- **Toggle cards that open** (`Components::Feeds::EventTypeSetting`) — an option with its own settings is a card: a
  `SettingRow` header with a chevron and the toggle at the card edge. Turning it on opens the card and turning it off folds
  it; a click anywhere on the header
  row, apart from the toggle, opens and folds it in either state, so the settings of a type that is off can be read.
  The card is a `<details>`, so the header is its `<summary>` and a keyboard reaches it. The
  accent border follows the checkbox through CSS (`has-[[data-type-toggle]:checked]`); the `disclosure`
  controller owns open and closed (`change->disclosure#follow` on the toggle), remembered in
  `localStorage`. Never put settings behind a loose "Settings" disclosure.
- **`Components::SettingRow`** — one labelled setting: `label:` + optional
  `help:` on the left, the control yielded as a block on the right. `align: :title`
  puts the control on the label's line instead of the middle of the row, so two rows
  side by side line up whether or not they have help; `ToggleRow` uses it. The *only*
  row treatment — `ToggleRow` is this plus a `Toggle`, and the staff-ping
  card is this plus a toggle. The visible label is a `<p>`, not a
  `<label>`: the accessible name belongs on the control (`Components::Toggle`
  carries its own `aria-label`), and a second `<label>` with no `for` only
  duplicates it.
- **`Components::InlineField`** — a setting read as one sentence: `label:` (a
  `<span>`, same reason as `SettingRow`) followed by the control yielded as a
  block, wrapping on narrow widths. Help goes below it as a `FieldHelp`. Used
  where the label leads into the value ("Treat accounts as new for [30] days").
- **`Components::SegmentedControl`** — one-of-N buttons over a hidden input. Pass
  `label:` when the visible label is a `FieldLabel` (no `for`): it names the
  `role="group"` for screen readers.

`Components::Icon` wraps Phosphor; names not in Phosphor (the `megaphone-slash`
sub-plugin glyph) are served from its `CUSTOM_GLYPHS` map of inline SVGs. `steam` is
Valve's mark, its path taken from Simple Icons (CC0); Valve's trademark terms are in the
terms of service.

An icon has to encode something the text does not already carry: state
(`caret-down` on a dropdown summary), identity (a plugin tile), or a symbol the
copy names outright (`at` beside "Allow anyone to @mention this role"). An icon
that pictures a noun the sentence already said is decoration, and a column of
them down a list of one-line facts reads as a generated feature list. The
explainer dropdowns on the Server Shield pages use real lists instead, and the
list type carries the meaning: `ol` on the image-scanning explainer, whose rows
are the pipeline in order, and dash-marked `ul` on the matching explainer, whose
rows are parallel facts. Number a list only where the order is real.

Single `TomSelect` pickers keep a selectable blank option, labelled with the
placeholder, so an optional value can be cleared. A required picker
(`ChannelSelect` takes `required: true`) renders `aria-required="true"`, and
`lib/blank_option` then skips the blank option so the placeholder stays an
unselectable hint. `tom_select_fixed_value: true` marks a short static list (the duration
unit picker): no search box, no clear button, no blank option.

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
`-strong`, `bg-accent-fill` for solid teal buttons (white text holds 4.5:1 in both themes, hover
included — **not** `bg-brand-500`, which fails white-on-teal contrast), `bg-accent-soft` +
`text-accent-soft-fg` for soft-tint chips/avatars, `text-accent` for a teal icon.
Copper is `text-accent-2-text` / `bg-accent-2-soft` / `bg-accent-2-fill` and owns
warmth/wayfinding (donate, OSS badge, the wordmark "bot") — **never** status.
Status colours split by job: `warning`/`danger` (`text-`, `bg-`, `border-`)
colour icons, dots and borders; text set in a status colour uses
`text-warning-text` / `text-danger-text` / `text-success-text`, and solid danger
buttons use `bg-danger-fill`. All hold 4.5:1 in both themes.
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

The theme switch is one of the two signature moments. The new page colour
spreads from the toggle as ink and covers the page in 240ms, the theme changes
under it, and the new theme then opens from the same point in 340ms
(`lib/theme_ink.js`). The ink is a fixed element with `data-theme` set to the
next theme, which is why the light tokens are declared on
`:root, [data-theme="light"]`: the element resolves `--surface-page` for a theme
the page does not have yet. Its background is a radial gradient whose radius is
the registered length `--theme-ink`, so the Web Animations API can animate it.
While it runs, `.theme-inking` on `<html>` turns element transitions off, so
nothing cross-fades under the ink; the toggle's sun/moon icons are exempt and
still morph (`.theme-morph`: they share a cell and rotate, scale and fade past
each other). The same class is the guard: a click while it is set is ignored,
also from a page Turbo loaded in the meantime. The ink is
`data-turbo-temporary`, so a page cached under it comes back without a cover,
and it comes off in a `finally`, so a switch that throws cannot leave the page
covered.

Do not build this on the View Transitions API. Firefox drops blank frames
during any view transition, even on a page with nothing but text, and a
full-page circle makes every one of them visible.

## Motion

Motion explains a change. It has four jobs, and each job has one treatment:

| Job | Where | What moves | In | Out |
| --- | --- | --- | --- | --- |
| Feedback | hover, switches, chevrons, tooltips, copy buttons | colour, or a small turn or slide | 120ms | 120ms |
| Reveal in place | every section that opens inside the page | height | 180ms | 120ms |
| Overlay | menus, toasts, dialogs | opacity and at most 8px of travel | 180ms | 120ms; a dialog closes at once |
| Signature | save bar, theme switch | spring, ink across the page | 420-580ms | 300ms |

Rules:

- A change in layout animates the layout. A fade never stands in for it.
- Leaving is faster than arriving.
- The more often something fires, the smaller it is. Only the two signature
  moments may use a spring or cover the page.
- A page does not animate in, and Turbo navigation stays instant. The one thing
  that moves after a load is a toast that reports the action that caused it.
- Form fields that appear because of a choice (`hidden` toggles: timeout
  length, mode panels, warnings, reset buttons) stay instant.
- No animation library. CSS transitions and keyframes plus the Web Animations
  API cover every case.

Tokens live in `tokens.css`: `--dur-fast` 120ms, `--dur-base` 180ms, `--dur-slow`
260ms, `--ease-standard` for arriving, `--ease-exit` for leaving, `--ease-spring`
for the save bar. `theme.css` points Tailwind's default transition duration and
easing at `--dur-fast` and `--ease-standard`, so a bare `transition-colors` or
`transition-transform` is already on the system; do not add `duration-*` or
`ease-*` to one. The signature moments keep literal durations beside their
keyframes: they sit off the scale on purpose, and each value has one user.

Reduced motion is one global rule at the end of `utilities.css` that collapses
every CSS animation and transition to 0.01ms and turns smooth scrolling off.
`animationend` still fires, so controllers that wait for it need no branch of
their own, and components need no `motion-safe:` variant. Only motion driven
from JavaScript checks `prefers-reduced-motion` itself. One exception, in
`save_bar.css`: the ring on a blocked navigation keeps its fade. It is a colour
change, and without it a refused click shows nothing.

The CSS patterns are in `utilities.css` (`card-lift`, `toast-enter` and
`toast-leave`, the `dialog[open]` entrance, the dropdown/chevron and theme-morph
choreography) and `save_bar.css`. The chamfer
geometry helpers (`chamfer-tile`, `chamfer-tile-sm`, `chamfer-cta`,
`chamfer-bar`) sit beside them and are for brand-forward surfaces only. Buttons
darken on hover (`hover:bg-accent-fill-hover` for primary, a sand wash for the
rest).

## Confirmations

Destructive actions use `data-turbo-confirm` (the body text) plus
`data-confirm-title` and `data-confirm-button`, all three required: the dialog has
no default copy, so a missing title or button label shows up empty. It works on
`button_to` and on `turbo_method` links. Never call `window.confirm` directly. `Components::ConfirmDialog`
is mounted once in the layout, and `lib/confirm_dialog` routes Turbo's confirm
through it.

The dialog cancels on a click outside it, not on a drag that merely ends outside
(selecting text inside the dialog and releasing over the backdrop keeps it open):
both the `mousedown` and the `click` must land on the backdrop.

The dialog and its backdrop fade in through CSS on `dialog[open]`, so any
`<dialog>` gets the entrance. It closes with no animation: the user has just
answered it.

## Layout: flex, not grid

Use flexbox for layout. Reach for CSS grid only when a layout genuinely can't be
done with flex — in practice that's a responsive multi-column **card grid** with
equal tracks (the server picker's `grid-cols-1 sm:grid-cols-2
lg:grid-cols-3` and the home page's plugin grid), where the flex equivalent needs fragile `calc()` basis values.
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

## Notification bell

The bell lives in the `Components::AppShell` top bar. It renders as an eager
Turbo Frame (`id: "notifications"`) that loads `GET /notifications` immediately
on page load — no data is threaded through other controllers or views. Until the
frame resolves a placeholder bell button is shown.

**Dropdown pattern:** `Components::NotificationBell` wraps the bell in a native
`<details>` element with a `data-controller="dropdown"` summary toggle, mirroring
the server-switcher and user-menu. The summary holds the bell icon and the
unread-count badge (only when count > 0, solid accent fill with a surface-card
ring). The menu target holds `Components::NotificationPanel`.

**Panel layout:** header (title, "Mark all read" button_to, scope toggle) +
scrollable body (grouped by server, or flat for the this-server scope) + empty
state when no active notifications.

**Scope toggle:** two links targeting the `notifications` frame —
`notifications_path(server_id: <current>)` for "This server" and
`notifications_path` (no server_id) for "All servers". Active tab = solid card
bg + shadow; inactive = muted text.

**Grouping:** "All servers" renders server-tile headers (initials tile + name)
between groups, sorted by server name. "This server" skips the headers.

**Item:** `Components::NotificationItem` renders a deep link to the plugin config
page, a warning icon circle (full-opacity unread, 60% opacity read), title
(hash icon prefix from the mockup), message, relative time, an unread dot on the
left rail, and a dismiss `button_to` (PATCH to `notification_path`).

**Mobile:** below `sm` the panel becomes a full-width sheet fixed under the app
bar (CSS only — same HTML structure; no JS changes).
