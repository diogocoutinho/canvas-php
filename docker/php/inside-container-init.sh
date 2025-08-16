#!/usr/bin/env bash
set -euo pipefail

FW=${1:-laravel}

# 1) Instala framework
bash /usr/local/bin/setup-framework.sh "$FW"

TARGET_DIR="/var/www/html"

FW_DIR="$TARGET_DIR/$FW"

if [ "$FW" = "laravel" ]; then
  if [ -f "$TARGER_DIR/current/composer.json" ]; then
    echo "🚨composer.json found, running composer install..."
    echo "Listando arquivos de $TARGER_DIR/current:"
    ls -la "$TARGER_DIR/current"
    composer install --no-interaction --prefer-dist --optimize-autoloader
  else
    if [ "$(ls -A $TARGER_DIR/current)" ]; then
      echo "Directory $TARGER_DIR/current is not empty but composer.json not found, skipping create-project."
    else
      echo "Creating new Laravel project in $TARGER_DIR/current..."
      composer create-project --prefer-dist laravel/laravel "$TARGER_DIR/current"
    fi
  fi

  # Install Octane and Swoole if specified
  if [ "${OCTANE:-}" = "true" ]; then
    composer require laravel/octane --no-interaction
    composer require swoole/ide-helper --no-interaction || true
    php artisan octane:install || true
  fi

  # Set permissions
  chown -R www-data:www-data "$TARGER_DIR/current"
  chmod -R 755 "$TARGER_DIR/current"

elif [ "$FW" = "hyperf" ]; then
  if [ ! -f "$TARGER_DIR/current/composer.json" ]; then
    composer create-project hyperf/hyperf-skeleton "$TARGER_DIR/current"
  fi
fi