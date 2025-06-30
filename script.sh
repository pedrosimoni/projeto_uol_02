#!/bin/bash

SERVER_URL="192.168.1.200"

LOG_FILE="/var/log/monitoramento.log"

DISCORD_WEBHOOK="https://discord.com/api/webhooks/1388665431811686541/IG5_8zHjWTYSBZ0v0Z_ul0ZzZmiL6oliNH-4BQyDeWG1CelDZDa9s6K-FSPGRjHt2C5-"


http_status=$(curl -s -w "%{http_code}" -o /dev/null "$SERVER_URL")
if [ $http_status = 200 ]; then
        message="Success - $(date +%d:%m:%y_%T)"
else
        message="Failure - $(date +%d:%m:%y_%T)"
        curl -X POST -H "Content-Type: application/json" -d "{\"content\": \"$message\"}" "$DISCORD_WEBHOOK"
fi

echo "$message" >> "$LOG_FILE"