# Image for the app processes (web/bot/jobs) in docker-compose.
# Development-oriented for now; production hardening (multi-stage, non-root,
# asset precompile, RAILS_ENV=production) is Phase 9.
FROM ruby:4.0.5-slim

# build-essential: native gem extensions (psych, bootsnap, msgpack…)
# libyaml-dev + pkg-config: psych · libpq-dev: pg · git: discordrb is a git gem
RUN apt-get update -qq \
  && apt-get install --no-install-recommends -y \
       build-essential libyaml-dev pkg-config libpq-dev git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Gems first, for layer caching.
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

# Overridden per service in docker-compose.yml.
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]