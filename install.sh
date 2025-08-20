#!/usr/bin/env bash

# Script de instalação do Canvas PHP
# Este script baixa e instala o Canvas PHP no sistema

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

# URL do repositório
REPO_URL="https://github.com/diogocoutinho/canvas-php.git"
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="canvas-php"

echo -e "${BLUE}🚀 Canvas PHP - Instalador${NC}"
echo "================================"

# Verificar dependências
log_info "Verificando dependências..."

command -v git >/dev/null 2>&1 || { log_error "git não encontrado. Instale o git e tente novamente."; exit 1; }
command -v docker >/dev/null 2>&1 || { log_error "docker não encontrado. Instale o docker e tente novamente."; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { log_error "docker-compose não encontrado. Instale o docker-compose e tente novamente."; exit 1; }

log_success "Todas as dependências estão instaladas"

# Criar diretório de instalação
log_info "Criando diretório de instalação..."
mkdir -p "$INSTALL_DIR"

# Baixar o projeto
log_info "Baixando Canvas PHP..."
TEMP_DIR=$(mktemp -d)
git clone --depth=1 "$REPO_URL" "$TEMP_DIR"

# Copiar arquivos necessários
log_info "Instalando Canvas PHP..."
cp "$TEMP_DIR/bootstrap.sh" "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/$INSTALL_DIR/$SCRIPT_NAME"

# Limpar arquivos temporários
rm -rf "$TEMP_DIR"

# Verificar se o PATH inclui o diretório de instalação
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    log_warning "O diretório $INSTALL_DIR não está no PATH"
    log_info "Adicione a seguinte linha ao seu ~/.bashrc, ~/.zshrc ou ~/.profile:"
    echo -e "${YELLOW}export PATH=\"\$PATH:$INSTALL_DIR\"${NC}"
    
    # Perguntar se quer adicionar automaticamente
    read -r -p "Deseja adicionar automaticamente ao PATH? (Y/n): " ADD_TO_PATH
    ADD_TO_PATH=${ADD_TO_PATH:-Y}
    
    if [ "$ADD_TO_PATH" = "Y" ] || [ "$ADD_TO_PATH" = "y" ]; then
        if [ -f "$HOME/.zshrc" ]; then
            echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.zshrc"
            log_success "Adicionado ao ~/.zshrc"
        elif [ -f "$HOME/.bashrc" ]; then
            echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.bashrc"
            log_success "Adicionado ao ~/.bashrc"
        elif [ -f "$HOME/.profile" ]; then
            echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.profile"
            log_success "Adicionado ao ~/.profile"
        else
            log_warning "Não foi possível encontrar arquivo de configuração do shell"
        fi
    fi
fi

log_success "Canvas PHP instalado com sucesso!"
echo ""
echo -e "${GREEN}🎉 Instalação concluída!${NC}"
echo ""
echo -e "${BLUE}📋 Como usar:${NC}"
echo "1. Abra um novo terminal ou recarregue o shell:"
echo "   source ~/.zshrc  # ou ~/.bashrc"
echo ""
echo "2. Crie um novo projeto:"
echo "   canvas-php"
echo ""
echo -e "${BLUE}📚 Documentação:${NC}"
echo "Visite: https://github.com/diogocoutinho/canvas-php"
echo ""
echo -e "${GREEN}🚀 Boa codificação!${NC}"
