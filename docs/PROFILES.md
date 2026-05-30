# Profiles

Lambda Terminal ships four built-in profiles aligned with the [dotfiles](https://github.com/shahzebqazi/dotfiles) xonsh profile names. On first launch, defaults are written to:

`~/.config/lambda-terminal/profiles.json`

## Profile table

| ID | Purpose | Shell | Working dir (default) | Env / behavior |
|----|---------|-------|----------------------|----------------|
| `default` | Baseline interactive shell | `$SHELL` | `~` | Minimal injection; `LAMBDA_TERMINAL_PROFILE=default` |
| `dev` | MacBook daily driver | `$SHELL` | `~/Git` if present, else `~` | XDG base dirs + tool paths; `DOTFILES_XONSH_PROFILE=dev` for xonsh |
| `lightweight` | SSH / Pi / fast startup | `$SHELL` | `~` | `DOTFILES_XONSH_PROFILE=lightweight`; no heavy XDG tool paths |
| `ai` | Cursor / agent sessions | `$SHELL` | `~/Git` if present | XDG injection; `DOTFILES_XONSH_PROFILE=ai`, `DOTFILES_SHELL_CONTEXT=ai` |

## Tab title template

Each profile supports `tabTitleTemplate` (default: `λ {profile} — {cwd}`).

## XDG environment injection

When `injectXDGEnvironment` is true (`dev`, `ai`), the session merges:

| Variable | Default (macOS) |
|----------|-----------------|
| `XDG_CONFIG_HOME` | `~/.config` |
| `XDG_CACHE_HOME` | `~/.cache` |
| `XDG_DATA_HOME` | `~/.local/share` |
| `XDG_STATE_HOME` | `~/.local/state` |

Plus non-secret tool paths (no hardcoded personal model directories):

- `WAKATIME_HOME`, `CURSOR_CONFIG_DIR`, `DOCKER_CONFIG`, `LM_STUDIO_HOME`
- `NPM_CONFIG_USERCONFIG`, `NPM_CONFIG_CACHE`

**Merge order:** inherited env → XDG defaults → profile `environment` map (profile wins).

## xonsh integration

If the resolved shell path contains `xonsh`, `DOTFILES_XONSH_PROFILE` is set from the profile id (when not already set in the profile env map). This matches the dotfiles monorepo `DOTFILES_XONSH_PROFILE` convention.

## Remembered working directories

`settings.json` stores `lastWorkingDirectoryByProfile`. **⌘N** new window uses the picker; subsequent opens default to the last cwd for that profile.

## Editing profiles

v0.1: edit `profiles.json` directly. Import/export UI is on the [ROADMAP](ROADMAP.md).
