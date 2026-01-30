#!/bin/bash

# Default values for variables
# (Are inherited from environment if set)
ZONE_ID="${ZONE_ID:-}"
RECORD_ID="${RECORD_ID:-}"
API_TOKEN="${API_TOKEN:-}"
RECORD_NAME="${RECORD_NAME:-}"
PROXIED="${PROXIED:-false}"

# Parse input arguments (support both short and long options)
# This allows manual override
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
    -p|--proxied)
      PROXIED="$2"
      shift 2
      ;;
    -*)
      echo "Usage: $0 -z ZONE_ID -r RECORD_ID -t API_TOKEN -n RECORD_NAME [-p PROXIED]"
      echo "   or: $0 --zone-id ZONE_ID --record-id RECORD_ID --api-token API_TOKEN --record-name RECORD_NAME [--proxied PROXIED]"
      exit 1
      ;;
    *) shift
      ;;
  esac
done

# Ensure all required arguments are provided
if [[ -z "$ZONE_ID" || -z "$RECORD_ID" || -z "$API_TOKEN" || -z "$RECORD_NAME" ]]; then
  echo "Error: Missing required arguments (ZONE_ID, RECORD_ID, API_TOKEN, RECORD_NAME)."
  exit 1
fi

# Convert comma-separated strings to arrays
IFS=',' read -r -a RECORD_IDS <<< "$RECORD_ID"
IFS=',' read -r -a RECORD_NAMES <<< "$RECORD_NAME"
IFS=',' read -r -a PROXIED_VALUES <<< "$PROXIED"

if [ "${#RECORD_IDS[@]}" -ne "${#RECORD_NAMES[@]}" ] || [ "${#RECORD_IDS[@]}" -ne "${#PROXIED_VALUES[@]}" ]; then
  echo "Error: RECORD_ID count (${#RECORD_IDS[@]}) and RECORD_NAME count (${#RECORD_NAMES[@]}) mismatch."
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
    
    # Log to file AND stdout (for Docker logs)
    echo "$current_datetime -> New IP: $IP (Old: $STORED_IP)" | tee -a "$LOG_FILE"
    
    ALL_SUCCESS=true

    for i in "${!RECORD_IDS[@]}"; do
        CURRENT_RECORD_ID="${RECORD_IDS[$i]}"
        CURRENT_RECORD_NAME="${RECORD_NAMES[$i]}"
        CURRENT_PROXIED="${PROXIED_VALUES[$i]}"
        
        echo "Updating DNS record for $CURRENT_RECORD_NAME..."

        # Construct JSON payload using jq if available, safely otherwise
        if command -v jq &> /dev/null; then
            DATA=$(jq -n \
                      --arg type "A" \
                      --arg name "$CURRENT_RECORD_NAME" \
                      --arg content "$IP" \
                      --argjson ttl 3600 \
                      --argjson proxied "$CURRENT_PROXIED" \
                      '{type: $type, name: $name, content: $content, ttl: $ttl, proxied: $proxied}')
        else
            # Fallback (less safe, but compatible if jq install fails)
            DATA="{\"type\":\"A\",\"name\":\"$CURRENT_RECORD_NAME\",\"content\":\"$IP\",\"ttl\":3600,\"proxied\":$CURRENT_PROXIED}"
        fi

        RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$CURRENT_RECORD_ID" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "$DATA")

        HTTP_BODY=$(echo "$RESPONSE" | head -n -1)
        HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

        UPDATE_SUCCESS=false
        if [[ "$HTTP_CODE" -eq 200 ]]; then
            # Check success field in JSON response
            if command -v jq &> /dev/null; then
                 SUCCESS=$(echo "$HTTP_BODY" | jq -r '.success')
                 if [[ "$SUCCESS" == "true" ]]; then
                     # echo "Success: DNS record updated for $CURRENT_RECORD_NAME." | tee -a "$LOG_FILE"
                     UPDATE_SUCCESS=true
                 else
                     echo "Error: API returned 200 but success=false for $CURRENT_RECORD_NAME." | tee -a "$LOG_FILE"
                     echo "Response: $HTTP_BODY" | tee -a "$LOG_FILE"
                 fi
            else
                 # Primitive check if jq missing
                 if [[ "$HTTP_BODY" == *"\"success\":true"* ]]; then
                      # echo "Success: DNS record updated for $CURRENT_RECORD_NAME." | tee -a "$LOG_FILE"
                      UPDATE_SUCCESS=true
                 else
                      echo "Error: Update might have failed for $CURRENT_RECORD_NAME." | tee -a "$LOG_FILE"
                      echo "Response: $HTTP_BODY" | tee -a "$LOG_FILE"
                 fi
            fi
        else
            echo "Error: Failed to update DNS record for $CURRENT_RECORD_NAME. HTTP Code: $HTTP_CODE" | tee -a "$LOG_FILE"
            echo "Response: $HTTP_BODY" | tee -a "$LOG_FILE"
        fi
        
        if [ "$UPDATE_SUCCESS" = false ]; then
            ALL_SUCCESS=false
        fi
    done

    if [ "$ALL_SUCCESS" = true ]; then
        echo "$IP" > "$STORED_IP_FILE"
        echo "All records updated successfully. Saved new IP."
        # echo "All records updated successfully. Saved new IP." | tee -a "$LOG_FILE"
    else
        echo "Warning: Some records failed to update. IP not saved to allow retry." | tee -a "$LOG_FILE"
    fi
else
    # Heartbeat (optional)
    echo "$current_datetime -> IP unchecked ($IP)"
fi
