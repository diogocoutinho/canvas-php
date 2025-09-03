#!/usr/bin/env bash
set -euo pipefail

VERSION="2.5.0"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

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
    mkdir -p "$PROJECT_NAME/docker/php" "$PROJECT_NAME/docker/nginx"

    cp "$SCRIPT_DIR/docker/php/Dockerfile" "$PROJECT_NAME/docker/php/"
    cp "$SCRIPT_DIR/docker/php/Dockerfile-hyperf" "$PROJECT_NAME/docker/php/" 2>/dev/null || true
    cp "$SCRIPT_DIR/docker/php/php.ini" "$PROJECT_NAME/docker/php/"
    cp "$SCRIPT_DIR/docker/php/start-app.sh" "$PROJECT_NAME/docker/php/"
    cp "$SCRIPT_DIR/docker/php/supervisord.conf" "$PROJECT_NAME/docker/php/"
    cp "$SCRIPT_DIR/docker/nginx/default.conf" "$PROJECT_NAME/docker/nginx/" 2>/dev/null || true

    echo "PROJECT_NAME=$PROJECT_NAME" > "$PROJECT_NAME/.env"

    # docker-compose.yml
    cat > "$PROJECT_NAME/docker-compose.yml" << EOF
services:
  app:
    build: ./docker/php
    container_name: ${PROJECT_NAME}_php
    working_dir: /var/www/html
    volumes:
      - ./:/var/www/html
    depends_on:
      - postgres
      - redis
    networks:
      - ${PROJECT_NAME}_net

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ${PROJECT_NAME}_db
      POSTGRES_USER: user
      POSTGRES_PASSWORD: secret
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - ${PROJECT_NAME}_net

  redis:
    image: redis:7-alpine
    networks:
      - ${PROJECT_NAME}_net

networks:
  ${PROJECT_NAME}_net:
    driver: bridge

volumes:
  postgres_data:
EOF

    increment_progress
    log_success "Arquivos essenciais criados"
}

create_framework() {
    cd "$PROJECT_NAME"
    TMP_FRAMEWORK=".canvas_tmp_framework"
    mkdir -p "$TMP_FRAMEWORK"

    log_step "Criando framework $FRAMEWORK..."
    if [ "$FRAMEWORK" = "Laravel" ]; then
        # 1️⃣ Criar Laravel na pasta temporária
        docker run --rm -v "$(pwd)/$TMP_FRAMEWORK":/var/www/html -w /var/www/html composer create-project laravel/laravel . --no-interaction

        # 2️⃣ Instalar Octane + Swoole **antes do merge**
        docker run --rm -v "$(pwd)/$TMP_FRAMEWORK":/var/www/html -w /var/www/html composer require laravel/octane --no-interaction
        docker run --rm -v "$(pwd)/$TMP_FRAMEWORK":/var/www/html -w /var/www/html php:8.4-cli php artisan octane:install --server=swoole --no-interaction
    else
        # Hyperf
        docker build -t canvas-php-hyperf-temp -f docker/php/Dockerfile-hyperf .
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

    # 5️⃣ Cache Laravel (somente Laravel)
    if [ "$FRAMEWORK" = "Laravel" ]; then
        docker-compose exec -T app php artisan config:cache
        docker-compose exec -T app php artisan route:cache
        docker-compose exec -T app php artisan view:cache
        increment_progress
        log_success "Laravel Octane + Swoole pronto para iniciar"
    fi
}

initialize_containers() {
    [ ! -f docker-compose.yml ] && log_error "docker-compose.yml não encontrado" && exit 1
    log_step "Subindo containers..."
    docker-compose up -d
    sleep 15
    increment_progress
}

main() {
    check_dependencies
    select_framework
    create_essential_files
    create_framework
    initialize_containers

    PROGRESS_CURRENT=$PROGRESS_TOTAL
    show_progress; echo
    log_success "Projeto $PROJECT_NAME criado com sucesso com o framework $FRAMEWORK!"
    echo "📁 Pasta do projeto: $(pwd)"
    echo "🌐 App: http://localhost:8080"
    echo "🐘 Postgres: localhost:5432 (db:${PROJECT_NAME}_db / user:user / pass:secret)"
    echo "🧠 Redis: localhost:6379"
}

main