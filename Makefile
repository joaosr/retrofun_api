docker:
	docker compose -f docker-compose.yml up -d
	docker compose run api alembic upgrade head
	docker compose run api python -m retrofun.import_products
	docker compose run api python -m retrofun.import_orders
	