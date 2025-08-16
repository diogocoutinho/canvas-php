#!/usr/bin/env bash
set -euo pipefail

APP_DIR=/var/www/html/current
cd "$APP_DIR"
FW="$(cat .framework 2>/dev/null || echo laravel)"

if [ "$FW" = "laravel" ]; then
  if [ -f "$APP_DIR/artisan" ]; then
    echo "🔶 Iniciando Laravel Octane (Swoole) em 0.0.0.0:9501 no diretório $APP_DIR"
    exec php artisan octane:start --server=swoole --host=0.0.0.0 --port=9501 --watch
  else
    echo "Arquivo artisan não encontrado em $APP_DIR. Não foi possível iniciar Laravel Octane."
    sleep 2
  fi
elif [ "$FW" = "hyperf" ]; then
  if [ -f "$APP_DIR/bin/hyperf.php" ]; then
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