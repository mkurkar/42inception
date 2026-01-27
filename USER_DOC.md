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

2. **Start the Services**

   Navigate to the project directory:
   ```bash
   cd /home/mkurkar/42/inception
   ```
   
   Start everything with:
   ```bash
   make
   ```
   
   Wait 1-2 minutes for all services to initialize.

## Starting and Stopping the Project

### Start All Services

```bash
make up
```

This command:
- Creates and starts all containers
- Runs in the background (detached mode)
- Services will be available in 1-2 minutes

### Stop All Services

```bash
make stop
```

This command:
- Stops all running containers
- Preserves all data
- Can be restarted with `make start`

### Restart Services

```bash
make restart
```

Use this when:
- Services are running slowly
- After configuration changes
- Troubleshooting issues

### Complete Shutdown

```bash
make down
```

This command:
- Stops all containers
- Removes containers (but keeps data)
- Use `make up` to recreate containers

## Accessing the Website

### WordPress Website

Open your web browser and navigate to:
```
https://mkurkar.42.fr
```

**Note**: You will see a security warning because the SSL certificate is self-signed. This is normal for local development.

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

All login credentials are stored in:
```
/home/mkurkar/42/inception/secrets/credentials.txt
```

View credentials with:
```bash
cat /home/mkurkar/42/inception/secrets/credentials.txt
```

### Default Users

The system has two WordPress users:

1. **Administrator Account**
   - Username: `mkurkar_admin`
   - Password: Located in `secrets/credentials.txt`
   - Capabilities: Full administrative access

2. **Regular User Account**
   - Username: `mkurkar_user`
   - Password: Located in `secrets/credentials.txt`
   - Capabilities: Author-level access (can create and publish posts)

### Changing Passwords

To change passwords:

1. Log in to WordPress admin panel
2. Go to Users → All Users
3. Click on the user you want to edit
4. Scroll to "Account Management"
5. Click "Generate Password" or enter a new password
6. Click "Update User"

**Important**: Update the `secrets/credentials.txt` file manually with new passwords for your records.

## Managing Credentials

### Security Best Practices

1. **Never share passwords** in plain text via email or chat
2. **Change default passwords** after initial setup
3. **Use strong passwords** with mixed characters
4. **Limit access** to the secrets directory:
   ```bash
   chmod 600 /home/mkurkar/42/inception/secrets/*.txt
   ```

### Database Credentials

Database passwords are stored in:
- `/home/mkurkar/42/inception/secrets/db_root_password.txt` (MariaDB root)
- `/home/mkurkar/42/inception/secrets/db_password.txt` (WordPress database user)

**Note**: These are automatically loaded by Docker and should not be changed unless you rebuild the entire infrastructure.

## Checking Service Status

### View Running Containers

```bash
make ps
```

Expected output:
```
NAME       IMAGE      STATUS         PORTS
nginx      nginx      Up 5 minutes   0.0.0.0:443->443/tcp
wordpress  wordpress  Up 5 minutes   9000/tcp
mariadb    mariadb    Up 5 minutes   3306/tcp
```

All three services should show "Up" status.

### View Service Logs

To see what's happening in real-time:
```bash
make logs
```

Press Ctrl+C to exit the logs view.

### View Individual Service Logs

```bash
# NGINX logs
docker logs nginx

# WordPress logs
docker logs wordpress

# MariaDB logs
docker logs mariadb
```

### Check Container Health

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

Look for "healthy" status on the MariaDB container.

## Troubleshooting

### Website Not Loading

1. **Check containers are running:**
   ```bash
   make ps
   ```

2. **Check NGINX logs:**
   ```bash
   docker logs nginx
   ```

3. **Verify domain in hosts file:**
   ```bash
   grep mkurkar.42.fr /etc/hosts
   ```

4. **Restart services:**
   ```bash
   make restart
   ```

### Cannot Login to WordPress

1. **Verify credentials** in `secrets/credentials.txt`
2. **Check WordPress logs:**
   ```bash
   docker logs wordpress
   ```
3. **Reset password** via WordPress "Lost your password?" link

### Services Won't Start

1. **Check disk space:**
   ```bash
   df -h /home/mkurkar/data
   ```

2. **View detailed logs:**
   ```bash
   make logs
   ```

3. **Restart from scratch:**
   ```bash
   make down
   make up
   ```

### SSL Certificate Warning

This is normal for self-signed certificates. The warning appears because the certificate is not issued by a trusted Certificate Authority (CA).

**Options:**
1. Accept the risk in your browser (safe for local development)
2. Add the certificate to your browser's trusted certificates (advanced)

### Port 443 Already in Use

If you see "port 443 already allocated":

1. **Find what's using port 443:**
   ```bash
   sudo lsof -i :443
   ```

2. **Stop the conflicting service:**
   ```bash
   sudo systemctl stop apache2  # or nginx, or other web server
   ```

3. **Start Inception:**
   ```bash
   make up
   ```

## Data Management

### Data Location

All persistent data is stored in:
- WordPress files: `/home/mkurkar/data/wordpress`
- Database files: `/home/mkurkar/data/mysql`

### Backing Up Data

To backup your website:

```bash
# Create backup directory
mkdir -p ~/inception-backups/$(date +%Y%m%d)

# Backup WordPress files
sudo cp -r /home/mkurkar/data/wordpress ~/inception-backups/$(date +%Y%m%d)/

# Backup database files
sudo cp -r /home/mkurkar/data/mysql ~/inception-backups/$(date +%Y%m%d)/

# Backup secrets
cp -r /home/mkurkar/42/inception/secrets ~/inception-backups/$(date +%Y%m%d)/
```

### Restoring Data

To restore from backup:

```bash
# Stop services
make down

# Restore files
sudo rm -rf /home/mkurkar/data/wordpress
sudo rm -rf /home/mkurkar/data/mysql
sudo cp -r ~/inception-backups/YYYYMMDD/wordpress /home/mkurkar/data/
sudo cp -r ~/inception-backups/YYYYMMDD/mysql /home/mkurkar/data/

# Start services
make up
```

## Maintenance

### Regular Maintenance Tasks

1. **Monitor Disk Space** (weekly):
   ```bash
   df -h /home/mkurkar/data
   ```

2. **Backup Data** (weekly):
   Follow the backup procedure above

3. **Update WordPress** (monthly):
   - Log in to WordPress admin
   - Navigate to Dashboard → Updates
   - Click "Update Now"

4. **Review Logs** (as needed):
   ```bash
   make logs
   ```

### When to Restart Services

Restart services when:
- Website is loading slowly
- After WordPress updates
- After installing new plugins/themes
- Services appear unresponsive

### Complete Reset

If you need to start completely fresh:

```bash
# WARNING: This deletes ALL data
make fclean

# Rebuild from scratch
make
```

## Getting Help

### Log Files

When reporting issues, include:
1. Container status: `make ps`
2. Service logs: `make logs`
3. What you were trying to do
4. What error message you saw

### Common Commands Reference

| Task | Command |
|------|---------|
| Start everything | `make` or `make up` |
| Stop services | `make stop` |
| View logs | `make logs` |
| Check status | `make ps` |
| Restart | `make restart` |
| Complete shutdown | `make down` |
| View credentials | `cat secrets/credentials.txt` |

## Security Reminders

1. Only access the admin panel from trusted networks
2. Keep WordPress and plugins updated
3. Use strong, unique passwords
4. Regular backups are essential
5. Monitor logs for suspicious activity
6. Change default credentials after initial setup

## Support

For technical issues with the infrastructure itself (not WordPress content issues):
1. Check the troubleshooting section above
2. Review logs with `make logs`
3. Consult the DEV_DOC.md for technical details
4. Contact your system administrator
