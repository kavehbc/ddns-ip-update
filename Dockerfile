# Use a lightweight base image with bash and cron installed
FROM debian:stable-slim

# Add metadata about the developer
LABEL maintainer="Kaveh Bakhtiyari" \
        version="1.0" \
        description="A Docker image for updating IP address in DDNS records using Cloudflare API" \
        license="Apache License 2.0" \
        homepage="https://kaveh.ai" \
        repository="https://hub.docker.com/repository/docker/kavehbc/ddns-ip-update" \
        vcs-url="https://github.com/kavehbc/ddns-ip-update" \
        vcs-type="git" \
        vcs-ref="master"

        # Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    cron \
    bash \
    jq \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the bash script and any required files into the container
COPY . .

# Make the script executable
RUN chmod +x /app/script/*.bash

# Start the cron service
ENTRYPOINT [ "/app/script/setup.bash" ]
