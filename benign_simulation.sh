#!/bin/bash

# Trap Ctrl+C or script exit and cleanup
cleanup() {
    echo "🧹 Cleaning up leftover nr-ue processes..."
    sudo pkill -9 nr-ue || true
    exit 0
}
trap cleanup INT TERM EXIT

# Parameters
SIMULATION_DURATION=300    # seconds
CONFIG_DIR="./config"
UERANSIM_BIN="./build/nr-ue"
LOG_DIR="./ue_logs"

# Prepare the log directory (purge previous logs)
echo "🗑️ Cleaning old logs..."
sudo rm -rf "$LOG_DIR"
mkdir -p "$LOG_DIR"

# Initialize counters
START_TIME=$(date +%s)
TOTAL_DEPLOYED=0

echo "Starting benign simulation for $SIMULATION_DURATION seconds..."

# Main simulation loop
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    if [ $ELAPSED_TIME -ge $SIMULATION_DURATION ]; then
        echo "Simulation time reached ($SIMULATION_DURATION seconds)."
        break
    fi

    # Randomize burst size: 1–5 UEs
    BURST_SIZE=$((1 + RANDOM % 5))

    # Update deployment counter BEFORE launching
    TOTAL_DEPLOYED=$((TOTAL_DEPLOYED + BURST_SIZE))

    echo "Deploying $BURST_SIZE UE(s)... (elapsed time: ${ELAPSED_TIME}s) (total deployed so far: $TOTAL_DEPLOYED)"

    # Kill previous nr-ue process (important to avoid overload, hide messages)
    sudo pkill -9 nr-ue >/dev/null 2>&1 || true
    sleep 1

    # Launch new burst cleanly
    sudo $UERANSIM_BIN -c "$CONFIG_DIR/ue1.yaml" -n "$BURST_SIZE" > "$LOG_DIR/burst_${ELAPSED_TIME}.log" 2>&1 &
    disown

    UE_PID=$!   #Capture the PID of the background nr-ue process

    # Random sleep 2–5 seconds
    SLEEP_TIME=$(awk -v min=2 -v max=5 'BEGIN{srand(); print min+rand()*(max-min)}')
    sleep $SLEEP_TIME

    # Check if script was killed during the sleep
    if ! kill -0 $$ 2>/dev/null; then
        cleanup
    fi
done

# Final cleanup

echo "✅ Benign scenario simulation complete!"
echo "📈 Total UEs deployed during simulation: $TOTAL_DEPLOYED"

cleanup



