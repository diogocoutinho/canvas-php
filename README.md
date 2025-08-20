# 🚀 Canvas PHP

**Canvas PHP** é uma ferramenta moderna e otimizada para criar projetos PHP com frameworks populares de forma rápida e limpa.

## ✨ Características

- 🎯 **Criação limpa**: Cria apenas o projeto solicitado, sem duplicações
- 🐳 **Docker nativo**: Ambiente completo com containers otimizados
- 🚀 **Frameworks suportados**: Laravel e Hyperf
- ⚡ **Performance**: Laravel Octane + Swoole para máxima velocidade
- 🗄️ **Stack completo**: PostgreSQL, Redis, MinIO, Mailpit
- 🛠️ **DevOps ready**: Makefile com comandos úteis
- 🧹 **Limpeza automática**: Remove projetos em caso de erro na criação
- 🎨 **Interface intuitiva**: Seleção interativa com setas do teclado e output colorido

## 🚀 Instalação Rápida

### Opção 1: Instalação Global (Recomendado)

```bash
curl -sSL https://raw.githubusercontent.com/diogocoutinho/canvas-php/main/install.sh | bash
```

### Opção 2: Instalação Manual

```bash
# Clonar o repositório
git clone https://github.com/diogocoutinho/canvas-php.git
cd canvas-php

# Executar o bootstrap
./bootstrap.sh
```

## 📋 Pré-requisitos

- Git
- Docker
- Docker Compose
- fzf (instalado automaticamente se não estiver presente)

## 🎯 Como Usar

### 1. Criar um novo projeto

```bash
canvas-php
```

### 2. Seguir as instruções

O script irá solicitar:

- Nome do projeto
- Framework (Laravel ou Hyperf) - seleção interativa com setas do teclado

### 3. Aguardar a criação

O sistema irá:

- Criar a estrutura do projeto
- Configurar containers Docker
- Instalar o framework escolhido automaticamente
- Configurar Laravel Octane + Swoole (para Laravel)
- Configurar banco de dados PostgreSQL
- Configurar ambiente de desenvolvimento completo

## 🏗️ Estrutura do Projeto Criado

```
meu-projeto/
├── laravel/               # Framework instalado (Laravel ou Hyperf)
│   ├── app/              # Aplicação do framework
│   ├── public/           # Arquivos públicos
│   └── ...               # Demais arquivos do framework
├── docker/               # Configurações Docker
│   ├── nginx/           # Configuração Nginx (proxy para Octane)
│   └── php/             # Dockerfile e scripts PHP
├── docker-compose.yml   # Orquestração de containers
├── Makefile            # Comandos úteis
├── .env                # Variáveis de ambiente
├── .gitignore          # Arquivos ignorados pelo Git
├── .framework          # Framework selecionado
├── current -> laravel  # Link simbólico para o framework
└── README.md           # Documentação do projeto
```

## 🐳 Stack Tecnológica

- **PHP 8.2** + Swoole + Laravel Octane
- **Nginx** como proxy reverso (para Laravel Octane)
- **PostgreSQL 15** como banco principal
- **Redis 7** para cache e sessões
- **MinIO** para armazenamento S3-compatible
- **Mailpit** para testes de email
- **Supervisor** para gerenciamento de processos

## 📚 Comandos Úteis

### Comandos Make

```bash
make up              # Subir containers
make down            # Parar containers
make restart         # Reiniciar containers
make logs            # Ver logs
make ps              # Status dos containers
make shell           # Acessar container
make migrate         # Executar migrações
make test            # Executar testes
make cache-clear     # Limpar cache
make optimize        # Otimizar aplicação
```

### Comandos Docker

```bash
docker-compose up -d     # Subir em background
docker-compose down      # Parar e remover
docker-compose logs -f   # Ver logs em tempo real
```

## 🌐 URLs do Ambiente

- **Aplicação**: http://localhost:8080 (Laravel via Octane/Swoole)
- **Mailpit**: http://localhost:8025 (Interface de email)
- **MinIO Console**: http://localhost:9001 (Interface de armazenamento)
- **PostgreSQL**: localhost:5432 (Banco de dados)
- **Redis**: localhost:6379 (Cache/Sessões)

### Credenciais

- **MinIO**: minio / minio123
- **PostgreSQL**: appdb / user / secret

## 🔧 Configurações

### PHP

O ambiente PHP vem configurado com:

- OPcache habilitado
- Extensões essenciais (PDO, Redis, GD, etc.)
- Configurações otimizadas para desenvolvimento
- Swoole para Laravel Octane

### Nginx

- Configuração otimizada como proxy reverso
- Suporte a Laravel Octane e Hyperf
- Proxy para Swoole na porta 9501
- Logs estruturados

## 🚀 Frameworks Suportados

### Laravel

- Versão mais recente
- Laravel Octane + Swoole
- Configurações otimizadas
- Migrations e seeders prontos

### Hyperf

- Skeleton oficial
- Configurações de performance
- Suporte a coroutines
- Ambiente de desenvolvimento completo

## 🛠️ Desenvolvimento

### Adicionar Dependências

```bash
# Via container
make shell
composer require package/name

# Ou diretamente
docker-compose exec app composer require package/name
```

### Executar Migrações

```bash
make migrate
```

### Executar Testes

```bash
make test
```

### Acessar Shell

```bash
make shell
```

## 🔍 Troubleshooting

### Container não inicia

```bash
# Ver logs
make logs

# Verificar status
make ps

# Reiniciar
make restart
```

### Problemas de permissão

```bash
# Acessar container
make shell

# Corrigir permissões
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
```

### Limpar ambiente

```bash
# Parar e remover containers
make down

# Remover volumes (cuidado!)
docker-compose down -v

# Reconstruir
make up
```

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🙏 Agradecimentos

- Comunidade Laravel
- Comunidade Hyperf
- Docker Community
- Todos os contribuidores

## 📞 Suporte

- **Issues**: [GitHub Issues](https://github.com/diogocoutinho/canvas-php/issues)
- **Discussions**: [GitHub Discussions](https://github.com/diogocoutinho/canvas-php/discussions)
- **Wiki**: [Documentação completa](https://github.com/diogocoutinho/canvas-php/wiki)

---

<div align="center">

**⭐ Se este projeto te ajudou, considere dar uma estrela! ⭐**

</div>
