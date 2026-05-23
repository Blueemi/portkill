# Kill a Port — Raycast extension

Part of the [Kill Port](../README.md) repo. The menu bar app lives in `Sources/`; this folder is the Raycast extension.

## Quick start

1. Set `"author"` in `package.json` to your [Raycast account](https://raycast.com) username (needed for `npm run lint` and Store submission).
2. From this directory:

```bash
npm install
npm run dev
```

3. Open Raycast and run **Kill a Port**.

To install without a dev terminal: `npm run build`, then **Manage Extensions** → **Import Extension** and choose this folder.

## Commands & shortcuts

| Action | Shortcut | Description |
| ------ | -------- | ----------- |
| Refresh | `⌘R` | Rescan TCP listeners with `lsof` |
| Kill All | `⌘K` | Stop every unique PID (confirmation) |
| Kill Process | — | Stop the selected row’s PID |

Use the detail pane for full endpoint and connection metadata.

## Scripts

- `npm run dev` — develop with hot reload
- `npm run build` — production build
- `npm run lint` / `npm run fix-lint` — check or fix style

## Assets

- `assets/extension-icon.svg` — source icon
- `assets/extension-icon.png` — icon referenced by `package.json` (regenerate from SVG with ImageMagick if you edit the SVG)
