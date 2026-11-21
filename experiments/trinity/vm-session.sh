#!/bin/sh
set -eu
export HOME=/home/live TDEHOME=/home/live/.trinity
export TQTDIR=/opt/tqt-experiment TDEDIR=/opt/trinity-experiment
export PATH="$TDEDIR/bin:$TQTDIR/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export LD_LIBRARY_PATH="$TDEDIR/lib:$TQTDIR/lib"
export XDG_RUNTIME_DIR=/run/user/1000
LOG=/home/live/results
mkdir -p "$TDEHOME/share/config"
if [ "${1:-}" = "--desktop" ]; then
    echo MABOS_LIVE_ID
    id
    dbus-send --system --print-reply --dest=org.freedesktop.DBus \
        /org/freedesktop/DBus org.freedesktop.DBus.ListNames
    curl --fail --location --max-time 30 https://alpinelinux.org/ \
        -o "$LOG/alpine.html"
    echo MABOS_LIVE_HTTPS_OK
    pulseaudio --start --exit-idle-time=-1 --log-target="file:$LOG/pulse.log"
    pactl load-module module-alsa-sink device=hw:0,0 sink_name=vm_hda
    pactl set-default-sink vm_hda
    pactl info > "$LOG/pulse-info.txt"
    pactl list short sinks > "$LOG/pulse-sinks.txt"
    cat "$LOG/pulse-sinks.txt"
    grep -q vm_hda "$LOG/pulse-sinks.txt"
    # Silencio PCM: verifica el flujo emulado, no sonido audible.
    dd if=/dev/zero of="$LOG/silence.pcm" bs=44100 count=2 2>/dev/null
    pacat --device=vm_hda --playback --raw --rate=44100 --channels=1 --format=s16le < "$LOG/silence.pcm"
    echo MABOS_AUDIO_STREAM_OK
    starttde > "$LOG/session.log" 2>&1 &
    session=$!
    ready=0
    for i in $(seq 1 90); do
        if xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q 'window id'; then
            ready=1
            break
        fi
        kill -0 "$session" || break
        sleep 1
    done
    [ "$ready" = 1 ]
    echo MABOS_LIVE_DESKTOP_READY
    konsole --caption "MabOs live test" -e /bin/sh \
        > "$LOG/konsole.log" 2>&1 &
    window=$(timeout 30 xdotool search --sync --onlyvisible --class konsole | head -n 1)
    xdotool windowactivate --sync "$window"
    xdotool type --clearmodifiers "id -u > '$LOG/typed-uid.txt'"
    xdotool key Return
    sleep 3
    [ "$(cat "$LOG/typed-uid.txt")" = 1000 ]
    echo MABOS_LIVE_KEYBOARD_OK
    xwininfo -root -tree > "$LOG/windows.txt"
    xprop -root > "$LOG/root-properties.txt"
    ps -ef > "$LOG/processes.txt"
    xwd -root -silent -out "$LOG/desktop.xwd"
    dcop > "$LOG/dcop-clients.txt"
    dcop knotify default > "$LOG/knotify-interface.txt"
    echo MABOS_LOGOUT_REQUEST
    dcop ksmserver ksmserver logout 0 0 0
    for i in $(seq 1 30); do
        if ! kill -0 "$session" 2>/dev/null; then
            wait "$session"
            echo MABOS_LOGOUT_OK
            exit 0
        fi
        sleep 1
    done
    echo MABOS_LOGOUT_TIMEOUT
    exit 1
fi
cat > "$TDEHOME/share/config/ksplashrc" <<'EOF'
[KSplash]
Theme=None
EOF
cat > "$TDEHOME/share/config/kpersonalizerrc" <<'EOF'
[General]
FirstLogin=false
EOF
Xvfb -displayfd 3 -screen 0 1280x800x24 -nolisten tcp \
    3> "$LOG/display-number" > "$LOG/xvfb.log" 2>&1 &
xvfb=$!
trap 'kill "$xvfb" 2>/dev/null || true; wait "$xvfb" 2>/dev/null || true' EXIT
for i in $(seq 1 20); do
    [ -s "$LOG/display-number" ] && break
    sleep 1
done
export DISPLAY=":$(cat "$LOG/display-number")"
xprop -root >/dev/null
dbus-run-session -- /bin/sh "$0" --desktop
