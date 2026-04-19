# pi

pi config lives here at `.pi/agent/` and is rsynced to `~/.pi/agent/` by `scripts/bootstrap-macos.sh`.

First run on a new machine:

1. `./scripts/bootstrap-macos.sh` — copies `settings.json`, themes, etc.
2. `pi` — reads `settings.json`, installs the listed packages, prompts login.
