from fastapi.testclient import TestClient
from retrofun.app import app

client = TestClient(app)


def test_orders():
    response = client.get("/api/orders", params={"start": 0, "length": 10})
    assert response.status_code == 200
    data = response.json()
    assert "data" in data
    assert "total" in data
