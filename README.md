<div align="center">

<p align="center">
  <img src="docs/assets/hero.svg" alt="λ Terminal" width="100%" />
</p>

# λ Terminal

### macOS Terminal With Profiles, XDG Environments, and Session Semantics

[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-lightgrey.svg)](#requirements)
[![Swift 5.9+](https://img.shields.io/badge/swift-5.9%2B-orange.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-46%20passing-brightgreen.svg)](#development)
[![Website](https://img.shields.io/badge/site-sqazi.sh%2Flambda--terminal-blue.svg)](https://sqazi.sh/lambda-terminal/)

**A macOS terminal for developer-workflow UX, not another config format.**

> **Status: experimental portfolio OSS.** Profiles, predictable XDG environments, project-root session semantics, and a local XDG audit tool. Useful as Swift/macOS proof for terminal tooling work. **Not** a production Terminal.app replacement.

**Website:** [sqazi.sh/lambda-terminal](https://sqazi.sh/lambda-terminal/) — retro Apple project page with screenshots, features, and build steps.

[Website](#website) &#8226; [What Is This?](#what-is-this) &#8226; [Features](#features-at-a-glance) &#8226; [Profiles](#profiles) &#8226; [Build](#build--run) &#8226; [Project Structure](#project-structure)

</div>

---

<div align="center">

```
          ┌─────────────────────────────────────────────┐
          │                                             │
          │   Profiles + cwd + XDG env on launch.       │
          │   One app. Deterministic session setup.     │
          │   Your dotfiles stay the source of truth.   │
          │                                             │
          └─────────────────────────────────────────────┘
```

</div>

---

## What is this?

Most terminal apps give you tabs and themes, then leave profile logic to shell config, tmux, or manual exports. λ Terminal does something else: it launches shells with **profile-aware cwd**, **XDG environment injection**, and **session semantics** that mirror the conventions in [dotfiles](https://github.com/shahzebqazi/dotfiles).

1. Pick a profile (`default`, `dev`, `lightweight`, `ai`)
2. Open a window or tab with the right cwd and env
3. Let the shell and dotfiles do the rest

| | Terminal.app / iTerm | λ Terminal |
|---|---|---|
| **Profile model** | Manual shell config | Built-in persisted profiles |
| **Project roots** | Remember last cwd yourself | ⌘N / ⇧⌘O session picker |
| **XDG env** | Inherited from login shell | Injected for `dev` / `ai` profiles |
| **Audit tooling** | External scripts | Developer → XDG Home Audit… |
| **Scope** | Production terminal | Portfolio OSS slice (v0.1) |

> Terminal power-users don't need another config format; they need **profiles**, **predictable environments**, and **session semantics** that match how they already work.

---

## Website

**Live site:** https://sqazi.sh/lambda-terminal/  
**GitHub Pages mirror:** https://shahzebqazi.github.io/lambda-terminal/

[![λ Terminal preview — main session](docs/review/screenshots/terminal-window.png)](https://sqazi.sh/lambda-terminal/)

| Main session | Menu bar & menus | Desktop context |
| --- | --- | --- |
| [![Main terminal window](docs/review/screenshots/terminal-window.png)](https://sqazi.sh/lambda-terminal/#screenshots) | [![Menu bar and Developer menu](docs/review/screenshots/terminal-menu-bar.png)](https://sqazi.sh/lambda-terminal/#screenshots) | [![Terminal on macOS desktop](docs/review/screenshots/terminal-desktop.png)](https://sqazi.sh/lambda-terminal/#screenshots) |

| New window sheet | Settings |
| --- | --- |
| [![New window profile picker](docs/review/screenshots/new-window-sheet.png)](https://sqazi.sh/lambda-terminal/#screenshots) | [![Settings panel](docs/review/screenshots/settings.png)](https://sqazi.sh/lambda-terminal/#screenshots) |

Full gallery on the [live site](https://sqazi.sh/lambda-terminal/#screenshots). Source: [`docs/review/`](docs/review/).

---

## Features at a Glance

### Four Profiles

Persisted under `~/.config/lambda-terminal/profiles.json`. See [docs/PROFILES.md](docs/PROFILES.md).

| Profile | Purpose |
|---|---|
| `default` | Baseline interactive shell |
| `dev` | Daily driver with XDG injection and `~/Git` cwd |
| `lightweight` | Fast startup for SSH / Pi-style sessions |
| `ai` | Cursor / agent sessions with XDG + shell context flags |

### Session Semantics

- **⌘N** — new window with profile + cwd picker (remembers last cwd per profile)
- **⌘T** — new tab inheriting profile
- **⇧⌘O** — Open in Project…

### XDG Home Audit

**Developer → XDG Home Audit…** writes a Markdown report to:

`~/.local/state/lambda-terminal/xdg-report.md`

CLI equivalent:

```bash
swift run xdg audit --stdout
swift run xdg check
```

### Settings

Default profile, font size, and Dracula theme preset.

---

## Profiles

Lambda Terminal ships four built-in profiles aligned with the [dotfiles](https://github.com/shahzebqazi/dotfiles) xonsh profile names.

When `injectXDGEnvironment` is true (`dev`, `ai`), sessions merge:

| Variable | Default (macOS) |
|---|---|
| `XDG_CONFIG_HOME` | `~/.config` |
| `XDG_CACHE_HOME` | `~/.cache` |
| `XDG_DATA_HOME` | `~/.local/share` |
| `XDG_STATE_HOME` | `~/.local/state` |

Plus non-secret tool paths (`WAKATIME_HOME`, `CURSOR_CONFIG_DIR`, `DOCKER_CONFIG`, and others). Profile env wins over defaults.

---

## Requirements

- macOS 14+
- Swift 5.9+
- Xcode 15+ (optional, for IDE debugging)

---

## Build & run

```bash
git clone https://github.com/shahzebqazi/lambda-terminal.git
cd lambda-terminal
swift build
swift run LambdaTerminal
```

Open in Xcode: **File → Open** → select `Package.swift`.

Unsigned local debug builds are expected for v0.1. Code signing and notarization are not configured in CI.

Local site preview:

```bash
python3 -m http.server 8766 --directory .
open http://127.0.0.1:8766/docs/review/
```

---

## Project Structure

```
lambda-terminal/
  Package.swift
  Sources/LambdaTerminalCore/   # profiles, env, XDG audit
  Sources/LambdaTerminal/         # SwiftUI + SwiftTerm app
  Sources/XDGAuditCLI/            # xdg audit executable
  Tests/                          # 46 tests
  Tools/xdg/                      # wrapper scripts
  docs/
    assets/hero.svg               # README banner
    review/                       # GitHub Pages site
    ARCHITECTURE.md
    PROFILES.md
    ROADMAP.md
  .github/workflows/
    ci.yml
    pages.yml
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/PROFILES.md](docs/PROFILES.md), [docs/ROADMAP.md](docs/ROADMAP.md).

---

## Design Influences

- [dotfiles](https://github.com/shahzebqazi/dotfiles) — xonsh profile model, XDG bootstrap
- [mac-config](https://github.com/shahzebqazi/mac-config) — sanitized macOS harness patterns

---

## Development

```bash
git clone https://github.com/shahzebqazi/lambda-terminal.git
cd lambda-terminal
swift build
swift test
```

---

## Limitations

- **Portfolio OSS, not shipped Apple terminal code.** Honest scope for hiring and review readers.
- **Unsigned debug builds only** in v0.1; no notarization path yet.
- **Four local profiles only**; no cloud sync or remote profile registry.
- **Dracula theme preset** is the current visual direction; broader theme system is future work.

---

<div align="center">

**MIT License** &#8226; Built by [@shahzebqazi](https://github.com/shahzebqazi) &#8226; [sqazi.sh](https://sqazi.sh) &#8226; [code@sqazi.sh](mailto:code@sqazi.sh)

</div>
