docker:
	docker-compose -f compose.yml up -d --remove-orphans
	echo "⏳ Waiting for db to be healthy..."
	docker-compose ps
	docker-compose wait db || sleep 10  # Fallback if 'wait' unsupported
	docker-compose exec -T api alembic upgrade head
	docker-compose exec -T api python -m retrofun.import_products
	docker-compose exec -T api python -m retrofun.import_orders


docker-dev:
	docker compose -f compose-dev.yml up -d --remove-orphans
	docker compose run api alembic upgrade head
	docker compose run api python -m retrofun.import_products
	docker compose run api python -m retrofun.import_orders
	