---
name: shrkbot-design
description: Use this skill to generate well-branded interfaces and assets for shrkbot (a modular Discord bot), either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colors, type, fonts, assets, and the web-config UI kit for prototyping.
user-invocable: true
---

Read the `README.md` file within this skill, and explore the other available files.

shrkbot's stack is **Ruby on Rails 8.1 · Phlex · Tailwind CSS v4 · Hotwire (Turbo + Stimulus) · Tom Select — NO React, no heavy front-end frameworks.** Match it: produce **static HTML + Tailwind** (it ports ~1:1 to Phlex), Stimulus for behavior, Tom Select for searchable dropdowns. Tokens live in `tokens/*.css` (source of truth) with a Tailwind v4 mirror in `tailwind/theme.css`.

Key brand facts: one accent — sky **`#39afe5`**; cool slate neutrals; type is Space Grotesk (display) / Hanken Grotesk (UI) / JetBrains Mono (code). shrkbot is **always lowercase**; voice is warm, transparent, modest; sentence case; explain *why* on blocked states. Icons: Lucide (or Heroicons). The mascot is `assets/shrkbot-mascot.png`.

If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy assets out and create static HTML files for the user to view. If working on production code, copy assets and read the rules here to become an expert in designing with this brand.

If the user invokes this skill without any other guidance, ask them what they want to build or design, ask some questions, and act as an expert designer who outputs HTML artifacts _or_ production code (HTML + Tailwind, Phlex-ready), depending on the need.
