#!/usr/bin/env sh
set -euo pipefail

FW=${1:-laravel}

# 1) Instala framework
bash /usr/local/bin/setup-framework.sh "$FW"

# 2) Depêndencias adicionais úteis
composer require predis/predis:^2.0 --no-interaction || true

# 3) Migrations (se Laravel)
if [[ "$FW" == "laravel" ]]; then
  php artisan key:generate || true
  php artisan migrate || true
fi

# 4) Criar bucket MinIO
bash /usr/local/bin/minio-bucket.sh app-bucket || true

# 5) Marcar framework (para start-app.sh)
echo "$FW" > /var/www/html/.framework