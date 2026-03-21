#!/bin/bash

# Configuration
RPS_THRESHOLD=50
MAX_REPLICAS=3
MIN_REPLICAS=1
COOLDOWN_PERIOD=30
CHECK_INTERVAL=2

# Variables
LAST_TOTAL_REQUESTS=0
LAST_SCALE_TIME=0
CURRENT_SCALE=$MIN_REPLICAS

# Ensure dependencies are installed
if ! command -v bc &> /dev/null; then
    echo "Installing 'bc' for calculations..."
    sudo apt-get update && sudo apt-get install -y bc
fi

echo "Starting Autoscaler for Nginx Containers..."

while true; do
    # Fetch total requests from nginx_status
    # We use curl to hit the internal status page
    TOTAL=$(curl -s http://localhost/nginx_status | sed -n '3p' | awk '{print $3}')

    # Validate if TOTAL is a number
    if [[ ! "$TOTAL" =~ ^[0-9]+$ ]]; then
        RPS=0
    else
        if [ "$LAST_TOTAL_REQUESTS" -eq 0 ]; then
            LAST_TOTAL_REQUESTS=$TOTAL
            RPS=0
        else
            # Calculate RPS (Requests Per Second)
            DIFF=$((TOTAL - LAST_TOTAL_REQUESTS))
            RPS=$(echo "scale=2; $DIFF / $CHECK_INTERVAL" | bc)
            LAST_TOTAL_REQUESTS=$TOTAL
        fi
    fi

    NOW=$(date +%s)
    echo "$(date '+%Y-%m-%d %H:%M:%S') | Traffic: $RPS RPS | Scale: $CURRENT_SCALE"

    # --- Scaling Logic ---
    
    # Scale UP if traffic exceeds threshold
    if (( $(echo "$RPS > $RPS_THRESHOLD" | bc -l) )) && [ "$CURRENT_SCALE" -lt "$MAX_REPLICAS" ]; then
        echo "!!! High Traffic: $RPS RPS. Scaling UP to $MAX_REPLICAS replicas !!!"
        sudo docker-compose up -d --scale website1=$MAX_REPLICAS --scale website2=$MAX_REPLICAS --scale website3=$MAX_REPLICAS
        CURRENT_SCALE=$MAX_REPLICAS
        LAST_SCALE_TIME=$NOW

    # Scale DOWN if traffic is low and cooldown has passed
    elif (( $(echo "$RPS < ($RPS_THRESHOLD / 2)" | bc -l) )) && [ "$CURRENT_SCALE" -gt "$MIN_REPLICAS" ]; then
        
        ELAPSED=$((NOW - LAST_SCALE_TIME))
        if [ "$ELAPSED" -gt "$COOLDOWN_PERIOD" ]; then
            echo "--- Low Traffic: $RPS RPS. Scaling DOWN to $MIN_REPLICAS replicas ---"
            sudo docker-compose up -d --scale website1=$MIN_REPLICAS --scale website2=$MIN_REPLICAS --scale website3=$MIN_REPLICAS
            CURRENT_SCALE=$MIN_REPLICAS
        else
            REMAINING=$((COOLDOWN_PERIOD - ELAPSED))
            echo "Cooldown active: ${REMAINING}s remaining before scale-down."
        fi
    fi

    sleep $CHECK_INTERVAL
done
