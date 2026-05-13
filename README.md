# KillPort

KillPort is a tiny macOS menu bar utility for finding local TCP listeners and stopping the process attached to a port.

It is built for the "what is using port 3000?" moment: open the menu bar item, scan active listening ports, and kill the process without dropping into `lsof`/`kill` by hand.

## Features

- Lists local TCP listeners using `lsof`
- Shows port, process name, PID, and endpoint details
- Kills a single process from the port list
- Supports `Kill All` for every unique listed PID
- Runs as a menu-bar-only app with no Dock icon
- Provides a right-click menu bar `Quit` action

## Requirements

- macOS 14 or newer
- Swift 5.9 or newer
- Xcode command line tools

## Build And Run

From the repo root:

```bash
./script/build_and_run.sh
```

The script builds the SwiftPM executable, creates `dist/KillPort.app`, and opens it. The generated app bundle is ignored by Git and can be deleted safely.

You can also build directly with SwiftPM:

```bash
swift build
```

For a release build:

```bash
swift build -c release
```

## Usage

- `Refresh` (`Command-R`) rescans listening TCP ports.
- Hover a row and press the red `x` to stop that process.
- `Kill All` (`Command-K`) asks for confirmation before stopping every listed unique PID.
- Right-click the menu bar icon to open a `Quit` menu.

KillPort is intentionally menu-bar-only. If you do not see a window after launching, look for the globe icon in the macOS menu bar.

## Safety Notes

KillPort sends `SIGTERM` first, waits briefly, then sends `SIGKILL` if the process is still alive. This is useful for stuck local dev servers, but it can force-quit work in any process shown in the list.

Only kill processes you recognize.

## Development

Common checks:

```bash
swift build
swift build -c release
./script/build_and_run.sh --verify
```

There is currently no test target, so `swift test` will report that no tests were found.

## Distribution Status

The local build script creates an unsigned/ad-hoc signed app bundle for development use. There is not currently a notarized release build or packaged installer.
