#!/bin/sh
# Invocar con enter-alpine.sh --isolated-session: sin red y con PID propios.
set -eu
BASE=/work/.work/trinity
LOG=/work/logs/trinity
export TQTDIR=/opt/tqt-experiment TDEDIR=/opt/trinity-experiment
export PATH="$TDEDIR/bin:$TQTDIR/bin:$PATH"
export LD_LIBRARY_PATH="$TDEDIR/lib:$TQTDIR/lib"
export HOME="$BASE/graphical-home"
if [ "${TDE_NO_SPLASH:-0}" = 1 ]; then
    LOG="$LOG/no-splash"
    export HOME="$BASE/graphical-home-no-splash"
fi
if [ "${TDE_EXTENDED_DESKTOP:-0}" = 1 ]; then
    LOG="$LOG-extended"
fi
mkdir -p "$LOG"
export TDEHOME="$HOME/.trinity"
export TDEROOTHOME="$TDEHOME"
export XDG_RUNTIME_DIR="$HOME/runtime"
mkdir -p "$TDEHOME/share/config" "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
if [ "${1:-}" = "--desktop" ]; then
    if [ "${TDE_DEBUG_SPLASH:-0}" = 1 ]; then
        set -x
        # /proc pertenece solo al namespace; GDB usa /proc/PID/mem.
        mount -o remount,rw /proc
        export XDG_CONFIG_DIRS="$TDEDIR/etc/xdg"
        export XDG_DATA_DIRS="$TDEDIR/share:/usr/local/share:/usr/share"
        "$TDEDIR/bin/tdeinit" --new-startup > "$LOG/debug-tdeinit.log" 2>&1
        status=0
        timeout 60 strace -o "$LOG/gdb-system-calls.log" gdb -batch -ex 'set pagination off' \
            -ex "set logging file $LOG/gdb-ksplash-details.log" \
            -ex 'set logging overwrite on' -ex 'set logging enabled on' \
            -ex 'set follow-fork-mode child' \
            -ex 'set detach-on-fork off' \
            -ex 'handle SIGSEGV stop print nopass' \
            -ex 'set startup-with-shell off' -ex start -ex bt \
            -ex 'set breakpoint pending on' \
            -ex 'break TDECrash::defaultCrashHandler(int)' \
            -ex continue -ex 'info program' \
            -ex 'thread apply all bt' \
            --args "$TDEDIR/bin/ksplash" --nodcop || status=$?
        echo "GDB exit status: $status"
        exit "$status"
    fi
    snapshot() {
        xprop -root > "$LOG/root-properties.txt" 2>&1 || true
        xwininfo -root -tree > "$LOG/window-tree.txt" 2>&1 || true
        ps -ef > "$LOG/session-processes.txt" 2>&1 || true
        xwd -root -silent -out "$LOG/desktop.xwd" 2>/dev/null || true
    }
    trap snapshot EXIT
    starttde > "$LOG/session.log" 2>&1 &
    session=$!
    # Espera acotada al gestor de ventanas; no basta un proceso activo.
    ready=0
    for i in $(seq 1 90); do
        if xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q 'window id'; then
            ready=1
            break
        fi
        kill -0 "$session" || break
        sleep 1
    done
    [ "$ready" -eq 1 ] || { echo "No apareció el gestor de ventanas"; exit 1; }
    konsole --caption "MabOs Trinity laboratory" \
        -e /bin/sh -c 'echo "MabOs: Trinity sobre Alpine/musl"; exec /bin/sh' \
        > "$LOG/konsole-graphical.log" 2>&1 &
    xdotool search --sync --onlyvisible --class konsole > "$LOG/konsole-window-id.txt" &
    search=$!
    for i in $(seq 1 30); do
        [ -s "$LOG/konsole-window-id.txt" ] && break
        sleep 1
    done
    kill "$search" 2>/dev/null || true
    [ -s "$LOG/konsole-window-id.txt" ]
    window=$(head -n 1 "$LOG/konsole-window-id.txt")
    xdotool windowactivate --sync "$window"
    xdotool type --clearmodifiers "echo MABOS_TRINITY_INPUT_OK > '$HOME/input-proof.txt'"
    xdotool key Return
    sleep 3
    [ "$(cat "$HOME/input-proof.txt")" = MABOS_TRINITY_INPUT_OK ]
    if [ "${TDE_EXTENDED_DESKTOP:-0}" = 1 ]; then
        xdotool windowsize --sync "$window" 900 500
        xdotool windowmove --sync "$window" 100 70
        xdotool getwindowgeometry --shell "$window" > "$LOG/konsole-geometry.txt"
        xdotool windowminimize --sync "$window"
        xprop -id "$window" _NET_WM_STATE > "$LOG/konsole-minimized.txt"
        grep -q _NET_WM_STATE_HIDDEN "$LOG/konsole-minimized.txt"
        xdotool windowmap --sync "$window"
        xdotool windowactivate --sync "$window"
        sleep 2
        xdotool key alt+F1
        sleep 2
        xwininfo -root -tree > "$LOG/menu-window-tree.txt"
        xwd -root -silent -out "$LOG/menu.xwd"
        xdotool key Escape
        sleep 1
    fi
    xprop -root > "$LOG/root-properties.txt"
    xwininfo -root -tree > "$LOG/window-tree.txt"
    ps -ef > "$LOG/session-processes.txt"
    xwd -root -silent -out "$LOG/desktop.xwd"
    echo "Sesión y ventana Konsole detectadas; captura pendiente de revisión."
    exit 0
fi
cat > "$TDEHOME/share/config/kpersonalizerrc" <<'EOF'
[General]
FirstLogin=false
EOF
if [ "${TDE_NO_SPLASH:-0}" = 1 ]; then
    cat > "$TDEHOME/share/config/ksplashrc" <<'EOF'
[KSplash]
Theme=None
EOF
fi
# Solo loopback del namespace privado: no hay interfaz ni ruta al anfitrión.
ip link set lo up
Xvfb -displayfd 3 -screen 0 1280x800x24 -nolisten tcp \
    3> "$HOME/display-number" > "$LOG/xvfb.log" 2>&1 &
xvfb=$!
cleanup() {
    kill "$xvfb" 2>/dev/null || true
    wait "$xvfb" 2>/dev/null || true
}
trap cleanup EXIT
for i in $(seq 1 20); do
    [ -s "$HOME/display-number" ] && break
    kill -0 "$xvfb" || exit 1
    sleep 1
done
export DISPLAY=":$(cat "$HOME/display-number")"
xprop -root >/dev/null
dbus-run-session -- /bin/sh "$0" --desktop
