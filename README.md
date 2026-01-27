# Inception

*This project has been created as part of the 42 curriculum by mkurkar.*

## Description

Inception is a system administration project that involves setting up a small infrastructure using Docker and Docker Compose. The project consists of three main services:

- **NGINX**: A web server configured with TLSv1.2/TLSv1.3 to serve as the entry point
- **WordPress**: A content management system with PHP-FPM
- **MariaDB**: A database server for WordPress data persistence

The entire infrastructure runs in isolated Docker containers with proper networking, volumes, and security measures. Each service is built from custom Dockerfiles using Debian Bullseye as the base image, ensuring complete control over the configuration and deployment process.

### Key Features

- Custom Docker images built from scratch (no pre-built images from DockerHub)
- SSL/TLS encryption for secure HTTPS connections
- Persistent data storage using Docker named volumes
- Isolated network environment for container communication
- Automatic container restart on crash
- Secret management for sensitive credentials
- Two-user WordPress setup (admin and regular user)

## Instructions

### Prerequisites

- Docker and Docker Compose installed
- Make utility
- Root/sudo access for creating data directories
- At least 2GB of free disk space

### Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd inception
```

2. Configure your hosts file to point the domain to localhost:
```bash
sudo echo "127.0.0.1 mkurkar.42.fr" >> /etc/hosts
```

3. Build and start the infrastructure:
```bash
make
```

### Compilation and Execution

The Makefile provides several commands:

- `make` or `make all`: Build images and start containers
- `make build`: Build Docker images only
- `make up`: Start containers in detached mode
- `make down`: Stop and remove containers
- `make start`: Start existing containers
- `make stop`: Stop running containers
- `make restart`: Restart containers
- `make logs`: View container logs in real-time
- `make ps`: List running containers
- `make clean`: Remove containers and images
- `make fclean`: Full cleanup including volumes and data
- `make re`: Rebuild everything from scratch

### Accessing the Services

After successful deployment:

- **WordPress Site**: https://mkurkar.42.fr
- **WordPress Admin Panel**: https://mkurkar.42.fr/wp-admin

Credentials are stored in `secrets/credentials.txt`

## Project Description

### Docker Architecture

This project uses Docker containerization to create an isolated, reproducible infrastructure. Each service runs in its own container with:

- **Custom Dockerfiles**: Built from Debian Bullseye base images
- **Docker Secrets**: Secure credential management
- **Named Volumes**: Persistent data storage at `/home/mkurkar/data`
- **Bridge Network**: Isolated container communication

### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|-----------------|-------------------|
| **Isolation** | Full OS isolation with hypervisor | Process-level isolation using kernel features |
| **Resource Usage** | Heavy (GBs of RAM, full OS) | Lightweight (MBs, shared kernel) |
| **Startup Time** | Minutes | Seconds |
| **Portability** | Limited (large image files) | High (small images, easy distribution) |
| **Performance** | Near-native but overhead exists | Near-native with minimal overhead |
| **Use Case** | Multiple OS types, strong isolation | Microservices, scalable applications |

**Why Docker for this project?** Docker provides sufficient isolation for service separation while maintaining excellent performance and resource efficiency. The ability to quickly rebuild and deploy makes it ideal for development and testing.

### Secrets vs Environment Variables

| Feature | Secrets | Environment Variables |
|---------|---------|---------------------|
| **Security** | Encrypted at rest, mounted as files | Plain text in container |
| **Visibility** | Not visible in `docker inspect` | Visible in process environment |
| **Storage** | Separate files, not in images | Can be in docker-compose.yml |
| **Rotation** | Easy to update without rebuild | Requires container restart |
| **Best For** | Passwords, API keys, certificates | Configuration, non-sensitive data |

**Implementation**: This project uses Docker secrets for database passwords (`db_root_password`, `db_password`) and environment variables for non-sensitive configuration like domain names and database names.

### Docker Network vs Host Network

| Type | Docker Network (Bridge) | Host Network |
|------|------------------------|--------------|
| **Isolation** | Containers have isolated network | Direct host network access |
| **Port Conflicts** | No conflicts between containers | Potential conflicts |
| **Performance** | Slight overhead from NAT | Native performance |
| **Security** | Better isolation | Direct exposure |
| **Service Discovery** | Container name resolution | Manual IP management |

**Choice**: This project uses a custom bridge network (`inception`) to provide isolation while allowing seamless communication between containers using service names (e.g., `mariadb:3306`).

### Docker Volumes vs Bind Mounts

| Feature | Named Volumes | Bind Mounts |
|---------|--------------|-------------|
| **Management** | Docker-managed | Manual path management |
| **Portability** | Portable across hosts | Host path-dependent |
| **Performance** | Optimized by Docker | Direct filesystem access |
| **Backups** | Docker volume commands | Standard filesystem tools |
| **Permissions** | Docker handles permissions | Manual permission setup |

**Implementation**: This project uses named volumes (`db_data`, `wp_data`) configured to bind to specific host directories (`/home/mkurkar/data/{mysql,wordpress}`), combining the benefits of both approaches - Docker management with explicit host location.

## Resources

### Official Documentation

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Documentation](https://wordpress.org/support/)
- [MariaDB Documentation](https://mariadb.org/documentation/)

### Tutorials and Articles

- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Understanding Docker Volumes](https://docs.docker.com/storage/volumes/)
- [NGINX SSL/TLS Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)

### AI Usage

AI tools were used in this project for:

1. **Research and Learning**: Understanding Docker networking concepts and best practices
2. **Configuration Guidance**: Reviewing NGINX SSL/TLS configuration options
3. **Script Development**: Assistance with bash script structure for initialization scripts
4. **Documentation**: Structuring and organizing project documentation
5. **Troubleshooting**: Debugging container startup issues and permission problems

AI was NOT used for:
- Direct code generation without understanding
- Copying configurations without customization
- Bypassing the learning process

All implementations were reviewed, understood, and customized for this specific project's requirements.

## Technical Choices

### Base Image: Debian Bullseye

**Reason**: Stable, well-documented, official support, smaller than Ubuntu, larger package repository than Alpine.

### Service Architecture

1. **Three-tier architecture**: Presentation (NGINX) → Application (WordPress) → Data (MariaDB)
2. **Single responsibility**: Each container runs one main service
3. **Dependency management**: Using `depends_on` with health checks for proper startup order

### Security Measures

- SSL/TLS encryption for all web traffic
- Docker secrets for credential management
- No hardcoded passwords in Dockerfiles or docker-compose.yml
- Restricted file permissions on secret files (600)
- Non-root user execution where possible (www-data, mysql)

### Persistence Strategy

- Database storage: `/home/mkurkar/data/mysql`
- WordPress files: `/home/mkurkar/data/wordpress`
- Survives container restarts and recreations
- Easy to backup and restore

## Project Structure

```
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── 50-server.cnf
        │   └── tools/
        │       └── init-db.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        │       └── setup-nginx.sh
        └── wordpress/
            ├── Dockerfile
            ├── .dockerignore
            ├── conf/
            │   └── www.conf
            └── tools/
                └── setup-wordpress.sh
```

## License

This project is part of the 42 school curriculum.
