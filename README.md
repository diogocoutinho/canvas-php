# Canvas PHP Development Environment

[![Build Status](https://github.com/diogocoutinho/canvas-php/actions/workflows/ci.yml/badge.svg)](https://github.com/diogocoutinho/canvas-php/actions)
[![License](https://img.shields.io/github/license/diogocoutinho/canvas-php)](https://github.com/diogocoutinho/canvas-php/blob/main/LICENSE)
[![Issues](https://img.shields.io/github/issues/diogocoutinho/canvas-php)](https://github.com/diogocoutinho/canvas-php/issues)

Ambiente de desenvolvimento PHP completo com **Laravel Octane (Swoole)** ou **Hyperf**, totalmente automatizado e pronto para uso no **Cursor IDE**.

## 🚀 Instalação

Execute o script abaixo para iniciar o setup automaticamente:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/diogocoutinho/canvas-php/main/bootstrap.sh)
```

## 📦 Serviços Incluídos

- **PHP-FPM 8.x**
- **Nginx**
- **Redis**
- **PostgreSQL**
- **Supervisor**
- **Mailpit** (SMTP testing)
- **MinIO** (S3-compatible storage)
- **Swoole** habilitado para todos os frameworks

## ⚡ Frameworks Suportados

Durante a instalação será solicitado que você escolha o framework:

- [Laravel Octane + Swoole](https://laravel.com/docs/octane)
- [Hyperf (Swoole)](https://hyperf.io/)

## 🛠️ Uso

Subir containers:
```bash
docker-compose up -d
```

Acessar o app no navegador:
- Laravel → [http://localhost:8080](http://localhost:8080)
- Hyperf → [http://localhost:9501](http://localhost:9501)

## 📖 Documentação Adicional

- [Laravel Octane Docs](https://laravel.com/docs/octane)
- [Hyperf Docs](https://hyperf.io/)
- [Docker Compose](https://docs.docker.com/compose/)

## 🤝 Contribuição

Sinta-se livre para abrir PRs e Issues.

## 📜 Licença

Este projeto é licenciado sob a [MIT License](LICENSE).
