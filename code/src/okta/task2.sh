#!/bin/bash


# Input validation
if [ -z "$1" ]; then
    echo "Usage: $0 <LOG_LEVEL> [DATE]"
    echo "Example: $0 ERROR 2026-04-06"
    exit 1
fi

LOG_LEVEL="$1"
DATE="${2:-$(date +%F)}"
LOG_FILE="app.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: $LOG_FILE not found in current directory."
    exit 1
fi

# Total count for the given level and date
TOTAL=$(grep "$DATE" "$LOG_FILE" | grep -c "$LOG_LEVEL")

# Breakdown by component, sorted descending
BREAKDOWN=$(grep "$DATE" "$LOG_FILE" | grep "$LOG_LEVEL" | awk '{print $4}' | sort | uniq -c | sort -rn)

echo "Log Level: $LOG_LEVEL"
echo "Date: $DATE"
echo "Total: $TOTAL"
echo "By component:"
echo "$BREAKDOWN"
