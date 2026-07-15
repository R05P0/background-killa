# Background Killa

A Magisk module that **force-kills apps the moment they leave the foreground**, with a browser-based UI to manage your kill list.

## Features

- Real-time foreground app monitoring (polling every 1s)
- Force-kills selected apps on foreground exit
- **Web UI** on port 8765 — dark themed, mobile-friendly
- Per-app toggle + instant kill button
- Kill log with timestamps
- Filter: user apps / all apps

## Install

1. Build the zip:
   ```bash
   bash build.sh
   ```
2. In the Magisk app → Modules → Install from storage → select `background-killa.zip`
3. Reboot

## Use the Web UI

After reboot, forward the port via ADB:

```bash
adb forward tcp:8765 tcp:8765
```

Then open in your browser:

```
http://localhost:8765
```

Toggle the apps you want Background Killa to nuke when they exit the foreground.

## How It Works

`service.sh` starts two background processes at boot:

| Process | What it does |
|---------|-------------|
| `busybox httpd` | Serves the WebUI + CGI API on port 8765 |
| Killer daemon | Polls `dumpsys activity` every 1s, force-stops any kill-listed app that just left foreground |

Config is stored in `/data/adb/modules/background_killa/config/`.

| File | Purpose |
|------|---------|
| `kill_list.txt` | One package name per line |
| `kill.log` | Timestamped kill events |

## Requirements

- Magisk v20.4+
- `busybox` (included with Magisk)
- ADB for WebUI access (or use a browser app on-device pointing to `127.0.0.1:8765`)
