#!/bin/bash

SERVER_URL="<EC2_IP>/pb-jun-2025"

LOG_FILE="/var/log/stats-nginx.log"

http_code=$(curl -s -w "%{http_code}" -o /dev/null "$SERVER_URL") # faz a requisição HTTP para o servidor e filtra apenas o http_code
if [ $http_code = 200 ]; then # verifica se o http_code é 200: servidor respondeu normalmente
        message="Success - $(date +%d:%m:%y_%T)"
else
        message="Failure - $(date +%d:%m:%y_%T)"
        curl -X POST -H "Content-Type: application/json" -d "{\"content\": \"$message\"}" "$DISCORD_WEBHOOK" # faz o POST HTTP para o webhook do discord
fi

echo "$message" >> "$LOG_FILE" # faz o log da mensagem de log