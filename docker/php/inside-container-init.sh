#!/usr/bin/env bash
set -euo pipefail

FW=${1:-laravel}

echo "Framework selecionado: $FW"

# 1) Instala framework
bash /usr/local/bin/setup-framework.sh "$FW"

echo "✅ Framework $FW instalado com sucesso!"