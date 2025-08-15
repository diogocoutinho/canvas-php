#!/usr/bin/env sh
set -euo pipefail

BUCKET=${1:-app-bucket}

# Alias + criação
mc() {
  docker run --rm --network=app_net minio/mc "$@"
}

mc alias set localminio http://minio:9000 minio minio123
mc mb localminio/"$BUCKET" --ignore-existing