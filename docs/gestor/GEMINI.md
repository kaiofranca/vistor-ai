# Módulo: Gestor

> Complementa o GEMINI.md raiz com regras específicas do perfil Gestor.
> O Gestor herda todas as permissões do Inspetor e tem acesso ao dashboard.

---

## Quem é o Gestor

Supervisor operacional que monitora inspeções em andamento, atribui inspetores,
analisa padrões geoespaciais e gera relatórios consolidados. Usa o app
principalmente para **visão macro**: mapa de calor, estatísticas e gestão de equipe.

---

## Features de responsabilidade do Gestor

| Feature | Caminho Flutter | Caminho Backend |
|---|---|---|
| Dashboard / mapa de calor | `features/map/` | `routers/geo.py` |
| Atribuir inspeção | `features/inspection/` | `PATCH /inspections/{id}` |
| Exportar GeoJSON/CSV | `features/map/` | `GET /geo/export` |
| Gerar relatório consolidado | `features/report/` | `POST /reports/generate` |
| Ver inspeções de toda a equipe | `features/inspection/` | `GET /inspections/` |

---

## Dashboard Geoespacial

### Heatmap (GET /geo/heatmap)

- Query PostGIS: `ST_Collect` agrupando pontos por severidade com peso.
- Gradiente: vermelho (#B71C1C) → laranja (#E65100) → verde (#2E7D32).
- Filtros disponíveis: período, severidade, categoria, status.
- Resposta: GeoJSON `FeatureCollection` comprimido com gzip.

### Inspeções próximas (GET /geo/nearby)

```
Parâmetros obrigatórios: lat, lon
Parâmetros opcionais:    radius_m (50–5000, default 300), severity, status
Query PostGIS:           ST_DWithin(location::geography, target::geography, radius_m)
```

### Exportação (GET /geo/export)

- Formatos: `geojson` (default) e `csv` (parâmetro `format=csv`).
- Filtros: mesmos do heatmap.
- Compressão: gzip obrigatória na resposta.

---

## Fluxo: Atribuir Inspeção (UC-06)

```
1. Gestor abre detalhe de inspeção com status == 'open'
2. Pressiona "Atribuir inspetor"
3. App busca GET /users?role=inspector&is_active=true
4. Gestor seleciona inspetor
5. App envia PATCH /inspections/{id}
   body: { assigned_to: uuid, status: "in_progress" }
6. Backend:
   - Valida que status atual == 'open' (RN-14)
   - Atualiza assigned_to e status
   - Registra em audit_log
   - Envia push FCM ao inspetor designado (RF-NT02)
7. UI do gestor: card da inspeção atualiza badge para "Em andamento"
```

**Regra crítica:** se a inspeção não estiver com status `open`, o botão de
atribuição fica **desabilitado** com tooltip explicativo (RN-14).

---

## Endpoints exclusivos do Gestor

```
GET    /api/geo/heatmap            # mapa de calor ponderado
GET    /api/geo/nearby             # inspeções num raio
GET    /api/geo/export             # exportar GeoJSON / CSV
GET    /api/inspections/           # todas as inspeções (sem filtro de owner)
PATCH  /api/inspections/{id}       # atribuir inspetor, reabrir inspeção
GET    /api/users?role=inspector   # lista de inspetores para atribuição
```

---

## Permissões RBAC do Gestor

| Ação | Permitido? |
|---|---|
| Tudo que o Inspetor pode | ✅ |
| Ver inspeções de toda a equipe | ✅ |
| Atribuir inspeção a inspetor | ✅ |
| Reabrir inspeção resolvida | ✅ |
| Ver dashboard e heatmap | ✅ |
| Exportar GeoJSON / CSV | ✅ |
| Gerar laudos de qualquer inspeção | ✅ |
| Gerenciar usuários (criar/desativar) | ❌ (somente admin) |
| Configurar categorias e modelos IA | ❌ (somente admin) |
