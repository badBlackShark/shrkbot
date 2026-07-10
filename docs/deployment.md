# Deployment

shrkbot deploys to a single Hetzner box via [Kamal 2](https://kamal-deploy.org).
One Docker image, three processes (web/bot/jobs) plus managed accessories
(Postgres, Redis, the OCR sidecar), all orchestrated by Kamal from your laptop.

## Prerequisites

### Server
- Hetzner box running Docker (pre-installed).
- DNS A-records for **both** `shrkbot.com` and `www.shrkbot.com` pointing at the
  box IP — these must resolve before the first deploy; kamal-proxy's Let's Encrypt
  HTTP-01 challenge needs them resolving correctly.
- Your SSH public key added to the box: `ssh-copy-id root@<ip>`, reachable via
  ssh-agent during the deploy.

### Laptop
- Kamal available: `bundle install` (run once after adding the gem).
- A GitHub Personal Access Token with `write:packages` scope for pushing to GHCR.

### Discord Developer Portal
Add the OAuth2 redirect URI `https://shrkbot.com/auth/discord/callback` under your
application's OAuth2 settings.

#### Privileged Gateway Intents

The **Server Shield / spam protection** feature requires the **MESSAGE CONTENT**
privileged intent. Enable it under your application's **Bot → Privileged Gateway
Intents** section in the Discord Developer Portal. Without it Discord sends
`event.message.content` as an empty string, so content-based spam detection will
not fire.

#### Invite permissions

The invite link's permission set must include everything Server Shield acts with:

- **View Audit Log** — moderation action logging (timeout, kick, ban attribution)
- **Mention @everyone, @here and All Roles** — staff-role pings on flag/notify posts
- **Manage Messages** — spam purge and scam image removal
- **Moderate Members** — the timeout punishment
- **Kick Members** / **Ban Members** — only needed when a server configures those
  punishments

Re-invite the bot with the updated link if it was originally invited with fewer
permissions.

## Secrets

Create a gitignored `.env.deploy` in the repo root on your laptop.
`config/deploy.yml` loads it itself (Kamal 2 no longer autoloads dotenv files),
so no `source` step is needed.

Variable reference:

| Variable | How to get it |
|---|---|
| `DEPLOY_HOST` | Box IP address |
| `KAMAL_REGISTRY_PASSWORD` | GHCR PAT (write:packages scope) |
| `SECRET_KEY_BASE` | `bin/rails secret` |
| `APP_DATABASE_PASSWORD` | Strong random string; **same value becomes `POSTGRES_PASSWORD`** |
| `DISCORD_TOKEN` | Bot token from Discord Developer Portal |
| `CLIENT_ID` | Bot application ID from Discord Developer Portal |
| `OWNER_ID` | Your personal Discord user snowflake |
| `DISCORD_CLIENT_ID` | OAuth2 client ID from Discord Developer Portal |
| `DISCORD_CLIENT_SECRET` | OAuth2 client secret from Discord Developer Portal |

Alternatively, use `kamal secrets fetch` with a secrets manager — see
[Kamal docs on secrets](https://kamal-deploy.org/docs/configuration/secrets/).

## OCR sidecar image

The Scam Image Detection feature talks to a Python OCR sidecar (`ocr/`), deployed
as the `ocr` Kamal accessory. Kamal only pulls the accessory image — build and push
it manually whenever `ocr/` changes:

```sh
docker build --platform linux/amd64 -t ghcr.io/badblackshark/shrkbot-ocr:latest ocr/
docker push ghcr.io/badblackshark/shrkbot-ocr:latest
```

`--platform linux/amd64` is mandatory on Apple Silicon: paddlepaddle aarch64 wheels
segfault at inference, so an arm64 image would build fine and then crash on every
scan (and the emulated image cannot be smoke-tested locally either — PaddleOCR
initialisation hangs under Rosetta; see `ocr/README.md`). Verify against the
deployed box instead.

Then boot (first time) or restart (after a push) the accessory:

```sh
bin/kamal accessory boot ocr     # first deploy
bin/kamal accessory reboot ocr   # picks up a newly pushed image
```

Operational notes:

- PaddleOCR models download on first start into the `shrkbot_ocr_models` volume,
  so restarts don't re-download them. First boot takes a few minutes; the
  container's Docker health check (`GET /health`, 180s start period) shows
  `healthy` once the model is loaded — check with `docker ps` on the box or
  `bin/kamal accessory details ocr`.
- The app reaches it as `http://shrkbot-ocr:8000` (`OCR_URL` in `deploy.yml`);
  the accessory is not exposed through kamal-proxy.

## First deploy

```sh
bin/kamal setup
```

`kamal setup` boots the accessories (db, redis, ocr — push the sidecar image
first, see above), builds the amd64 app image, pushes it to GHCR, starts the
web/bot/jobs processes, and has kamal-proxy provision the TLS certificate.
Migrations run automatically on web boot via the entrypoint (`RUN_DB_PREPARE=1`
is set on the web role only, so the three processes don't race).

## Redeploys

```sh
bin/kamal deploy
```

## Ops cheatsheet

```sh
# Tail bot logs
bin/kamal app logs -r bot -f

# Rails console on the web process
bin/kamal app exec -r web "bin/rails console"

# Postgres accessory logs
bin/kamal accessory logs db

# OCR sidecar logs
bin/kamal accessory logs ocr

# Roll back to the previous image
bin/kamal rollback
```

## HTTPS

kamal-proxy handles TLS automatically. It provisions Let's Encrypt certificates on
first boot and renews them before expiry, persisting them in its own volume.
Nothing to manage manually.
