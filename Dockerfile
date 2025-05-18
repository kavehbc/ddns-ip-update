# Use a lightweight base image with bash and cron installed
FROM debian:stable-slim

# Add metadata about the developer
LABEL maintainer="Kaveh Bakhtiyari" \
      version="1.0" \
      description="A Docker image for updating IP address in DDNS records using Cloudflare API"

# Set environment variables for input arguments
# CRON_INTERVAL default to every 5 minutes
ENV ZONE_ID="" \
    RECORD_ID="" \
    API_TOKEN="" \
    DOMAIN="" \
    CRON_INTERVAL="*/5 * * * *"
    
# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    cron \
    bash
#    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the bash script and any required files into the container
COPY . .

# Make the script executable
RUN chmod +x /app/ip-update.bash
RUN chmod +x /app/setup.bash

# Start the cron service
ENTRYPOINT [ "/app/setup.bash" ]