# Módulo: Administrador

> Complementa o GEMINI.md raiz com regras específicas do perfil Admin.
> O Admin herda todas as permissões do Gestor e do Inspetor.

---

## Quem é o Administrador

Gestor do sistema responsável por configuração, usuários e auditoria.
Não precisa necessariamente usar o app em campo; pode operar via interface
web (futuro) ou pelo próprio app mobile.

---

## Features de responsabilidade do Admin

| Feature | Caminho Flutter | Caminho Backend |
|---|---|---|
| Gerenciar usuários | `features/admin/users/` | `routers/users.py` |
| Auditar logs | `features/admin/audit/` | `GET /audit-logs/` |
| Configurar categorias | `features/admin/settings/` | `routers/settings.py` |
| Gerenciar locais/setores | `features/admin/locations/` | `routers/locations.py` |

---

## Fluxo: Gerenciar Usuários (UC-08)

```
POST   /api/users/              # criar usuário (nome, email, role, senha temp.)
GET    /api/users/              # listar paginado
PATCH  /api/users/{id}          # editar role, is_active
DELETE /api/users/{id}          # soft delete (is_active = false, nunca remove)
```

### Regras críticas

- Admin **não pode desativar a própria conta** (backend retorna 403 — evita lockout).
- Ao criar usuário, senha temporária é enviada por email (template `email_new_user.html`).
- Email duplicado retorna HTTP 409 com mensagem clara.
- Toda ação em usuário gera registro em `audit_log`.

---

## Auditoria

A tabela `audit_log` é **imutável** — nunca atualize ou delete registros nela.
O Admin pode consultá-la via:

```
GET /api/audit-logs/?entity=inspection&entity_id=uuid&limit=50
```

Campos disponíveis para filtro: `entity`, `entity_id`, `user_id`, `action`, `created_at`.

---

## Configuração de Modelos de IA

O Admin pode trocar o modelo HuggingFace padrão via settings:

```
PATCH /api/settings/ai
body: { "model_id": "microsoft/resnet-50", "confidence_threshold": 0.60 }
```

- `confidence_threshold`: valor mínimo para aceitar classificação automática (RN-04).
- Alterações em configuração de IA geram registro em `audit_log`.

---

## Permissões RBAC do Admin

| Ação | Permitido? |
|---|---|
| Tudo que o Gestor pode | ✅ |
| Criar / editar / desativar usuários | ✅ |
| Configurar categorias de inspeção | ✅ |
| Configurar modelo de IA e threshold | ✅ |
| Consultar audit_log | ✅ |
| Reativar laudos com hash divergente | ✅ |
| Gerenciar setores/locais no mapa | ✅ |
| Deletar fisicamente qualquer registro | ❌ (soft delete apenas, sempre) |
