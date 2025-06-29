#!/bin/bash

echo "Starting IP update script..."

# Default values for variables
CRON_INTERVAL="${CRON_INTERVAL:-*/5 * * * *}"
ZONE_ID="${ZONE_ID:-}"
RECORD_ID="${RECORD_ID:-}"
API_TOKEN="${API_TOKEN:-}"
DOMAIN="${DOMAIN:-}"

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
    -d|--domain)
      DOMAIN="$2"
      shift 2
      ;;
    -*)
      echo "Usage: $0 -z ZONE_ID -r RECORD_ID -t API_TOKEN -d DOMAIN"
      echo "   or: $0 --zone-id ZONE_ID --record-id RECORD_ID --api-token API_TOKEN --domain DOMAIN"
      exit 1
      ;;
    *)
      shift
      ;;
  esac
done

# Ensure all required arguments are provided
if [[ -z "$ZONE_ID" || -z "$RECORD_ID" || -z "$API_TOKEN" || -z "$DOMAIN" ]]; then
  echo "Error: Missing required arguments."
  echo "Usage: $0 -z ZONE_ID -r RECORD_ID -t API_TOKEN -d DOMAIN"
  echo "   or: $0 --zone-id ZONE_ID --record-id RECORD_ID --api-token API_TOKEN --domain DOMAIN"
  exit 1
fi

# Get the current public IP address
IP=$(curl -s http://checkip.amazonaws.com)

# Retrieve saved IP
STORED_IP=$(</app/log/stored_ip.txt)

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
	  "name": "'"$DOMAIN"'",
	  "content": "'"$IP"'",
	  "ttl": 3600,
	  "proxied": false
	}'

	# Store new IP address
	echo "$IP" > /app/log/stored_ip.txt

fi