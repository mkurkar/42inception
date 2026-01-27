# Quick Setup Guide

## Prerequisites Check

Run these commands to ensure your system is ready:

```bash
# Check Docker installation
docker --version

# Check Docker Compose installation
docker-compose --version

# Check if Docker is running
docker ps
```

If Docker is not installed, run:
```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose
sudo usermod -aG docker $USER
newgrp docker
```

## Quick Start

### 1. Configure Domain

Add the domain to your hosts file:

```bash
sudo bash -c 'echo "127.0.0.1 mkurkar.42.fr" >> /etc/hosts'
```

Verify it was added:
```bash
grep mkurkar.42.fr /etc/hosts
```

### 2. Build and Start

From the project root directory:

```bash
make
```

This will:
- Create data directories at `/home/mkurkar/data/`
- Build all Docker images (takes 3-5 minutes first time)
- Start all containers

### 3. Wait for Services to Initialize

Watch the logs to see when everything is ready:

```bash
make logs
```

Look for these messages:
- MariaDB: "Starting MariaDB..."
- WordPress: "WordPress installed successfully!"
- NGINX: "Starting NGINX..."

Press `Ctrl+C` to exit the logs view.

### 4. Access WordPress

Open your browser and go to:
```
https://mkurkar.42.fr
```

**Note:** You'll see a security warning because of the self-signed certificate. This is normal.

Click "Advanced" → "Proceed to mkurkar.42.fr" (or equivalent in your browser).

### 5. Login to WordPress Admin

Go to:
```
https://mkurkar.42.fr/wp-admin
```

Use credentials from:
```bash
cat secrets/credentials.txt
```

Default admin username: `mkurkar_admin`

## Useful Commands

```bash
# Check container status
make ps

# View logs in real-time
make logs

# Stop containers
make stop

# Start containers
make start

# Restart containers
make restart

# Stop and remove containers
make down

# Complete cleanup (WARNING: deletes all data)
make fclean

# Rebuild everything from scratch
make re
```

## Troubleshooting

### Port 443 Already in Use

If you get "port is already allocated":

```bash
# Find what's using port 443
sudo lsof -i :443

# If it's Apache or another web server, stop it:
sudo systemctl stop apache2
# or
sudo systemctl stop nginx
```

### Containers Keep Restarting

Check the logs:
```bash
docker logs mariadb
docker logs wordpress
docker logs nginx
```

### Permission Denied Errors

Fix volume permissions:
```bash
sudo chmod -R 755 /home/mkurkar/data
```

### Can't Access Website

1. Check containers are running:
   ```bash
   make ps
   ```

2. Check domain in hosts file:
   ```bash
   grep mkurkar.42.fr /etc/hosts
   ```

3. Restart services:
   ```bash
   make restart
   ```

### Database Connection Issues

Reset everything:
```bash
make fclean
make
```

## Next Steps

After successful setup:

1. Read `USER_DOC.md` for user documentation
2. Read `DEV_DOC.md` for developer documentation
3. Customize WordPress at https://mkurkar.42.fr/wp-admin
4. Consider adding bonus services (Redis, FTP, Adminer)

## Important Notes

- **Never commit** the `secrets/` directory to Git
- **Never commit** the `.env` file with real passwords
- **Always use** `make fclean` before submitting the project
- **Test thoroughly** after any configuration changes

## Getting Help

If you encounter issues:

1. Check the logs: `make logs`
2. Check container status: `make ps`
3. Review DEV_DOC.md for debugging tips
4. Consult the official Docker documentation

## Project Validation

Before submitting, verify:

- [ ] All three containers are running
- [ ] Website accessible at https://mkurkar.42.fr
- [ ] Two WordPress users exist (admin + regular)
- [ ] Admin username doesn't contain "admin" or "administrator"
- [ ] TLSv1.2 or TLSv1.3 only (check with: `openssl s_client -connect mkurkar.42.fr:443`)
- [ ] Volumes stored at /home/mkurkar/data/
- [ ] No passwords in Dockerfiles or docker-compose.yml
- [ ] Secrets used for credentials
- [ ] No `latest` tag used
- [ ] No `tail -f`, `sleep infinity`, or infinite loops
- [ ] Containers restart on crash (`restart: unless-stopped`)
- [ ] README.md, USER_DOC.md, and DEV_DOC.md present

Good luck!
