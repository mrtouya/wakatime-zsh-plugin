# wakatime-zsh-plugin
#
# Documentation is available at:
# https://github.com/mrtouya/wakatime-zsh-plugin

# Internal helper: returns 0 when $1 is a "truthy" string (1, true, yes, on)
# so env vars like WAKATIME_DO_NOT_TRACK=true work as expected.
_wakatime_is_truthy() {
  case "${1:l}" in
    1|true|yes|on) return 0 ;;
    *)             return 1 ;;
  esac
}

_wakatime_heartbeat() {
  # Sends a heartbeat to the wakatime server before each command.
  # Can be disabled by setting any of:
  #   WAKATIME_DO_NOT_TRACK=1 (or true/yes/on) — skip every heartbeat
  if _wakatime_is_truthy "$WAKATIME_DO_NOT_TRACK"; then
    return
  fi

  # Set a custom path for the wakatime-cli binary,
  # otherwise use the default `~/.wakatime/wakatime-cli` symlink
  # created by the install_cli.py script or the Homebrew formula.
  local wakatime_bin="${ZSH_WAKATIME_BIN:=$HOME/.wakatime/wakatime-cli}"

  # Check that `wakatime-cli` exists and is executable.
  # `[[ -x ]]` works for both absolute paths and names that resolve via $PATH
  # (when the user sets ZSH_WAKATIME_BIN to a bare command name, we fall back
  # to a `command -v` lookup so it behaves like a PATH-aware check).
  if [[ ! -x "$wakatime_bin" ]]; then
    local resolved
    resolved=$(command -v "$wakatime_bin" 2>/dev/null)
    if [[ -z "$resolved" || ! -x "$resolved" ]]; then
      echo 'wakatime-cli is not installed. Install one of:'
      echo '  macOS (recommended): brew install wakatime-cli'
      echo '  Cross-platform:      python3 -c "$(curl -fsSL https://raw.githubusercontent.com/wakatime/vim-wakatime/master/scripts/install_cli.py)"'
      echo '  Manual download:     https://github.com/wakatime/wakatime-cli/releases/latest'
      echo
      echo 'Or set $ZSH_WAKATIME_BIN to a valid wakatime-cli path.'
      echo 'Time is not tracked for now.'
      return
    fi
    wakatime_bin="$resolved"
  fi

  # Extract the last command's first token as the entity.
  # Using zsh's (z) word-splitter avoids forking to `cut`/`awk`.
  # We only send the first word (usually a binary) — no arguments,
  # so sensitive data in flags/paths never leaves the machine.
  local last_command
  last_command=${${(z)history[$HISTCMD]}[1]}

  # Skip empty commands (e.g. a bare Enter key, or HIST_IGNORE_SPACE commands).
  if [[ -z "$last_command" ]]; then
    return
  fi

  # Optional user-supplied regex: when the command matches, skip tracking.
  # Matched against the first token only (the same value sent as --entity).
  # Example: export WAKATIME_IGNORE_REGEX='^(ls|cd|clear|pwd|exit)$'
  if [[ -n "$WAKATIME_IGNORE_REGEX" ]] && [[ "$last_command" =~ $WAKATIME_IGNORE_REGEX ]]; then
    return
  fi

  # Determine the project name.
  local root_directory
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)

  # Look for `.wakatime-project` first in the current directory,
  # then at the git repository root (if we are inside a git repo).
  # If found, read the first line to get the project name.
  #
  # Note: we read the file ourselves rather than letting wakatime-cli
  # auto-detect, so the `{project}` placeholder documented at
  # https://github.com/wakatime/wakatime-cli/blob/develop/USAGE.md
  # is NOT expanded. Use a literal project name for terminal heartbeats.
  if [[ -f .wakatime-project ]]; then
    read -r root_directory < .wakatime-project
  elif [[ -n "$git_root" && -f "$git_root/.wakatime-project" ]]; then
    read -r root_directory < "$git_root/.wakatime-project"
  fi

  # If no `.wakatime-project` file was found and we are not in a git repo,
  # use the default project name `Terminal`.
  # When inside a git repo without a `.wakatime-project` file, we omit
  # `--project` entirely and let wakatime-cli auto-detect (folder basename,
  # or git remote when `project_from_git_remote` is enabled in ~/.wakatime.cfg).
  if [[ -z "$root_directory" && -z "$git_root" ]]; then
    root_directory='Terminal'
  fi

  # Build the CLI argument list as an array so quoting is preserved.
  local -a wakatime_args
  wakatime_args=(
    --write
    --plugin 'zsh-wakatime/0.3.0'
    --entity-type app
    --entity "$last_command"
    --language "${WAKATIME_LANGUAGE:-sh}"
    --timeout "${WAKATIME_TIMEOUT:-5}"
  )

  if [[ -n "$root_directory" ]]; then
    wakatime_args+=(--project "${root_directory:t}")
  fi

  if _wakatime_is_truthy "$WAKATIME_DISABLE_OFFLINE"; then
    wakatime_args+=(--disable-offline)
  fi

  if [[ -n "$WAKATIME_CATEGORY" ]]; then
    wakatime_args+=(--category "$WAKATIME_CATEGORY")
  fi

  if [[ -n "$WAKATIME_HOSTNAME" ]]; then
    wakatime_args+=(--hostname "$WAKATIME_HOSTNAME")
  fi

  # Optional escape hatch: append any extra arguments supplied by the user.
  # Set as an array in ~/.zshrc, e.g.
  #   WAKATIME_EXTRA_ARGS=(--hide-project-folder --exclude '^/tmp/')
  if (( ${#WAKATIME_EXTRA_ARGS[@]} )); then
    wakatime_args+=("${WAKATIME_EXTRA_ARGS[@]}")
  fi

  # Where should CLI stderr go? By default we swallow it so a broken install
  # doesn't spam the prompt. Set WAKATIME_LOG to a writable path to capture it.
  local log_target='/dev/null'
  if [[ -n "$WAKATIME_LOG" ]]; then
    log_target="$WAKATIME_LOG"
  fi

  # Fire the heartbeat in a fully detached background process so it never
  # delays the prompt, even if the network or API is slow.
  "$wakatime_bin" "${wakatime_args[@]}" >/dev/null 2>>"$log_target" </dev/null &!
}

# See docs on `add-zsh-hook`:
# https://github.com/zsh-users/zsh/blob/master/Functions/Misc/add-zsh-hook
autoload -U add-zsh-hook

# See docs on what `preexec` is:
# http://zsh.sourceforge.net/Doc/Release/Functions.html
add-zsh-hook preexec _wakatime_heartbeat
