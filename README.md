# Vistor AI

Plataforma móvel de inspeção técnica de infraestrutura com inteligência artificial.
Inspetores registram ocorrências em campo com foto, GPS e vídeo — um modelo de visão
computacional classifica a severidade automaticamente e gera laudos PDF com hash SHA-256.

> **Status:** Em desenvolvimento ativo — backend em construção.

---

## Stack

| Camada | Tecnologia |
|---|---|
| Mobile | Flutter 3.x (Android 10+ / iOS 14+) |
| Backend | FastAPI + Python 3.11 |
| Banco de dados | PostgreSQL 16 + PostGIS |
| Armazenamento | MinIO (S3-compatible) |
| Cache | Redis 7 |
| IA | HuggingFace Inference API |
| Infra | Docker Compose |

---

## Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Git](https://git-scm.com/)

---

## Como rodar (desenvolvimento)

```bash
# 1. Clone o repositório
git clone https://github.com/seu-usuario/vistor-ai.git
cd vistor-ai

# 2. Configure as variáveis de ambiente
cp .env.example .env
# Edite o .env com suas credenciais

# 3. Suba a infraestrutura
docker compose up -d

# 4. Verifique se está tudo funcionando
curl http://localhost:8000/health
```

---

## Estrutura do projeto

```
vistor-ai/
├── backend/        # FastAPI — API REST
├── mobile/         # Flutter — app Android/iOS
├── docs/           # Documentação técnica e contexto do agente
└── docker-compose.yml
```

A documentação técnica completa (requisitos, casos de uso, design system)
está (ou estará em breve) nos arquivos `.md` dentro de `docs/`.

---

## Progresso

Acompanhe o andamento sprint a sprint em [`PROGRESS.md`](./PROGRESS.md).