FROM python:3.12

WORKDIR /retrofun

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

# RUN alembic upgrade head

# RUN python retrofun/import_orders.py

# RUN python retrofun/import_products.py

CMD ["uvicorn", "retrofun.app:app", "--host", "0.0.0.0", "--port", "8000"]
