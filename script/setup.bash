#!/bin/bash

# Default values for variables
CRON_INTERVAL="${CRON_INTERVAL:-*/5 * * * *}"
ZONE_ID="${ZONE_ID:-}"
RECORD_ID="${RECORD_ID:-}"
API_TOKEN="${API_TOKEN:-}"
DOMAIN="${DOMAIN:-}"

# Create the cron job
echo "$CRON_INTERVAL root /app/script/ip-update.bash -z $ZONE_ID -r $RECORD_ID -t $API_TOKEN -d $DOMAIN" > /etc/cron.d/ip-update

# Give execution rights on the cron job file
chmod 0644 /etc/cron.d/ip-update

# Apply the cron job
crontab /etc/cron.d/ip-update

cron -f