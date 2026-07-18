source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Render views as Ruby objects [https://www.phlex.fun]
gem "phlex-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# --- shrkbot ---
# Discord bot library (the gateway bot lives in app/bot, run via bin/bot).
# Tracking main: releases are infrequent and we want to stay current with the Discord API.
# require:false so only bin/bot loads it — keeps the web/console processes lean
# and avoids the libsodium/voice warning everywhere.
gem "discordrb", github: "shardlab/discordrb", branch: "main", require: false
# Discord OAuth2 login for the web config UI
gem "omniauth-discord"
gem "omniauth-rails_csrf_protection"
# Redis: web->bot config propagation (pub/sub) and background jobs
gem "redis"
# Phosphor Icons as inline SVG for the web UI
gem "phosphor_icons"
# Catches migrations unsafe under rolling deploys (dropped columns, renames)
gem "strong_migrations"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 2.0"

# Load env vars from .env in dev/test (12-factor; prod uses real env). Lives in
# the default group so the runtime image keeps it when dev/test gems are pruned;
# dotenv-rails only auto-loads .env in dev/test, so it stays inert in production.
gem "dotenv-rails"

# See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
gem "debug", platforms: %i[mri windows], require: "debug/prelude"

group :development, :test do
  # House test framework + test-data factories
  gem "rspec-rails"
  gem "factory_bot_rails"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis security scanner for app code (use config/brakeman.ignore to baseline)
  gem "brakeman", require: false

  # Ruby styling/linting
  gem "standard", require: false

  gem "ruby-lsp", require: false

  gem "active_record_doctor"

  # Lints locale files: missing/unused keys, normalization
  gem "i18n-tasks", require: false

  gem "simplecov", require: false
  gem "simplecov-lcov", require: false

  gem "undercover", "0.8.5", require: false

  # Advisory code-smell + structural-duplication analysis (SRP/DRY signal); non-blocking
  gem "reek", require: false
  gem "flay", require: false

  # N+1 query detection in the test suite (raises on offending specs)
  gem "prosopite", require: false
  gem "pg_query", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false
