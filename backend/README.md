# Vistor AI — Backend API

API de alta performance construída com FastAPI para o sistema de inspeção Vistor AI.

## Tecnologias

- FastAPI, SQLAlchemy (Async), PostgreSQL (PostGIS), Redis, MinIO.

## Como rodar localmente (sem Docker)

```bash
# 1. Crie o ambiente virutal: 
python -m venv venv

# 2. Ative-o: 
.\venv\Scripts\activate

# 3. Instale os pacotes e dependências: 
pip install -e .

# 4. Rode a API: 
uvicorn app.main:app --reload
```

## Testes

```bash
# Execute os testes para verificar integridade da API
pytest app/tests --cov=app` para verificar a integridade.
```

---
