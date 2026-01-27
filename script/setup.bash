#!/bin/bash

# Default values for variables from environment
CRON_INTERVAL="${CRON_INTERVAL:-*/5 * * * *}"
ZONE_ID="${ZONE_ID:-}"
RECORD_ID="${RECORD_ID:-}"
API_TOKEN="${API_TOKEN:-}"
RECORD_NAME="${RECORD_NAME:-}"

# Parse input arguments (override env if provided)
while getopts "i:z:r:t:d:" opt; do
  case $opt in
    i) CRON_INTERVAL="$OPTARG" ;;
    z) ZONE_ID="$OPTARG" ;;
    r) RECORD_ID="$OPTARG" ;;
    t) API_TOKEN="$OPTARG" ;;
    n) RECORD_NAME="$OPTARG" ;;
    *)
      echo "Usage: $0 -z ZONE_ID -r RECORD_ID -t API_TOKEN -n RECORD_NAME"
      ;;
  esac
done

# Check if all required variables are set
if [[ -z "$ZONE_ID" || -z "$RECORD_ID" || -z "$API_TOKEN" || -z "$RECORD_NAME" || -z "$CRON_INTERVAL" ]]; then
  echo "Error: Missing required arguments."
  echo "Usage: $0 -z ZONE_ID -r RECORD_ID -t API_TOKEN -n RECORD_NAME"
  exit 1
fi

# initial execution of the update script
echo "Executing initial IP update..."
/app/script/ip-update-v2.bash -z $ZONE_ID -r $RECORD_ID -t $API_TOKEN -n $RECORD_NAME

# Create the cron job
echo "Creating cron job with interval: $CRON_INTERVAL"
echo "$CRON_INTERVAL root /app/script/ip-update-v2.bash -z $ZONE_ID -r $RECORD_ID -t $API_TOKEN -n $RECORD_NAME" > /etc/cron.d/ip-update

# Give execution rights on the cron job file
chmod 0644 /etc/cron.d/ip-update

# Apply the cron job
crontab /etc/cron.d/ip-update

exec cron -f
