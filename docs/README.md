[![English](https://img.shields.io/badge/English-blue.svg)](README.en.md)
[![Português](https://img.shields.io/badge/Português-green.svg)](README.md)

# Projeto 2 - Configuração de Servidor Web Utilizando Wordpress e Docker na AWS

## Objeitvo

![alt text](../img/diagrama.png)

## 1 Configuração da Rede

### 1.1 Criação da VPC

- `Name`: `desafio-wordpress-vpc`
- IPv4 CIDR manual input
- Bloco CIDR: `10.0.0.0/16`
- No IPv6 CIDR block

### 1.2 Criação das Sub-redes

Todas vão ser criadas na VPC que acabamos de criar, as sub-redes públicas serão responsáveis por abrigar os gateways NAT, já as sub-redes privadas serão responsáveis por abrigar as instâncias EC2 que estarão rodando nosso aplicativo.

**Sub-rede Pública 1:**
- `Name`: `subnet-wordpress-publica-1`
    - Zona de Disponibilidade: `us-east-1a`
    - Bloco CIDR: `10.0.1.0/24`
- **Configuração Adicional:** Habilitar "Auto-assign public IPv4 address" para que as instâncias EC2 recebam IPs públicos automaticamente.

**Sub-rede Pública 2:**
- `Name`: `subnet-wordpress-publica-2`
    - Zona de Disponibilidade: `us-east-1b`
    - Bloco CIDR: `10.0.2.0/24`
- **Configuração Adicional:** Habilitar "Auto-assign public IPv4 address" para que as instâncias EC2 recebam IPs públicos automaticamente.

**Sub-rede Privada 1:**
- `Name`: `subnet-wordpress-privada-1`
    - Zona de Disponibilidade: `us-east-1a`
    - Bloco CIDR: `10.0.3.0/24`

**Sub-rede Privada 1:**
- `Name`: `subnet-wordpress-privada-2`
    - Zona de Disponibilidade: `us-east-1b`
    - Bloco CIDR: `10.0.4.0/24`

### 1.3 Criação dos Security Groups (SG)

Aqui já vamos fazer a criação e configuração dos Security Groups para já facilitar posteriormente na configuração de novos serviços. Perceba que aqui já dá para ter uma boa ideia de como o sistema vai se comunicar.

- `Name`: `DesafioWordpressALBSecurityGroup`
    - **Description**: Allow HTTP/HTTPS from anywhere
    - **VPC**: desafio-wordpress-vpc
    - **Regras de Entrada (Inbound Rules):**
        - **HTTP:** Permitir tráfego de `Anywhere` (`0.0.0.0/0`) para que o site seja acessível publicamente.
        - **HTTPS:** Permitir tráfego de `Anywhere` (`0.0.0.0/0`) para que o site seja acessível publicamente.
    - **Regras de Saída (Outbound Rules):**
        - **All trafic:** Manter regra padrão que permite tráfego para `0.0.0.0/0`.

- `Name`: `DesafioWordpressEC2SecurityGroup`
    - **Description**: Allow HTTP from ALB and NFS from EFS
    - **VPC**: desafio-wordpress-vpc
    - **Regras de Entrada (Inbound Rules):**
        - **HTTP:** Permitir tráfego de `DesafioWordpressALBSecurityGroup`.
        - **HTTPS:** Permitir tráfego de `DesafioWordpressALBSecurityGroup`.
    - **Regras de Saída (Outbound Rules):**
        - **All trafic:** Manter regra padrão que permite tráfego para `0.0.0.0/0`.

- `Name`: `DesafioWordpressRDSSecurityGroup`
    - **Description**: Allow MySQL from EC2
    - **VPC**: desafio-wordpress-vpc
    - **Regras de Entrada (Inbound Rules):**
        - **MYSQL/Aurora (3306):** Permitir tráfego de `DesafioWordpressEC2SecurityGroup`.
    - **Regras de Saída (Outbound Rules):**
        - **All trafic:** Manter regra padrão que permite tráfego para `0.0.0.0/0`.

- `Name`: `DesafioWordpressEFSSecurityGroup`
    - **Description**: Allow NFS from EC2
    - **VPC**: desafio-wordpress-vpc
    - **Regras de Entrada (Inbound Rules):**
        - **NFS (2049):** Permitir tráfego de `DesafioWordpressEC2SecurityGroup`.
    - **Regras de Saída (Outbound Rules):**
        - **All trafic:** Manter regra padrão que permite tráfego para `0.0.0.0/0`.

- `Name`: `DesafioWordpressBastionHostSecurityGroup`
    - **Description**: Allow SSH from Me
    - **VPC**: desafio-wordpress-vpc
    - **Regras de Entrada (Inbound Rules):**
        - **SSH (22):** Permitir tráfego de `My IP` permitindo que você acesse as instâncias EC2 usando o protocolo SSH pelo Bastion Host.
    - **Regras de Saída (Outbound Rules):**
        - **All trafic:** Manter regra padrão que permite tráfego para `0.0.0.0/0`.

- **Agora vamos voltar e adicionar duas regras em `DesafioWordpressEC2SecurityGroup`:**
    - **NFS** vindo de `DesafioWordpressEFSSecurityGroup`.
    - **SSH** vindo de `DesafioWordpressBastionHostSecurityGroup`.

### 1.4 Criação e Configuração do Internet Gateway (IGW), NAT Gateways e Tabelas de Roteamento

1.  **Criação do Internet Gateway (IGW):**
    - `Name`: `igw-desafio-wordpress`
    - `Ações` > `Anexar à uma VPC` > `Anexar IGW na nossa VPC`

2. **Criação dos NAT Gateways:**
    - `Name`: `nat-gateway-desafio-wordpress-1`
        - `Subnet`: `subnet-wordpress-publica-1`
        - `Connectivity type`: `Public`
        - `Allocate Elastic IP`
    - `Name`: `nat-gateway-desafio-wordpress-2`
        - `Subnet`: `subnet-wordpress-publica-2`
        - `Connectivity type`: `Public`
        - `Allocate Elastic IP`

3.  **Criação da Tabela de Roteamento Pública:**
    - `Name`: `rtb-desafio-wordpress-publica`
        - **VPC:** `desafio-wordpress-vpc`.
    - **Rotas:** Adicionar uma rota com `Destination: 0.0.0.0/0` (todo o tráfego da internet) e `Target: igw-desafio-wordpress`.
    - **Associações de Sub-rede:** Associar esta tabela de roteamento às nossas sub-rede públicas (subnet-wordpress-publica-1 e subnet-wordpress-publica-2).

4.  **Criação das Tabelas de Roteamento Privadas:**
    - `Name`: `rtb-desafio-wordpress-privada-1`
        - **VPC:** `desafio-wordpress-vpc`.
    - **Rotas:** Adicionar uma rota com `Destination: 0.0.0.0/0` (todo o tráfego da internet) e `Target: nat-gateway-desafio-wordpress-1`.
    - **Associações de Sub-rede:** Associar à subnet-wordpress-publica-1.

    - `Name`: `rtb-desafio-wordpress-privada-2`
        - **VPC:** `desafio-wordpress-vpc`.
    - **Rotas:** Adicionar uma rota com `Destination: 0.0.0.0/0` (todo o tráfego da internet) e `Target: nat-gateway-desafio-wordpress-2`.
    - **Associações de Sub-rede:** Associar à subnet-wordpress-publica-2.

## 2 Criação do Banco de Dados (RDS)

- `Engine`: `MySQL`
- `Templates`: `Free tier`
- `DB instance identifier`: `database-desafio-wordpress`
- **configure e guarde a senha escolhida**
- `DB instance class`: `db.t3.micro`
- `Storage type`: `General Purpose SSD (gp3)`
- `Allocated storage`: `20`
- **Connectivity**:
    - **não vamos conectar à nenhuma instância EC2 por agora**
    - `VPC`: `desafio-wordpress-vpc`
    - `Public access`: `No`
    - `VPC security group`: **choose existing**
        - `Existing VPC security groups`: `DesafioWordpressRDSSecurityGroup`
        - `AZ`: `us-east-1a`
- `Database authentication`: `Password authentication`
- **Additional configuration**:
    - `Initial database name`: `wordpress`

## 3 Criação do Elastic File System (EFS)

1. **File System Settings**
    - `Name`: `WordPress File System`
    - `File system type`: `Regional`
    - `Automatic bakcups`: `Desativado`
    - `Transition into Archive`: `None`

2. **Network Access**
    - `VPC`: `desafio-wordpress-vpc`
    - `Mount targets`:
        - `us-east-1a`
            - `subnet-wordpress-privada-1`
            - `IPv4 only`
            - `DesafioWordpressEFSSecurityGroup`
        - `us-east-1b`
            - `subnet-wordpress-privada-2`
            - `IPv4 only`
            - `DesafioWordpressEFSSecurityGroup`

## 4 Criação do App Load Balancer (ALB), Auto Scaling Group (ASG) e Launch Template

### 4.1 IAM Role e Launch Template

Vamos começar configurando um IAM role para que as instâncias EC2 tenham acesso ao nosso EFS, e támbem o Launch Template que servirá de base para o nosso ASG.

1. **IAM Role**
    - `Trusted entity type`: `AWS service`
    - `Service or use case`: `EC2`
    - `Use case`: `EC2`
    - `Permissions policies`: `AmazonElasticFileSystemClientReadWriteAccess`
    - `Role name`: `EC2-EFS-Role`
    - `Description`: `IAM role for Wordpress EC2 instances to connect to EFS services.`
    - `Description`: `Allows EC2 instances to call EFS services.`
    - **Após a criação adicione uma permissão (Create inline policy):**
        - `Service`: `EC2`
        - `Action`: `DescribeAvailabilityZones`
        - `Policy name`: `DescribeAZ`


2. **Launch Template**
    - `Name`: `WordpressTemplate`
    - `Description`: `Template for EC2 hosting Wordpress in Docker.`
    - `Auto scaling guidance`: `Enabled`
    - `Application and OS Images`
        - `Amazon Linux 2023 kernel-6.1 AMI`
    - `Instance type`
        - `t2.micro`
    - `Key pair`: **configure e selecione corretamente um key pair**
    - `Network settings`
        - `Subnet`: **não vamos configurar nenhuma subnet por agora**
        - `Common security groups`: `DesafioWordpressEC2SecurityGroup`
    - `Resource tags` (todas as tags devem ser aplicadas nas instâncias e nos volumes):
        - `Name`: `WordpressServer`
        - `CostCenter`: `**********`
        - `Project`: `PB - JUN 2025`
    - `Advance details`
        - `IAM instance profile`: `EC2-EFS-Role`
        - `User data`: **aicione e configure corretamente o user data**

### 4.2 App Load Balancer (ALB)

Vamos primeiro criar um target group para facilitar a nossa criação do Application Load Balancer.

1. **Target Groups**
- `Target type`: `Instances`
- `Name`: `WordpressTG`
- `Protocol`: `HTTP`
- `Port`: `80`
- `VPC`: `desafio-wordpress-vpc`
- `Health check protocol`: `HTTP`
- `Health check path`: `/`

2. **Application Load Balancer**
- `Name`: `WordpressALB`
- `Scheme`: `Internet-facing`
- `Load balancer IP address type`: `IPv4`
- `VPC`: `desafio-wordpress-vpc`
- `AZ and subnets`: **selecionar ambas AZs que estamos usando (us-east-1a, us-east-1b) e nossas subnets públicas referente à cada AZ**
- `Security group`: `DesafioWordpressALBSecurityGroup`
- `Listeners and routing`: `HTTP:80 -> WordpressTG`

### 4.3 Auto Scaling Group (ASG)
- **Choose launch template**
    - `Name`: `WordpressASG`
    - `Launch template`: `WordpressTemplate`
- **Choose instance launch options**
    - `VPC`: `desafio-wordpress-vpc`
    - `AZ and subnets`: **selecionar nossas subnets privadas (subnet-wordpress-privada-1, subnet-wordpress-privada-2)**
- **Integrate with other services**
    - `Load balancing`: `Attach to an existing load balancer`
        - `WordpressTG`
    - `Turn on Elastic Load Balancing health checks`: `Enabled`
    - `Health check grace period`: `30 segundos`
- **Configure group size and scaling**
    - `Desired capacity`: `2`
    - `Min desired capacity`: `1`
    - `Max desired capacity`: `4`
    - `Target tracking scaling policy`
        - `Scaling policy name`: `Wordpress Target Tracking Policy`
        - `Metric type`: `Average CPU utilization`
        - `Target value`: `65`
        - `Instance warmup`: `300`

## 5 Bastion Host

A bastion host se cosiste apenas de uma instância EC2 em uma subnet pública e que tem acesso por ssh às outras instâncias.

- `Tags` (todas as tags devem ser aplicadas nas instâncias e nos volumes):
    - `Name`: `WordpressBastionHost`
    - `CostCenter`: `**********`
    - `Project`: `PB - JUN 2025`
- `Application and OS Images`: `Amazon Linux 2023`
- `Instance type`: `t2.micro`
- `Key pair name`: **escolha a sua key pair**
- **Network settings**:
    - `VPC`: `desafio-wordpress-vpc`
    - `Subnet`: `subnet-wordpress-publica-1`
    - `Auto-assign public IP`: `Enable`
    - `**Select existing security group**
        - `Common security groups`: `DesafioWordpressBastionHostSecurityGroup`
