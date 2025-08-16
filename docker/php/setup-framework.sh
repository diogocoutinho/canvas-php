#!/usr/bin/env bash
set -euo pipefail

FW=${1:-laravel}
APP_DIR=/var/www/html/current
FW_DIR="$APP_DIR/$FW"

echo "Listando arquivos de $APP_DIR:"
ls -la "$APP_DIR"

if [ "$FW" = "laravel" ]; then
  if [ ! -d "$FW_DIR" ]; then
    echo "🚀 Criando projeto Laravel em $FW_DIR..."
    composer create-project laravel/laravel "$FW_DIR"
  else
    echo "✅ Diretório $FW_DIR já existe."
  fi

  if [ -f "$FW_DIR/composer.json" ]; then
    cd "$FW_DIR"
    composer install --no-interaction
  else
    cd "$FW_DIR"
  fi

  # Octane + Swoole
  composer require laravel/octane:^2.6 --no-interaction
  php artisan octane:install --server=swoole --no-interaction || true
  # Permissões
  mkdir -p storage bootstrap/cache
  chmod -R 777 storage bootstrap/cache

elif [ "$FW" = "hyperf" ]; then
  if [ ! -d "$FW_DIR" ]; then
    echo "🚀 Criando projeto Hyperf em $FW_DIR..."
    composer create-project hyperf/hyperf-skeleton "$FW_DIR" -n
  else
    echo "✅ Diretório $FW_DIR já existe."
  fi

  if [ -f "$FW_DIR/composer.json" ]; then
    cd "$FW_DIR"
    composer install --no-interaction
  else
    cd "$FW_DIR"
  fi

  mkdir -p runtime
  chmod -R 777 runtime || true

else
  echo "❌ Framework não suportado: $FW"
  exit 1
fi

# Create/update symlink for Nginx: /var/www/html/current -> $FW_DIR
SYMLINK_PATH="$APP_DIR/current"
if [ -L "$SYMLINK_PATH" ] || [ -e "$SYMLINK_PATH" ]; then
  rm -rf "$SYMLINK_PATH"
fi
ln -s "$FW_DIR" "$SYMLINK_PATH"
echo "🔗 Symlinked $SYMLINK_PATH -> $FW_DIR (Nginx will serve from /var/www/html/current/public)"