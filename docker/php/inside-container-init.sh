#!/usr/bin/env bash
set -euo pipefail

FW=${1:-laravel}

# 1) Instala framework
bash /usr/local/bin/setup-framework.sh "$FW"

TARGET_DIR="/var/www/html"

FW_DIR="$TARGET_DIR/$FW"

if [ "$FW" = "laravel" ]; then
  if [ -f "$FW_DIR/composer.json" ]; then
    echo "composer.json found, running composer install..."
    composer install --no-interaction --prefer-dist --optimize-autoloader
  else
    if [ "$(ls -A $FW_DIR)" ]; then
      echo "Directory $FW_DIR is not empty but composer.json not found, skipping create-project."
    else
      echo "Creating new Laravel project in $FW_DIR..."
      composer create-project --prefer-dist laravel/laravel "$FW_DIR"
    fi
  fi

  # Install Octane and Swoole if specified
  if [ "${OCTANE:-}" = "true" ]; then
    composer require laravel/octane --no-interaction
    composer require swoole/ide-helper --no-interaction || true
    php artisan octane:install || true
  fi

  # Set permissions
  chown -R www-data:www-data "$FW_DIR"
  chmod -R 755 "$FW_DIR"

elif [ "$FW" = "hyperf" ]; then
  if [ ! -f "$FW_DIR/composer.json" ]; then
    composer create-project hyperf/hyperf-skeleton "$FW_DIR"
  fi
fi