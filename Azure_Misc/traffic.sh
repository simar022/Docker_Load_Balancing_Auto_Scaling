#!/bin/bash

# Configuration
TARGET_URL="http://10.0.2.4/"
DURATION=120
MAX_WORKERS=40
CHECK_INTERVAL=2

START_TIME=$(date +%s)
ACTIVE_PIDS=()

echo "--- Starting Sine-Wave Traffic Test (Duration: ${DURATION}s) ---"

# Clean up background processes on exit
trap 'echo "Stopping..."; kill ${ACTIVE_PIDS[@]} 2>/dev/null; exit' SIGINT SIGTERM

while true; do
    NOW=$(date +%s)
    ELAPSED=$((NOW - START_TIME))

    if [ "$ELAPSED" -ge "$DURATION" ]; then
        break
    fi

    # Calculate target workers using sine wave: target = MAX * sin((elapsed/duration) * pi)
    # We use 'bc' to handle the math
    PI=3.14159
    TARGET_NOW=$(echo "scale=0; $MAX_WORKERS * s(($ELAPSED / $DURATION) * $PI)" | bc -l | cut -d. -f1)
    
    # Ensure at least 1 worker
    if [ -z "$TARGET_NOW" ] || [ "$TARGET_NOW" -lt 1 ]; then TARGET_NOW=1; fi

    CURRENT_COUNT=${#ACTIVE_PIDS[@]}

    # Spin up workers if needed
    while [ "${#ACTIVE_PIDS[@]}" -lt "$TARGET_NOW" ]; do
        # Each worker is a loop of curl requests
        ( while true; do curl -s -o /dev/null "$TARGET_URL"; done ) &
        ACTIVE_PIDS+=($!)
    done

    # Kill workers if needed
    while [ "${#ACTIVE_PIDS[@]}" -gt "$TARGET_NOW" ]; do
        PID=${ACTIVE_PIDS[-1]}
        kill "$PID" 2>/dev/null
        unset 'ACTIVE_PIDS[${#ACTIVE_PIDS[@]}-1]'
        # Re-index array
        ACTIVE_PIDS=("${ACTIVE_PIDS[@]}")
    done

    echo "Time: ${ELAPSED}s | Target Workers: $TARGET_NOW | Active PIDs: ${#ACTIVE_PIDS[@]}"
    sleep $CHECK_INTERVAL
done

echo "--- Traffic Test Ended ---"
kill ${ACTIVE_PIDS[@]} 2>/dev/null
