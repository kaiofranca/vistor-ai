# Vistor AI — Contexto do Agente

> Este arquivo é carregado automaticamente pelo Gemini CLI em cada sessão.
> Ele define as regras gerais do projeto. Regras específicas de cada módulo
> ficam em `docs/<modulo>/GEMINI.md` e são importadas abaixo.

---

## Visão Geral do Projeto

**Vistor AI** é um aplicativo móvel de inspeção técnica de infraestrutura com
inteligência artificial. Inspetores registram ocorrências em campo com foto, GPS
e vídeo; um modelo de visão computacional classifica automaticamente a severidade;
laudos PDF são gerados com hash SHA-256 para integridade. O sistema funciona
completamente offline com sincronização automática.

---

## Stack

| Camada | Tecnologia |
|---|---|
| Mobile | Flutter 3.x + Dart (Android 10+ / iOS 14+) |
| State management | BLoC / Cubit + Freezed |
| Banco local | Drift (SQLite) |
| HTTP client | Dio + interceptors JWT |
| Mapas | flutter_map + OpenStreetMap |
| Backend | FastAPI (Python 3.11) + Uvicorn |
| ORM | SQLAlchemy 2.0 async + GeoAlchemy2 |
| Banco remoto | PostgreSQL 16 + PostGIS 3.4 |
| Armazenamento | MinIO (S3-compatible, self-hosted) |
| Cache / sessões | Redis 7 |
| IA | HuggingFace Inference API + fallback ONNX local |
| PDF | WeasyPrint + Jinja2 |
| Notificações | Firebase Cloud Messaging (FCM) |
| Infra | Docker Compose (Windows 11 dev) |
| Migrations | Alembic |

---

## Estrutura de Pastas

```
vistor-ai/
├── GEMINI.md                  ← este arquivo
├── .geminiignore
├── .gemini/
│   └── settings.json
├── docker-compose.yml
├── .env.example
├── docs/
│   ├── backend/
│   │   └── GEMINI.md
│   ├── mobile/
│   │   ├── GEMINI.md
│   │   ├── LAYOUT.md
│   │   ├── THEME.dart
│   │   ├── ROUTER.dart
│   │   └── STATES.md
│   ├── inspetor/
│   │   └── GEMINI.md
│   ├── gestor/
│   │   └── GEMINI.md
│   └── admin/
│       └── GEMINI.md
│
├── backend/                   ← FastAPI
└── mobile/                    ← Flutter
```

---

## Arquitetura — Princípios Invioláveis

### Backend

- **Routers** só recebem a requisição HTTP e delegam para `services/`. Zero lógica de negócio em routers.
- **Services** contêm toda a lógica de negócio. São chamados por routers, jobs agendados e testes.
- **Models** são mapeamento ORM puro. Sem métodos de negócio, sem lógica de validação.
- **Schemas** são separados por direção: `XxxCreate` (entrada), `XxxUpdate` (patch), `XxxOut` (saída/response_model).
- Toda alteração em `Inspection` deve gerar registro em `AuditLog` (action, old_value, new_value, user_id, ip).
- Nunca use `DELETE` físico em `Inspection`. Sempre soft delete: `deleted_at = now()`.
- Toda query de listagem deve filtrar `deleted_at IS NULL`.

### Mobile (Flutter)

- Arquitetura **Feature-First**: cada feature tem `data/`, `domain/`, `presentation/`.
- `core/` contém apenas infraestrutura genérica. **Nunca importa nada de `features/`**.
- `shared/` contém widgets e modelos usados por 2 ou mais features.
- Toda lógica de estado fica em `BLoC` ou `Cubit`. Widgets são puramente declarativos.
- **Nenhuma chamada HTTP direta em widget**. Sempre via repository → BLoC/Cubit.
- DTOs usam `Freezed` (imutabilidade garantida). Nunca use `Map<String, dynamic>` como modelo.
- Tokens JWT ficam **exclusivamente** no `FlutterSecureStorage`. Nunca em `SharedPreferences`.

---

## Padrões de Código

### Python / FastAPI

- Siga **PEP 8** + type hints obrigatórios em todos os parâmetros e retornos de função.
- Use `async def` em toda função que faz I/O (db, http, storage).
- Nomeação: `snake_case` para variáveis e funções, `PascalCase` para classes.
- Imports: stdlib → third-party → local, separados por linha em branco.
- Nunca concatene SQL dinamicamente. Use sempre ORM ou parâmetros vinculados.
- Erros de negócio: levante `HTTPException` com código e mensagem claros.
- Sempre valide MIME type de uploads por **magic bytes** (`python-magic`), não pela extensão.

### Dart / Flutter

- Siga o **Effective Dart** (style, design, usage).
- Indentação: 2 espaços.
- Nomeação: `camelCase` para variáveis/funções, `PascalCase` para classes, `snake_case` para arquivos.
- Use `const` onde possível em widgets para otimizar rebuilds.
- Sempre trate erros em `repositories`: capture exceções específicas, não `catch (e)` genérico.
- Toda tela deve ter um estado de loading, erro e sucesso explícito via BLoC/Cubit.

---

## Banco de Dados

- Extensão PostGIS **obrigatória**. Coordenadas GPS sempre no tipo `GEOMETRY(POINT, 4326)`.
- Índice `GIST` em `inspections.location` é **obrigatório** para queries de proximidade.
- Índice parcial `WHERE deleted_at IS NULL` para queries de listagem ativa.
- Migrations gerenciadas pelo **Alembic**. **Nunca edite uma migration já commitada**; crie uma nova.
- Migrations devem ser idempotentes quando possível (`CREATE TABLE IF NOT EXISTS`, etc.).
- UUIDs como PK em todas as tabelas (`gen_random_uuid()`).

---

## Segurança — Regras Não Negociáveis

- **Senhas**: bcrypt custo mínimo 12. Nunca logar, nunca retornar em response.
- **JWT**: access token TTL 15 min, refresh token TTL 7 dias armazenado em Redis.
- **IDOR**: verificar ownership em **todo** endpoint. `inspector_id == current_user.id OR role in ('manager','admin')`.
- **RBAC**: decorator `require_role(roles=[...])` obrigatório em endpoints sensíveis.
- **TLS**: toda comunicação usa HTTPS. Sem exceção em produção.
- **Presigned URLs**: TTL máximo de 1 hora para acesso a mídias.
- **Rate limiting**: máx. 5 tentativas/min em `/auth/login` por IP (SlowAPI).
- Campos sensíveis (senha, token, hash) **mascarados** em logs antes de persistir.

---

## IA e Processamento de Imagem

- Modelo padrão: `google/vit-base-patch16-224` via HuggingFace Inference API.
- Timeout da chamada externa: **10 segundos**.
- Fallback obrigatório para modelo ONNX local quando API indisponível.
- Score de confiança < 0,55 → severidade `'pending_review'` (nunca encerrar inspeção automaticamente).
- Salvar resposta bruta da IA em campo `ai_raw JSONB` para auditoria e reprocessamento.
- Registrar correções humanas sobre o label da IA para análise futura de acurácia.

---

## Regras de Negócio Globais

| ID | Regra |
|---|---|
| RN-01 | Inspeção só pode ser encerrada com pelo menos 1 foto e GPS registrado |
| RN-02 | Somente o criador da inspeção ou gestor/admin pode editá-la |
| RN-03 | Severidade `critical` dispara push FCM para todos os gestores ativos |
| RN-04 | Score IA < 0,55 → status `pending_review`; inspetor deve confirmar antes de encerrar |
| RN-05 | Laudos só gerados para inspeções com status `in_progress` ou `resolved` |
| RN-07 | Exclusão é sempre soft delete (`deleted_at`). Nunca DELETE físico |
| RN-08 | GPS com precisão > 50 m exibe alerta antes de salvar |
| RN-09 | Hash SHA-256 do PDF revalidado a cada download; divergência bloqueia e notifica admin |
| RN-10 | Inspeções a menos de 10 m entre si são agrupadas como mesmo ponto físico |
| RN-15 | Laudo é imutável após geração. Alterações posteriores não modificam o PDF existente |

---

## Testes

- Cobertura mínima de **70%** no backend (`pytest --cov`).
- Todo service deve ter testes unitários com mocks dos repositórios.
- Routers testados com `httpx.AsyncClient` (não com requests síncronos).
- Flutter: todo Cubit/BLoC deve ter testes de unidade com `bloc_test`.
- Nunca commite código com testes pulados (`@pytest.mark.skip`, `skip:` no Flutter) sem justificativa.

---

## O que o Agente NÃO Deve Fazer

- **Não altere** arquivos de migration já commitados (`alembic/versions/`).
- **Não modifique** `.env.example` com valores reais.
- **Não instale** dependências novas sem indicar explicitamente qual pacote e por quê.
- **Não use** `WidthType.PERCENTAGE` em tabelas DOCX (quebra no Google Docs).
- **Não gere** código com `catch (e)` genérico sem ao menos logar o erro.
- **Não use** `SharedPreferences` para dados sensíveis no Flutter.
- **Não concatene** SQL dinamicamente. Sempre ORM com parâmetros.
- **Não adicione** lógica de negócio em widgets Flutter ou em routers FastAPI.

---

## Contextos Específicos por Módulo

@./docs/inspetor/GEMINI.md
@./docs/gestor/GEMINI.md
@./docs/admin/GEMINI.md
@./docs/backend/GEMINI.md
@./docs/mobile/GEMINI.md
