# Dependency updates

Dependabot opens security PRs only for advisories in GitHub's reviewed Advisory
Database. bundler-audit reads the rubysec database, which often lists an
advisory days earlier. The Puma advisories of 2026-11 never reached GitHub's
database, so `main` went red with no PR to fix it.

`.github/workflows/security-updates.yml` closes that gap. It runs nightly and on
demand (`workflow_dispatch`), one run at a time:

1. The `update` job fetches the rubysec database and runs `bin/security-updates`,
   a thin wrapper over `lib/security_updates/`. It audits the gems and the
   importmap pins, resolves each vulnerable gem with `bundle lock --update --conservative`,
   re-pins each vulnerable pin with `bin/importmap pin`, and audits again. It
   writes the PR body, with old and new versions for gems and pins. It exits 2
   when an advisory has no fix, and any other failure keeps its own exit code.
2. The `open-pr` job (`.github/workflows/open-pr.yml`, shared with the Bundler
   workflow) opens or updates a standing `security-updates` PR. When the change
   is already on `main`, the branch is deleted and the PR closes.
3. The run fails only when an advisory remains, and the `update` job's summary
   lists it. A red run here means a manual fix is needed: a version constraint
   in the `Gemfile`, or an advisory with no patched release.

`bin/importmap pin` takes the newest release, so a pin fix can be a major
version bump. The PR body shows the old and new version.

Each run rebuilds the PR branch from `main` and force-pushes it. A commit pushed
by hand to `security-updates` is lost on the next run, so a manual fix belongs
on its own branch.

The update job never installs or runs a new version. `bundle lock --update`
resolves the fixed versions into `Gemfile.lock` without installing them, and the
re-audit reads the lockfile in-process. The nightly run happens on `main`, so
code running there could write to the Actions cache that later `main` runs
restore. A new version first runs in CI on the security PR, where the cache is
scoped to the PR and no secrets exist, as on a Dependabot PR. The update job
also holds no secrets. The `open-pr` job holds the `SECURITY_PR_TOKEN`
repository secret and runs no package code: it checks out `main`, refuses
symlinks, copies the changed paths from the update job's artifact, and opens the
PR. The token is fine-grained, with write access to Contents and Pull requests
on this repository only. A PR opened with the built-in `GITHUB_TOKEN` would not
trigger CI.

`bundle update --bundler` in the Bundler workflow does run the new Bundler on
`main`. That residual risk is accepted: Bundler ships with Ruby itself, and a
compromised release would reach every Ruby CI at once.

Ignored gem advisories go in `config/bundler-audit.yml`, which both
`bin/bundler-audit check` and the workflow honour. Pin advisories have no ignore
list, so an npm advisory that does not apply here still turns the run red until
the pin moves.

`Gemfile.lock` lists the `ruby` platform. Dependabot's resolver writes generic
variants of native gems (`nokogiri`, `ffi`, `mini_portile2`) that a plain Bundler
resolve drops, so each security PR removed them and the next Dependabot PR added
them back. With `ruby` locked, Bundler needs those variants too and both agree.
Installs still pick the precompiled platform builds.

Dependabot never changes the `BUNDLED WITH` version: it writes the old one back
after every update. It resolves with the newest Bundler, though, so a stale pin
makes the two write different lockfiles. `.github/workflows/bundler-update.yml`
runs weekly (and on `workflow_dispatch`), runs `bundle update --bundler`, and
opens or updates a `bundler-update` PR when a newer Bundler exists. It uses the
same token as the security workflow.
