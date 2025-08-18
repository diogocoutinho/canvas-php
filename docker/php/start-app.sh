#!/usr/bin/env bash
set -euo pipefail

APP_DIR=/var/www/html
FW="$(cat .framework 2>/dev/null || echo laravel)"
cd "$APP_DIR/$FW"
ls -la "$APP_DIR"

if [ "$FW" = "laravel" ]; then
  if [ -f "$APP_DIR/$FW/artisan" ]; then
    cd "$APP_DIR/$FW"
    echo "🔶 Iniciando Laravel Octane (Swoole) em 0.0.0.0:9501 no diretório $APP_DIR/$FW"
    exec php artisan octane:start --server=swoole --host=0.0.0.0 --port=9501 --watch --workers=1
  else
    echo "Arquivo artisan não encontrado em $APP_DIR. Não foi possível iniciar Laravel Octane."
    sleep 2
  fi
elif [ "$FW" = "hyperf" ]; then
  if [ -f "$APP_DIR/$FW/bin/hyperf.php" ]; then
    echo "🟣 Iniciando Hyperf (Swoole) em 0.0.0.0:9501 no diretório $APP_DIR"
    export SCAN_CACHEABLE=false
    exec php bin/hyperf.php start
  else
    echo "Arquivo bin/hyperf.php não encontrado em $APP_DIR. Não foi possível iniciar Hyperf."
    sleep 2
  fi
else
  echo "Framework desconhecido: $FW"; sleep 2
fi