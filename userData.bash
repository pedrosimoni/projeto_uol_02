#!/bin/bash

SECRET_NAME="DBSecret"
AWS_REGION="us-east-2"
DB_NAME="wordpress"

# Instala pacotes necessários (awscli para buscar o segredo e os endpoints)
yum update -y
yum install -y docker amazon-efs-utils python3-botocore nc jq

# Instala docker-compose 
curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Instala AWS CLI v2
sudo dnf install awscli

# Busca o ID do EFS e o Endereço do RDS usando o AWS CLI
EFS_ID=$(aws efs describe-file-systems --query "FileSystems[?Tags[?Key=='Name' && Value=='WordPress File System']].FileSystemId" --output text --region ${AWS_REGION})
DB_HOST=$(aws rds describe-db-instances --db-instance-identifier database-desafio-wordpress --query "DBInstances[0].Endpoint.Address" --output text --region ${AWS_REGION})

# Busca o segredo do Secrets Manager
SECRET=$(aws secretsmanager get-secret-value --secret-id ${SECRET_NAME} --region ${AWS_REGION} --query SecretString --output text)
DB_USER=$(echo $SECRET | jq -r .username)
DB_PASSWORD=$(echo $SECRET | jq -r .password)

# Roda o Docker
service docker start

# Cria ponto de montagem para o EFS e o monta
mkdir -p /mnt/efs/wordpress
mount -t efs -o tls ${EFS_ID}:/ /mnt/efs/wordpress

# Cria o arquivo docker-compose.yaml e roda o docker-compose
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

# Implementação da função de espera usando Netcat (nc)
until nc -vz $DB_HOST 3306; do
  sleep 5
done

docker-compose -f /home/ec2-user/docker-compose.yaml up -d