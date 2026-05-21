import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User

@pytest.mark.asyncio
async def test_list_inspections_empty_for_new_user(authed_client: AsyncClient):
    response = await authed_client.get("/api/inspections/")
    assert response.status_code == 200
    assert response.json() == []

@pytest.mark.asyncio
async def test_create_inspection_success(authed_client: AsyncClient):
    payload = {
        "category": "civil",
        "description": "Buraco na via",
        "lat": -5.794,
        "lon": -35.211,
        "gps_accuracy": 10.5
    }
    response = await authed_client.post("/api/inspections/", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["category"] == "civil"
    assert data["location"]["lat"] == -5.794
    assert data["location"]["lon"] == -35.211
    assert data["status"] == "open"
    assert "id" in data

@pytest.mark.asyncio
async def test_get_inspection_nearby_success(authed_client: AsyncClient):
    # Criar uma inspeção
    payload = {
        "category": "electrical",
        "lat": -5.794,
        "lon": -35.211
    }
    await authed_client.post("/api/inspections/", json=payload)
    
    # Buscar próxima (mesmo ponto)
    response = await authed_client.get("/api/geo/nearby?lat=-5.794&lon=-35.211&radius_m=100")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["inspection"]["category"] == "electrical"
    assert data[0]["distance_m"] < 1.0
    
    # Buscar longe
    response = await authed_client.get("/api/geo/nearby?lat=0&lon=0&radius_m=100")
    assert response.status_code == 200
    assert response.json() == []

@pytest.mark.asyncio
async def test_geo_nearby_validation(authed_client: AsyncClient):
    # Lat inválida
    response = await authed_client.get("/api/geo/nearby?lat=100&lon=0")
    assert response.status_code == 422
    
    # Raio inválido
    response = await authed_client.get("/api/geo/nearby?lat=0&lon=0&radius_m=6000")
    assert response.status_code == 422

@pytest.mark.asyncio
async def test_geo_export_geojson(authed_client: AsyncClient):
    # Criar uma inspeção
    await authed_client.post("/api/inspections/", json={
        "category": "hydraulic",
        "lat": -5.0,
        "lon": -35.0
    })
    
    response = await authed_client.get("/api/geo/export?format=geojson")
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/geo+json"
    data = response.json()
    assert data["type"] == "FeatureCollection"
    assert len(data["features"]) >= 1

@pytest.mark.asyncio
async def test_geo_export_csv(authed_client: AsyncClient):
    response = await authed_client.get("/api/geo/export?format=csv")
    assert response.status_code == 200
    assert "text/csv" in response.headers["content-type"]
    assert "attachment; filename=inspections_" in response.headers["content-disposition"]
