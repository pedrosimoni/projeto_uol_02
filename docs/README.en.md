[![English](https://img.shields.io/badge/English-blue.svg)](README.en.md)
[![Português](https://img.shields.io/badge/Português-green.svg)](README.md)

# Project 1 - Web Server Configuration with Monitoring on AWS

This project aims to develop and test basic skills in Linux, Amazon Web Services (AWS), and process automation. The main objective is to configure a monitored Nginx web server environment on AWS, which includes availability monitoring and automatic notifications in case of service unavailability.

## Table of Contents

- [Project 1 - Web Server Configuration with Monitoring on AWS](#project-1---web-server-configuration-with-monitoring-on-aws)
  - [Table of Contents](#table-of-contents)
  - [1 Environment Configuration](#1-environment-configuration)
    - [1.1 VPC Creation](#11-vpc-creation)
    - [1.2 Subnet Creation](#12-subnet-creation)
    - [1.3 Internet Gateway (IGW) and Route Table Creation and Configuration](#13-internet-gateway-igw-and-route-table-creation-and-configuration)
    - [1.4 EC2 Instance Configuration](#14-ec2-instance-configuration)
    - [1.5 Result](#15-result)
    - [1.6 Accessing the Machine via SSH](#16-accessing-the-machine-via-ssh)
  - [2 Web Server Configuration](#2-web-server-configuration)
    - [2.1 Nginx Installation and Initialization](#21-nginx-installation-and-initialization)
    - [2.2 Custom HTML Page Creation](#22-custom-html-page-creation)
    - [2.3 Nginx Configuration](#23-nginx-configuration)
    - [2.4 Test and Apply Nginx Configuration](#24-test-and-apply-nginx-configuration)
  - [3 Monitoring and Notifications](#3-monitoring-and-notifications)
    - [3.1 Monitoring Script Creation](#31-monitoring-script-creation)
    - [3.2 Configure the Script to Run Automatically (Cron)](#32-configure-the-script-to-run-automatically-cron)
  - [4 Test and Automation](#4-test-and-automation)
  - [5. References](#5-references)

## 1 Environment Configuration

### 1.1 VPC Creation
- `Name`: `PB - JUN 2025`
- IPv4 CIDR manual input
- CIDR Block: `10.0.0.0/16`
- No IPv6 CIDR block
- **Tags (these will be our default tags):**
- `CostCenter`: `**********`
- `Project`: `PB - JUN 2025`

### 1.2 Subnet Creation

All will be created in the VPC we just created

**Public Subnet 1:**
- `Name`: `subnet-pb-jun-2025-publica-1`
- Availability Zone: `us-east-2a`
- CIDR Block: `10.0.1.0/24`
- `Apply Tags`
- **Additional Configuration:** Enable "Auto-assign public IPv4 address" for EC2 instances to automatically receive public IPs.

**Public Subnet 2:**
- `Name`: `subnet-pb-jun-2025-publica-2`
- Availability Zone: `us-east-2b` (Suggestion: use a different AZ than the first public for greater resilience)
- CIDR Block: `10.0.2.0/24`
- `Apply Tags`
- **Additional Configuration:** Enable "Auto-assign public IPv4 address".

**Private Subnet 1:**
- `Name`: `subnet-pb-jun-2025-privada-1`
- Availability Zone: `us-east-2a`
- CIDR Block: `10.0.3.0/24`
- `Apply Tags`

**Private Subnet 2:**
- `Name`: `subnet-pb-jun-2025-privada-2`
- Availability Zone: `us-east-2b` (Suggestion: use a different AZ than the first private for greater resilience)
- CIDR Block: `10.0.4.0/24`
- `Apply Tags`

### 1.3 Internet Gateway (IGW) and Route Table Creation and Configuration

1.  **Internet Gateway (IGW) Creation:**
    - `Name`: `igw-pb-jun-2025`
    - **VPC:** `PB - JUN 2025`
    - `Apply Tags`
    - `Attach IGW to our VPC`

2.  **Public Route Table Creation:**
    - `Name`: `rtb-pb-jun-2025-publica`
    - **VPC:** `PB - JUN 2025`.
    - `Apply Tags`

    - **Routes:** Add a route with `Destination: 0.0.0.0/0` (all internet traffic) and `Target: igw-pb-jun-2025`.
    - **Subnet Associations:** Associate this route table with the public subnets (`subnet-pb-jun-2025-publica-1` and `subnet-pb-jun-2025-publica-2`).

### 1.4 EC2 Instance Configuration

-   **Name:** `PB - JUN 2025` (instances and volumes)
-   `Apply Tags` (instances and volumes)
-   **Operating System (OS):** `Ubuntu`
-   **Type of Instance:** `t2.micro`
-   **Key Pair:** Create a new key pair or select an existing one (`pb-jun-2025`).
-   **Network Settings:**
    -   **VPC:** `PB - JUN 2025`.
    -   **Subnet:** `subnet-pb-jun-2025-publica-1`.
    -   **Auto-assign public IP:** `Enable`.
    -   **Security Group:** Create a new Security Group.
        -   **Name:** `pb-jun-2025-web`
        -   **Description:** `Security Group for Compass UOL PB project 1 (JUN 2025)`
        -   **Inbound Rules:**
            -   **SSH (Port 22):** Allow traffic from your IP (for security).
            -   **HTTP (Port 80):** Allow traffic from `Anywhere` (`0.0.0.0/0`) for the website to be publicly accessible.

### 1.5 Result

![alt text](aws_details.png)

### 1.6 Accessing the Machine via SSH

```sh
chmod 400 pb-jun-2025.pem
ssh -i pb-jun-2025.pem ubuntu@<machine_IP>
```

![alt text](img/connected_to_ec2.png)

## 2 Web Server Configuration

### 2.1 Nginx Installation and Initialization

Inside the EC2 instance (via SSH):

```sh
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install nginx
sudo systemctl enable nginx # Ensures Nginx starts automatically with the system.
sudo systemctl status nginx # Expected output is 'enabled' and 'active (running)'.
```

![alt text](img/nginx_page.png)

### 2.2 Custom HTML Page Creation

```sh
sudo vim /var/www/html/pb-jun-2025.html
```

**Add your content to the file**

### 2.3 Nginx Configuration

To ensure the default Nginx page remains accessible at `http://<MACHINE_IP>/` and your new page at `http://<MACHINE_IP>/pb-jun-2025`, we will edit the default configuration file.

```sh
sudo vim /etc/nginx/sites-available/default
```

The configuration should look like this:

```sh
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;

    # In my specific case, the default html file created is index.nginx-debian.html
    index index.html index.nginx-debian.html;

    # This specific block for the URL /pb-jun-2025 must be added
    location = /pb-jun-2025 {
        try_files /pb-jun-2025.html =404;
    }

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### 2.4 Test and Apply Nginx Configuration

1.  **Test Nginx configuration syntax:**

```sh
sudo nginx -t
```

2.  **Reload Nginx:**
    Apply the new configurations without interrupting the service.

```sh
sudo systemctl reload nginx
```

![alt text](img/nginx_ready.png)


## 3 Monitoring and Notifications

### 3.1 Monitoring Script Creation

It is recommended that system scripts be placed in `/usr/local/bin/` or `/opt/scripts/`.

```sh
sudo vim /usr/local/bin/monitor-nginx.sh
```

Script:

```sh
#!/bin/bash

SERVER_URL="<ec2_ip>/pb-jun-2025"

LOG_FILE="/var/log/stats-nginx.log"

http_code=$(curl -s -w "%{http_code}" -o /dev/null "$SERVER_URL") # performs the HTTP request to the server and filters only the http_code
if [ $http_code = 200 ]; then # checks if the http_code is 200: server responded normally
        message="Success - $(date +%d:%m:%y_%T)"
else
        message="Failure - $(date +%d:%m:%y_%T)"
        curl -X POST -H "Content-Type: application/json" -d "{\"content\": \"$message\"}" "$DISCORD_WEBHOOK" # performs the HTTP POST to the discord webhook
fi

echo "$message" >> "$LOG_FILE" # logs the message
```

For the script to work, the global variable **DISCORD_WEBHOOK** must be created:

```sh
export DISCORD_WEBHOOK="<webhook>"
sudo vim /etc/environment # Place DISCORD_WEBHOOK="<webhook>"
```

To test, let's run:

```sh
sudo bash /usr/local/bin/monitor-nginx.sh
```

No message should appear. But you can see the output with:

```sh
sudo cat /var/log/stats-nginx.log
```

![alt text](img/log-nginx.png)

### 3.2 Configure the Script to Run Automatically (Cron)

1.  **Edit the `root` user's crontab**, as the script requires privileges to write to `/var/log/`.

```sh
sudo crontab -e
```

2.  **Add the following line at the end of the file:**

```sh
*/1 * * * * /bin/bash /usr/local/bin/monitor-nginx.sh
```

The fields are, separated by space: minute, hour, day, month, day of the week, shell, script.

To view existing crontabs:

```sh
sudo crontab -l
```

![alt text](img/crontab.png)

## 4 Test and Automation

To stop the Nginx process and stop serving the page:

```sh
sudo systemctl stop nginx
```

We can use this opportunity to test our notification when the server is down.

![alt text](img/ds-error.png)

We can see that after running the command, the program started sending notifications. We can also confirm this from the log file:

![alt text](img/error-log.png)

## 5. References

- [Amazon Virtual Private Cloud (VPC) Documentation](https://docs.aws.amazon.com/vpc/?icmpid=docs_homepage_featuredsvcs)
- [Amazon Elastic Compute Cloud (Amazon EC2) Documentation](https://docs.aws.amazon.com/ec2/?icmpid=docs_homepage_featuredsvcs)
- [nginx Documentation](https://nginx.org/en/docs/)
- [Cron Jobs Configuration and Usage Guide](https://www.pantz.org/software/cron/croninfo)