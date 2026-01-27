#!/bin/bash
set -e

# Generate SSL certificate if it doesn't exist
if [ ! -f "/etc/nginx/ssl/certificate.crt" ]; then
    echo "Generating SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/private.key \
        -out /etc/nginx/ssl/certificate.crt \
        -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42Paris/CN=${DOMAIN_NAME}"
    echo "SSL certificate generated!"
fi

# Replace DOMAIN_NAME in nginx config
sed -i "s/DOMAIN_NAME/${DOMAIN_NAME}/g" /etc/nginx/nginx.conf

echo "Starting NGINX..."
# Start NGINX in foreground
exec nginx -g "daemon off;"
