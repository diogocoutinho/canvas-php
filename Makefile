EXEC_APP = docker-compose exec app
DC = docker-compose

.PHONY: help init up down restart logs ps info install update migrate seed test cache-clear optimize shell

help:
	@echo "Comandos disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

init: up install migrate ## Inicializar projeto

up:
	$(DC) up -d --build

down:
	$(DC) down

restart: down up

logs:
	$(DC) logs -f

ps:
	$(DC) ps

install:
	$(EXEC_APP) composer install --no-interaction --prefer-dist --optimize-autoloader

migrate:
	$(EXEC_APP) sh -c 'if [ -f artisan ]; then php artisan migrate; else php bin/hyperf.php migrate; fi'

shell:
	$(EXEC_APP) bash