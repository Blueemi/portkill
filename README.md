# Kill Port

Kill Port finds local TCP listeners and stops the process bound to a port. It targets the “what is using port 3000?” moment: scan active listeners and kill the process without hand-rolling `lsof` and `kill`.

This repository ships **two macOS clients** that share the same behavior (scan via `lsof`, SIGTERM then SIGKILL):

| Client | Location | Best for |
| ------ | -------- | -------- |
| **Menu bar app** | `Sources/` | Always-available globe icon in the menu bar |
| **Kill a Port** (Raycast) | `raycast/` | Launcher-first workflow inside Raycast |

Pick whichever fits how you work; you do not need both running at once.

## Features (both clients)

- Lists local TCP listeners using `lsof`
- Shows port, process name, PID, and endpoint details
- Kills a single process from the list
- **Kill All** stops every unique PID (with confirmation)
- Sends `SIGTERM` first, waits briefly, then `SIGKILL` if the process is still alive

## Requirements

- macOS 14 or newer
- For the menu bar app: Swift 5.9+ and Xcode Command Line Tools
- For the Raycast extension: [Raycast](https://raycast.com) and Node.js 18+

## Repository layout

```text
killportapp/
├── Sources/KillPort/     # Swift menu bar app
├── raycast/              # Raycast extension (TypeScript)
├── script/               # Menu bar build & run helpers
├── Package.swift         # SwiftPM manifest
└── dist/                 # Generated KillPort.app (gitignored)
```

---

## Menu bar app

A menu-bar-only utility (no Dock icon). Look for the **globe** icon after launch.

### Build and run

From the repo root:

```bash
./script/build_and_run.sh
```

This builds with SwiftPM, creates `dist/KillPort.app`, and opens it. The bundle is gitignored and safe to delete.

Other modes:

```bash
./script/build_and_run.sh --verify   # build, launch, confirm process is running
./script/build_and_run.sh --debug    # run binary under lldb
./script/build_and_run.sh --logs     # launch and stream unified logs
```

Build only with SwiftPM:

```bash
swift build
swift build -c release
```

### Usage

- **Refresh** (`⌘R`) — rescan listening TCP ports
- Hover a row and click the red **×** — stop that process
- **Kill All** (`⌘K`) — confirm, then stop every listed unique PID
- Right-click the menu bar icon — **Quit**

### Development

```bash
swift build
swift build -c release
./script/build_and_run.sh --verify
```

There is no test target yet; `swift test` reports no tests.

---

## Raycast extension

A [Raycast](https://raycast.com) command that lists listeners in Raycast’s UI, with a detail panel for full endpoint info.

See also [`raycast/README.md`](raycast/README.md) for extension-specific notes.

### Install on your Mac

**Development (quickest to try):**

```bash
cd raycast
npm install
npm run dev
```

Leave the terminal running, open Raycast, and run **Kill a Port**.

**Import into Raycast (stays installed without `npm run dev`):**

```bash
cd raycast
npm install
npm run build
```

In Raycast: **Manage Extensions** → **+** → **Import Extension** → select the `raycast/` folder (the one containing `package.json`).

Before publishing or running `npm run lint`, set `"author"` in `raycast/package.json` to your [Raycast account](https://raycast.com) username.

### Usage

- Search filters by port, app name, or PID
- **Refresh** (`⌘R`) — rescan
- **Kill All** (`⌘K`) — confirm, then stop every unique PID
- **Kill Process** — on the selected row
- Open the detail pane for full endpoint / connection metadata

### Development

```bash
cd raycast
npm install
npm run dev          # hot reload
npm run build        # production build
npm run lint         # requires valid Raycast author in package.json
npm run fix-lint
```

---

## Safety

Kill Port can force-quit any process it lists. That is useful for stuck dev servers, but destructive if you kill the wrong thing. **Only stop processes you recognize.**

## Distribution

- **Menu bar app:** `script/build_and_run.sh` produces an unsigned, ad-hoc signed app bundle for local use. There is no notarized installer yet.
- **Raycast extension:** import the `raycast/` folder locally, or follow Raycast’s store guidelines if you publish it.
