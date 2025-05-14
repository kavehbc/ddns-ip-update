# ddns-ip-update
DynamicDNS IP Update on Cloudflare

## Overview
This project updates a Dynamic DNS (DDNS) record on Cloudflare with the current public IP address using a bash script and a Docker container.

## Bash Script Input Arguments
The bash script `ip-update.bash` accepts the following input arguments from Cloudflare:

- `-z` or `--zone-id`: The Zone ID of the DNS record.
- `-r` or `--record-id`: The Record ID of the DNS record.
- `-t` or `--api-token`: The API token for authentication.
- `-d` or `--domain`: The domain name to update.

## Running the Docker Image
To run the Docker image, use the following steps:

1. Build the Docker image:
   ```bash
   docker build -t ddns-ip-update .
   ```

2. Run the Docker container:
   ```bash
   docker run -d \
     --name ddns-updater \
     -e ZONE_ID=<your_zone_id> \
     -e RECORD_ID=<your_record_id> \
     -e API_TOKEN=<your_api_token> \
     -e DOMAIN=<your_domain> \
     -v $(pwd)/stored_ip.txt:/app/stored_ip.txt \
     ddns-ip-update
   ```

Replace `<your_zone_id>`, `<your_record_id>`, `<your_api_token>`, and `<your_domain>` with your actual values.

## Notes
- The `stored_ip.txt` file is used to store the last known IP address to avoid unnecessary updates.
- The cron job inside the container runs the script every 5 minutes.
