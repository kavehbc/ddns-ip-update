#!/bin/bash

echo "Starting IP update script..."

# Default values for variables
CRON_INTERVAL="${CRON_INTERVAL:-*/5 * * * *}"
ZONE_ID="${ZONE_ID:-}"
RECORD_ID="${RECORD_ID:-}"
API_TOKEN="${API_TOKEN:-}"
RECORD_NAME="${RECORD_NAME:-}"

# Parse input arguments (support both short and long options)
while [[ $# -gt 0 ]]; do
  case "$1" in
    -z|--zone-id)
      ZONE_ID="$2"
      shift 2
      ;;
    -r|--record-id)
      RECORD_ID="$2"
      shift 2
      ;;
    -t|--api-token)
      API_TOKEN="$2"
      shift 2
      ;;
    -n|--record-name)
      RECORD_NAME="$2"
      shift 2
      ;;
    -*)
      echo "Usage: $0 -z ZONE_ID -r RECORD_ID -t API_TOKEN -n RECORD_NAME"
      echo "   or: $0 --zone-id ZONE_ID --record-id RECORD_ID --api-token API_TOKEN --record-name RECORD_NAME"
      exit 1
      ;;
    *) shift
      ;;
  esac
done

# Ensure all required arguments are provided
if [[ -z "$ZONE_ID" || -z "$RECORD_ID" || -z "$API_TOKEN" || -z "$RECORD_NAME" ]]; then
  echo "Error: Missing required arguments."
  echo "Usage: $0 -z ZONE_ID -r RECORD_ID -t API_TOKEN -n RECORD_NAME"
  echo "   or: $0 --zone-id ZONE_ID --record-id RECORD_ID --api-token API_TOKEN --record-name RECORD_NAME"
  exit 1
fi

# Get the current public IP address
IP=$(curl -s http://checkip.amazonaws.com)

# Validate IP address format (simple regex for IPv4)
if ! [[ "$IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
  echo "Error: Invalid IP address retrieved: '$IP'"
  exit 1
fi

LOG_FILE="/app/log/ip-update.log"
STORED_IP_FILE="/app/log/stored_ip.txt"

# Create log directory if it doesn't exist
mkdir -p $(dirname "$STORED_IP_FILE")

# Retrieve saved IP
if [[ -f "$STORED_IP_FILE" ]]; then
  STORED_IP=$(cat "$STORED_IP_FILE")
else
  STORED_IP=""
fi

# Get the current date and time
current_datetime=$(date)

if [[ "$IP" != "$STORED_IP" ]]; then
	
	# logging the IP change
	echo "$current_datetime -> $IP" >> /app/log/ip-update.log

	# Updating the DNS record
	echo "$current_datetime -> $IP. Updating DNS record..."

	curl -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
	-H "Authorization: Bearer $API_TOKEN" \
	-H "Content-Type: application/json" \
	--data '{
	  "type": "A",
	  "name": "'"$RECORD_NAME"'",
	  "content": "'"$IP"'",
	  "ttl": 3600,
	  "proxied": false
	}'

	# Store new IP address
	echo "$IP" > /app/log/stored_ip.txt

fi