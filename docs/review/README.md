# Project site

Static marketing page for λ Terminal, deployed with GitHub Pages.

## Live

https://shahzebqazi.github.io/lambda-terminal/

## Local preview

From the repo root:

```bash
python3 -m http.server 8766 --directory .
open http://127.0.0.1:8766/docs/review/
```

Use port **8766** if another local site is already on **8765**.

## Deploy

`.github/workflows/pages.yml` publishes this directory (`docs/review/`) to GitHub Pages on pushes to `main`.

## Assets

- `index.html` — landing page
- `assets/` — CSS and icons
- `screenshots/` — captured from a local debug build
