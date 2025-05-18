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

## Cloudflare Zone ID
Zone IDs can be extracted by calling the following API:


```bash
curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
-H "Authorization: Bearer $API_TOKEN" \
-H "Content-Type: application/json" | jq '.' > output.json
```

## Running the Docker Image
To run the Docker image, use the following steps:

1. Build the Docker image:
   ```bash
   docker build -t kavehbc/ddns-ip-update .
   ```

2. Run the Docker container:
   ```bash
   docker run -d \
     --name ddns-updater \
     -e ZONE_ID=<your_zone_id> \
     -e RECORD_ID=<your_record_id> \
     -e API_TOKEN=<your_api_token> \
     -e DOMAIN=<your_domain> \
     -e CRON_INTERVAL="*/10 * * * *" \ # Optional: Set to run every 10 minutes
     -v $(pwd)/stored_ip.txt:/app/stored_ip.txt \
     kavehbc/ddns-ip-update
   ```

3. Run the Docker container using Docker Compose:
   ```bash
   docker-compose up -d
   ```

   Ensure the `docker-compose.yml` file is properly configured with the required environment variables:
   ```yaml
   services:
     ddns-updater:
       environment:
         - ZONE_ID=<your_zone_id>
         - RECORD_ID=<your_record_id>
         - API_TOKEN=<your_api_token>
         - DOMAIN=<your_domain>
         - CRON_INTERVAL="*/10 * * * *" # Optional: Set to run every 10 minutes
   ```

Replace `<your_zone_id>`, `<your_record_id>`, `<your_api_token>`, and `<your_domain>` with your actual values. The `CRON_INTERVAL` environment variable is optional and defaults to every 5 minutes.

## Notes
- The `stored_ip.txt` file is used to store the last known IP address to avoid unnecessary updates.
- The cron job inside the container runs the script at the specified interval.

## Developer(s)
Kaveh Bakhtiyari - [Website](http://bakhtiyari.com) | [Medium](https://medium.com/@bakhtiyari)
  | [LinkedIn](https://www.linkedin.com/in/bakhtiyari) | [Github](https://github.com/kavehbc)

## Contribution
Feel free to join the open-source community and contribute to this repository.