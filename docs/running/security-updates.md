# Security updates

Dependabot opens security PRs only for advisories in GitHub's reviewed Advisory
Database. bundler-audit reads the rubysec database, which often lists an
advisory days earlier. The Puma advisories of 2026-11 never reached GitHub's
database, so `main` went red with no PR to fix it.

`.github/workflows/security-updates.yml` closes that gap. It runs nightly and on
demand (`workflow_dispatch`):

1. `bin/bundler-audit update` fetches the rubysec database.
2. `bin/security-updates` audits the gems and the importmap pins. It updates each
   vulnerable gem with `bundle update --conservative` and re-pins each vulnerable
   pin with `bin/importmap pin`, then audits again. It writes the PR body and
   exits non-zero when an advisory has no fix.
3. A standing `security-updates` PR is opened or updated with the change. When
   the change is already on `main`, the branch is deleted and the PR closes.
4. The run fails only when an advisory remains, and the run summary lists it.
   A red run here means a manual fix is needed: a version constraint in the
   `Gemfile`, or an advisory with no patched release.

The PR is opened with the `SECURITY_PR_TOKEN` repository secret, a fine-grained
token with write access to Contents and Pull requests on this repository only.
A PR opened with the built-in `GITHUB_TOKEN` would not trigger CI.

Ignored advisories go in `config/bundler-audit.yml`, which both
`bin/bundler-audit check` and the workflow honour.
