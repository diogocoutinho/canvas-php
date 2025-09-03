#!/usr/bin/env bash
set -euo pipefail

APP_DIR=/var/www/html
FW="${FRAMEWORK:-laravel}"

cd "$APP_DIR"

if [ "$FW" = "laravel" ]; then
    if [ -f "$APP_DIR/artisan" ]; then
        echo "🔶 Iniciando Laravel Octane (Swoole) em 0.0.0.0:9501"
        exec php artisan octane:start --server=swoole --host=0.0.0.0 --port=9501 --workers=1
    else
        echo "❌ Arquivo artisan não encontrado em $APP_DIR"
        sleep 2
        exit 1
    fi

elif [ "$FW" = "hyperf" ]; then
    if [ -f "$APP_DIR/bin/hyperf.php" ]; then
        echo "🟣 Iniciando Hyperf (Swoole) em 0.0.0.0:9501"
        export SCAN_CACHEABLE=false
        exec php bin/hyperf.php start
    else
        echo "❌ Arquivo bin/hyperf.php não encontrado em $APP_DIR"
        sleep 2
        exit 1
    fi

else
    echo "❌ Framework não suportado: $FW"
    sleep 2
    exit 1
fi