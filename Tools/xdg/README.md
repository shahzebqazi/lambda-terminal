# XDG audit tool

The audit engine lives in `Sources/LambdaTerminalCore/XDGAudit/`. Run it via SPM:

```bash
swift run xdg audit --stdout
swift run xdg check
```

Or use the shell wrapper (builds on first run):

```bash
./Tools/xdg/xdg audit
```

Default report path: `~/.local/state/lambda-terminal/xdg-report.md`

v0.1 supports **`audit`** and **`check`** only. Destructive **`migrate`** is planned for v0.2.
