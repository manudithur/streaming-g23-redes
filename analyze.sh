#!/bin/bash

# Default log file location
LOG_FILE="/usr/local/nginx/logs/hls.log"

# Check if the time frame in seconds is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <time_frame_in_seconds>"
    exit 1
fi

TIME_FRAME=$1

# Calculate the start and end times based on the current time and the provided time frame
END_TIME=$(date "+%d/%b/%Y:%H:%M:%S")
START_TIME=$(date -d "-$TIME_FRAME seconds" "+%d/%b/%Y:%H:%M:%S")

# Extract relevant log entries within the specified time frame and ignore .m3u8 files
LOG_ENTRIES=$(awk -v start="$START_TIME" -v end="$END_TIME" '{
    time=$4
    gsub(/[\[\]]/, "", time)
    if (time >= start && time <= end && $7 !~ /\.m3u8$/) print $0
}' "$LOG_FILE")

# Check if LOG_ENTRIES is empty
if [ -z "$LOG_ENTRIES" ]; then
    echo "No log entries found in the specified time frame."
    exit 0
fi

# Process log entries to aggregate data by stream
process_log_entries() {
    local log_entries=$1

    # Declare associative arrays
    declare -A viewers
    declare -A bytes_sent

    while IFS= read -r entry; do
        # Extract stream name and IP address
        stream=$(echo "$entry" | grep -oP '/hls/\K[^-]*')
        ip=$(echo "$entry" | awk '{print $1}')
        bytes=$(echo "$entry" | awk '{print $10}')

        # Aggregate unique viewers by IP
        viewers["$stream,$ip"]=1

        # Aggregate bytes sent
        bytes_sent["$stream"]=$((bytes_sent["$stream"] + bytes))
    done <<< "$log_entries"

    # Aggregate unique viewers per stream
    declare -A unique_viewers_per_stream
    for key in "${!viewers[@]}"; do
        stream=$(echo "$key" | awk -F',' '{print $1}')
        unique_viewers_per_stream["$stream"]=$((unique_viewers_per_stream["$stream"] + 1))
    done

    for stream in "${!unique_viewers_per_stream[@]}"; do
        unique_viewers=${unique_viewers_per_stream["$stream"]}
        total_bytes=${bytes_sent["$stream"]}
        echo "Stream: $stream"
        echo "Unique Viewers: $unique_viewers"
        echo "Bytes Sent: $total_bytes"
        echo "-------------------------"
    done
}

process_log_entries "$LOG_ENTRIES"