#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/diogocoutinho/canvas-php.git"

prompt() { read -r -p "$1" REPLY; echo "$REPLY"; }

command -v git >/dev/null 2>&1 || { echo "❌ git não encontrado. Instale o git e tente novamente."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ docker não encontrado."; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "❌ docker-compose não encontrado."; exit 1; }

APP_DIR="/var/www/html"

PROJECT_NAME=$(prompt "📦 Nome do projeto (pasta destino): ")

if [ -d "$PROJECT_NAME" ]; then
  echo "❌ A pasta '$PROJECT_NAME' já existe."; exit 1
fi

FRAMEWORK=$(prompt "🧰 Framework [laravel|hyperf]: ")
FRAMEWORK=$(echo "$FRAMEWORK" | tr '[:upper:]' '[:lower:]')

if [ "$FRAMEWORK" != "laravel" ] && [ "$FRAMEWORK" != "hyperf" ]; then
  echo "❌ Framework inválido."; exit 1
fi

echo "➡️ Clonando template..."
git clone --depth=1 "$REPO_URL" "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Marcar framework escolhido
echo "$FRAMEWORK" > .framework

# Copiar .env.example correspondente
if [ "$FRAMEWORK" = "laravel" ]; then
  cp .env.example.laravel .env
else
  cp .env.example.hyperf .env
fi

# Subir containers
echo "🐳 Subindo containers..."
docker-compose up -d --build

# Rodar init dentro do container
echo "⚙️ Inicializando app dentro do container..."
docker-compose exec -T app bash /usr/local/bin/inside-container-init.sh "$FRAMEWORK"

read -r -p "➡️ Rodar 'make init' para finalizar (Y/n)? " RUN_INIT
RUN_INIT=${RUN_INIT:-Y}
if [ "$RUN_INIT" = "Y" ] || [ "$RUN_INIT" = "y" ]; then
  make init || true
fi

cat <<EOF

✅ Pronto!
- App:       http://localhost:8080
- Mailpit:   http://localhost:8025
- MinIO UI:  http://localhost:9001 (minio / minio123)
- Postgres:  localhost:5432 (db: appdb / user: user / pass: secret)
- Redis:     localhost:6379
EOF