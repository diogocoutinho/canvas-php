#!/bin/sh
set -e

# Ensure storage directory has correct permissions
if [ -d /var/www/html/storage ]; then
    chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
fi

# If Laravel Octane is installed, use it, otherwise fallback to PHP-FPM
if [ -f "/var/www/html/artisan" ] && [ -f "/var/www/html/vendor/bin/octane" ]; then
    # Start Laravel Octane with Swoole
    php artisan octane:start --server=swoole --host=0.0.0.0 --port=9000
else
    # Start PHP-FPM
    php-fpm
fi
