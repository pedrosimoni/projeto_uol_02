[](README.md)
[](https://www.google.com/search?q=README.en.md)

# Project 2 - Web Server Configuration Using WordPress and Docker on AWS

## Project Overview

The goal of this project is to set up a robust and scalable infrastructure on Amazon Web Services (AWS) to host a WordPress web application. The solution will be built on a microservices architecture using **Docker**, ensuring high availability, automatic scalability, and security. The architecture will be based on an **Application Load Balancer (ALB)** to distribute traffic, an **Auto Scaling Group (ASG)** to manage the scalability of **EC2** instances, an **RDS** database for data persistence, and an **Elastic File System (EFS)** for shared storage of WordPress files. The network will be isolated in a **Virtual Private Cloud (VPC)**, with public and private subnets, and security will be managed through **Security Groups (SGs)** and a **Bastion Host**.

## Technologies Used

  * **Amazon Web Services (AWS)**
  * **Virtual Private Cloud (VPC)**
  * **EC2 (Elastic Compute Cloud)**
  * **RDS (Relational Database Service)**
  * **EFS (Elastic File System)**
  * **Application Load Balancer (ALB)**
  * **Auto Scaling Group (ASG)**
  * **IAM (Identity and Access Management)**
  * **Docker**
  * **WordPress**

## Summary

  - 1.[Network Configuration](https://www.google.com/search?q=%231-network-configuration)
      - 1.1.[VPC Creation](https://www.google.com/search?q=%2311-vpc-creation)
      - 1.2.[Subnet Creation](https://www.google.com/search?q=%2312-subnet-creation)
      - 1.3.[Security Group (SG) Creation](https://www.google.com/search?q=%2313-security-group-sg-creation)
      - 1.4.[Internet Gateway (IGW), NAT Gateways, and Route Table Creation and Configuration](https://www.google.com/search?q=%2314-internet-gateway-igw-nat-gateways-and-route-table-creation-and-configuration)
  - 2.[Database Creation (RDS)](https://www.google.com/search?q=%232-database-creation-rds)
  - 3.[Elastic File System (EFS) Creation](https://www.google.com/search?q=%233-elastic-file-system-efs-creation)
  - 4.[App Load Balancer (ALB), Auto Scaling Group (ASG), and Launch Template Creation](https://www.google.com/search?q=%234-app-load-balancer-alb-auto-scaling-group-asg-and-launch-template-creation)
      - 4.1.[IAM Role and Launch Template](https://www.google.com/search?q=%2341-iam-role-and-launch-template)
      - 4.2.[App Load Balancer (ALB)](https://www.google.com/search?q=%2342-app-load-balancer-alb)
      - 4.3.[Auto Scaling Group (ASG)](https://www.google.com/search?q=%2343-auto-scaling-group-asg)
  - 5.[Bastion Host](https://www.google.com/search?q=%235-bastion-host)
  - 6.[Final Configurations](https://www.google.com/search?q=%236-final-configurations)
  - 7.[Final Considerations and Operation](https://www.google.com/search?q=%237-final-considerations-and-operation)

-----

## 1. Network Configuration

In this section, we will set up the foundation of our network infrastructure, creating a custom VPC with subnets, route tables, and gateways to ensure proper communication and isolation.

### 1.1. VPC Creation

The first step is to create our **VPC (Virtual Private Cloud)**, which will serve as an isolated virtual data center in AWS.

  * `Name`: `desafio-wordpress-vpc`
  * **IPv4 CIDR manual input**
  * `CIDR block`: `10.0.0.0/16`
  * **No IPv6 CIDR block**

### 1.2. Subnet Creation

Next, we will segment our VPC into subnets to organize and isolate resources. The public subnets will host externally accessible components, while the private subnets will house internal resources, such as EC2 instances and the database.

  * **Public Subnet 1:**
      * `Name`: `subnet-wordpress-publica-1`
      * `Availability Zone`: `us-east-1a`
      * `CIDR block`: `10.0.1.0/24`
      * **Additional Configuration:** Enable "Auto-assign public IPv4 address" so that EC2 instances automatically receive public IPs.
  * **Public Subnet 2:**
      * `Name`: `subnet-wordpress-publica-2`
      * `Availability Zone`: `us-east-1b`
      * `CIDR block`: `10.0.2.0/24`
      * **Additional Configuration:** Enable "Auto-assign public IPv4 address" so that EC2 instances automatically receive public IPs.
  * **Private Subnet 1:**
      * `Name`: `subnet-wordpress-privada-1`
      * `Availability Zone`: `us-east-1a`
      * `CIDR block`: `10.0.3.0/24`
  * **Private Subnet 2:**
      * `Name`: `subnet-wordpress-privada-2`
      * `Availability Zone`: `us-east-1b`
      * `CIDR block`: `10.0.4.0/24`

### 1.3. Security Group (SG) Creation

Now, we will define the network traffic rules for our components. **Security Groups** will act as virtual firewalls, controlling inbound and outbound access for each service.

  * `Name`: `DesafioWordpressALBSecurityGroup`
      * `Description`: Allow HTTP/HTTPS traffic from anywhere, directed to our Application Load Balancer.
      * `VPC`: `desafio-wordpress-vpc`
      * **Inbound Rules:**
          * **HTTP:** Allow traffic from `Anywhere` (`0.0.0.0/0`).
          * **HTTPS:** Allow traffic from `Anywhere` (`0.0.0.0/0`).
      * **Outbound Rules:**
          * **All traffic:** Keep default rule that allows traffic to `0.0.0.0/0`.
  * `Name`: `DesafioWordpressEC2SecurityGroup`
      * `Description`: Control inbound traffic to EC2 instances, allowing only communication from the ALB and secure SSH connections.
      * `VPC`: `desafio-wordpress-vpc`
      * **Inbound Rules:**
          * **HTTP:** Allow traffic from `DesafioWordpressALBSecurityGroup`.
          * **NFS (2049):** Allow traffic from `DesafioWordpressEFSSecurityGroup`.
          * **SSH (22):** Allow traffic from `DesafioWordpressBastionHostSecurityGroup`.
      * **Outbound Rules:**
          * **All traffic:** Keep default rule that allows traffic to `0.0.0.0/0`.
  * `Name`: `DesafioWordpressRDSSecurityGroup`
      * `Description`: Ensure that only EC2 instances can communicate with the MySQL database.
      * `VPC`: `desafio-wordpress-vpc`
      * **Inbound Rules:**
          * **MYSQL/Aurora (3306):** Allow traffic from `DesafioWordpressEC2SecurityGroup`.
      * **Outbound Rules:**
          * **All traffic:** Keep default rule that allows traffic to `0.0.0.0/0`.
  * `Name`: `DesafioWordpressEFSSecurityGroup`
      * `Description`: Allow EC2 instances to access the shared file system via NFS.
      * `VPC`: `desafio-wordpress-vpc`
      * **Inbound Rules:**
          * **NFS (2049):** Allow traffic from `DesafioWordpressEC2SecurityGroup`.
      * **Outbound Rules:**
          * **All traffic:** Keep default rule that allows traffic to `0.0.0.0/0`.
  * `Name`: `DesafioWordpressBastionHostSecurityGroup`
      * `Description`: Limit SSH access to the Bastion Host to your IP address only, protecting the private network.
      * `VPC`: `desafio-wordpress-vpc`
      * **Inbound Rules:**
          * **SSH (22):** Allow traffic from `My IP`.
      * **Outbound Rules:**
          * **All traffic:** Keep default rule that allows traffic to `0.0.0.0/0`.

### 1.4. Internet Gateway (IGW), NAT Gateways, and Route Table Creation and Configuration

In this step, we will configure internet access for our subnets. The **Internet Gateway** will enable inbound and outbound communication for public subnets, while the **NAT Gateways** will allow instances in private subnets to securely access the internet.

1.  **Internet Gateway (IGW) Creation:**
      * `Name`: `igw-desafio-wordpress`
      * **Attach to VPC** `desafio-wordpress-vpc`.
2.  **NAT Gateway Creation:**
      * `Name`: `nat-gateway-desafio-wordpress-1`
          * `Subnet`: `subnet-wordpress-publica-1`
          * `Connectivity type`: `Public`
          * **Allocate Elastic IP**.
      * `Name`: `nat-gateway-desafio-wordpress-2`
          * `Subnet`: `subnet-wordpress-publica-2`
          * `Connectivity type`: `Public`
          * **Allocate Elastic IP**.
3.  **Public Route Table Creation:**
      * `Name`: `rtb-desafio-wordpress-publica`
      * `VPC`: `desafio-wordpress-vpc`.
      * **Routes:** Add a route with `Destination: 0.0.0.0/0` and `Target: igw-desafio-wordpress`.
      * **Subnet Associations:** Associate with `subnet-wordpress-publica-1` and `subnet-wordpress-publica-2`.
4.  **Private Route Table Creation:**
      * `Name`: `rtb-desafio-wordpress-privada-1`
      * `VPC`: `desafio-wordpress-vpc`.
      * **Routes:** Add a route with `Destination: 0.0.0.0/0` and `Target: nat-gateway-desafio-wordpress-1`.
      * **Subnet Associations:** Associate with `subnet-wordpress-privada-1`.
      * `Name`: `rtb-desafio-wordpress-privada-2`
      * `VPC`: `desafio-wordpress-vpc`.
      * **Routes:** Add a route with `Destination: 0.0.0.0/0` and `Target: nat-gateway-desafio-wordpress-2`.
      * **Subnet Associations:** Associate with `subnet-wordpress-privada-2`.

## 2. Database Creation (RDS)

In this step, we will provision a MySQL database instance managed by **Amazon RDS**. This guarantees us high availability and automatic backups, keeping our application's data in a secure and isolated environment.

  * `Engine`: `MySQL`
  * `Templates`: `Free tier`
  * `DB instance identifier`: `database-desafio-wordpress`
  * **Configure and save the chosen password.**
  * `DB instance class`: `db.t3.micro`
  * `Storage type`: `General Purpose SSD (gp3)`
  * `Allocated storage`: `20`
  * **Connectivity**:
      * `VPC`: `desafio-wordpress-vpc`
      * `Public access`: `No`
      * `VPC security group`: **choose existing**
          * `Existing VPC security groups`: `DesafioWordpressRDSSecurityGroup`
      * `AZ`: `us-east-1a`
  * `Database authentication`: `Password authentication`
  * **Additional configuration**:
      * `Initial database name`: `wordpress`

## 3. Elastic File System (EFS) Creation

**Amazon EFS** will be our shared file system, allowing all instances in the Auto Scaling Group to access the same WordPress files, such as themes, plugins, and media.

1.  **File System Settings**
      * `Name`: `WordPress File System`
      * `File system type`: `Regional`
      * `Automatic backups`: `Disabled`
      * `Transition into Archive`: `None`
2.  **Network Access**
      * `VPC`: `desafio-wordpress-vpc`
      * `Mount targets`:
          * `us-east-1a`
              * `subnet-wordpress-privada-1`
              * `IPv4 only`
              * `DesafioWordpressEFSSecurityGroup`
          * `us-east-1b`
              * `subnet-wordpress-privada-2`
              * `IPv4 only`
              * `DesafioWordpressEFSSecurityGroup`

## 4. App Load Balancer (ALB), Auto Scaling Group (ASG), and Launch Template Creation

In this section, we will configure the core of our scalable environment. The **Launch Template** will be the blueprint for the EC2 instances, the **Auto Scaling Group** will ensure the number of instances adjusts to demand, and the **Application Load Balancer** will distribute traffic among them.

### 4.1. IAM Role and Launch Template

Let's start by configuring an **IAM Role** so that the EC2 instances can connect to EFS, and then create the **Launch Template** that will serve as the base for our Auto Scaling Group.

1.  **IAM Role**
      * `Trusted entity type`: `AWS service`
      * `Service or use case`: `EC2`
      * `Permissions policies`: `AmazonElasticFileSystemClientReadWriteAccess`
      * `Role name`: `EC2-EFS-Role`
      * **After creation, add a permission (Create inline policy):**
          * `Service`: `EC2`
          * `Action`: `DescribeAvailabilityZones`
          * `Policy name`: `DescribeAZ`
2.  **Launch Template**
      * `Name`: `WordpressTemplate`
      * `Description`: `Template for EC2 hosting Wordpress in Docker.`
      * `Auto scaling guidance`: `Enabled`
      * `Application and OS Images`
          * `Amazon Linux 2023 kernel-6.1 AMI`
      * `Instance type`
          * `t2.micro`
      * `Key pair`: **configure and correctly select a key pair.**
      * `Network settings`
          * `Subnet`: **we will not configure any subnet for now.**
          * `Common security groups`: `DesafioWordpressEC2SecurityGroup`
      * `Resource tags`:
          * `Name`: `WordpressServer`
          * `CostCenter`: `**********`
          * `Project`: `PB - JUN 2025`
      * `Advanced details`
          * `IAM instance profile`: `EC2-EFS-Role`
          * `User data`: **add and correctly configure the user data, ensuring Docker is installed and the connection to EFS and RDS.**

### 4.2. App Load Balancer (ALB)

First, let's create a **Target Group** to facilitate the configuration of the Application Load Balancer. This group will receive instances from our ASG.

1.  **Target Groups**
      * `Target type`: `Instances`
      * `Name`: `WordpressTG`
      * `Protocol`: `HTTP`
      * `Port`: `80`
      * `VPC`: `desafio-wordpress-vpc`
      * `Health check protocol`: `HTTP`
      * `Health check path`: `/`
2.  **Application Load Balancer**
      * `Name`: `WordpressALB`
      * `Scheme`: `Internet-facing`
      * `Load balancer IP address type`: `IPv4`
      * `VPC`: `desafio-wordpress-vpc`
      * `AZ and subnets`: **select both AZs we are using (`us-east-1a`, `us-east-1b`) and our public subnets for each AZ.**
      * `Security group`: `DesafioWordpressALBSecurityGroup`
      * `Listeners and routing`: `HTTP:80 -> WordpressTG`

### 4.3. Auto Scaling Group (ASG)

The **Auto Scaling Group** will use the Launch Template to start EC2 instances in the private subnets and connect them to the Target Group of our Load Balancer, scaling the number of servers based on CPU usage.

  * **Choose launch template**
      * `Name`: `WordpressASG`
      * `Launch template`: `WordpressTemplate`
  * **Choose instance launch options**
      * `VPC`: `desafio-wordpress-vpc`
      * `AZ and subnets`: **select our private subnets (`subnet-wordpress-privada-1`, `subnet-wordpress-privada-2`).**
  * **Integrate with other services**
      * `Load balancing`: `Attach to an existing load balancer`
          * `WordpressTG`
      * `Turn on Elastic Load Balancing health checks`: `Enabled`
      * `Health check grace period`: `30 seconds`
  * **Configure group size and scaling**
      * `Desired capacity`: `2`
      * `Min desired capacity`: `1`
      * `Max desired capacity`: `4`
      * `Target tracking scaling policy`
          * `Scaling policy name`: `Wordpress Target Tracking Policy`
          * `Metric type`: `Average CPU utilization`
          * `Target value`: `65`
          * `Instance warmup`: `300`

## 5. Bastion Host

We will create a **Bastion Host** to allow secure SSH access to the private EC2 instances without exposing these machines to the internet.

  * `Tags`:
      * `Name`: `WordpressBastionHost`
      * `CostCenter`: `**********`
      * `Project`: `PB - JUN 2025`
  * `Application and OS Images`: `Amazon Linux 2023`
  * `Instance type`: `t2.micro`
  * `Key pair name`: **choose your key pair.**
  * **Network settings**:
      * `VPC`: `desafio-wordpress-vpc`
      * `Subnet`: `subnet-wordpress-publica-1`
      * `Auto-assign public IP`: `Enable`
      * `Security groups`: `DesafioWordpressBastionHostSecurityGroup`

## 6. Final Configurations

To finalize the configuration, it is essential to validate the communication between all components, test site access, and scalability.

1.  **Verify instance health:** After creating the Auto Scaling Group, check that the EC2 instances are healthy and communicate correctly with EFS and RDS.
2.  **Test access via Bastion Host:** Connect to the Bastion Host via SSH and, from there, access one of the private EC2 instances to verify internal communication and service installation.
3.  **Access the application:** Get the DNS of the Application Load Balancer and access the site. The WordPress configuration page should appear.
4.  **Finalize WordPress configuration:** Complete the WordPress installation using the database access details (RDS endpoint, database name, user, and password) created earlier.

-----

## 7. Final Considerations and Operation