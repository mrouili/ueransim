#!/bin/bash

# Trap Ctrl+C or script exit and cleanup
cleanup() {
    echo "🧹 Cleaning up leftover nr-ue processes..."
    sudo pkill -9 nr-ue || true
    exit 0
}
trap cleanup INT TERM EXIT

# Parameters
SIMULATION_DURATION=    # seconds (adjustable)
CONFIG_DIR="./config"
UERANSIM_BIN="./build/nr-ue"
LOG_DIR="./ue_logs_attack"

# Prepare the log directory (purge previous logs)
echo "🗑️ Cleaning old attack logs..."
sudo rm -rf "$LOG_DIR"
mkdir -p "$LOG_DIR"

# Initialize counters
START_TIME=$(date +%s)
TOTAL_DEPLOYED=0

echo "Starting Signaling Storm simulation for $SIMULATION_DURATION seconds..."

# Main simulation loop
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    if [ $ELAPSED_TIME -ge $SIMULATION_DURATION ]; then
        echo "Simulation time reached ($SIMULATION_DURATION seconds)."
        break
    fi

    # Randomize burst size: 5–15 UEs
    BURST_SIZE=$((10 + RANDOM % 100))

    # Update deployment counter BEFORE launching
    TOTAL_DEPLOYED=$((TOTAL_DEPLOYED + BURST_SIZE))

    echo "🚨 Deploying $BURST_SIZE UE(s)... (elapsed time: ${ELAPSED_TIME}s) (total deployed so far: $TOTAL_DEPLOYED)"

    # Kill previous nr-ue process (prevent overload)
    sudo pkill -9 nr-ue >/dev/null 2>&1 || true
    sleep 0.2

    # Launch aggressive burst
    sudo $UERANSIM_BIN -c "$CONFIG_DIR/ue1.yaml" -n "$BURST_SIZE" > "$LOG_DIR/burst_${ELAPSED_TIME}.log" 2>&1 &
    disown

    # Random fast sleep (0.1–0.5 seconds)
    SLEEP_TIME=$(awk -v min=0.05 -v max=0.3 'BEGIN{srand(); print min+rand()*(max-min)}')
    sleep $SLEEP_TIME

    # Safety check for script termination
    if ! kill -0 $$ 2>/dev/null; then
        cleanup
    fi
done

echo "✅ Attack scenario simulation complete"
echo "📈 Total UEs deployed during attack: $TOTAL_DEPLOYED"

cleanup