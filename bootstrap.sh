#!/usr/bin/env bash
set -euo pipefail

VERSION="2.5.0"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

PROJECT_NAME=""; FRAMEWORK=""; SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROGRESS_TOTAL=55; PROGRESS_CURRENT=0

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "${CYAN}🔹 $1${NC}"; }
increment_progress() { PROGRESS_CURRENT=$((PROGRESS_CURRENT + 1)); show_progress; }

show_progress() {
    local width=62
    local completed=$((PROGRESS_CURRENT * width / PROGRESS_TOTAL))
    local remaining=$((width - completed))
    tput sc
    tput cup 4 0
    printf "${CYAN}["
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "] %d%%${NC}" $((PROGRESS_CURRENT * 100 / PROGRESS_TOTAL))
    tput rc
}

render_header() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    🚀 Canvas PHP v${VERSION}                      ║${NC}"
    echo -e "${BLUE}║            Criador de Projetos Profissionais                 ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n"
    echo
    show_progress
}

check_dependencies() {
    for dep in git docker docker-compose nc; do
        command -v "$dep" >/dev/null 2>&1 || { log_error "$dep não encontrado"; exit 1; }
    done
}

select_framework() {
    render_header
    read -rp "📦 Nome do projeto (pasta destino): " PROJECT_NAME
    [ -z "$PROJECT_NAME" ] && log_error "Nome do projeto não pode ser vazio" && exit 1

    local options=("Laravel" "Hyperf"); local selected=0; tput civis
    while true; do
        render_header
        echo "Escolha o framework para o projeto:"
        for i in "${!options[@]}"; do
            if [[ "$i" -eq "$selected" ]]; then echo -e " > ${GREEN}${options[i]}${NC}"; else echo "   ${options[i]}"; fi
        done
        IFS= read -rsn1 key
        if [[ $key == "" ]]; then break; fi
        if [[ $key == $'\x1b' ]]; then IFS= read -rsn2 key2
            case "$key2" in '[A') selected=$(( (selected - 1 + ${#options[@]}) % ${#options[@]} )) ;; '[B') selected=$(( (selected + 1) % ${#options[@]} )) ;; esac
        fi
    done
    tput cnorm
    FRAMEWORK="${options[$selected],,}"; increment_progress
    echo "DEBUG: FRAMEWORK selecionado = $FRAMEWORK"
}

create_essential_files() {
    # Ensure project directory exists, use absolute PROJECT_DIR
    mkdir -p "$PROJECT_DIR"/.docker/{php,nginx}

    # Create essential configuration files
    cat > "$PROJECT_DIR/.env" << EOF
PROJECT_NAME=$PROJECT_NAME
DB_DATABASE=${PROJECT_NAME}_db
DB_USERNAME=user
DB_PASSWORD=secret
EOF

    # Create empty directories with proper permissions
    mkdir -p "$PROJECT_DIR"/{storage,bootstrap/cache}
    chmod -R 775 "$PROJECT_DIR"/storage "$PROJECT_DIR"/bootstrap/cache 2>/dev/null || true

    # Copy Docker configuration files
    cp -f "$SCRIPT_DIR/.docker/php/Dockerfile" "$PROJECT_DIR/.docker/php/"
    cp -f "$SCRIPT_DIR/.docker/php/php.ini" "$PROJECT_DIR/.docker/php/"
    cp -f "$SCRIPT_DIR/.docker/php/start-app.sh" "$PROJECT_DIR/.docker/php/"
    chmod +x "$PROJECT_DIR/.docker/php/start-app.sh"
    cp -f "$SCRIPT_DIR/.docker/nginx/default.conf" "$PROJECT_DIR/.docker/nginx/"

    # docker-compose.yml with updated configuration
    cat > "$PROJECT_DIR/docker-compose.yml" << EOF
services:
  app:
    build: ./.docker/php
    container_name: ${PROJECT_NAME}_php
    working_dir: /var/www/html
    volumes:
      - ./:/var/www/html
    environment:
      PHP_IDE_CONFIG: "serverName=app"
      DB_CONNECTION: pgsql
      DB_HOST: postgres
      DB_PORT: 5432
      DB_DATABASE: ${PROJECT_NAME}_db
      DB_USERNAME: user
      DB_PASSWORD: secret
      REDIS_HOST: redis
      REDIS_PORT: 6379
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - ${PROJECT_NAME}_net

  nginx:
    image: nginx:1.25-alpine
    container_name: ${PROJECT_NAME}_nginx
    volumes:
      - ./:/var/www/html
      - ./.docker/nginx/default.conf:/etc/nginx/conf.d/default.conf
    ports:
      - "8080:80"
    depends_on:
      - app
    networks:
      - ${PROJECT_NAME}_net

  postgres:
    image: postgres:15-alpine
    container_name: ${PROJECT_NAME}_postgres
    environment:
      POSTGRES_DB: ${PROJECT_NAME}_db
      POSTGRES_USER: user
      POSTGRES_PASSWORD: secret
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d ${PROJECT_NAME}_db"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - ${PROJECT_NAME}_net

  redis:
    image: redis:7-alpine
    container_name: ${PROJECT_NAME}_redis
    networks:
      - ${PROJECT_NAME}_net

  minio:
    image: minio/minio
    container_name: ${PROJECT_NAME}_minio
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    volumes:
      - minio_data:/data
    command: server /data
    ports:
      - "9000:9000"
    networks:
      - ${PROJECT_NAME}_net

  mailpit:
    image: mailhog/mailhog
    container_name: ${PROJECT_NAME}_mailpit
    ports:
      - "8025:8025"
    networks:
      - ${PROJECT_NAME}_net

networks:
  ${PROJECT_NAME}_net:
    driver: bridge

volumes:
  postgres_data:
  minio_data:
EOF

    increment_progress
    log_success "Arquivos essenciais criados"
}

initialize_containers() {
    # Ensure docker-compose commands run inside the project directory
    pushd "$PROJECT_DIR" >/dev/null || { log_error "Não foi possível entrar no diretório $PROJECT_DIR"; exit 1; }

    log_step "Parando containers anteriores (se existirem)..."
    docker-compose down --remove-orphans --volumes 2>/dev/null || true

    log_step "Construindo containers (tentar docker compose build)..."

    # Try docker compose build first. If it fails with a bake error, fall back to docker build for the php image.
    if docker-compose build --no-cache app; then
        log_success "docker-compose build concluído com sucesso"
        BUILD_FALLBACK=false
    else
        log_warning "docker-compose build falhou — tentando fallback com docker build"
        BUILD_FALLBACK=true
    fi

    if [ "$BUILD_FALLBACK" = true ]; then
        # Build the php image directly and then bring up the stack without building
        PHP_IMAGE_TAG="${PROJECT_NAME}_php"
        log_step "Construindo imagem php diretamente: ${PHP_IMAGE_TAG}"
        if docker build -t "${PHP_IMAGE_TAG}" ./.docker/php; then
            log_success "Imagem php construída: ${PHP_IMAGE_TAG}"
        else
            log_error "Falha ao construir a imagem php diretamente"
            popd >/dev/null
            exit 1
        fi

        log_step "Iniciando containers (sem rebuild)..."
        docker-compose up -d --no-build
    else
        log_step "Iniciando containers..."
        docker-compose up -d
    fi

    # Wait for containers to be ready
    log_step "Aguardando containers iniciarem..."
    local max_attempts=30
    local attempt=0
    while ! docker-compose ps app | grep -q "Up" && [ $attempt -lt $max_attempts ]; do
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    echo ""

    if [ $attempt -eq $max_attempts ]; then
        log_error "Timeout aguardando containers iniciarem"
        docker-compose logs app || true
        popd >/dev/null
        exit 1
    fi

    # Wait for postgres to be healthy
    log_step "Aguardando banco de dados..."
    attempt=0
    while ! docker-compose exec -T postgres pg_isready -U user -d "${PROJECT_NAME}_db" >/dev/null 2>&1 && [ $attempt -lt $max_attempts ]; do
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    echo ""

    if [ $attempt -eq $max_attempts ]; then
        log_error "Timeout aguardando banco de dados"
        docker-compose logs postgres || true
        popd >/dev/null
        exit 1
    fi

    # Give extra time for services to fully initialize
    sleep 5
    increment_progress
    popd >/dev/null
}

create_framework() {
    # Build framework inside the project dir but don't leave the script inside it
    pushd "$PROJECT_DIR" >/dev/null || { log_error "Não foi possível entrar em $PROJECT_DIR"; exit 1; }
    TMP_FRAMEWORK=".canvas_tmp_framework"
    mkdir -p "$TMP_FRAMEWORK"

    log_step "Criando framework $FRAMEWORK..."
    if [ "$FRAMEWORK" = "Laravel" ]; then
        # 1️⃣ Criar Laravel na pasta temporária
        docker run --rm -v "$(pwd)/$TMP_FRAMEWORK":/var/www/html -w /var/www/html composer create-project laravel/laravel . --no-interaction

        # 2️⃣ Instalar Octane + Swoole **antes do merge**
        docker run --rm -v "$(pwd)/$TMP_FRAMEWORK":/var/www/html -w /var/www/html composer require laravel/octane --no-interaction
    else
        # Hyperf
        docker build -t canvas-php-hyperf-temp -f .docker/php/Dockerfile-hyperf .
        docker run --rm -v "$(pwd)/$TMP_FRAMEWORK":/var/www/html -w /var/www/html canvas-php-hyperf-temp composer create-project hyperf/hyperf-skeleton . --no-interaction
    fi
    increment_progress

    # 3️⃣ Remover diretórios antigos do host
    dirs_to_remove=(app bootstrap config database public resources routes storage tests vendor)
    for dir in "${dirs_to_remove[@]}"; do [ -d "$dir" ] && rm -rf "$dir"; done

    # 4️⃣ Mover framework para pasta do host
    shopt -s dotglob
    mv "$TMP_FRAMEWORK"/* .
    rm -rf "$TMP_FRAMEWORK"
    shopt -u dotglob
    increment_progress
    log_success "Framework movido e merge concluído"
    popd >/dev/null
}

# New function: update the project's .env so containerized services are referenced correctly.
update_project_env() {
    local env_file="${PROJECT_DIR}/.env"

    # Ensure project directory exists and env path is writable
    mkdir -p "$(dirname "$env_file")"

    # If no .env exists, create an empty one so we can write into it
    if [ ! -f "$env_file" ]; then
        touch "$env_file"
    fi

    # Helper to set or add a KEY=VALUE line in the env file (portable with sed -i.bak)
    update_kv() {
        local kv="$1"
        local key="${kv%%=*}"
        local val="${kv#*=}"
        if grep -qE "^${key}=" "$env_file"; then
            sed -i.bak "s|^${key}=.*|${key}=${val}|" "$env_file"
        else
            # Append at end
            printf "%s=%s\n" "$key" "$val" >> "$env_file"
        fi
    }

    log_step "Atualizando $env_file com valores de container..."

    # Desired values for containerized environment
    update_kv "APP_NAME=${PROJECT_NAME}"
    update_kv "APP_ENV=local"
    update_kv "APP_DEBUG=true"
    update_kv "APP_URL=http://localhost:8080"

    update_kv "DB_CONNECTION=pgsql"
    update_kv "DB_HOST=postgres"
    update_kv "DB_PORT=5432"
    update_kv "DB_DATABASE=${PROJECT_NAME}_db"
    update_kv "DB_USERNAME=user"
    update_kv "DB_PASSWORD=secret"

    update_kv "BROADCAST_DRIVER=log"
    update_kv "CACHE_DRIVER=file"
    update_kv "QUEUE_CONNECTION=redis"
    update_kv "SESSION_DRIVER=file"

    update_kv "REDIS_HOST=redis"
    update_kv "REDIS_PASSWORD=null"
    update_kv "REDIS_PORT=6379"

    # Minio / S3 settings (use minio container as S3-compatible endpoint)
    update_kv "FILESYSTEM_DRIVER=s3"
    update_kv "AWS_ACCESS_KEY_ID=minioadmin"
    update_kv "AWS_SECRET_ACCESS_KEY=minioadmin"
    update_kv "AWS_DEFAULT_REGION=us-east-1"
    update_kv "AWS_BUCKET=${PROJECT_NAME}-bucket"
    update_kv "AWS_ENDPOINT=http://minio:9000"
    update_kv "AWS_USE_PATH_STYLE_ENDPOINT=true"

    # Mailpit (local SMTP) settings
    update_kv "MAIL_MAILER=smtp"
    update_kv "MAIL_HOST=mailpit"
    update_kv "MAIL_PORT=1025"
    update_kv "MAIL_USERNAME="
    update_kv "MAIL_PASSWORD="
    update_kv "MAIL_ENCRYPTION="
    update_kv "MAIL_FROM_ADDRESS=hello@${PROJECT_NAME}.local"
    update_kv "MAIL_FROM_NAME=${PROJECT_NAME}"

    # Remove sed backup if created
    rm -f "${env_file}.bak" 2>/dev/null || true

    increment_progress
    log_success "$env_file atualizado"
}

setup_laravel() {
    if [ "$FRAMEWORK" = "Laravel" ]; then
        # Run all docker-compose commands inside the project directory
        pushd "$PROJECT_DIR" >/dev/null || { log_error "Não foi possível entrar em $PROJECT_DIR"; return 1; }

        log_step "Configurando Laravel Octane..."

        # Fix permissions
        docker-compose exec -T app chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
        docker-compose exec -T app chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

        # Generate application key
        docker-compose exec -T app php artisan key:generate || true

        # Install and configure Octane
        docker-compose exec -T app composer require laravel/octane || true
        docker-compose exec -T app php artisan octane:install --server=swoole --no-interaction || true

        # Run Laravel optimizations
        docker-compose exec -T app php artisan config:cache || true
        docker-compose exec -T app php artisan route:cache || true
        docker-compose exec -T app php artisan view:cache || true

        # Restart the container to apply Octane
        docker-compose restart app || true

        increment_progress
        log_success "Laravel Octane + Swoole configurado com sucesso"

        popd >/dev/null
    fi
}

main() {
    check_dependencies

    # Non-interactive support for CI or automated runs
    if [ -n "${CI_PROJECT_NAME:-}" ] && [ -n "${CI_FRAMEWORK:-}" ]; then
        PROJECT_NAME="${CI_PROJECT_NAME}"
        FRAMEWORK="${CI_FRAMEWORK}"
        echo "Non-interactive mode: PROJECT_NAME=$PROJECT_NAME, FRAMEWORK=$FRAMEWORK"
        increment_progress
    else
        select_framework
    fi

    # Absolute project path (use cwd as base) so functions can operate even when cwd changes
    PROJECT_DIR="$(pwd)/$PROJECT_NAME"

    create_essential_files
    create_framework
    update_project_env
    initialize_containers
    setup_laravel

    PROGRESS_CURRENT=$PROGRESS_TOTAL
    show_progress; echo
    log_success "Projeto $PROJECT_NAME criado com sucesso com o framework $FRAMEWORK!"
    echo "📁 Pasta do projeto: $(pwd)"
    echo "🌐 App: http://localhost:8080"
    echo "🐘 Postgres: localhost:5432 (db:${PROJECT_NAME}_db / user:user / pass:secret)"
    echo "🧠 Redis: localhost:6379"
}

main