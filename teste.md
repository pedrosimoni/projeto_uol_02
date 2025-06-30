# Projeto 1 - Configuração de Servidor Web com Monitoramento na AWS

Este projeto visa desenvolver e testar habilidades essenciais em Linux, Amazon Web Services (AWS) e automação de processos. O objetivo principal é configurar um ambiente de servidor web monitorado Nginx na AWS, que inclua monitoramento de disponibilidade e notificações automáticas em caso de indisponibilidade do serviço.

## Etapa 1 - Configuração do Ambiente

### Criação da VPC

**Tags:**
- `Name`: `PB - JUN 2025`
- `CostCenter`: `C092000024`
- `Project`: `PB - JUN 2025`

### Criação das Sub-redes

**Sub-rede Pública 1:**
- `Name`: `subnet-pb-jun-2025-publica-1`
- Zona de Disponibilidade: `us-east-2a`
- Bloco CIDR: `10.0.1.0/24`
- **Configuração Adicional:** Habilitar "Auto-assign public IPv4 address" para que as instâncias EC2 recebam IPs públicos automaticamente.
- **Tags:** Aplicar as mesmas tags da VPC.

**Sub-rede Pública 2:**
- `Name`: `subnet-pb-jun-2025-publica-2`
- Zona de Disponibilidade: `us-east-2b` (Sugestão: usar uma AZ diferente da primeira pública para maior resiliência)
- Bloco CIDR: `10.0.2.0/24`
- **Configuração Adicional:** Habilitar "Auto-assign public IPv4 address".
- **Tags:** Aplicar as mesmas tags da VPC.

**Sub-rede Privada 1:**
- `Name`: `subnet-pb-jun-2025-privada-1`
- Zona de Disponibilidade: `us-east-2a`
- Bloco CIDR: `10.0.3.0/24`
- **Tags:** Aplicar as mesmas tags da VPC.

**Sub-rede Privada 2:**
- `Name`: `subnet-pb-jun-2025-privada-2`
- Zona de Disponibilidade: `us-east-2b` (Sugestão: usar uma AZ diferente da primeira privada para maior resiliência)
- Bloco CIDR: `10.0.4.0/24`
- **Tags:** Aplicar as mesmas tags da VPC.

### Criação e Configuração do Internet Gateway (IGW) e Tabelas de Roteamento

1.  **Criação do Internet Gateway (IGW):**
    - `Name`: `igw-pb-jun-2025`
    - **Ação:** Anexar o IGW à VPC criada (`PB - JUN 2025`).

2.  **Criação da Tabela de Roteamento Pública:**
    - `Name`: `rtb-pb-jun-2025-publica`
    - **Ação:** Associar à VPC `PB - JUN 2025`.
    - **Rotas:** Adicionar uma rota com `Destination: 0.0.0.0/0` (todo o tráfego da internet) e `Target: igw-pb-jun-2025`.
    - **Associações de Sub-rede:** Associar esta tabela de roteamento às sub-redes públicas (`subnet-pb-jun-2025-publica-1` e `subnet-pb-jun-2025-publica-2`).

### Configuração da Instância EC2

-   **Nome:** `PB - JUN 2025`
-   **Tags:** Aplicar as tags `CostCenter: C092000024` e `Project: PB - JUN 2025` para a instância e seus volumes.
-   **Sistema Operacional (OS):** `Ubuntu` 
-   **Tipo de Instância:** `t2.micro` 
-   **Key Pair:** Criar um novo par de chaves ou selecionar um existente (`pb-jun-2025`).
-   **Configurações de Rede:** 
    -   **VPC:** `PB - JUN 2025`.
    -   **Subnet:** `subnet-pb-jun-2025-publica-1`. 
    -   **Auto-assign public IP:** `Enable`.
    -   **Security Group:** Criar um novo Security Group. 
        -   **Name:** `sg-pb-jun-2025-web`
        -   **Description:** `Security Group for Compass UOL PB project 1 (JUN 2025)`
        -   **Regras de Entrada (Inbound Rules):**
            -   **SSH (Porta 22):** Permitir tráfego do seu IP (por segurança). 
            -   **HTTP (Porta 80):** Permitir tráfego de `Anywhere` (`0.0.0.0/0`) para que o site seja acessível publicamente.

### Acessar a Máquina via SSH


```sh
chmod 400 pb-jun-2025.pem
ssh -i pb-jun-2025.pem ubuntu@<IP da máquina>
```

-----

## Etapa 2 - Configuração do Servidor Web

### Instalação e Inicialização do Nginx

Dentro da instância EC2 (via SSH):

```sh
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install nginx 
sudo systemctl enable nginx # Garante que o Nginx inicie automaticamente com o sistema.
sudo systemctl status nginx # Verifica o status do Nginx (a saída esperada é 'active (running)').
```

### Criação da Página HTML

```sh
sudo vim /var/www/html/pb-jun-2025.html
```

Cole o conteúdo da sua página HTML e salve.

### Configuração do Nginx

Para garantir que a página padrão do Nginx continue acessível em `http://<IP_DA_MAQUINA>/` e sua nova página em `http://<IP_DA_MAQUINA>/pb-jun-2025`, editaremos o arquivo de configuração padrão. 

```sh
sudo vim /etc/nginx/sites-available/default
```

A configuração deve ficar assim:

```sh
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;

    index index.html index.htm;

    # Este bloco específico para a URL /pb-jun-2025 que deve ser adicionado
    location = /pb-jun-2025 {
        try_files /pb-jun-2025.html =404;
    }

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Testar e Aplicar a Configuração do Nginx

1.  **Testar a sintaxe da configuração do Nginx:**
```sh
    sudo nginx -t
```

2.  **Recarregar o Nginx:**
    Aplicar as novas configurações sem interromper o serviço.
```sh
    sudo systemctl reload nginx
```

-----

## Etapa 3 - Monitoramento e Notificações

### Criação do Script de Monitoramento

Crie o arquivo do script e cole seu conteúdo dentro. É recomendado que scripts de sistema fiquem em `/usr/local/bin/` ou `/opt/scripts/`.

```sh
sudo vim /usr/local/bin/alerta-nginx.sh
```

### Configurar o Script para Rodar Automaticamente (Cron)

1.  **Edite o crontab do usuário `root`**, pois o script precisa de privilégios para escrever em `/var/log/`.

```sh
    sudo crontab -e
```

2.  **Adicione a seguinte linha no final do arquivo:**

```sh
    */1 * * * * /bin/bash /usr/local/bin/alerta-nginx.sh
```

Para verificar as crontabs existentes:

```sh
crontab -l
```

## Etapa 4 - Automação e Testes

Para testar a solução podemos entrar pelo navegador em uma máquina externa em `http://<ip_da_instância>` e em `http://<ip_da_instância>/pb-jun-2025` para verificar se as páginas estão sendo apropiadamente servidas.

Podemos também executar requisições HTTP GET para ver se retornam nossas páginas.

Além disso podemos rodar nosso script manualmente e posteriormente verificar o arquivo de logs e as notificações no discord.