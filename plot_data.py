import pandas as pd
import matplotlib.pyplot as plt

# Read CSV (no headers, two columns: timestamp, rcrc count)
df = pd.read_csv("rcrc_timeseries.csv", header=None, names=["time", "rcrc_count"])

# Convert time from float to seconds for better readability if needed
# df['time'] = df['time'].astype(float)

# Plot setup
plt.figure(figsize=(10, 4))
plt.plot(df["time"], df["rcrc_count"], linestyle='-', linewidth=1.5, color='steelblue')

# Labels and formatting
plt.title("RCRC Timeseries")
plt.xlabel("Time (seconds)")
plt.ylabel("RCRC count (per 100 ms window)")
plt.grid(True, linestyle='--', alpha=0.5)

# Clean ticks
plt.xticks(rotation=0)
plt.tight_layout()

# Save the figure cleanly
plt.savefig("rcrc_timeseries_clean.png", dpi=300, bbox_inches='tight', facecolor='white')

print("✅ Saved clean RCRC timeseries plot as 'rcrc_timeseries_clean.png'")