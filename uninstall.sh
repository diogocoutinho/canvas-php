#!/usr/bin/env bash

# Script de desinstalação do Canvas PHP
# Este script remove o Canvas PHP do sistema

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para output colorido
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Configurações
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="canvas-php"

echo -e "${BLUE}🗑️  Canvas PHP - Desinstalador${NC}"
echo "=================================="

# Verificar se está instalado
if [ ! -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    log_warning "Canvas PHP não está instalado em $INSTALL_DIR/$SCRIPT_NAME"
    log_info "Verificando outras localizações..."
    
    # Verificar se está no PATH
    if command -v canvas-php >/dev/null 2>&1; then
        SCRIPT_PATH=$(which canvas-php)
        log_info "Encontrado em: $SCRIPT_PATH"
        
        read -r -p "Deseja remover de $SCRIPT_PATH? (Y/n): " REMOVE_FROM_PATH
        REMOVE_FROM_PATH=${REMOVE_FROM_PATH:-Y}
        
        if [ "$REMOVE_FROM_PATH" = "Y" ] || [ "$REMOVE_FROM_PATH" = "y" ]; then
            sudo rm -f "$SCRIPT_PATH"
            log_success "Canvas PHP removido de $SCRIPT_PATH"
        else
            log_info "Desinstalação cancelada"
            exit 0
        fi
    else
        log_error "Canvas PHP não foi encontrado no sistema"
        exit 1
    fi
else
    # Remover arquivo principal
    log_info "Removendo Canvas PHP..."
    rm -f "$INSTALL_DIR/$SCRIPT_NAME"
    log_success "Arquivo principal removido"
fi

# Verificar se o diretório está vazio
if [ -d "$INSTALL_DIR" ] && [ -z "$(ls -A "$INSTALL_DIR")" ]; then
    log_info "Diretório $INSTALL_DIR está vazio, removendo..."
    rmdir "$INSTALL_DIR"
    log_success "Diretório vazio removido"
fi

# Remover do PATH (se configurado)
log_info "Verificando configurações do shell..."

SHELL_CONFIGS=("$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile")

for config in "${SHELL_CONFIGS[@]}"; do
    if [ -f "$config" ]; then
        if grep -q "export PATH.*$INSTALL_DIR" "$config"; then
            log_info "Removendo PATH de $config..."
            
            # Criar backup
            cp "$config" "$config.backup.$(date +%Y%m%d_%H%M%S)"
            
            # Remover linha do PATH
            sed -i.bak "/export PATH.*$INSTALL_DIR/d" "$config"
            
            log_success "PATH removido de $config (backup criado)"
        fi
    fi
done

# Verificar se há projetos criados
log_info "Verificando projetos existentes..."
PROJECTS_COUNT=$(find "$HOME" -maxdepth 2 -name ".framework" -type f 2>/dev/null | wc -l)

if [ "$PROJECTS_COUNT" -gt 0 ]; then
    log_warning "Encontrados $PROJECTS_COUNT projetos criados com Canvas PHP"
    log_info "Estes projetos continuarão funcionando, mas você precisará do Canvas PHP para criar novos"
    
    read -r -p "Deseja listar os projetos encontrados? (Y/n): " LIST_PROJECTS
    LIST_PROJECTS=${LIST_PROJECTS:-Y}
    
    if [ "$LIST_PROJECTS" = "Y" ] || [ "$LIST_PROJECTS" = "y" ]; then
        echo ""
        log_info "Projetos encontrados:"
        find "$HOME" -maxdepth 2 -name ".framework" -type f 2>/dev/null | while read -r framework_file; do
            project_dir=$(dirname "$framework_file")
            framework=$(cat "$framework_file")
            echo "  📁 $project_dir (Framework: $framework)"
        done
        echo ""
    fi
fi

# Limpeza final
log_info "Executando limpeza final..."

# Remover arquivos temporários se existirem
if [ -d "/tmp/canvas-php" ]; then
    rm -rf "/tmp/canvas-php"
    log_success "Arquivos temporários removidos"
fi

log_success "Canvas PHP desinstalado com sucesso!"
echo ""
echo -e "${GREEN}🎉 Desinstalação concluída!${NC}"
echo ""
echo -e "${BLUE}📋 O que foi removido:${NC}"
echo "✅ Executável canvas-php"
echo "✅ Configurações do PATH"
echo "✅ Arquivos temporários"
echo ""
echo -e "${BLUE}⚠️  O que NÃO foi removido:${NC}"
echo "📁 Projetos existentes (continuam funcionando)"
echo "🐳 Containers Docker (use 'docker-compose down' nos projetos)"
echo "🗄️  Volumes Docker (use 'docker-compose down -v' se necessário)"
echo ""
echo -e "${BLUE}🔄 Para reinstalar:${NC}"
echo "curl -sSL https://raw.githubusercontent.com/diogocoutinho/canvas-php/main/install.sh | bash"
echo ""
echo -e "${GREEN}👋 Obrigado por usar o Canvas PHP!${NC}"
