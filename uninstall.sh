#!/system/bin/sh
# Background Killa - Uninstall cleanup

MODDIR=${0%/*}
CONFIG_DIR="$MODDIR/config"

# Kill httpd if running
if [ -f "$CONFIG_DIR/httpd.pid" ]; then
    kill "$(cat "$CONFIG_DIR/httpd.pid")" 2>/dev/null
fi

# Kill daemon if running
if [ -f "$CONFIG_DIR/daemon.pid" ]; then
    kill "$(cat "$CONFIG_DIR/daemon.pid")" 2>/dev/null
fi
