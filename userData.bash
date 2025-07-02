#!/bin/bash

yes | sudo apt-get update
yes | sudo apt-get upgrade
yes | sudo apt-get install nginx 
yes | sudo systemctl enable nginx 

echo "HTML" > /var/www/html/index.nginx-debian.html

sudo systemctl reload nginx

echo "Script" > /usr/local/bin/monitor-nginx.sh

export DISCORD_WEBHOOK="<webhook>"

echo 'DISCORD_WEBHOOK="<webhook>"' | sudo tee -a /etc/environment > /dev/null # substituímos >> por tee -a e desconsideramos a saída com > /dev/null

sudo crontab -e # aprender a fazer
