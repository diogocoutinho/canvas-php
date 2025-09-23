#!/usr/bin/env bash
set -euo pipefail

FW=${1:-laravel}
APP_DIR=/var/www/html

echo "🚀 Instalando framework $FW em $APP_DIR..."

if [ "$FW" = "laravel" ]; then
    # Instalar Laravel diretamente na raiz
    if [ ! -f "$APP_DIR/composer.json" ]; then
        echo "🚀 Criando projeto Laravel em $APP_DIR..."
        composer create-project --prefer-dist laravel/laravel "$APP_DIR" --no-interaction
    else
        echo "✅ composer.json já existe em $APP_DIR"
    fi
    
    cd "$APP_DIR"
    
    # Instalar Laravel Octane + Swoole
    if [ -f composer.json ]; then
        composer require laravel/octane:^2.6 --no-interaction
        php artisan octane:install --server=swoole --no-interaction || true
        
        # Configurar permissões
        mkdir -p storage bootstrap/cache
        chmod -R 777 storage bootstrap/cache
    fi

elif [ "$FW" = "hyperf" ]; then
    # Instalar Hyperf diretamente na raiz
    if [ ! -f "$APP_DIR/composer.json" ]; then
        echo "🚀 Criando projeto Hyperf em $APP_DIR..."
        composer create-project hyperf/hyperf-skeleton "$APP_DIR" --no-interaction
    else
        echo "✅ composer.json já existe em $APP_DIR"
    fi
    
    cd "$APP_DIR"
    
    if [ -f composer.json ]; then
        # Configurar Hyperf
        mkdir -p runtime
        chmod -R 777 runtime || true
    fi

else
    echo "❌ Framework não suportado: $FW"
    exit 1
fi

echo "✅ Framework $FW instalado com sucesso em $APP_DIR"