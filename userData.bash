#!/bin/bash

EFS_ID="fs-0b09ab72cfeb183b1"
DB_HOST="database-desafio-wordpress.c7cyq8wsifmj.us-east-2.rds.amazonaws.com"
DB_USER="admin"
DB_PASSWORD="password"
DB_NAME="wordpress"

# Instala pacotes necessários
yum update -y
yum install  -y docker amazon-efs-utils python3-botocore
curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Roda o Docker
service docker start

# Cria ponto de montagem para o EFS e o monta
mkdir /mnt/efs/wordpress -p
mount -t efs -o tls ${EFS_ID}:/ /mnt/efs/wordpress

# Cria o arquivo docker-compose.yaml e rodar docker-compose
cat <<EOF > /home/ec2-user/docker-compose.yaml
services:
  wordpress:
    image: wordpress
    restart: always
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: ${DB_HOST}:3306
      WORDPRESS_DB_USER: ${DB_USER}
      WORDPRESS_DB_PASSWORD: ${DB_PASSWORD}
      WORDPRESS_DB_NAME: ${DB_NAME}
    volumes:
      - /mnt/efs/wordpress:/var/www/html
EOF

docker-compose -f /home/ec2-user/docker-compose.yaml up -d