#!/usr/bin/env sh
set -euo pipefail

FW=${1:-laravel}
APP_DIR=/var/www/html

if [[ "$FW" == "laravel" ]]; then
  if [[ ! -f "$APP_DIR/artisan" ]]; then
    composer create-project laravel/laravel .
  fi
  # Octane + Swoole
  composer require laravel/octane:^2.6 --no-interaction
  php artisan octane:install --server=swoole --no-interaction || true
  # Ajustar permissões de storage e bootstrap
  mkdir -p storage bootstrap/cache
  chmod -R 777 storage bootstrap/cache

elif [[ "$FW" == "hyperf" ]]; then
  if [[ ! -f "$APP_DIR/composer.json" || ! -d "$APP_DIR/app" ]]; then
    composer create-project hyperf/hyperf-skeleton . -n
  fi
  # Ajustes comuns
  mkdir -p runtime
  chmod -R 777 runtime || true
else
  echo "Framework não suportado: $FW"; exit 1
fi