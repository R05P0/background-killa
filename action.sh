#!/system/bin/sh
MODID="background_killa"

launch_webui() {
    if pm path io.github.a13e300.ksuwebui >/dev/null 2>&1; then
        am start -n io.github.a13e300.ksuwebui/.WebUIActivity -e id "$MODID" >/dev/null 2>&1
    elif pm path com.dergoogler.mmrl >/dev/null 2>&1; then
        am start -n com.dergoogler.mmrl/.ui.activity.webui.WebUIActivity -e MODID "$MODID" >/dev/null 2>&1
    else
        echo "Install KsuWebUIStandalone or MMRL to open the WebUI."
        echo "Fallback: adb forward tcp:8765 tcp:8765 → http://127.0.0.1:8765"
    fi
}

# When called from Magisk action button (non-interactive) → open WebUI
# When called from a terminal → print status
if [ -t 0 ]; then
    MODDIR=${0%/*}
    CONFIG_DIR="$MODDIR/config"
    MON_PID=$(cat "$CONFIG_DIR/monitor.pid" 2>/dev/null)
    if [ -n "$MON_PID" ] && kill -0 "$MON_PID" 2>/dev/null; then
        DAEMON="Running (pid $MON_PID)"
    else
        DAEMON="Stopped"
    fi
    CURRENT=$(cat "$CONFIG_DIR/prev_pkg" 2>/dev/null); [ -z "$CURRENT" ] && CURRENT="unknown"
    KILL_COUNT=$(wc -l < "$CONFIG_DIR/kill_list.txt" 2>/dev/null | tr -d ' ')
    echo ""
    echo "  Background Killa"
    echo "  Daemon    : $DAEMON"
    echo "  Foreground: $CURRENT"
    echo "  Kill list : ${KILL_COUNT:-0} app(s)"
    echo ""
    launch_webui
else
    launch_webui
fi
