# Deployment

shrkbot deploys to a single Hetzner box via [Kamal 2](https://kamal-deploy.org).
One Docker image, three processes (web/bot/jobs) plus managed accessories
(Postgres, Redis), all orchestrated by Kamal from your laptop.

## Prerequisites

### Server
- Hetzner box running Docker + docker-compose (pre-installed).
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

## Secrets

Create a gitignored `.deploy.env` on your laptop and source it before deploying:

```sh
source .deploy.env
```

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

## First deploy

```sh
source .deploy.env
bin/kamal setup
```

`kamal setup` boots the db and redis accessories, builds the amd64 image, pushes it
to GHCR, starts the web/bot/jobs processes, and has kamal-proxy provision the TLS
certificate. Migrations run automatically on web boot via the entrypoint
(`RUN_DB_PREPARE=1` is set on the web role only, so the three processes don't race).

## Redeploys

```sh
source .deploy.env
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

# Roll back to the previous image
bin/kamal rollback
```

## HTTPS

kamal-proxy handles TLS automatically. It provisions Let's Encrypt certificates on
first boot and renews them before expiry, persisting them in its own volume.
Nothing to manage manually.
