#!/bin/bash
set -e

# Read secrets
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

# First-run: initialise and configure the database
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "First run — initialising database..."

    # --auth-root-authentication-method=normal makes root use mysql_native_password
    # with no initial password, so we can connect as "mysql -u root" (no -p) below.
    # Without this flag Debian's MariaDB defaults to unix_socket for root, which
    # works for OS-root connections but ALTER USER / SET PASSWORD then flip it to
    # unix_socket-based auth in ways that break subsequent container restarts.
    mysql_install_db --user=mysql --datadir=/var/lib/mysql \
        --auth-root-authentication-method=normal

    # Start mysqld temporarily (normal mode, socket only — no TCP yet)
    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    MYSQL_PID=$!

    # Wait for the socket to become ready
    echo "Waiting for MySQL to start..."
    for i in {30..0}; do
        if mysqladmin ping --silent 2>/dev/null; then
            break
        fi
        sleep 1
    done

    if [ "$i" = 0 ]; then
        echo "ERROR: MySQL failed to start during initialisation"
        exit 1
    fi

    echo "Configuring database..."

    # root has no password at this point (mysql_native_password, empty password)
    mysql -u root <<-EOSQL
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
        DELETE FROM mysql.user WHERE User='';
        DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
        DROP DATABASE IF EXISTS test;
        DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        FLUSH PRIVILEGES;
EOSQL

    echo "Database configured successfully!"

    # Shut down the temporary instance cleanly
    kill "${MYSQL_PID}"
    wait "${MYSQL_PID}" 2>/dev/null || true
    echo "Init complete."
else
    echo "Database already initialised — skipping configuration."
fi

# Start MariaDB in the foreground as PID 1
echo "Starting MariaDB..."
exec mysqld --user=mysql --datadir=/var/lib/mysql
