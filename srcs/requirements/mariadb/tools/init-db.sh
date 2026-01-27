#!/bin/bash
set -e

# Read secrets
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

# Initialize database if not exists
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing database..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Start MySQL temporarily to configure
mysqld --user=mysql --datadir=/var/lib/mysql &
MYSQL_PID=$!

# Wait for MySQL to be ready
echo "Waiting for MySQL to start..."
for i in {30..0}; do
    if mysqladmin ping &>/dev/null; then
        break
    fi
    sleep 1
done

if [ "$i" = 0 ]; then
    echo "MySQL failed to start"
    exit 1
fi

echo "Configuring database..."

# Secure installation and create database
mysql -u root <<-EOSQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
    DELETE FROM mysql.user WHERE User='';
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
    CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
    FLUSH PRIVILEGES;
EOSQL

echo "Database configured successfully!"

# Stop temporary MySQL
mysqladmin -u root -p"${DB_ROOT_PASSWORD}" shutdown

# Wait for shutdown
wait $MYSQL_PID

# Start MySQL in foreground
echo "Starting MariaDB..."
exec mysqld --user=mysql --datadir=/var/lib/mysql
