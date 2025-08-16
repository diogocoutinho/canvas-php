#!/usr/bin/env bash
set -euo pipefail

FW=${1:-laravel}
APP_DIR=/var/www/html

echo "Listando arquivos de $APP_DIR:"
ls -la "$APP_DIR"

if [ "$FW" = "laravel" ]; then
  if [ ! -f "$APP_DIR/artisan" ]; then
    echo "🚀 Criando projeto Laravel..."
    composer create-project laravel/laravel "$APP_DIR"
  else
    echo "✅ Projeto Laravel já existe, pulando create-project"
    # Instead of create-project, run composer install if composer.json exists
    if [ -f "$APP_DIR/composer.json" ]; then
      cd "$APP_DIR"
      composer install --no-interaction
    fi
  fi

  cd "$APP_DIR"
  # Octane + Swoole
  composer require laravel/octane:^2.6 --no-interaction
  php artisan octane:install --server=swoole --no-interaction || true
  # Permissões
  mkdir -p storage bootstrap/cache
  chmod -R 777 storage bootstrap/cache

elif [ "$FW" = "hyperf" ]; then
  if [ ! -f "$APP_DIR/composer.json" ] || [ ! -d "$APP_DIR/app" ]; then
    echo "🚀 Criando projeto Hyperf..."
    composer create-project hyperf/hyperf-skeleton "$APP_DIR" -n
  else
    echo "✅ Projeto Hyperf já existe, pulando create-project"
  fi

  cd "$APP_DIR"
  mkdir -p runtime
  chmod -R 777 runtime || true

else
  echo "❌ Framework não suportado: $FW"
  exit 1
fi