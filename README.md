# KillPort

KillPort is a small macOS menu bar utility for finding local TCP listeners and killing the process attached to a port.

## Run

Use the Codex `Run` action, or run:

```bash
./script/build_and_run.sh
```

The app is intentionally menu-bar-only. It does not show a Dock icon.

## Controls

- `Refresh` (`Command-R`) rescans listening TCP ports.
- Hover a row and press the red `x` to kill that process.
- `Kill All` (`Command-K`) asks for confirmation before terminating every listed unique PID.
- Right-click the menu bar icon to open a `Quit` menu.
