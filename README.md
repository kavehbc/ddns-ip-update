# ddns-ip-update
DynamicDNS IP Update on Cloudflare

## Overview
This project updates a Dynamic DNS (DDNS) record on Cloudflare with the current public IP address using a bash script and a Docker container.

## Bash Script Input Arguments
The bash script `ip-update.bash` accepts the following input arguments from Cloudflare:

- `-t` or `--api-token`: The API token for authentication.
- `-z` or `--zone-id`: The Zone ID of the DNS record.
- `-r` or `--record-id`: The Record ID of the DNS record. (Can be comma-separated for multiple records)
- `-n` or `--record-name`: The record name to update. (Can be comma-separated for multiple records)
- `-p` or `--proxied`: Proxy status (true/false, default: false). (Can be comma-separated for each record, or single value for all)

## Cloudflare Zone ID
Zone IDs can be extracted by calling the following API:


```bash
curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
-H "Authorization: Bearer $API_TOKEN" \
-H "Content-Type: application/json" | jq '.' > output.json
```

## Building a Multi-Platforms

```bash
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t kavehbc/ddns-ip-update:latest .
```

## Docker Image
To run the Docker image, use the following steps:

1. Build the Docker image:
   
   For local architecture:
   ```bash
   docker build -t kavehbc/ddns-ip-update .
   ```
   
   For multiple platforms (requires [Docker Buildx](https://docs.docker.com/build/building/multi-platform/)):

   ```bash
   docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t kavehbc/ddns-ip-update .
   ```

2. Run the Docker container:
   ```bash
   docker run -d \
     --name ddns-updater \
     -e API_TOKEN=<your_api_token> \
     -e ZONE_ID=<your_zone_id> \
     -e RECORD_ID=<your_record_id1>,<your_record_id2> \
     -e RECORD_NAME=<your_dns_record_name1>,<your_dns_record_name2> \
     -e PROXIED=false,true \ # Optional: Set to true if you want to proxy the traffic through Cloudflare
     -e CRON_INTERVAL="*/10 * * * *" \ # Optional: Set to run every 10 minutes
     -v $(pwd)/stored_ip.txt:/app/stored_ip.txt \
     -v $(pwd)/ip-update.log:/app/ip-update.log \
     kavehbc/ddns-ip-update
   ```

3. Run the Docker container using Docker Compose:

   ```bash
   docker-compose --env-file=./docker.env up -d
   ```

   Ensure the `docker-compose.yml` file is properly configured with the required environment variables:

   ```yaml
   services:
     ddns-updater:
       image: kavehbc/ddns-ip-update
       environment:
         - API_TOKEN=<your_api_token>
         - ZONE_ID=<your_zone_id>
         - RECORD_ID=<your_record_id1>,<your_record_id2>
         - RECORD_NAME=<your_dns_record_name1>,<your_dns_record_name2>
         - PROXIED=false,true # Optional: Set to true if you want to proxy the traffic through Cloudflare
         - CRON_INTERVAL=*/10 * * * * # Optional: Set to run every 10 minutes
       volumes:
         - ./log/:/app/log/
   ```

**Note:**  
Replace `<your_zone_id>`, `<your_record_id>`, `<your_api_token>`, and `<your_dns_record_name>` with your actual values.  
The `CRON_INTERVAL` environment variable is optional and defaults to every 5 minutes if not set.
The `PROXIED` environment variable is optional and defaults to `false` if not set.
Multiple records can be updated by comma-separating the `RECORD_ID`, `RECORD_NAME`, and `PROXIED` values.

You can pass environment variables directly in the `docker-compose.yml` file as shown above, or use an `.env` file and reference them in the compose file.
A template file `docker.env.template` is provided to help you set up the environment variables. You can rename it to `docker.env` and update the values.

```bash
cp docker.env.template docker.env
# Edit docker.env with your actual values
docker-compose --env-file=./docker.env up -d
```

## Notes
- `/app/log/stored_ip.txt`: It stores the last known IP address to avoid unnecessary updates.
- `/app/log/ip-update.log`: It contains the log of the updates with date and updated IP address.
- The cron job inside the container runs the script at the specified interval.

## References
- [Docker Hub](https://hub.docker.com/repository/docker/kavehbc/ddns-ip-update)
- [GitHub Repository](https://github.com/kavehbc/ddns-ip-update)

## Developer(s)
Kaveh Bakhtiyari - [Website](http://bakhtiyari.com) | [Medium](https://medium.com/@bakhtiyari)
  | [LinkedIn](https://www.linkedin.com/in/bakhtiyari) | [Github](https://github.com/kavehbc)

## Contribution
Feel free to join the open-source community and contribute to this repository.