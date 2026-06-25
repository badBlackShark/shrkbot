# shrkbot DS refresh — implementation handoff (for Sonnet)

You are implementing a locked design-direction refresh of the **shrkbot design system**. All
creative decisions are made; this is a faithful rollout. Do NOT relitigate the direction.
Read `tokens/colors.css` and `tokens/spacing.css` first — the new tokens are already written
there and are the source of truth. The visual targets live in `explorations/dark-copper.html`
(panel **B**), `explorations/direction-mock.html`, and `explorations/dark-palettes.html`.

## The four locked decisions

1. **Dark mode = warm espresso** (panel B of `explorations/dark-copper.html`). The old "cool
   teal-tinted" dark mode is gone. Tokens are already updated in `tokens/colors.css` under
   `[data-theme="dark"]`: warm espresso surfaces, a softened "patina" teal for controls, and
   **copper used liberally** (active-nav, section eyebrows, donate/support, wordmark "bot").
   Light mode is UNCHANGED.

2. **Copper has a real, recurring job**: warmth / community / **wayfinding** — NEVER status
   (status stays green/amber/red). Light mode keeps copper light-touch (donate, OSS badge,
   "made with ♥", wordmark "bot"). Dark mode adds: active-nav indicator (`--nav-active`),
   section eyebrows/labels (`--eyebrow`), the support/donate callout. Use the aliases already
   in `colors.css` (`--accent-2-text`, `--accent-2-fill`, `--nav-active`, `--eyebrow`) — don't
   hardcode copper hexes in components.

3. **Geometry = the chamfer** (machined cut-corner), the mascot's missing geometry. Tokens
   `--chamfer` (12px) and `--chamfer-sm` (6px) are in `tokens/spacing.css` with the technique
   documented there. Apply ONLY to brand-forward surfaces: top app-bar, plugin-identity tiles
   (chamfered/octagon, replacing the rounded tiles), the mascot lockup frame, primary CTA.
   **Everyday cards, inputs, chips KEEP their rounded radii** — the soft-body/sharp-metal
   contrast is intentional. For bordered chamfered elements use the two-layer even-border
   technique (outer = border color + 1px pad + chamfer(c); inner = fill + chamfer(c-1px)) —
   `clip-path` alone slices the border off the diagonals and looks wonky.

4. **Icons = Phosphor, one-tone** (NOT two-tone — teal/copper are near-complementary and
   vibrate inside a small glyph). Replace Heroicons/Lucide. The Rails gem is
   `maful/ruby-phosphor-icons` (production); for prototype HTML use the Phosphor web CDN
   `@phosphor-icons/web`. Standardize weights: **Regular** workhorse, **Bold** for
   active/emphasis, **Fill** for a white icon inside a filled teal tile. Reassign plugin icons:
   - Roles → `users-three`
   - Welcomes → `hand-waving`
   - Logging → `scroll`
   - Reminders → `bell-ringing`  (currently a clock — change it)

## Files to update (rollout)

- **`ui_kits/dashboard/index.html`** — biggest job. (a) Remove the old hardcoded teal-tinted
  dark `!important` overrides (the `[data-theme="dark"] ...` block and the `.copper-badge`,
  `[data-gate-overlay]` overrides) and rely on the new tokens; reconcile the save-bar-blocked
  copper shake. (b) Swap all icons to Phosphor (web CDN) with the weights above + the plugin
  reassignments. (c) Apply chamfer to the top app-bar + plugin-identity tiles + primary CTA.
  (d) In dark, route active-nav → `--nav-active`, section labels → `--eyebrow`, donate/support
  → copper. Keep the Tailwind config's `copper`/`brand`/`ink` scales.
- **`components/controls.card.html`** & **`components/patterns.card.html`** — Phosphor swap;
  chamfer on the plugin-row identity tile; copper "Pro tip" badge stays (it's personality, fine).
- **`foundations/dark-mode.html`** — rebuild to show the NEW espresso palette + copper roles
  (it currently shows the old teal-tinted swatches and a Lucide-ish inline SVG). Mirror the
  swatch set to the new tokens.
- **`foundations/color-copper.html`** — update rationale text (fin-spring, not neck-ring;
  warmth/community/wayfinding; liberal in dark) and show the new dark copper usages.
- **`foundations/radii.html`** (and/or a new `foundations/geometry.html` card) — add the chamfer
  as the geometric signature; show the chamfered tile + even-border technique.
- **`landing.html`** — Phosphor icons; chamfer on header bar + primary CTA; confirm wordmark
  (teal `shrk` + copper `bot`) and footer "♥" use copper aliases.
- **`tailwind/theme.css`** — mirror the new tokens so utilities work: the espresso dark surface
  values, softened-teal accent, copper expanded aliases, and `--chamfer*`. Verify dark utilities
  resolve via the `[data-theme="dark"]` selector.
- **`README.md`** — correct: (1) copper rationale = fin-spring + warmth/community/wayfinding,
  never status, liberal in dark; (2) dark mode = warm espresso + softened patina teal + liberal
  copper (replace "cool teal-tinted"); (3) Iconography = Phosphor (gem + web CDN), one-weight
  rule, one-tone, the plugin reassignments; (4) soften the "differentiated radii echo the
  mascot's geometry" overclaim — the chamfer is now the real geometric signature; (5) keep
  lowercase shrkbot / sentence-case / no em dashes voice rules.

## Deferred (do NOT silently resolve — confirm with the user)

- **Body font (Exo 2 vs IBM Plex Sans).** `--font-sans` is **Exo 2** (the chosen body/UI face),
  but Exo 2 only loads via the Google Fonts CDN — see the `TODO(self-host)` at the top of
  `tokens/fonts.css` — which clashes with the project's **no-CDN-in-production** policy.
  Meanwhile **IBM Plex Sans is already fully self-hosted** under `packages/plex-sans/` with
  `@font-face` blocks in `fonts.css`, but nothing references it. This was deferred to
  implementation. Two paths: (a) **self-host Exo 2** — download the OFL woff2 files, drop them
  under `fonts/exo2/`, add `@font-face` blocks, remove the `@import`; or (b) **switch
  `--font-sans` to the already-vendored IBM Plex Sans** and drop Exo 2. Don't pick silently —
  surface the tradeoff and let the user decide. Out of scope for the color/geometry/icon
  rollout above; treat as a separate task.

## Guardrails
- Voice: shrkbot always lowercase, sentence-case headings, **no em dashes** (single dashes ok),
  explain *why* for disabled/blocked states. Don't introduce emoji (typed emoticons `:)` `<3`
  only, in warm long-form copy).
- Don't touch light-mode color values. Don't change the type system, spacing grid, or motion.
- Don't reintroduce two-tone icons. Don't chamfer everyday cards/inputs/chips.
- After editing, run `check_design_system` and fix anything it reports until clean. Spot-check
  both light and dark in the dashboard and specimen cards.
- The exploration files in `explorations/` are reference only — you can delete them at the end
  if you like, but confirm with the user first.
