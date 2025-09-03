#!/usr/bin/env bash
set -euo pipefail

FW=${1:-laravel}

echo "🚀 Canvas PHP - Inicializando framework $FW..."

# Instalar framework
bash /usr/local/bin/setup-framework.sh "$FW"

echo "✅ Framework $FW instalado com sucesso!"