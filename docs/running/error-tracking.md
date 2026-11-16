# Error tracking

shrkbot reports errors, performance traces and one cron check-in to
[Sentry](https://sentry.io). The SDK reads `SENTRY_DSN` from the environment and
sends nothing without it, so a self-hosted copy runs without a Sentry account.

## What each process sends

| Process | Errors | Traces |
|---|---|---|
| web | every unhandled exception in a request | every request |
| jobs | a job's exception once its retries are used up | every job run |
| bot | every exception rescued in a command, an event handler or the config subscriber | none |

A retried job stays quiet until `retry_on` gives up, the same rule the owner DM
follows: a passing blip is not an issue.

Bot errors go through `Bot::ErrorReporter`, which logs the error, hands it to
`Rails.error` and DMs the owner. Sentry subscribes to `Rails.error`
(`config.rails.register_error_subscriber`), so anything else reported there
arrives too, Solid Queue's own thread errors included. In Sentry a bot error
carries the tags `source:bot` and `origin`, for example `origin:command /remind`.

The release is the deployed git SHA: the SDK reads `KAMAL_VERSION`, which Kamal
sets in every container.

## Privacy limits

The privacy policy names what a report holds, and the SDK settings behind that
promise are pinned in `spec/config/sentry_spec.rb`, so a dependency bump that
flips a default fails the suite. Three things stay off:

- `send_default_pii` and every `data_collection` category: no user identity,
  cookies, request bodies, query strings, query values, job arguments or local
  variables.
- The `:http_logger` breadcrumbs: the bot answers interactions on URLs that carry
  the interaction token in the path.
- Log forwarding: log lines can quote what a handler was processing.

## Cron monitor

The Developer plan has one cron monitor seat. It watches
`integrations_stranded_event_dispatch`, which runs every 5 minutes, so a missed
check-in means the scheduler or the worker is down. Every other task in
`config/recurring.yml` is excluded in `config/initializers/sentry.rb`; with more
seats, delete that line and each task gets its own monitor.

## Retention

Sentry sets retention by plan and has no setting to shorten it. The Developer
plan keeps everything for 30 days; a trial or a Team or Business plan keeps
errors for 90. The privacy policy promises "at most 90 days" so it holds on
every plan.

## Local setup

Put the DSN in `.env` as `SENTRY_DSN`. Development sends; the test suite never
does, although it loads the same `.env`.
