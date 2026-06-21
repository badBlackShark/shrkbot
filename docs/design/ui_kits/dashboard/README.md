# shrkbot UI kit — Web config dashboard

A high-fidelity, click-through recreation of shrkbot's **web configuration dashboard** (the Rails/Phlex "Phase 7" surface). It is built the way the real app is built — **static HTML + Tailwind utility classes + a thin layer of vanilla JS** standing in for Hotwire/Stimulus — so the markup ports ~1:1 into Phlex components.

## Run it
Open `index.html`. It is fully self-contained (Tailwind Play CDN + Lucide + Google Fonts over the network). No build step.

## Flow
`Login → Server picker → Server dashboard → Roles config page`

- **Login** — single "Continue with Discord" action (Discord OAuth in production).
- **Server picker** — your manageable servers (admin **and** bot present), servers missing the bot show an *Invite* affordance, plus the empty-state pattern.
- **App shell** — top bar with logo, **server switcher**, and user/logout menu; frames every authed screen. A quiet "Saved" pill appears on change.
- **Server dashboard** — the three configurable plugins (**Roles, Welcomes, Logging**) with enable toggles + at-a-glance status, the server-level *force-DM-reminders* setting, and a note that Reminders are slash-command-only.
- **Roles config page** — the hard case: plugin header + enable-gate (settings stay visible but inert when off), default channel, role-set list, and an expanded **set editor** with single/multi type, channel override, and the **multi-select role picker that greys out roles shrkbot can't assign** (above its highest role / Discord-managed) with a "why" explanation. Changes auto-save (toast + pill).

## How it maps to production
| Mock | Production |
|---|---|
| Tailwind Play CDN + inline `tailwind.config` | Tailwind v4 with `tailwind/theme.css` (`@theme`) compiled from Phlex `.rb` views |
| `.shrk-switch`, segmented control, `.shrk-select` (vanilla JS) | Stimulus controllers |
| `.shrk-select` dropdowns | **Tom Select** |
| `toast()` + "Saved" pill | Turbo form submit + flash |
| `data-screen` / `data-view` routing | Real routes / Turbo frames |

All sample data is placeholder — no real Discord users or servers.

## Patterns demonstrated (from the design brief)
App shell · plugin config page template · enable-gate · setting row with inline warning · switch + single/multi select · disabled-with-reason grey-out · auto-save feedback · empty states.
