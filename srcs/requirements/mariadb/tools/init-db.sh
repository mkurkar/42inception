#!/bin/bash
set -e

# Read secrets
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

# First-run: initialise and configure the database
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "First run — initialising database..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    # Start MySQL temporarily with no auth and no networking
    # --skip-grant-tables: bypass all authentication (safe because --skip-networking
    #   disables TCP so no remote connections are possible during init)
    mysqld --user=mysql --datadir=/var/lib/mysql \
           --skip-grant-tables --skip-networking &
    MYSQL_PID=$!

    # Wait for MySQL to be ready (socket only)
    echo "Waiting for MySQL to start..."
    for i in {30..0}; do
        if mysqladmin ping --silent; then
            break
        fi
        sleep 1
    done

    if [ "$i" = 0 ]; then
        echo "ERROR: MySQL failed to start during initialisation"
        exit 1
    fi

    echo "Configuring database..."

    # With --skip-grant-tables all SQL runs without auth/privilege checks.
    # Do NOT FLUSH PRIVILEGES before ALTER USER — that would re-enable auth
    # mid-session and cause subsequent statements to fail.
    # One FLUSH PRIVILEGES at the very end is sufficient.
    mysql -u root <<-EOSQL
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
        DELETE FROM mysql.user WHERE User='';
        DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
        DROP DATABASE IF EXISTS test;
        DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
        CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
        FLUSH PRIVILEGES;
EOSQL

    echo "Database configured successfully!"

    # Shut down the temporary instance
    kill "${MYSQL_PID}"
    wait "${MYSQL_PID}" 2>/dev/null || true
    echo "Init complete."
else
    echo "Database already initialised — skipping configuration."
fi

# Start MariaDB in the foreground as PID 1
echo "Starting MariaDB..."
exec mysqld --user=mysql --datadir=/var/lib/mysql
