#!/system/bin/sh
# Background Killa - Event-driven foreground monitor

MODDIR=${0%/*}
CONFIG_DIR="$MODDIR/config"
KILL_LIST="$CONFIG_DIR/kill_list.txt"
KILL_LOG="$CONFIG_DIR/kill.log"
KILL_DELAY="$CONFIG_DIR/kill_delay"
PREV_PKG_FILE="$CONFIG_DIR/prev_pkg"
MAX_LOG=300

log() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$KILL_LOG"
    local n
    n=$(wc -l < "$KILL_LOG" 2>/dev/null)
    [ "${n:-0}" -gt "$MAX_LOG" ] && \
        tail -n 150 "$KILL_LOG" > "$KILL_LOG.tmp" && \
        mv "$KILL_LOG.tmp" "$KILL_LOG"
}

extract_pkg() {
    printf '%s' "$1" | grep -oE '\[0,[a-zA-Z][a-zA-Z0-9_.]+' | cut -d, -f2
}

# Kill pkg after delay, but abort if app came back to foreground in the meantime
kill_after_delay() {
    local pkg="$1"
    local delay="$2"
    sleep "$delay"
    local cur
    cur=$(cat "$PREV_PKG_FILE" 2>/dev/null)
    if [ "$cur" != "$pkg" ]; then
        am force-stop "$pkg" 2>/dev/null
        log "KILLED: $pkg (delay: ${delay}s)"
    fi
}

log "INFO: monitor started (pid $$)"
: > "$PREV_PKG_FILE"

while true; do
    logcat -b events -c 2>/dev/null

    logcat -b events 2>/dev/null \
        | grep -E "wm_set_resumed_activity|am_focused_app" \
        | while IFS= read -r line; do
            cur=$(extract_pkg "$line")
            [ -z "$cur" ] && continue

            prev=$(cat "$PREV_PKG_FILE" 2>/dev/null)
            [ "$cur" = "$prev" ] && continue

            if [ -n "$prev" ] && grep -qxF "$prev" "$KILL_LIST" 2>/dev/null; then
                delay=$(cat "$KILL_DELAY" 2>/dev/null)
                if [ -z "$delay" ] || [ "$delay" = "0" ]; then
                    am force-stop "$prev" 2>/dev/null
                    log "KILLED: $prev"
                else
                    kill_after_delay "$prev" "$delay" &
                fi
            fi

            printf '%s' "$cur" > "$PREV_PKG_FILE"
        done

    log "WARN: logcat stream ended, restarting in 5s"
    sleep 5
done
