docker:
	docker-compose -f compose.yml up -d --remove-orphans
	docker-compose run api alembic upgrade head
	docker-compose run api python -m retrofun.import_products
	docker-compose run api python -m retrofun.import_orders


docker-dev:
	docker compose -f compose-dev.yml up -d --remove-orphans
	docker compose run api alembic upgrade head
	docker compose run api python -m retrofun.import_products
	docker compose run api python -m retrofun.import_orders
	