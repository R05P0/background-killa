<p align="center">
  <img src="assets/logo.png" width="120" alt="Background Killa">
</p>

# Background Killa

A Magisk module that **force-kills apps the moment they leave the foreground**, with a native WebUI to manage your kill list.

[**Download latest release →**](https://github.com/R05P0/background-killa/releases/latest/download/background-killa.zip)

## Features

- Event-driven foreground monitoring via `wm_set_resumed_activity` — zero polling, zero battery waste
- Force-kills selected apps on foreground exit, with optional kill delay (0s / 30s / 1m / 2m / 5m / 20m / 1h / 2h)
- Native WebUI via KsuWebUIStandalone or MMRL — opens from the Action button in Magisk
- Per-app toggle + instant kill button
- Kill log with timestamps
- Filter: active / user apps / all apps

## Install

1. Download `background-killa.zip` from the [latest release](https://github.com/R05P0/background-killa/releases/latest)
2. In Magisk → Modules → Install from storage → select the zip
3. Reboot
4. Tap the **Action** button on the module to open the WebUI

## Requirements

- Magisk v20.4+
- [KsuWebUIStandalone](https://github.com/a13e300/ksuwebui) or MMRL for the native WebUI

## How It Works

`service.sh` starts two processes at boot:

| Process | What it does |
|---------|-------------|
| `busybox httpd` | Serves the WebUI on port 8765 (fallback for browser access) |
| `monitor.sh` | Streams `logcat -b events`, reacts instantly to `wm_set_resumed_activity` |

When an app leaves the foreground, if it is in the kill list the monitor runs `am force-stop` (immediately or after the configured delay). If a delay is set and the app returns to foreground before it expires, the kill is cancelled.

Config is stored in `/data/adb/modules/background_killa/config/`.

| File | Purpose |
|------|---------|
| `kill_list.txt` | One package name per line |
| `kill_delay` | Delay in seconds before killing (0 = immediate) |
| `kill.log` | Timestamped kill events |
