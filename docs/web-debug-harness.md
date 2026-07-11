# Web debug harness

Boots the website with **stubbed Discord auth** and a **seeded fixture guild**, so the
UI can be driven by a real browser (manually or via Playwright) without OAuth or a live
bot. Built for debugging client-side behaviour — Turbo submissions, Stimulus
controllers, dialogs — that request specs can't see.

## Boot

```sh
bin/web-debug          # serves on 127.0.0.1:3123 (PORT overrides)
```

Everything is gated behind `WEB_DEBUG=1` **and** `Rails.env.development?`
(`config/initializers/web_debug.rb`) — the initializer is inert in test and
production. On boot it:

- puts OmniAuth in test mode with a mock Discord identity (uid `12345`),
- stubs `Bot::Discord::UserGuilds.call` to return one fixture guild
  (`Dev Refuge`, id `900000001`, owner),
- idempotently seeds that guild: server configuration, the four plugin rows +
  activations (all disabled), settings rows, a `Moderator` role (id 500) and a
  `#mod-log` channel (id 111).

The seed never toggles state back — flip things in the UI or via `bin/rails runner`.

## Log in inside the browser

Visit `/auth/discord/callback` once (OmniAuth test mode completes the session), then
`/servers/900000001` to authorize the guild for the session. From there every page
works as a signed-in owner.

## Driving with Playwright

Playwright is not a project dependency — install it in a scratch directory:

```sh
mkdir -p /tmp/pw && cd /tmp/pw
npm install playwright
npx playwright install chromium
```

Minimal script (`node drive.mjs`):

```js
import { chromium } from "playwright"

const BASE = "http://127.0.0.1:3123"
const browser = await chromium.launch()
const page = await browser.newPage()
page.on("dialog", async (d) => { console.log("DIALOG", d.type(), d.message()); await d.accept() })
page.on("pageerror", (e) => console.log("PAGEERROR", e.message))
page.on("response", (r) => { if (r.status() >= 400) console.log(r.status(), r.url()) })

await page.goto(`${BASE}/auth/discord/callback`)
await page.goto(`${BASE}/servers/900000001`)
await page.goto(`${BASE}/servers/900000001/moderation`)
// interact + assert…
await browser.close()
```

Useful listeners when hunting Turbo/Stimulus bugs: `dialog` (beforeunload prompts mean
a NATIVE form submission slipped past Turbo), `pageerror` (a Stimulus controller
exception often degrades silently), and `response` for 4xx/5xx that Turbo swallows.

Toggles use `sr-only` checkboxes — click them with `{ force: true }` or click the
wrapping label.

## Resetting state

```sh
WEB_DEBUG=1 bin/rails runner 'ServerConfiguration.find_by(discord_id: 900_000_001)&.destroy!'
```

Next boot reseeds from scratch (the guild purge cascade removes everything hanging off
the configuration).
