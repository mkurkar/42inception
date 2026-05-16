# User Documentation

This document provides instructions for end users and administrators on how to use and manage the Inception WordPress infrastructure.

## Overview

The Inception project provides a secure, containerized WordPress website with the following services:

- **WordPress Website**: A fully functional WordPress CMS
- **Admin Panel**: WordPress dashboard for content management
- **Database**: MariaDB database for data storage
- **Web Server**: NGINX with SSL/TLS encryption

## Getting Started

### Prerequisites

Before starting, ensure you have:
- Docker and Docker Compose v2 installed
- Access to a terminal/command line
- The project files in `/home/mkurkar/42/inception`
- Sufficient disk space (minimum 2GB free)

### Initial Setup

1. **Configure Domain Resolution**

   Add the domain to your hosts file:
   ```bash
   sudo nano /etc/hosts
   ```

   Add this line:
   ```
   127.0.0.1 mkurkar.42.fr
   ```

   Save and exit (Ctrl+X, Y, Enter)

2. **Build and Start the Services**

   Navigate to the project directory:
   ```bash
   cd /home/mkurkar/42/inception
   ```

   Build and start everything:
   ```bash
   make
   ```

   Wait 1-2 minutes for all services to initialize on the first run (WordPress is downloaded and installed automatically).

## Starting and Stopping the Project

### Build and Start All Services

```bash
make
```

This builds all Docker images and starts all containers. Use this after a fresh clone or after `make fclean`.

### Start Previously Built Services

```bash
make up
```

Starts containers from already-built images (faster). Does **not** rebuild images.

### Stop All Services (preserve data)

```bash
make stop
```

Stops all running containers without removing them or their data. Resume with `make start`.

### Resume Stopped Services

```bash
make start
```

Starts previously stopped containers. All data and WordPress configuration are preserved.

### Restart Services

```bash
make restart
```

Equivalent to `make stop` followed by `make start`. Use when troubleshooting or after minor configuration changes.

### Shutdown (remove containers, keep data)

```bash
make down
```

Stops and removes containers but keeps all data volumes intact. Use `make up` to recreate containers.

### Full Reset (removes everything including data)

```bash
make fclean
```

> **Warning:** This deletes all database and WordPress data permanently. Requires `sudo` for data directory removal. Rebuild from scratch with `make` afterwards.

## Accessing the Website

### WordPress Website

Open your web browser and navigate to:
```
https://mkurkar.42.fr
```

> **Note:** You will see a browser security warning because the SSL certificate is self-signed. This is expected for local development.

**To bypass the warning:**
- **Chrome/Edge**: Click "Advanced" → "Proceed to mkurkar.42.fr (unsafe)"
- **Firefox**: Click "Advanced" → "Accept the Risk and Continue"
- **Safari**: Click "Show Details" → "visit this website"

### WordPress Admin Panel

Access the admin dashboard at:
```
https://mkurkar.42.fr/wp-admin
```

## Credentials

### Locating Credentials

All login credentials are documented in:
```
/home/mkurkar/42/inception/secrets/credentials.txt
```

View with:
```bash
cat /home/mkurkar/42/inception/secrets/credentials.txt
```

The actual passwords used at runtime are stored as Docker secrets in individual files under `secrets/`. Docker mounts these into containers at `/run/secrets/` — they are never exposed as environment variables.

### WordPress Users

The system has two WordPress users:

1. **Administrator Account**
   - Username: `mkurkar_wp`
   - Password: stored in `secrets/wp_admin_password.txt`
   - Capabilities: Full administrative access

2. **Regular User Account**
   - Username: `mkurkar_user`
   - Password: stored in `secrets/wp_user_password.txt`
   - Capabilities: Author-level access (can create and publish posts)

### Changing Passwords

To change a WordPress user password:

1. Log in to the WordPress admin panel
2. Go to **Users → All Users**
3. Click the user you want to edit
4. Scroll to **Account Management**
5. Click "Generate Password" or enter a new one
6. Click **Update User**

Also update the corresponding file under `secrets/` and `secrets/credentials.txt` for your records. If you want the change to survive a full `make fclean` + `make`, update the secret file before rebuilding.

## Managing Credentials

### Security Best Practices

1. **Never share passwords** in plain text via email or chat
2. **Change default passwords** after initial setup
3. **Use strong passwords** with mixed characters
4. **Restrict access** to the secrets directory:
   ```bash
   chmod 600 /home/mkurkar/42/inception/secrets/*.txt
   ```

### Secret Files

| File | Purpose |
|------|---------|
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/db_password.txt` | MariaDB WordPress user password |
| `secrets/wp_admin_password.txt` | WordPress admin password |
| `secrets/wp_user_password.txt` | WordPress regular user password |

> **Note:** These files are gitignored and never committed to version control.

## Checking Service Status

### View Running Containers

```bash
make ps
```

Expected output:
```
NAME        STATUS                    PORTS
mariadb     Up X minutes (healthy)    3306/tcp
wordpress   Up X minutes              9000/tcp
nginx       Up X minutes              0.0.0.0:443->443/tcp
```

All three services should show "Up". MariaDB should show "(healthy)".

### View All Service Logs

```bash
make logs
```

Press Ctrl+C to exit.

### View Individual Service Logs

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

## Troubleshooting

### Website Not Loading

1. Check containers are running:
   ```bash
   make ps
   ```
2. Check the NGINX logs:
   ```bash
   docker logs nginx
   ```
3. Verify the domain is in your hosts file:
   ```bash
   grep mkurkar.42.fr /etc/hosts
   ```
4. Restart services:
   ```bash
   make restart
   ```

### Cannot Login to WordPress

1. Verify credentials in `secrets/credentials.txt`
2. Check WordPress logs:
   ```bash
   docker logs wordpress
   ```
3. Use the WordPress "Lost your password?" link to reset via email (if email is configured)

### Services Won't Start

1. Check disk space:
   ```bash
   df -h /home/mkurkar/data
   ```
2. View detailed logs:
   ```bash
   make logs
   ```
3. Try a clean restart:
   ```bash
   make down
   make up
   ```

### SSL Certificate Warning

Expected for self-signed certificates. The certificate is not issued by a trusted CA — this is normal for local development. Accept the risk in your browser to proceed.

### Port 443 Already in Use

1. Find what is using port 443:
   ```bash
   sudo lsof -i :443
   ```
2. Stop the conflicting service, for example:
   ```bash
   sudo systemctl stop apache2
   ```
3. Start Inception:
   ```bash
   make up
   ```

## Data Management

### Data Location

All persistent data is stored on the host at:
- WordPress files: `/home/mkurkar/data/wordpress`
- Database files: `/home/mkurkar/data/mysql`

### Backing Up Data

```bash
BACKUP=~/inception-backups/$(date +%Y%m%d)
mkdir -p "$BACKUP"

# WordPress files
sudo cp -r /home/mkurkar/data/wordpress "$BACKUP/"

# Database files
sudo cp -r /home/mkurkar/data/mysql "$BACKUP/"

# Secrets (keep these safe)
cp -r /home/mkurkar/42/inception/secrets "$BACKUP/"
```

### Restoring Data

```bash
make down

sudo rm -rf /home/mkurkar/data/wordpress /home/mkurkar/data/mysql
sudo cp -r ~/inception-backups/YYYYMMDD/wordpress /home/mkurkar/data/
sudo cp -r ~/inception-backups/YYYYMMDD/mysql /home/mkurkar/data/

make up
```

## Common Commands Reference

| Task | Command |
|------|---------|
| Build and start everything | `make` |
| Start existing containers | `make start` |
| Stop containers (keep data) | `make stop` |
| View logs | `make logs` |
| Check status | `make ps` |
| Restart | `make restart` |
| Remove containers (keep data) | `make down` |
| Full reset (delete all data) | `make fclean` |
| View credentials | `cat secrets/credentials.txt` |

## Security Reminders

1. Only access the admin panel from trusted networks
2. Keep WordPress and plugins updated
3. Use strong, unique passwords
4. Take regular backups
5. Monitor logs for suspicious activity
6. The `secrets/` directory must never be committed to version control

## Support

For infrastructure issues:
1. Check the troubleshooting section above
2. Review logs with `make logs`
3. Consult `DEV_DOC.md` for technical details
