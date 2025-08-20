#!/usr/bin/env bash
set -euo pipefail



# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para limpeza em caso de erro
cleanup_on_error() {
    echo
    if [ -n "${PROJECT_NAME:-}" ] && [ -d "$PROJECT_NAME" ]; then
        log_warning "Erro detectado. Limpando projeto '$PROJECT_NAME'..."
        rm -rf "$PROJECT_NAME"
        log_info "Projeto removido. Tente novamente."
    fi
    exit 1
}

# Função para limpeza em caso de interrupção
cleanup_on_interrupt() {
    echo
    log_warning "Operação interrupção pelo usuário."
    if [ -n "${PROJECT_NAME:-}" ] && [ -d "$PROJECT_NAME" ]; then
        log_warning "Limpando projeto '$PROJECT_NAME'..."
        rm -rf "$PROJECT_NAME"
        log_info "Projeto removido."
    fi
    exit 0
}

# Função para limpeza manual
manual_cleanup() {
    local project_name
    if [ -f "/tmp/canvas_php_project" ]; then
        project_name=$(cat /tmp/canvas_php_project)
        if [ -n "$project_name" ] && [ -d "$project_name" ]; then
            log_warning "Limpando projeto '$project_name' devido a erro..."
            rm -rf "$project_name"
            log_info "Projeto removido. Tente novamente."
        fi
        rm -f /tmp/canvas_php_project
    fi
}

# Configurar traps para limpeza automática
trap cleanup_on_error ERR
trap cleanup_on_interrupt INT TERM

# Função para output colorido
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "\033[1;36m🔹 $1${NC}"; }

# Função para limpar tela
clear_screen() {
    clear
    echo -e "\033[0;34m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[0;34m║                    🚀 Canvas PHP                            ║\033[0m"
    echo -e "\033[0;34m║              Criador de Projetos Profissionais              ║\033[0m"
    echo -e "\033[0;34m╚══════════════════════════════════════════════════════════════╝\033[0m"
    echo
}

# Função para mostrar progresso
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    printf "\r\033[0;34m["
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "] %d%%\033[0m" $((current * 100 / total))
    
    if [ $current -eq $total ]; then
        echo
    fi
}

# Função para prompt
prompt() { 
    read -r -p "$1" REPLY
    echo "$REPLY"
}

# Função para seleção de framework (fzf com instalação automática)
select_framework() {
    local options=("laravel" "hyperf")
    local choice

    if ! command -v fzf >/dev/null 2>&1; then
        echo "⚠️  fzf não encontrado. Tentando instalar..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew >/dev/null 2>&1; then
                brew install fzf
            else
                echo "❌ Homebrew não encontrado. Instale o Homebrew ou o fzf manualmente."
                exit 1
            fi
        elif [[ -f /etc/debian_version ]]; then
            sudo apt-get update && sudo apt-get install -y fzf
        elif [[ -f /etc/redhat-release ]]; then
            sudo dnf install -y fzf
        else
            echo "❌ Sistema não suportado para instalação automática. Instale o fzf manualmente."
            exit 1
        fi
    fi

    # Mostrar o prompt na saída de erro para não interferir com a captura
    echo "🚀 Canvas PHP - Selecione o framework (use ↑ ↓ e Enter):" >&2
    choice=$(printf "%s\n" "${options[@]}" | fzf --height=10 --border --ansi --prompt="Framework: " 2>/dev/null)
    
    # Verificar se o usuário cancelou
    if [ $? -ne 0 ] || [ -z "$choice" ]; then
        echo "exit"
        return
    fi
    
    echo "$choice"
}

# Verificar dependências
check_dependencies() {
    log_info "Verificando dependências..."
    
    local total_deps=3
    local current_dep=0
    
    # Verificar git
    log_step "Verificando git..."
    command -v git >/dev/null 2>&1 || { log_error "git não encontrado. Instale o git e tente novamente."; exit 1; }
    ((current_dep++))
    show_progress $current_dep $total_deps
    log_success "git ✓"
    
    # Verificar docker
    log_step "Verificando docker..."
    command -v docker >/dev/null 2>&1 || { log_error "docker não encontrado. Instale o docker e tente novamente."; exit 1; }
    ((current_dep++))
    show_progress $current_dep $total_deps
    log_success "docker ✓"
    
    # Verificar docker-compose
    log_step "Verificando docker-compose..."
    command -v docker-compose >/dev/null 2>&1 || { log_error "docker-compose não encontrado. Instale o docker-compose e tente novamente."; exit 1; }
    ((current_dep++))
    show_progress $current_dep $total_deps
    log_success "docker-compose ✓"
    
    log_success "Todas as dependências estão instaladas"
}

# Obter informações do projeto
get_project_info() {
    clear_screen
    log_info "Configuração do projeto"
    echo
    
    # Nome do projeto
    read -r -p "📦 Nome do projeto (pasta destino): " PROJECT_NAME
    
    if [ -d "$PROJECT_NAME" ]; then
        log_error "A pasta '$PROJECT_NAME' já existe."
        exit 1
    fi
    
    # Salvar nome do projeto para limpeza automática
    echo "$PROJECT_NAME" > /tmp/canvas_php_project
    
    log_info "Escolha o framework para o projeto:"
    FRAMEWORK=$(select_framework)
    
    # Verificar se o usuário saiu
    if [ "$FRAMEWORK" = "exit" ]; then
        log_info "Operação cancelada pelo usuário."
        exit 0
    fi
    
    echo
    log_success "Projeto: $PROJECT_NAME | Framework: $FRAMEWORK"
    echo
    echo -e "\033[0;36m⏳ Preparando para criar o projeto...\033[0m"
    sleep 2
}

# Criar estrutura do projeto
create_project_structure() {
    clear_screen
    log_info "Criando estrutura do projeto..."
    
    local total_steps=8
    local current_step=0
    
    # Salvar o caminho completo do projeto antes de fazer cd
    PROJECT_FULL_PATH="$(pwd)/$PROJECT_NAME"
    
    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    ((current_step++))
    show_progress $current_step $total_steps
    log_step "Diretório do projeto criado"
    
    # Criar diretórios Docker primeiro
    create_docker_dirs
    

    ((current_step++))
    show_progress $current_step $total_steps
    log_step "Diretórios Docker criados"
    
    # Copiar arquivos Docker existentes
    cp ../docker/php/Dockerfile docker/php/
    cp ../docker/php/php.ini docker/php/
    cp ../docker/php/start-app.sh docker/php/
    cp ../docker/php/minio-bucket.sh docker/php/
    ((current_step++))
    show_progress $current_step $total_steps
    log_step "Arquivos Docker copiados"
    
    # Criar docker-compose.yml
    create_docker_compose
    ((current_step++))
    show_progress $current_step $total_steps
    log_step "Docker Compose configurado"
    
    # Criar Makefile
    create_makefile
    ((current_step++))
    show_progress $current_step $total_steps
    log_step "Makefile criado"
    
    # Criar .env
    create_env_file
    ((current_step++))
    show_progress $current_step $total_steps
    log_step "Arquivo .env criado"
    
    # Criar .gitignore
    create_gitignore
    ((current_step++))
    show_progress $current_step $total_steps
    log_step "Gitignore configurado"
    
    # Criar README
    create_readme
    ((current_step++))
    show_progress $current_step $total_steps
    log_step "README criado"
    
    log_success "Estrutura do projeto criada"
}

# Criar docker-compose.yml
create_docker_compose() {
    cat > docker-compose.yml << EOF
# Docker Compose sem versão (obsoleta)

services:
  app:
    build:
      context: ./docker/php
      dockerfile: Dockerfile
    container_name: ${PROJECT_NAME}_php
    restart: unless-stopped
    working_dir: /var/www/html
    volumes:
      - ./:/var/www/html
      - ./docker/php/php.ini:/usr/local/etc/php/php.ini
    networks:
      - ${PROJECT_NAME}_net
    depends_on:
      - postgres
      - redis
      - minio
    environment:
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_DATABASE=appdb
      - DB_USERNAME=user
      - DB_PASSWORD=secret
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - MINIO_ENDPOINT=minio:9000
      - MINIO_ACCESS_KEY=minio
      - MINIO_SECRET_KEY=minio123

  nginx:
    image: nginx:alpine
    container_name: ${PROJECT_NAME}_nginx
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./:/var/www/html
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf
    networks:
      - ${PROJECT_NAME}_net
    depends_on:
      - app

  postgres:
    image: postgres:15-alpine
    container_name: ${PROJECT_NAME}_postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: user
      POSTGRES_PASSWORD: secret
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - ${PROJECT_NAME}_net
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    container_name: ${PROJECT_NAME}_redis
    restart: unless-stopped
    networks:
      - ${PROJECT_NAME}_net
    ports:
      - "6379:6379"

  minio:
    image: minio/minio:latest
    container_name: ${PROJECT_NAME}_minio
    restart: unless-stopped
    environment:
      MINIO_ROOT_USER: minio
      MINIO_ROOT_PASSWORD: minio123
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data
    networks:
      - ${PROJECT_NAME}_net
    ports:
      - "9000:9000"
      - "9001:9001"

  mailpit:
    image: axllent/mailpit:latest
    container_name: ${PROJECT_NAME}_mailpit
    restart: unless-stopped
    ports:
      - "8025:8025"
      - "1025:1025"
    networks:
      - ${PROJECT_NAME}_net

volumes:
  postgres_data:
  minio_data:

networks:
  ${PROJECT_NAME}_net:
    driver: bridge
EOF
}

# Criar diretórios Docker
create_docker_dirs() {
    mkdir -p docker/php docker/nginx

    # Configuração Nginx (será atualizada depois com o framework correto)
    cat > docker/nginx/default.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /var/www/html/current/public;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

    # Script de inicialização do container
    cat > docker/php/inside-container-init.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

FW=${1:-laravel}

# Instalar framework
bash /usr/local/bin/setup-framework.sh "$FW"

TARGET_DIR="/var/www/html"
FW_DIR="$TARGET_DIR/$FW"

cd $FW_DIR

if [ "$FW" = "laravel" ]; then
    if [ -f "$TARGET_DIR/composer.json" ]; then
        echo "composer.json found, running composer install..."
        composer install --no-interaction --prefer-dist --optimize-autoloader
    else
        if [ "$(ls -A $TARGET_DIR)" ]; then
            echo "Directory $TARGET_DIR is not empty but composer.json not found, skipping create-project."
        else
            echo "Creating new Laravel project in $TARGET_DIR..."
            composer create-project --prefer-dist laravel/laravel "$TARGET_DIR"
        fi
    fi

    # Install Octane and Swoole
    if [ "${OCTANE:-}" = "true" ]; then
        composer require laravel/octane --no-interaction
        composer require swoole/ide-helper --no-interaction || true
        php artisan octane:install || true
    fi

    # Set permissions
    chown -R www-data:www-data "$TARGET_DIR"
    chmod -R 755 "$TARGET_DIR"

elif [ "$FW" = "hyperf" ]; then
    if [ ! -f "$TARGET_DIR/composer.json" ]; then
        composer create-project hyperf/hyperf-skeleton "$TARGET_DIR"
    fi
fi
EOF

    # Script de configuração do framework
    cat > docker/php/setup-framework.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

FW=${1:-laravel}
APP_DIR=/var/www/html
FW_DIR="$APP_DIR/$FW"

echo "Listando arquivos de $APP_DIR:"
ls -la "$APP_DIR"

if [ "$FW" = "laravel" ]; then
    if [ ! -d "$FW_DIR" ]; then
        echo "🚀 Criando projeto Laravel em $FW_DIR..."
        composer create-project laravel/laravel "$FW_DIR"
    else
        echo "✅ Diretório $FW_DIR já existe."
    fi

    if [ -f "$FW_DIR/composer.json" ]; then
        cd "$FW_DIR"
        composer install --no-interaction
    else
        cd "$FW_DIR"
    fi

    # Octane + Swoole
    composer require laravel/octane:^2.6 --no-interaction
    php artisan octane:install --server=swoole --no-interaction || true
    # Permissões
    mkdir -p storage bootstrap/cache
    chmod -R 777 storage bootstrap/cache

elif [ "$FW" = "hyperf" ]; then
    if [ ! -d "$FW_DIR" ]; then
        echo "🚀 Criando projeto Hyperf em $FW_DIR..."
        composer create-project hyperf/hyperf-skeleton "$FW_DIR" -n
    else
        echo "✅ Diretório $FW_DIR já existe."
    fi

    if [ -f "$FW_DIR/composer.json" ]; then
        cd "$FW_DIR"
        composer install --no-interaction
    else
        cd "$FW_DIR"
    fi

    mkdir -p runtime
    chmod -R 777 runtime || true

else
    echo "❌ Framework não suportado: $FW"
    exit 1
fi

# Create/update symlink for Nginx: /var/www/html/current -> $FW_DIR
SYMLINK_PATH="$APP_DIR/current"
if [ -L "$SYMLINK_PATH" ] || [ -e "$SYMLINK_PATH" ]; then
    rm -rf "$SYMLINK_PATH"
fi
ln -s "$FW_DIR" "$SYMLINK_PATH"
echo "🔗 Symlinked $SYMLINK_PATH -> $FW_DIR (Nginx will serve from /var/www/html/current/public)"
EOF

    # Configuração do Supervisor
    cat > docker/php/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:php-fpm]
command=php-fpm
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/php-fpm.err.log
stdout_logfile=/var/log/supervisor/php-fpm.out.log

[program:app-server]
command=/usr/local/bin/start-app.sh
autostart=true
autorestart=false
priority=2
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
EOF
}

# Criar Makefile
create_makefile() {
    cat > Makefile << 'EOF'
EXEC_APP = docker-compose exec app
DC = docker-compose

cmd := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))

init: up install migrate minio-make-bucket info

up:
	$(DC) up -d --build

down:
	$(DC) down

restart: down up

logs:
	$(DC) logs -f

ps:
	$(DC) ps

info:
	@echo "\n🚀 Ambiente pronto!" \
	&& echo "🌐 App:       http://localhost:8080" \
	&& echo "📧 Mailpit:   http://localhost:8025" \
	&& echo "🗄️  MinIO UI:  http://localhost:9001 (user: minio / pass: minio123)" \
	&& echo "🐘 Postgres:  localhost:5432 (db: appdb / user: user / pass: secret)" \
	&& echo "🧠 Redis:     localhost:6379" \
	&& echo ""

install:
	$(EXEC_APP) composer install || true
	$(EXEC_APP) npm install --prefix frontend || true

update:
	$(EXEC_APP) composer update || true

migrate:
	$(EXEC_APP) sh -lc 'if [ -f artisan ]; then php artisan migrate; else php bin/hyperf.php migrate; fi' || true

migrate-fresh:
	$(EXEC_APP) php artisan migrate:fresh --seed || true

seed:
	$(EXEC_APP) php artisan db:seed || true

test:
	$(EXEC_APP) sh -lc 'if [ -f ./vendor/bin/phpunit ]; then ./vendor/bin/phpunit; else php bin/hyperf.php test; fi' || true

cache-clear:
	$(EXEC_APP) php artisan config:clear || true
	$(EXEC_APP) php artisan cache:clear || true
	$(EXEC_APP) php artisan route:clear || true
	$(EXEC_APP) php artisan view:clear || true

optimize:
	$(EXEC_APP) php artisan config:cache || true
	$(EXEC_APP) php artisan route:cache || true
	$(EXEC_APP) php artisan view:cache || true

minio-make-bucket:
	docker run --rm --network=$(shell docker-compose ps -q | head -1 | xargs docker inspect --format='{{.Config.Networks.app_net.NetworkID}}' | cut -d: -f2) minio/mc \
		alias set localminio http://minio:9000 minio minio123 && \
		docker run --rm --network=$(shell docker-compose ps -q | head -1 | xargs docker inspect --format='{{.Config.Networks.app_net.NetworkID}}' | cut -d: -f2) minio/mc mb localminio/app-bucket --ignore-existing

shell:
	$(EXEC_APP) bash $(cmd)
EOF
}

# Criar arquivo .env
create_env_file() {
    cat > .env << 'EOF'
# Configurações do projeto
PROJECT_NAME=app
FRAMEWORK=laravel

# Configurações do banco de dados
DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=appdb
DB_USERNAME=user
DB_PASSWORD=secret

# Configurações do Redis
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

# Configurações do MinIO
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=minio
MINIO_SECRET_KEY=minio123
MINIO_BUCKET=app-bucket
MINIO_USE_SSL=false

# Configurações do Mailpit
MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"
EOF
}

# Criar .gitignore
create_gitignore() {
    cat > .gitignore << 'EOF'
# Dependências
/vendor/
/node_modules/

# Arquivos de configuração
.env
.env.local
.env.production

# Cache e logs
/storage/logs/
/storage/framework/cache/
/storage/framework/sessions/
/storage/framework/views/
/bootstrap/cache/

# Arquivos temporários
*.log
*.cache
*.tmp

# IDEs
.vscode/
.idea/
*.swp
*.swo

# Docker
.dockerignore

# Sistema
.DS_Store
Thumbs.db
EOF
}

# Criar README
create_readme() {
    cat > README.md << 'EOF'
# ${PROJECT_NAME}

Projeto criado com o framework ${FRAMEWORK}.

## 🚀 Início Rápido

1. **Subir containers:**
   ```bash
   make up
   ```

2. **Inicializar projeto:**
   ```bash
   make init
   ```

3. **Acessar aplicação:**
   - App: http://localhost:8080
   - Mailpit: http://localhost:8025
   - MinIO UI: http://localhost:9001 (minio/minio123)
   - Postgres: localhost:5432 (db: appdb, user: user, pass: secret)
   - Redis: localhost:6379

## 📋 Comandos Úteis

- `make up` - Subir containers
- `make down` - Parar containers
- `make restart` - Reiniciar containers
- `make logs` - Ver logs
- `make shell` - Acessar container

## 🛠️ Desenvolvimento

O projeto está configurado com:
- PHP 8.2 + FPM
- Nginx
- PostgreSQL 15
- Redis 7
- MinIO (S3-compatible)
- Mailpit (SMTP testing)
- Laravel Octane + Swoole (para Laravel)
- Supervisor para gerenciamento de processos

## 📁 Estrutura

```
.
├── docker/           # Configurações Docker
├── docker-compose.yml
├── Makefile         # Comandos úteis
├── .env             # Variáveis de ambiente
└── README.md        # Este arquivo
```
EOF
}

# Inicializar projeto
initialize_project() {
    clear_screen
    log_info "Inicializando projeto..."
    
    local total_steps=5
    local current_step=0
    
    # Marcar framework escolhido
    echo "$FRAMEWORK" > .framework
    ((current_step++))
    show_progress $current_step $total_steps
    log_step "Framework marcado"
    
    # Subir containers
    log_step "Subindo containers Docker..."
    docker-compose up -d --build
    clear_screen
    # Verificar se os containers estão rodando
    log_step "Verificando status dos containers..."
    sleep 10
    log_step "Status dos containers:"
    docker-compose ps
    
    # if ! docker-compose ps | grep -q "Up"; then
    #     log_error "Erro ao subir containers Docker - verificação falhou"
    #     log_step "Executando limpeza automática..."
        
    #     # Limpeza direta
    #     local project_name
    #     if [ -f "/tmp/canvas_php_project" ]; then
    #         project_name=$(cat /tmp/canvas_php_project)
    #         if [ -n "$project_name" ] && [ -d "$project_name" ]; then
    #             log_warning "Limpando projeto '$project_name' devido a erro..."
    #             rm -rf "$project_name"
    #             log_info "Projeto removido. Tente novamente."
    #         fi
    #         rm -f /tmp/canvas_php_project
    #     fi
        
    #     log_step "Limpeza concluída"
    #     exit 1
    # fi
    
    ((current_step++))
    show_progress $current_step $total_steps
    log_success "Containers subindo..."
    
    # Aguardar containers estarem prontos
    log_step "Aguardando containers estarem prontos..."
    sleep 10
    ((current_step++))
    show_progress $current_step $total_steps
    log_success "Containers prontos"
    
    # Instalar o framework selecionado
    log_step "Instalando framework $FRAMEWORK..."
    
    # Criar diretório para o framework
    mkdir -p "$FRAMEWORK"
    
    # Executar script de instalação do framework
    if [ "$FRAMEWORK" = "laravel" ]; then
        log_info "Instalando Laravel..."
        composer create-project --prefer-dist laravel/laravel "$FRAMEWORK" --no-interaction
        
        # Configurar Laravel
        cd "$FRAMEWORK"
        composer require laravel/octane:^2.6 --no-interaction
        php artisan octane:install --server=swoole --no-interaction || true
        
        # Configurar permissões
        mkdir -p storage bootstrap/cache
        chmod -R 777 storage bootstrap/cache
        
        cd ..
        
    elif [ "$FRAMEWORK" = "hyperf" ]; then
        log_info "Instalando Hyperf..."
        composer create-project hyperf/hyperf-skeleton "$FRAMEWORK" --no-interaction
        
        # Configurar Hyperf
        cd "$FRAMEWORK"
        mkdir -p runtime
        chmod -R 777 runtime || true
        cd ..
        
    else
        log_error "Framework não suportado: $FRAMEWORK"
        exit 1
    fi
    
    # Criar link simbólico para o framework
    log_step "Configurando Nginx..."
    ln -sf "$FRAMEWORK" current
    
    # Atualizar configuração do Nginx para apontar para o framework correto
    sed -i.bak "s|/var/www/html/current/public|/var/www/html/$FRAMEWORK/public|g" docker/nginx/default.conf
    rm -f docker/nginx/default.conf.bak
    
    ((current_step++))
    show_progress $current_step $total_steps
    log_success "Framework $FRAMEWORK instalado e configurado"
    
    # Criar bucket MinIO (pulando por enquanto)
    log_step "Configurando MinIO..."
    log_warning "Configuração do MinIO pulada temporariamente"
    ((current_step++))
    show_progress $current_step $total_steps
    log_success "MinIO configurado (pulado)"
    
    log_success "Projeto inicializado com sucesso!"
}

# Função para limpeza final em caso de erro
final_cleanup() {
    if [ -f "/tmp/canvas_php_project" ]; then
        local project_name=$(cat /tmp/canvas_php_project)
        if [ -n "$project_name" ] && [ -d "$project_name" ]; then
            log_warning "Limpando projeto '$project_name' devido a erro..."
            rm -rf "$project_name"
            log_info "Projeto removido. Tente novamente."
        fi
        rm -f /tmp/canvas_php_project
    fi
}

# Mostrar informações finais
show_final_info() {
    clear_screen
    echo -e "\033[0;32m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[0;32m║                    🎉 PROJETO CRIADO!                       ║\033[0m"
    echo -e "\033[0;32m╚══════════════════════════════════════════════════════════════╝\033[0m"
    echo
    
    log_success "Projeto criado com sucesso!"
    echo
    
    echo -e "\033[0;34m📁 Localização:\033[0m $PROJECT_FULL_PATH"
    echo -e "\033[0;34m🧰 Framework:\033[0m $FRAMEWORK"
    echo -e "\033[0;34m🐳 Containers:\033[0m Subindo..."
    echo
    
    echo -e "\033[1;33m⏳ Aguarde alguns minutos para os containers estarem prontos...\033[0m"
    echo
    
    echo -e "\033[0;32m✅ URLs disponíveis:\033[0m"
    echo -e "  🌐 App:       http://localhost:8080"
    echo -e "  📧 Mailpit:   http://localhost:8025"
    echo -e "  🗄️  MinIO UI:  http://localhost:9001 (minio / minio123)"
    echo -e "  🐘 Postgres:  localhost:5432 (db: appdb / user: user / pass: secret)"
    echo -e "  🧠 Redis:     localhost:6379"
    echo
    
    echo -e "\033[0;34m📋 Comandos úteis:\033[0m"
    echo -e "  make up      # Subir containers"
    echo -e "  make down    # Parar containers"
    echo -e "  make logs    # Ver logs"
    echo -e "  make shell   # Acessar container"
    echo
    
    echo -e "\033[0;32m🚀 Para começar a desenvolver:\033[0m"
    echo -e "  cd $PROJECT_NAME"
    echo -e "  make up"
    echo
    
    echo -e "\033[0;34m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[0;34m║                    🎯 Próximos passos                       ║\033[0m"
    echo -e "\033[0;34m╚══════════════════════════════════════════════════════════════╝\033[0m"
}

# Função principal
main() {
    clear_screen
    
    if ! check_dependencies; then
        final_cleanup
        exit 1
    fi
    
    if ! get_project_info; then
        final_cleanup
        exit 1
    fi
    
    if ! create_project_structure; then
        final_cleanup
        exit 1
    fi
    
    if ! initialize_project; then
        final_cleanup
        exit 1
    fi
    
    show_final_info
}

# Executar função principal
main "$@"