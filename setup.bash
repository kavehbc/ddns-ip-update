#!/bin/bash

# Default values for variables
CRON_INTERVAL="*/1 * * * *"
ZONE_ID=""
RECORD_ID=""
API_TOKEN=""
DOMAIN=""

# Parse input arguments
while getopts "i:z:r:t:d:" opt; do
  case $opt in
    i) CRON_INTERVAL="$OPTARG" ;;  # Cron interval
    z) ZONE_ID="$OPTARG" ;;  # Zone ID
    r) RECORD_ID="$OPTARG" ;;  # Record ID
    t) API_TOKEN="$OPTARG" ;;  # API Token
    d) DOMAIN="$OPTARG" ;;  # Domain
    *) 
      echo "Usage: $0 -i CRON_INTERVAL -z ZONE_ID -r RECORD_ID -t API_TOKEN -d DOMAIN"
      exit 1
      ;;
  esac
done

# Ensure all required arguments are provided
if [[ -z "$ZONE_ID" || -z "$RECORD_ID" || -z "$API_TOKEN" || -z "$DOMAIN" || -z "$CRON_INTERVAL" ]]; then
  echo "Error: Missing required arguments."
  echo "Usage: $0 -i CRON_INTERVAL -z ZONE_ID -r RECORD_ID -t API_TOKEN -d DOMAIN"
  exit 1
fi

# Create the cron job
echo "$CRON_INTERVAL root /app/ip-update.bash -z $ZONE_ID -r $RECORD_ID -t $API_TOKEN -d $DOMAIN" > /etc/cron.d/ip-update

# Give execution rights on the cron job file
chmod 0644 /etc/cron.d/ip-update

# Apply the cron job
crontab /etc/cron.d/ip-update

cron -f