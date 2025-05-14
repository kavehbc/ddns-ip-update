# Use a lightweight base image with bash and cron installed
FROM debian:latest-slim

# Add metadata about the developer
LABEL maintainer="Developer Name <developer@example.com>" \
      version="1.0" \
      description="A Docker image for updating DDNS records."

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the bash script and any required files into the container
COPY ip-update.bash /app/ip-update.bash
COPY stored_ip.txt /app/stored_ip.txt

# Make the script executable
RUN chmod +x /app/ip-update.bash

# Add a cron job to run the script every 5 minutes
RUN echo "*/5 * * * * /app/ip-update.bash -z $ZONE_ID -r $RECORD_ID -t $API_TOKEN -d $DOMAIN" > /etc/cron.d/ip-update

# Set environment variables for input arguments
ENV ZONE_ID="" \
    RECORD_ID="" \
    API_TOKEN="" \
    DOMAIN=""

# Give execution rights on the cron job file
RUN chmod 0644 /etc/cron.d/ip-update

# Apply the cron job
RUN crontab /etc/cron.d/ip-update

# Start the cron service
CMD ["cron", "-f"]
