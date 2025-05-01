#!/bin/bash

# Trap Ctrl+C or script exit to stop gNB and process logs
cleanup() {
    echo ""
    echo "🛑 Stopping gNB process..."
    sudo pkill -9 nr-gnb || true
    echo "📄 Processing captured gNB logs..."
    process_logs
    echo "✅ Done."
    exit 0
}
trap cleanup INT EXIT

# Paths
UERANSIM_DIR="$(pwd)"
CONFIG_FILE="$UERANSIM_DIR/config/open5gs-gnb.yaml"
GNB_BIN="$UERANSIM_DIR/build/nr-gnb"
LOG_FILE="./gnb_logs.log"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RCRC_DIR="./rcrc_dataset"
RCRC_TIMESERIES_FILE="$RCRC_DIR/rcrc_timeseries_$TIMESTAMP.csv"

# Ensure output directory exists
mkdir -p "$RCRC_DIR"

# Remove previous live log
rm -f "$LOG_FILE"

# Function to process logs
process_logs() {
    grep "new signal detected" "$LOG_FILE" | awk -F'[][]' '{print $2}' > rcrc_timestamps.txt

    TOTAL_RCRC=$(wc -l < rcrc_timestamps.txt)
    echo "📊 Total captured RRC connection requests: $TOTAL_RCRC"

    python3 - <<EOF
import pandas as pd
from datetime import datetime, timedelta

with open('rcrc_timestamps.txt', 'r') as f:
    timestamps = [datetime.strptime(line.strip(), "%Y-%m-%d %H:%M:%S.%f") for line in f]

if not timestamps:
    print("No RCRC events found.")
    exit(0)

start_time = min(timestamps)
end_time = max(timestamps)
bin_size = timedelta(milliseconds=100)

current = start_time
bins = []
while current <= end_time + bin_size:
    bins.append(current)
    current += bin_size

series = pd.Series(timestamps)
counts = pd.cut(series, bins=bins, right=False).value_counts().sort_index()

times = [interval.left.strftime("%Y-%m-%d %H:%M:%S.%f") for interval in counts.index]
df = pd.DataFrame({
    'Time': times,
    'RRC Connection Request Count (RCRC)': counts.values
})
df['Cumulative RCRC'] = df['RRC Connection Request Count (RCRC)'].cumsum()

df.to_csv("$RCRC_TIMESERIES_FILE", index=False)
print(f"🧾 RCRC timeseries saved to $RCRC_TIMESERIES_FILE")
EOF

    rm -f rcrc_timestamps.txt
}

# Launch gNB
echo "🚀 Starting gNB (live + logging to $LOG_FILE)..."
sudo "$GNB_BIN" -c "$CONFIG_FILE" | tee "$LOG_FILE"