#!/system/bin/sh
# Background Killa - CGI API
# Handles all WebUI requests

MODDIR="/data/adb/modules/background_killa"
CONFIG_DIR="$MODDIR/config"
KILL_LIST="$CONFIG_DIR/kill_list.txt"
KILL_LOG="$CONFIG_DIR/kill.log"
KILL_DELAY="$CONFIG_DIR/kill_delay"

mkdir -p "$CONFIG_DIR"
touch "$KILL_LIST"

# ── helpers ───────────────────────────────────────────────────────────────────

json_header() {
    printf "Content-Type: application/json\r\n"
    printf "Access-Control-Allow-Origin: *\r\n"
    printf "Cache-Control: no-cache\r\n"
    printf "\r\n"
}

# URL-decode a string
urldecode() {
    local encoded="$1"
    printf '%b' "$(echo "$encoded" | sed 's/+/ /g; s/%\([0-9A-Fa-f][0-9A-Fa-f]\)/\\x\1/g')"
}

# Get a query string parameter by name
get_param() {
    local key="$1"
    local value
    value=$(echo "$QUERY_STRING" | tr '&' '\n' | grep "^${key}=" | head -1 | cut -d= -f2-)
    urldecode "$value"
}

json_escape() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g'
}

# ── action handlers ───────────────────────────────────────────────────────────

action_list() {
    local filter
    filter=$(get_param "filter")
    [ -z "$filter" ] && filter="user"

    json_header

    # Active: return only kill-listed packages
    if [ "$filter" = "active" ]; then
        printf '{"packages":['
        local first=1
        while IFS= read -r pkg; do
            [ -z "$pkg" ] && continue
            [ "$first" = "1" ] && first=0 || printf ','
            printf '{"pkg":"%s","enabled":true}' "$(json_escape "$pkg")"
        done < "$KILL_LIST"
        printf ']}'
        return
    fi

    local pm_args=""
    [ "$filter" = "user" ] && pm_args="-3"

    local packages
    packages=$(pm list packages $pm_args 2>/dev/null | sed 's/^package://' | sort)

    printf '{"packages":['
    local first=1
    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue

        local enabled=false
        grep -qx "$pkg" "$KILL_LIST" 2>/dev/null && enabled=true

        [ "$first" = "1" ] && first=0 || printf ','
        printf '{"pkg":"%s","enabled":%s}' "$(json_escape "$pkg")" "$enabled"
    done << EOF
$packages
EOF
    printf ']}'
}

action_status() {
    json_header

    local daemon_running=false
    if [ -f "$CONFIG_DIR/daemon.pid" ] && kill -0 "$(cat "$CONFIG_DIR/daemon.pid")" 2>/dev/null; then
        daemon_running=true
    fi

    local cur_fg
    cur_fg=$(dumpsys activity activities 2>/dev/null \
        | grep -E "mResumedActivity|topResumedActivity" \
        | grep -oE '[a-zA-Z][a-zA-Z0-9_.]+/[a-zA-Z]' \
        | head -1 \
        | cut -d/ -f1)

    local kill_count
    kill_count=$(wc -l < "$KILL_LIST" 2>/dev/null | tr -d ' ')

    printf '{"daemon":%s,"foreground":"%s","kill_count":%s}' \
        "$daemon_running" \
        "$(json_escape "${cur_fg:-unknown}")" \
        "${kill_count:-0}"
}

action_add() {
    local pkg
    pkg=$(get_param "pkg")
    json_header

    if [ -z "$pkg" ]; then
        printf '{"ok":false,"error":"missing pkg"}'
        return
    fi

    if ! grep -qx "$pkg" "$KILL_LIST" 2>/dev/null; then
        echo "$pkg" >> "$KILL_LIST"
        sort -u "$KILL_LIST" -o "$KILL_LIST"
    fi

    printf '{"ok":true,"pkg":"%s"}' "$(json_escape "$pkg")"
}

action_remove() {
    local pkg
    pkg=$(get_param "pkg")
    json_header

    if [ -z "$pkg" ]; then
        printf '{"ok":false,"error":"missing pkg"}'
        return
    fi

    grep -vx "$pkg" "$KILL_LIST" > "$KILL_LIST.tmp" 2>/dev/null && mv "$KILL_LIST.tmp" "$KILL_LIST"
    printf '{"ok":true,"pkg":"%s"}' "$(json_escape "$pkg")"
}

action_log() {
    json_header

    local lines
    lines=$(get_param "lines")
    [ -z "$lines" ] && lines=100

    printf '{"log":['
    local first=1
    if [ -f "$KILL_LOG" ]; then
        tail -n "$lines" "$KILL_LOG" | while IFS= read -r line; do
            [ "$first" = "1" ] && first=0 || printf ','
            printf '"%s"' "$(json_escape "$line")"
        done
    fi
    printf ']}'
}

action_killnow() {
    local pkg
    pkg=$(get_param "pkg")
    json_header

    if [ -z "$pkg" ]; then
        printf '{"ok":false,"error":"missing pkg"}'
        return
    fi

    am force-stop "$pkg" 2>/dev/null
    printf '{"ok":true,"pkg":"%s"}' "$(json_escape "$pkg")"
}

action_get_delay() {
    json_header
    local d
    d=$(cat "$KILL_DELAY" 2>/dev/null)
    [ -z "$d" ] && d=0
    printf '{"delay":%s}' "$d"
}

action_set_delay() {
    local d
    d=$(get_param "seconds")
    json_header
    case "$d" in
        0|30|60|120|300|1200|3600|7200)
            printf '%s' "$d" > "$KILL_DELAY"
            printf '{"ok":true,"delay":%s}' "$d"
            ;;
        *)
            printf '{"ok":false,"error":"invalid delay"}'
            ;;
    esac
}

# ── router ────────────────────────────────────────────────────────────────────

ACTION=$(get_param "action")

case "$ACTION" in
    list)      action_list ;;
    status)    action_status ;;
    add)       action_add ;;
    remove)    action_remove ;;
    log)       action_log ;;
    killnow)   action_killnow ;;
    getdelay)  action_get_delay ;;
    setdelay)  action_set_delay ;;
    *)
        json_header
        printf '{"ok":false,"error":"unknown action: %s"}' "$(json_escape "$ACTION")"
        ;;
esac
