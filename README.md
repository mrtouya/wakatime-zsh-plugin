# wakatime-zsh-plugin

[![CI](https://github.com/mrtouya/wakatime-zsh-plugin/actions/workflows/ci.yml/badge.svg)](https://github.com/mrtouya/wakatime-zsh-plugin/actions/workflows/ci.yml) [![GitHub Release](https://img.shields.io/badge/release-0.3.0-brightgreen.svg?style=default)](https://github.com/mrtouya/wakatime-zsh-plugin/releases)


## What does this plugin do?

This plugin provides `zsh` and `wakatime` integration. It tracks the time you spend in a terminal — every command you run triggers a lightweight, asynchronous heartbeat to the WakaTime (or self-hosted Wakapi) API. Unlike some other plugins, this one keeps all your time in the same `wakatime` project rather than creating a new one per directory.

It is tested on macOS (including [Warp](https://www.warp.dev/)), Linux, and the standard oh-my-zsh toolchain.

![Info](https://github.com/mrtouya/wakatime-zsh-plugin/blob/master/info.png)


## Prerequisites

You need the [WakaTime CLI](https://github.com/wakatime/wakatime-cli) installed and a valid API key.

### Install wakatime-cli

**macOS (recommended)** — via [Homebrew](https://brew.sh/):

```bash
brew install wakatime-cli
```

Homebrew installs the binary at `$(brew --prefix)/bin/wakatime-cli`. If you want the plugin's default path (`~/.wakatime/wakatime-cli`) to work, symlink it:

```bash
mkdir -p ~/.wakatime
ln -sf "$(brew --prefix)/bin/wakatime-cli" ~/.wakatime/wakatime-cli
```

Otherwise point the plugin at Homebrew directly via `ZSH_WAKATIME_BIN` (see [Configuration](#configuration)).

**Cross-platform** — the official Python bootstrap used by most editor plugins:

```bash
python3 -c "$(curl -fsSL https://raw.githubusercontent.com/wakatime/vim-wakatime/master/scripts/install_cli.py)"
```

This downloads the correct native binary from [GitHub Releases](https://github.com/wakatime/wakatime-cli/releases) into `~/.wakatime/`, creates the `~/.wakatime/wakatime-cli` symlink, and self-updates on subsequent runs.

**Manual** — grab the right archive for your OS/arch from [wakatime-cli releases](https://github.com/wakatime/wakatime-cli/releases/latest) and unzip to a directory on your `$PATH`.

### Configure your API key

Create or edit `~/.wakatime.cfg`:

```ini
[settings]
api_key = your-wakatime-api-key
```

(Alternatively set `WAKATIME_API_KEY` as an environment variable; the CLI picks it up automatically.)


## Installation

### oh-my-zsh (manual)

```bash
git clone https://github.com/mrtouya/wakatime-zsh-plugin.git \
  ~/.oh-my-zsh/custom/plugins/wakatime
```

Then add `wakatime` to the `plugins=(...)` array in your `~/.zshrc`. See the [oh-my-zsh external-plugin docs](https://github.com/ohmyzsh/ohmyzsh/wiki/External-plugins) for details.

### antigen

```zsh
antigen bundle mrtouya/wakatime-zsh-plugin
```

### zgen

```zsh
zgen load mrtouya/wakatime-zsh-plugin
```

### zinit

```zsh
zinit light mrtouya/wakatime-zsh-plugin
```

### zplug

```zsh
zplug "mrtouya/wakatime-zsh-plugin"
```

### sheldon

```toml
[plugins.wakatime]
github = "mrtouya/wakatime-zsh-plugin"
```


## Configuration

Most WakaTime settings belong in [`~/.wakatime.cfg`](https://github.com/wakatime/wakatime-cli/blob/develop/USAGE.md) — the plugin just shells out to `wakatime-cli`, so anything the CLI supports (excludes, obfuscation, proxies, custom API URLs, project maps, rate-limiting, etc.) works unchanged.

Rate-limiting tip: by default `wakatime-cli` sends at most **one heartbeat per entity every 120 seconds** and queues the rest to the offline database. To tune or disable this, add `heartbeat_rate_limit_seconds = <n>` to `~/.wakatime.cfg` (`0` disables it).

### Environment variables

The plugin itself reads these variables from your shell:

| Variable | Effect | Default |
|---|---|---|
| `WAKATIME_DO_NOT_TRACK` | When truthy (`1`/`true`/`yes`/`on`), skip all heartbeats. | unset |
| `WAKATIME_DISABLE_OFFLINE` | When truthy, pass `--disable-offline` (don't queue when offline). | unset |
| `WAKATIME_TIMEOUT` | Seconds before the CLI gives up on the API call. | `5` |
| `WAKATIME_CATEGORY` | Pass `--category <value>` (e.g. `coding`, `debugging`, `building`, `running tests`). | unset → CLI uses `coding` |
| `WAKATIME_LANGUAGE` | Override the `--language` flag (default is `sh`). | `sh` |
| `WAKATIME_HOSTNAME` | Pass `--hostname <value>`. Handy when one machine reports under multiple names. | unset → CLI auto-detects |
| `WAKATIME_IGNORE_REGEX` | zsh-extended regex matched against the first token of each command. Matches are skipped silently. | unset |
| `WAKATIME_LOG` | Path to a file where wakatime-cli's stderr is appended (for debugging). | stderr discarded |
| `WAKATIME_EXTRA_ARGS` | Array of extra args passed verbatim to `wakatime-cli`. Escape hatch for flags the plugin doesn't expose. | unset |
| `ZSH_WAKATIME_BIN` | Path to the `wakatime-cli` binary. | `$HOME/.wakatime/wakatime-cli` |

Example `~/.zshrc` snippet:

```zsh
# Don't track short/noisy commands
export WAKATIME_IGNORE_REGEX='^(ls|ll|la|cd|pwd|clear|exit|history|bg|fg|jobs|which|type)$'

# Point to Homebrew's wakatime-cli without symlinking
export ZSH_WAKATIME_BIN="$(brew --prefix)/bin/wakatime-cli"

# Capture CLI errors for debugging (comment out once working)
# export WAKATIME_LOG="$HOME/.wakatime/zsh-plugin.log"

# Forward extra flags — array form, must be declared before the plugin loads
WAKATIME_EXTRA_ARGS=(--hide-project-folder)
```

### Project Detection

The plugin determines the project name in this order:

1. `.wakatime-project` file in the current directory
2. `.wakatime-project` file at the git repository root
3. Inside a git repo with no `.wakatime-project` file → `--project` is **omitted** and `wakatime-cli` auto-detects (folder basename, or the git remote URL when [`project_from_git_remote`](https://github.com/wakatime/wakatime-cli/blob/develop/USAGE.md#git-section) is enabled in `~/.wakatime.cfg`)
4. Outside any git repository → project name defaults to `Terminal`

**Note on the `{project}` placeholder.** The wakatime-cli docs describe a `{project}` placeholder that can be used inside `.wakatime-project` files (e.g. `my-org/{project}`). Because this plugin reads the file itself rather than delegating to the CLI, **placeholders are not expanded** — use a literal project name. If you need placeholder support, leave `.wakatime-project` empty and rely on the CLI's auto-detection when editing files inside the repo.

### Use with Warp terminal

Warp is fully supported: it runs a real zsh instance that honors `preexec`, so the plugin works unmodified. A couple of things to be aware of:

- Commands issued by **Warp Agent Mode** (Warp's AI assistant) go through the same preexec hook, so they're tracked as normal terminal heartbeats. Use `WAKATIME_DO_NOT_TRACK=1` for the session if you want to exclude them.
- Warp splits each command into its own "block"; this plugin sends one heartbeat per block, which the wakatime-cli rate limiter will de-duplicate according to `heartbeat_rate_limit_seconds` in `~/.wakatime.cfg`.


## Troubleshooting

- **No time appears on the dashboard.** Set `debug = true` in `~/.wakatime.cfg` and check `~/.wakatime/wakatime.log`. Separately, set `WAKATIME_LOG=~/.wakatime/zsh-plugin.log` to capture the plugin's CLI invocation stderr.
- **"wakatime-cli is not installed" on every prompt.** Run `which wakatime-cli`; if found, export `ZSH_WAKATIME_BIN` to that path. If not, re-run the install step above.
- **Offline queue growing.** Normal. Check its size with `wakatime-cli --offline-count`. It flushes automatically when you regain connectivity.


## Alternatives

There are several alternatives to this project:

1. [`zsh-wakatime`](https://github.com/wbingli/zsh-wakatime) — earlier fork, less active.
2. [`bash-wakatime`](https://github.com/gjsheep/bash-wakatime)
3. [`fish-wakatime`](https://github.com/Cyber-Duck/fish-wakatime)

See the full list [here](https://wakatime.com/terminal).


## License

MIT. See [LICENSE](https://github.com/mrtouya/wakatime-zsh-plugin/blob/master/LICENSE) for more details.
