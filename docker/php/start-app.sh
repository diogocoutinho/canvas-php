#!/usr/bin/env sh
set -euo pipefail

cd /var/www/html
FW="$(cat .framework 2>/dev/null || echo laravel)"

if [[ "$FW" == "laravel" ]]; then
  echo "🔶 Iniciando Laravel Octane (Swoole) em 0.0.0.0:9501"
  exec php artisan octane:start --server=swoole --host=0.0.0.0 --port=9501 --watch
elif [[ "$FW" == "hyperf" ]]; then
  echo "🟣 Iniciando Hyperf (Swoole) em 0.0.0.0:9501"
  # Hyperf usa 9501 por padrão; garantir bind
  export SCAN_CACHEABLE=false
  exec php bin/hyperf.php start
else
  echo "Framework desconhecido: $FW"; sleep 2
fi