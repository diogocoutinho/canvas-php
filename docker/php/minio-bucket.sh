#!/usr/bin/env bash
set -euo pipefail

echo "🗄️ Configurando MinIO..."

# Configurar alias para MinIO
mc alias set localminio http://minio:9000 minio minio123

# Criar bucket padrão
mc mb localminio/app-bucket --ignore-existing

# Configurar política de acesso público para o bucket (opcional)
mc policy set download localminio/app-bucket

echo "✅ MinIO configurado com sucesso!"
echo "   Endpoint: http://minio:9000"
echo "   Bucket: app-bucket"
echo "   Access Key: minio"
echo "   Secret Key: minio123"