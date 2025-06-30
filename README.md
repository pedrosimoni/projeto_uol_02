# Projeto 1 - Compass





Somente com IPv4 - 10.0.0.0/16

Tags:
- Name: PB - JUN 2025
- CostCenter: C092000024
- Project: PB - JUN 2025

### Criação das Sub-redes

Rede 1:
- Name: subnet-pb-jun-2025-publica-1
- Zona: us-east-2a
- Mask: 10.0.1.0/24
- Adicionar tags
- Acionar auto-assign public IPv4 address

Rede 2:
- Name: subnet-pb-jun-2025-publica-2
- Zona: us-east-2a
- Mask: 10.0.2.0/24
- Adicionar tags
- Acionar auto-assign public IPv4 address

Rede 3:
- Name: subnet-pb-jun-2025-privada-1
- Zona: us-east-2a
- Mask: 10.0.3.0/24
- Adicionar tags

Rede 4:
- Name: subnet-pb-jun-2025-privada-2
- Zona: us-east-2a
- Mask: 10.0.4.0/24
- Adicionar tags

### Criação e configuração do Internet Gateway

- Criar igw e dar respectivas tags 
  - Name: igw-pb-jun-2025
- Associar igw à VPC criada (PB - JUN 2025) 
- Criar route table associada à mesma VPC e dar respectivas tags
  - Name: rtb-pb-jun-2025
- Associar rtb às subnets públicas
- Adicionar rota
  - destination: 0.0.0.0/0
  - target: igw 

### Configuração da Máquina

- Nome: PB - JUN 2025
  - CostCenter: C092000024
  - Project: PB - JUN 2025
  - todas as tags aplicadas para instâncias e volumes
- OS: Ubuntu
- Key Pair: pb-jun-2025
- Network Settings:
  - VPC: PB - JUN 2025
  - Subnet: subnet-pb-jun-2025-publica-1
  - Auto-assign public IP: Enable
  - Security Group: 
    - Name: pb-jun-2025
    - Description: Security Group for Compass UOL PB project 1 (JUN 2025)
    - Rules:
      - ssh do meu IP
      - HTTP do meu IP

### Acessar máquina

```sh
ssh -i pb-jun-2025.pem ubuntu@<IP da máquina>
```

## Etapa 2 - Configuração do Servidor Web

### Instalação e inicializando do Nginx

```sh
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install nginx
sudo systemctl enable nginx
```

### Configuração do Nginx

```sh
sudo touch /var/www/html/pb-jun-2025.html
```

Adicionar a seguinte linha em */etc/nginx/sites-available/default*:
```sh
    location = /pb-jun-2025 {
            try_files /pb-jun-2025.html =404;
    }
```

Ativar o site:
```sh
sudo ln -s /etc/nginx/sites-available/pb-jun-2025 /etc/nginx/sites-enabled/
```

## Etapa 3 - Monitoramento e Notificações

Após copiar o script, rode:
```sh
sudo chmod 666 /var/log
touch /var/log/monitoramento.log
sudo chmod 666 /var/log/monitoramento.log
bash /var/scripts/alertas-nginx.sh
```
Para adicionar a crontab:

```sh
crontab -e
```

e adicionar 

```sh
*/1 * * * * /bin/bash /var/scripts/alertas-nginx.sh
```

Para ver todas as crontabs:

```sh
crontab -l
```