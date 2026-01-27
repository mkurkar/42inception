# Developer Documentation

This document provides technical information for developers who want to understand, modify, or extend the Inception project infrastructure.

## Table of Contents

1. [Environment Setup](#environment-setup)
2. [Project Architecture](#project-architecture)
3. [Building and Launching](#building-and-launching)
4. [Container Management](#container-management)
5. [Volume Management](#volume-management)
6. [Networking](#networking)
7. [Service Details](#service-details)
8. [Configuration](#configuration)
9. [Debugging](#debugging)
10. [Extending the Project](#extending-the-project)

## Environment Setup

### Prerequisites

Install the required software:

```bash
# Update system
sudo apt-get update

# Install Docker
sudo apt-get install -y docker.io

# Install Docker Compose
sudo apt-get install -y docker-compose

# Add user to docker group (optional, to avoid using sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verify installations
docker --version
docker-compose --version
```

### Clone and Setup

```bash
# Navigate to project directory
cd /home/mkurkar/42/inception

# Verify directory structure
tree -L 3
```

### Configuration Files

1. **Environment Variables** (`srcs/.env`):
   - Contains non-sensitive configuration
   - Loaded by docker-compose automatically
   - Must never contain actual passwords

2. **Secrets** (`secrets/*.txt`):
   - Contains sensitive credentials
   - Mounted as Docker secrets
   - Should be in `.gitignore`

3. **Docker Compose** (`srcs/docker-compose.yml`):
   - Defines services, networks, volumes
   - References Dockerfiles
   - Configures dependencies

## Project Architecture

### High-Level Overview

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ HTTPS (443)
       ▼
┌─────────────┐
│    NGINX    │ TLS Termination, Reverse Proxy
└──────┬──────┘
       │ FastCGI (9000)
       ▼
┌─────────────┐
│  WordPress  │ PHP-FPM Application Server
└──────┬──────┘
       │ MySQL Protocol (3306)
       ▼
┌─────────────┐
│   MariaDB   │ Database Server
└─────────────┘
```

### Container Communication

Containers communicate via the `inception` Docker bridge network:

- **NGINX** → **WordPress**: FastCGI protocol on port 9000
- **WordPress** → **MariaDB**: MySQL protocol on port 3306
- All communication stays within the Docker network
- Only NGINX port 443 is exposed to the host

### Data Persistence

```
Host Machine                    Container
─────────────────────────────────────────
/home/mkurkar/data/mysql   ←→  /var/lib/mysql (mariadb)
/home/mkurkar/data/wordpress ←→ /var/www/html (wordpress, nginx)
```

## Building and Launching

### Build Process

The build process creates Docker images from Dockerfiles:

```bash
# Build all images
make build
```

This command:
1. Creates data directories at `/home/mkurkar/data/{mysql,wordpress}`
2. Builds each Dockerfile in order
3. Tags images with service names

**Build Steps by Service:**

1. **MariaDB**:
   - Base: Debian Bullseye
   - Installs MariaDB server and client
   - Copies configuration and initialization script
   - Sets up proper permissions

2. **WordPress**:
   - Base: Debian Bullseye
   - Installs PHP 7.4 with FPM and extensions
   - Downloads WP-CLI for WordPress management
   - Copies configuration and setup script

3. **NGINX**:
   - Base: Debian Bullseye
   - Installs NGINX and OpenSSL
   - Copies configuration and setup script
   - Prepares SSL directory

### Launch Process

```bash
# Start all containers
make up
```

This command:
1. Creates the `inception` network if it doesn't exist
2. Creates named volumes if they don't exist
3. Starts containers in dependency order:
   - MariaDB (first, others depend on it)
   - WordPress (waits for MariaDB health check)
   - NGINX (waits for WordPress)

### Initial Container Startup

**MariaDB Container:**
1. Checks if database is initialized
2. If not, runs `mysql_install_db`
3. Starts MySQL temporarily
4. Runs configuration SQL commands
5. Creates database and user
6. Restarts MySQL in foreground

**WordPress Container:**
1. Waits for MariaDB to be accessible
2. Checks if wp-config.php exists
3. If not, downloads WordPress core
4. Creates configuration file
5. Installs WordPress with WP-CLI
6. Creates additional user
7. Starts PHP-FPM in foreground

**NGINX Container:**
1. Generates self-signed SSL certificate
2. Replaces domain name placeholder in config
3. Starts NGINX in foreground

## Container Management

### Useful Docker Commands

```bash
# List all containers
docker ps -a

# List running containers
docker ps

# View container resource usage
docker stats

# Inspect container details
docker inspect <container_name>

# Execute command in running container
docker exec -it <container_name> bash

# View container logs
docker logs <container_name>

# Follow container logs in real-time
docker logs -f <container_name>

# View last 100 lines of logs
docker logs --tail 100 <container_name>
```

### Docker Compose Commands

```bash
# View service status
docker-compose -f srcs/docker-compose.yml ps

# Start specific service
docker-compose -f srcs/docker-compose.yml start <service_name>

# Stop specific service
docker-compose -f srcs/docker-compose.yml stop <service_name>

# Restart specific service
docker-compose -f srcs/docker-compose.yml restart <service_name>

# View logs for specific service
docker-compose -f srcs/docker-compose.yml logs <service_name>

# Rebuild specific service
docker-compose -f srcs/docker-compose.yml build --no-cache <service_name>

# Execute command in service
docker-compose -f srcs/docker-compose.yml exec <service_name> <command>
```

### Accessing Containers

```bash
# Access MariaDB container
docker exec -it mariadb bash

# Access MariaDB database
docker exec -it mariadb mysql -u root -p
# Password is in secrets/db_root_password.txt

# Access WordPress container
docker exec -it wordpress bash

# Run WP-CLI commands
docker exec -it wordpress wp --allow-root plugin list

# Access NGINX container
docker exec -it nginx bash

# Test NGINX configuration
docker exec -it nginx nginx -t
```

## Volume Management

### Volume Details

Volumes are defined in `docker-compose.yml`:

```yaml
volumes:
  db_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/mkurkar/data/mysql
  wp_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/mkurkar/data/wordpress
```

This creates named volumes that bind to specific host directories.

### Volume Commands

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect db_data
docker volume inspect wp_data

# Check volume usage
du -sh /home/mkurkar/data/*

# Backup volumes
sudo tar -czf ~/backup-mysql-$(date +%Y%m%d).tar.gz -C /home/mkurkar/data mysql
sudo tar -czf ~/backup-wordpress-$(date +%Y%m%d).tar.gz -C /home/mkurkar/data wordpress

# Remove volumes (WARNING: deletes data)
make down
docker volume rm db_data wp_data
```

### Data Location

All persistent data is stored on the host at:
- `/home/mkurkar/data/mysql` - MariaDB database files
- `/home/mkurkar/data/wordpress` - WordPress installation files

**Permissions:**
- Owned by Docker container users (mysql:mysql, www-data:www-data)
- Requires `sudo` for host access
- Automatically managed by Docker

## Networking

### Network Configuration

The `inception` network is a custom bridge network:

```yaml
networks:
  inception:
    driver: bridge
```

### Network Commands

```bash
# List networks
docker network ls

# Inspect inception network
docker network inspect inception

# View network connections
docker network inspect inception | grep -A 20 "Containers"

# Test connectivity between containers
docker exec wordpress ping -c 3 mariadb
docker exec nginx ping -c 3 wordpress
```

### DNS Resolution

Docker provides automatic DNS resolution:
- Containers can reach each other by service name
- `wordpress` container connects to `mariadb:3306`
- `nginx` container proxies to `wordpress:9000`

### Port Mapping

Only NGINX exposes a port to the host:

```yaml
ports:
  - "443:443"
```

This maps host port 443 to container port 443.

## Service Details

### MariaDB Service

**Dockerfile Location:** `srcs/requirements/mariadb/Dockerfile`

**Key Components:**
- Base: Debian Bullseye
- Packages: mariadb-server, mariadb-client
- Config: `/etc/mysql/mariadb.conf.d/50-server.cnf`
- Init Script: `/usr/local/bin/init-db.sh`
- Data Directory: `/var/lib/mysql`
- Port: 3306 (internal)

**Configuration File:** `srcs/requirements/mariadb/conf/50-server.cnf`
```ini
bind-address = 0.0.0.0  # Accept connections from all network interfaces
```

**Initialization Script:** `srcs/requirements/mariadb/tools/init-db.sh`
- Reads secrets from `/run/secrets/`
- Initializes database if not exists
- Creates WordPress database and user
- Secures installation (removes test database, anonymous users)

**Environment Variables:**
- `MYSQL_DATABASE` - Database name
- `MYSQL_USER` - Database user

**Secrets:**
- `db_root_password` - Root password
- `db_password` - User password

### WordPress Service

**Dockerfile Location:** `srcs/requirements/wordpress/Dockerfile`

**Key Components:**
- Base: Debian Bullseye
- Packages: PHP 7.4 FPM + extensions, MariaDB client
- WP-CLI: WordPress command-line tool
- Config: `/etc/php/7.4/fpm/pool.d/www.conf`
- Setup Script: `/usr/local/bin/setup-wordpress.sh`
- Working Directory: `/var/www/html`
- Port: 9000 (FastCGI, internal)

**PHP-FPM Configuration:** `srcs/requirements/wordpress/conf/www.conf`
```ini
listen = 9000           # Listen on port 9000
pm = dynamic           # Dynamic process management
pm.max_children = 5    # Maximum child processes
```

**Setup Script:** `srcs/requirements/wordpress/tools/setup-wordpress.sh`
- Waits for MariaDB to be ready
- Downloads WordPress core
- Creates wp-config.php
- Installs WordPress with admin user
- Creates additional author user

**Environment Variables:**
- `MYSQL_DATABASE` - Database name
- `MYSQL_USER` - Database user
- `WP_URL` - WordPress site URL
- `WP_TITLE` - Site title
- `WP_ADMIN_USER` - Admin username
- `WP_ADMIN_PASSWORD` - Admin password
- `WP_ADMIN_EMAIL` - Admin email
- `WP_USER` - Additional user
- `WP_USER_PASSWORD` - User password
- `WP_USER_EMAIL` - User email

**Secrets:**
- `db_password` - Database password

### NGINX Service

**Dockerfile Location:** `srcs/requirements/nginx/Dockerfile`

**Key Components:**
- Base: Debian Bullseye
- Packages: nginx, openssl
- Config: `/etc/nginx/nginx.conf`
- Setup Script: `/usr/local/bin/setup-nginx.sh`
- SSL Directory: `/etc/nginx/ssl/`
- Port: 443 (HTTPS, exposed to host)

**NGINX Configuration:** `srcs/requirements/nginx/conf/nginx.conf`
- Listens on port 443 with SSL
- SSL protocols: TLSv1.2, TLSv1.3 only
- Proxies PHP requests to WordPress FastCGI
- Serves static files directly
- Security headers and restrictions

**Setup Script:** `srcs/requirements/nginx/tools/setup-nginx.sh`
- Generates self-signed SSL certificate
- Configures certificate for 365 days
- Replaces domain name in config
- Starts NGINX in foreground

**Environment Variables:**
- `DOMAIN_NAME` - Server domain name

## Configuration

### Modifying Environment Variables

Edit `srcs/.env`:
```bash
nano srcs/.env
```

After changes:
```bash
make down
make up
```

### Changing Domain Name

1. Edit `srcs/.env`:
   ```bash
   DOMAIN_NAME=newdomain.42.fr
   ```

2. Update hosts file:
   ```bash
   sudo nano /etc/hosts
   ```
   Add:
   ```
   127.0.0.1 newdomain.42.fr
   ```

3. Rebuild:
   ```bash
   make down
   make up
   ```

### Changing Database Credentials

**Warning:** This requires rebuilding the database.

1. Edit secrets:
   ```bash
   nano secrets/db_password.txt
   nano secrets/db_root_password.txt
   ```

2. Clean and rebuild:
   ```bash
   make fclean
   make
   ```

### Adding PHP Extensions

Edit `srcs/requirements/wordpress/Dockerfile`:

```dockerfile
RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-new-extension \  # Add here
    && rm -rf /var/lib/apt/lists/*
```

Rebuild:
```bash
docker-compose -f srcs/docker-compose.yml build --no-cache wordpress
make restart
```

### Modifying NGINX Configuration

1. Edit `srcs/requirements/nginx/conf/nginx.conf`
2. Test configuration:
   ```bash
   docker exec nginx nginx -t
   ```
3. If valid, restart:
   ```bash
   make restart
   ```

## Debugging

### Common Issues

**1. Containers Won't Start**

Check logs:
```bash
make logs
```

Check specific service:
```bash
docker logs mariadb
docker logs wordpress
docker logs nginx
```

**2. MariaDB Connection Refused**

Check if MariaDB is running:
```bash
docker exec mariadb mysqladmin ping
```

Check MariaDB logs:
```bash
docker logs mariadb
```

Verify credentials:
```bash
cat secrets/db_password.txt
```

**3. WordPress Can't Connect to Database**

Test connection from WordPress container:
```bash
docker exec wordpress mysql -h mariadb -u wpuser -p$(cat secrets/db_password.txt) -e "SELECT 1"
```

**4. NGINX Returns 502 Bad Gateway**

Check if WordPress is running:
```bash
docker ps | grep wordpress
```

Test PHP-FPM:
```bash
docker exec wordpress ps aux | grep php-fpm
```

Check NGINX error log:
```bash
docker logs nginx 2>&1 | grep error
```

**5. Permission Denied on Volumes**

Fix permissions:
```bash
sudo chown -R 999:999 /home/mkurkar/data/mysql
sudo chown -R 33:33 /home/mkurkar/data/wordpress
```

### Debug Mode

Enable detailed logging in docker-compose.yml:

```yaml
services:
  mariadb:
    command: mysqld --verbose
```

Or run containers with debug commands:

```bash
docker exec wordpress bash -c "tail -f /var/log/php7.4-fpm.log"
```

### Rebuilding Specific Service

```bash
# Rebuild without cache
docker-compose -f srcs/docker-compose.yml build --no-cache mariadb

# Recreate container
docker-compose -f srcs/docker-compose.yml up -d --force-recreate mariadb
```

## Extending the Project

### Adding a New Service

1. **Create Directory Structure:**
   ```bash
   mkdir -p srcs/requirements/newservice/{conf,tools}
   ```

2. **Create Dockerfile:**
   ```bash
   nano srcs/requirements/newservice/Dockerfile
   ```

3. **Add to docker-compose.yml:**
   ```yaml
   newservice:
     container_name: newservice
     build:
       context: ./requirements/newservice
       dockerfile: Dockerfile
     image: newservice
     restart: unless-stopped
     networks:
       - inception
   ```

4. **Build and Start:**
   ```bash
   make down
   make up
   ```

### Adding Redis Cache (Bonus)

1. Create Redis Dockerfile
2. Install Redis Object Cache plugin in WordPress
3. Configure WordPress to use Redis
4. Add to docker-compose.yml

### Adding FTP Server (Bonus)

1. Create vsftpd Dockerfile
2. Configure FTP to point to WordPress volume
3. Set up FTP users
4. Add to docker-compose.yml

### Adding Adminer (Bonus)

1. Create Adminer Dockerfile
2. Configure to connect to MariaDB
3. Expose on different port
4. Add to docker-compose.yml

## Testing

### Integration Tests

```bash
# Test MariaDB connectivity
docker exec wordpress mysql -h mariadb -u wpuser -p$(cat secrets/db_password.txt) -e "SHOW DATABASES;"

# Test WordPress installation
curl -k https://mkurkar.42.fr

# Test SSL/TLS version
openssl s_client -connect mkurkar.42.fr:443 -tls1_2

# Test PHP-FPM
docker exec wordpress php -v

# Test WP-CLI
docker exec wordpress wp --allow-root core version
```

### Performance Testing

```bash
# Check resource usage
docker stats

# Test response time
time curl -k https://mkurkar.42.fr

# Load testing with Apache Bench
ab -n 100 -c 10 https://mkurkar.42.fr/
```

## Best Practices

1. **Never commit secrets** to version control
2. **Use .dockerignore** to reduce image size
3. **Run processes in foreground** (no daemons)
4. **Use health checks** for dependencies
5. **Set restart policies** for reliability
6. **Use specific package versions** for reproducibility
7. **Clean up** after package installations
8. **Set proper permissions** on files and directories
9. **Use secrets** for sensitive data
10. **Document changes** in comments

## References

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [WP-CLI Documentation](https://wp-cli.org/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.org/documentation/)
