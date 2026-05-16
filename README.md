# Inception

*This project has been created as part of the 42 curriculum by mkurkar.*

## Description

Inception is a system administration project that involves setting up a small infrastructure using Docker and Docker Compose. The project consists of three main services:

- **NGINX**: A web server configured with TLSv1.2/TLSv1.3 as the sole entry point on port 443
- **WordPress**: A content management system with PHP-FPM (no nginx)
- **MariaDB**: A database server for WordPress data persistence

The entire infrastructure runs in isolated Docker containers with proper networking, volumes, and security measures. Each service is built from custom Dockerfiles using Debian Bullseye as the base image, ensuring complete control over the configuration and deployment process.

### Key Features

- Custom Docker images built from scratch (no pre-built images from DockerHub)
- SSL/TLS encryption for secure HTTPS connections (TLSv1.2/TLSv1.3 only)
- Persistent data storage using Docker named volumes at `/home/mkurkar/data`
- Isolated bridge network for container communication
- Automatic container restart on crash
- Docker secrets for all sensitive credentials (DB passwords, WP passwords)
- Two-user WordPress setup (admin and regular user)

## Instructions

### Prerequisites

- Docker and Docker Compose (v2) installed
- Make utility
- Root/sudo access for creating data directories
- At least 2GB of free disk space

### Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd inception
```

2. Create the secrets files (not committed to git):
```bash
echo "your_root_db_password" > secrets/db_root_password.txt
echo "your_db_password"      > secrets/db_password.txt
echo "your_wp_admin_pass"    > secrets/wp_admin_password.txt
echo "your_wp_user_pass"     > secrets/wp_user_password.txt
```

3. Copy and configure the environment file:
```bash
cp srcs/.env.sample srcs/.env
# Edit srcs/.env if you need to change domain, usernames, or paths
```

4. Add the domain to your hosts file:
```bash
echo "127.0.0.1 mkurkar.42.fr" | sudo tee -a /etc/hosts
```

5. Build and start the infrastructure:
```bash
make
```

### Makefile Commands

| Command | Description |
|---------|-------------|
| `make` / `make all` | Create data dirs, build images, start containers |
| `make build` | Create data dirs and build Docker images only |
| `make up` | Start containers in detached mode |
| `make down` | Stop and remove containers |
| `make start` | Start existing stopped containers |
| `make stop` | Stop running containers |
| `make restart` | Stop then start containers |
| `make logs` | Stream container logs |
| `make ps` | List project containers and their status |
| `make clean` | Remove containers and project images |
| `make fclean` | Full cleanup: containers, images, volumes, and host data |
| `make re` | Full rebuild from scratch |

### Accessing the Services

After successful deployment:

- **WordPress Site**: https://mkurkar.42.fr
- **WordPress Admin Panel**: https://mkurkar.42.fr/wp-admin

Credentials are managed via Docker secrets in the `secrets/` directory (gitignored).  
See `secrets/credentials.txt` for a reference to which file contains which credential.

## Project Description

### Docker Architecture

This project uses Docker containerization to create an isolated, reproducible infrastructure. Each service runs in its own container with:

- **Custom Dockerfiles**: Built from Debian Bullseye (penultimate stable)
- **Docker Secrets**: Secure credential management for all passwords
- **Named Volumes**: Persistent data storage at `/home/mkurkar/data`
- **Bridge Network**: Isolated container communication via the `inception` network

### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|-----------------|-------------------|
| **Isolation** | Full OS isolation with hypervisor | Process-level isolation using kernel features |
| **Resource Usage** | Heavy (GBs of RAM, full OS) | Lightweight (MBs, shared kernel) |
| **Startup Time** | Minutes | Seconds |
| **Portability** | Limited (large image files) | High (small images, easy distribution) |
| **Performance** | Near-native but with overhead | Near-native with minimal overhead |
| **Use Case** | Multiple OS types, strong isolation | Microservices, scalable applications |

**Why Docker for this project?** Docker provides sufficient isolation for service separation while maintaining excellent performance and resource efficiency. The ability to quickly rebuild and deploy makes it ideal for development and testing environments.

### Secrets vs Environment Variables

| Feature | Secrets | Environment Variables |
|---------|---------|---------------------|
| **Security** | Mounted as in-memory tmpfs files | Plain text in container environment |
| **Visibility** | Not visible in `docker inspect` | Visible in `docker inspect` |
| **Storage** | Separate files, never baked into images | Can leak into image layers |
| **Best For** | Passwords, API keys, certificates | Configuration, non-sensitive data |

**Implementation**: This project uses Docker secrets for all passwords (`db_root_password`, `db_password`, `wp_admin_password`, `wp_user_password`) and environment variables for non-sensitive configuration such as domain names, database names, and usernames.

### Docker Network vs Host Network

| Type | Docker Network (Bridge) | Host Network |
|------|------------------------|--------------|
| **Isolation** | Containers have isolated network namespace | Direct host network access |
| **Port Conflicts** | No conflicts between containers | Potential conflicts with host services |
| **Performance** | Slight overhead from virtual network | Native performance |
| **Security** | Strong isolation from host | Direct exposure to host network |
| **Service Discovery** | Container name DNS resolution | Manual IP management |

**Choice**: This project uses a custom bridge network (`inception`) to provide isolation while enabling seamless inter-container communication via service names (e.g., `mariadb:3306`, `wordpress:9000`). `network: host` and `--link` are explicitly forbidden by the subject.

### Docker Volumes vs Bind Mounts

| Feature | Named Volumes | Bind Mounts |
|---------|--------------|-------------|
| **Management** | Docker-managed lifecycle | Manual host path management |
| **Portability** | Portable, Docker handles location | Host path-dependent |
| **Compose Declaration** | Declared in `volumes:` block | Declared inline in service |
| **Subject Compliance** | Required by the subject | Forbidden by the subject |

**Implementation**: This project uses named volumes (`db_data`, `wp_data`) declared in the `volumes:` block of `docker-compose.yml`. The local driver is configured to store data at `/home/mkurkar/data/{mysql,wordpress}` on the host as required by the subject.

## Resources

### Official Documentation

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Documentation](https://wordpress.org/support/)
- [MariaDB Documentation](https://mariadb.org/documentation/)

### Tutorials and Articles

- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Understanding Docker Volumes](https://docs.docker.com/storage/volumes/)
- [NGINX SSL/TLS Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [PID 1 and Zombie Processes in Containers](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/)

### AI Usage

AI tools were used in this project for:

1. **Research and Learning**: Understanding Docker networking concepts and best practices
2. **Configuration Guidance**: Reviewing NGINX SSL/TLS configuration options
3. **Script Development**: Assistance with bash script structure for initialization scripts
4. **Debugging**: Identifying container startup issues and permission problems
5. **Documentation**: Structuring and organizing project documentation

All implementations were reviewed, understood, and customized for this specific project's requirements.

## Project Structure

```
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                        # gitignored — never committed
│   ├── credentials.txt
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env                        # gitignored — never committed
    ├── .env.sample                 # committed template (no passwords)
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
