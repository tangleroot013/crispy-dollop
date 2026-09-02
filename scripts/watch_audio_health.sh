#!/bin/bash
# Watchdog for audio stability in Crostini
# Logs buffer underruns, playback gaps, and focus events

LOG_DIR="$HOME/.local/share/ez_jukebox/audio_health"
mkdir -p "$LOG_DIR"

# Log file with timestamp
LOG_FILE="$LOG_DIR/audio_health_$(date +%Y%m%d).log"

# Track last update time
LAST_UPDATE=$(date +%s)

# Function to log events
log_event() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Main loop
log_event "=== Audio Health Monitor Started ==="
mpc idleloop player | while read -r event; do
    case "$event" in
        "player")
            CURRENT_TIME=$(date +%s)
            TIME_SINCE_UPDATE=$((CURRENT_TIME - LAST_UPDATE))
            if [ "$TIME_SINCE_UPDATE" -gt 2 ]; then
                log_event "⚠️  PLAYBACK GAP: $TIME_SINCE_UPDATE seconds since last update"
            fi
            LAST_UPDATE=$CURRENT_TIME
            ;;
        *)
            log_event "Event: $event"
            ;;
    esac
done
