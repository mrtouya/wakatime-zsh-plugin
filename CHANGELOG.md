# Changelog


## Version 0.3.0

### Improvements

- **New env vars for fine-grained control:**
  - `WAKATIME_CATEGORY` — passed as `--category` (e.g. `coding`, `debugging`, `building`).
  - `WAKATIME_LANGUAGE` — override the default `--language sh`.
  - `WAKATIME_HOSTNAME` — passed as `--hostname` for multi-machine setups.
  - `WAKATIME_IGNORE_REGEX` — zsh-extended regex matched against the command's first token; matches are skipped silently (e.g. `^(ls|cd|clear)$`).
  - `WAKATIME_LOG` — optional path to capture wakatime-cli stderr for debugging.
  - `WAKATIME_EXTRA_ARGS` — array of extra arguments appended verbatim to every `wakatime-cli` invocation.
- Env var truthiness: `WAKATIME_DO_NOT_TRACK` and `WAKATIME_DISABLE_OFFLINE` now accept `1`, `true`, `yes`, and `on` (case-insensitive) instead of only numeric `1`.
- Skip empty commands (bare Enter, or commands hidden by `HIST_IGNORE_SPACE`) instead of sending empty heartbeats.
- Zsh-native parsing of the command history — replaced `echo | cut` subshell with the built-in `(z)` word-splitter, removing a fork per command.
- Executable check now uses `[[ -x ]]` with a `command -v` fallback, so both absolute paths and bare command names work.
- Install-missing message updated to recommend `brew install wakatime-cli` first, with `curl -fsSL` (instead of `wget`) for the Python bootstrap fallback.
- Bumped `--plugin` identifier to `zsh-wakatime/0.3.0`.

### Tooling

- Replaced the dead Travis CI setup with a GitHub Actions workflow running `shellcheck` and a `zsh -n` syntax check on every push/PR.
- Refreshed README: modernized install instructions (Homebrew-first), documented all env vars, added Warp terminal notes, added `zinit`/`zplug`/`sheldon` snippets.


## Version 0.2.2

### Bugfixes

- Rename the plugin user-agent identifier from `wakatime-zsh-plugin/<ver>` to `zsh-wakatime/<ver>` so Wakapi's `ParseUserAgent` regex correctly extracts editor and OS fields ([#24](https://github.com/sobolevn/wakatime-zsh-plugin/pull/24)).
- Resolve `.wakatime-project` from the git repository root when not present in the current directory ([#23](https://github.com/sobolevn/wakatime-zsh-plugin/pull/23)). Previously the file was ignored when running commands from a subdirectory.
- When inside a git repo without a `.wakatime-project` file, omit `--project` so `wakatime-cli` can auto-detect (e.g. from `project_from_git_remote`) instead of always using the git toplevel basename ([#23](https://github.com/sobolevn/wakatime-zsh-plugin/pull/23)).
- Replace `~` tilde with `$HOME` in the default `ZSH_WAKATIME_BIN` so the path expands correctly under all quoting contexts ([#21](https://github.com/sobolevn/wakatime-zsh-plugin/pull/21)).

### Improvements

- Support the new Go-based `wakatime-cli` binary (replaces the retired Python `wakatime` package). Default binary path is now `~/.wakatime/wakatime-cli` ([#19](https://github.com/sobolevn/wakatime-zsh-plugin/pull/19)).


## Version 0.2.1

### Improvements

- Allow a custom `wakatime-cli` path via the `ZSH_WAKATIME_BIN` environment variable ([#15](https://github.com/sobolevn/wakatime-zsh-plugin/pull/15)).


## Version 0.2.0

### Improvements

- Addresses review from Reddit: removes useless functions, improves performance.

### Bugfixes

- Fixes how `should_work_offline` work.


## Version 0.1.1

### Improvements

- Linting fixes.


## Version 0.1.0

### Improvements

- Bumps `wakatime` to `12.0`.
- Adds `$WAKATIME_TIMEOUT` option.
- Adds `$WAKATIME_DISABLE_OFFLINE` option.

### Bugfixes

- Now exceptions from `wakatime` are visible in the console.


## Version 0.0.2

### Improvements

- Now calls to `wakatime` server are async.
- If `wakatime` cli is not installed, plugin will tell users about it.

### Bugfixes

- Fixed the bug with `$WAKATIME_DO_NOT_TRACK` killing the shell.


## Version 0.0.1

- Initial release.
