#!/bin/bash
# Service name for the Laravel backend
SERVICE_NAME="laravel-backend.service"
# CPU usage threshold
THRESHOLD=80
# Interval between checks in seconds
INTERVAL=10
while true; do
  # Get the average CPU usage in percentage
  CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
  # Convert CPU usage to an integer for comparison
  CPU_USAGE_INT=${CPU_USAGE%.*}
  if [ "$CPU_USAGE_INT" -gt "$THRESHOLD" ]; then
    echo "CPU usage is $CPU_USAGE%. Restarting $SERVICE_NAME..."
    sudo systemctl restart $SERVICE_NAME
    if [ $? -eq 0 ]; then
      echo "$SERVICE_NAME restarted successfully."
    else
      echo "Failed to restart $SERVICE_NAME."
    fi
  else
    echo "CPU usage is $CPU_USAGE%. No action required."
  fi
  # Wait for the specified interval
  sleep $INTERVAL
