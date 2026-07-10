# shrkbot

A Discord bot with a companion website. All per-server configuration lives on the site; the bot handles Discord interactions and events. For what the bot actually does, see [shrkbot.com](https://shrkbot.com).

This README covers getting the bot running locally. Architecture and how-tos (adding plugins, commands, events) live in [docs/](docs/).

## Prerequisites

* Ruby 4.0.5 (see `.ruby-version`)
* Docker — `docker-compose.yml` provides Postgres and Redis. You can also run the whole app inside compose; the comments in `.env.example` cover both setups.
* A Discord application ([developer portal](https://discord.com/developers/applications)) with:
  * a bot token
  * the **MESSAGE CONTENT** privileged intent enabled (required by Server Shield)
  * the OAuth2 redirect URI `http://localhost:3000/auth/discord/callback` for logging into the local web UI

## Setup

```
cp .env.example .env   # then fill in the blanks — the comments explain each value
docker compose up -d db redis
bin/setup              # installs dependencies, prepares the database, starts the web server
```

In separate terminals:

```
bin/bot    # the gateway connection
bin/jobs   # background jobs (reminder delivery)
```

Set `TEST_SERVER_ID` in `.env` to your test server so guild commands register there instantly. If you work on Scam Image Detection, you'll also need the OCR sidecar: `docker compose --profile ocr up -d ocr`.

## AI-assisted development

If you want to use coding agents but keep them isolated from the rest of your machine, the compose file includes a sandbox: the `dev` container (built from `Dockerfile.dev`) ships Ruby, the GitHub CLI, Claude Code, and Copilot CLI as an unprivileged user, with the repo mounted at `/app`. Secrets (`.env`, `.env.deploy`) are masked inside the container, and the compose file and Dockerfiles are mounted read-only, so the agent can't read your credentials or loosen its own sandbox.

Agent state lives on the host under `~/.ai-sandbox` so it survives container rebuilds. One-time setup:

```
mkdir -p ~/.ai-sandbox/shrkbot/{claude,local-state,local-share}
touch ~/.ai-sandbox/shrkbot/claude.json
```

Then:

* put the git identity the agent should commit with into `~/.ai-sandbox/gitconfig-shrkbot`,
* optionally put a GitHub PAT into `~/.ai-sandbox/github-pat-private` (used for pushes; scope it to this repo),
* make sure `gh auth login` has been run on the host — `~/.config/gh` is mounted in.

Start it with:

```
docker compose run --rm dev bash
```

and run your agent from there. It talks to the same compose Postgres as the other services.

## Contributing

Found a bug, or missing a feature? Open an issue, or send an email to [info@shrkbot.com](mailto:info@shrkbot.com) — both are read. If you'd like to add something yourself, fork the project and open a PR; the how-tos in [docs/](docs/) will get you started. For bigger changes it's worth opening an issue first so we can talk it through before you put the work in.

## Deployment

Deploys to a single box via [Kamal 2](https://kamal-deploy.org) — see [docs/deployment.md](docs/deployment.md).

## License

[MIT](LICENSE)
