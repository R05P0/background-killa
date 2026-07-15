#!/system/bin/sh
# Background Killa - Boot service
# Starts httpd (WebUI) and the event-driven monitor

MODDIR=${0%/*}
CONFIG_DIR="$MODDIR/config"

mkdir -p "$CONFIG_DIR"
touch "$CONFIG_DIR/kill_list.txt"

# Wait for system boot
until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
sleep 5

# Start WebUI HTTP server (fallback for browser access)
busybox httpd -p 8765 -h "$MODDIR/webroot" &
echo $! > "$CONFIG_DIR/httpd.pid"

# Start event-driven monitor
sh "$MODDIR/monitor.sh" &
echo $! > "$CONFIG_DIR/monitor.pid"
