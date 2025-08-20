ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
DC = docker-compose -f $(ROOT_DIR)/docker-compose.yml
EXEC_APP = $(DC) exec app

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
	docker run --rm --network=poenatela_app_net minio/mc \
		alias set localminio http://minio:9000 minio minio123 && \
		docker run --rm --network=poenatela_app_net minio/mc mb localminio/app-bucket --ignore-existing

shell:
	$(EXEC_APP) bash $(cmd)
