#!/bin/bash
set -e

# Read database password from secret
DB_PASSWORD=$(cat /run/secrets/db_password)

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
until mysql -h mariadb -u"${MYSQL_USER}" -p"${DB_PASSWORD}" -e "SELECT 1" &>/dev/null; do
    echo "MariaDB is unavailable - sleeping"
    sleep 3
done

echo "MariaDB is ready!"

# Download WordPress if not already present
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "Setting up WordPress..."
    
    # Download WordPress
    wp core download --allow-root
    
    # Create wp-config.php
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost=mariadb:3306 \
        --allow-root
    
    # Install WordPress
    wp core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
    
    # Create additional user
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root
    
    echo "WordPress installed successfully!"
else
    echo "WordPress already installed"
fi

# Set correct permissions
chown -R www-data:www-data /var/www/html

echo "Starting PHP-FPM..."
# Start PHP-FPM in foreground
exec php-fpm7.4 -F
