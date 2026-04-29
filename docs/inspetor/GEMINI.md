# Módulo: Inspetor

> Contexto carregado automaticamente quando o Gemini CLI está no projeto.
> Complementa o GEMINI.md raiz com regras específicas do perfil Inspetor.

---

## Quem é o Inspetor

Usuário de campo que utiliza o app em situações adversas: luz solar direta,
luvas, uma mão ocupada, conexão instável ou ausente. A UX deve priorizar
**rapidez, clareza e resiliência a falhas de rede**.

---

## Features de responsabilidade do Inspetor

| Feature | Caminho Flutter | Caminho Backend |
|---|---|---|
| Criar inspeção | `features/inspection/` | `routers/inspections.py` |
| Captura de GPS | `core/services/gps_service.dart` | — |
| Upload de mídia | `core/services/media_service.dart` | `routers/media.py` |
| Trabalho offline | `core/local/sync_manager.dart` | `routers/inspections.py` (sync batch) |
| Visualizar laudo | `features/report/` | `routers/reports.py` |

---

## Fluxo principal: Criar Inspeção (UC-02)

```
Stepper 5 etapas:
1. Localização  → GPS capturado + validação de precisão (alerta se > 50 m)
2. Categoria    → grid de seleção (elétrica, civil, hidráulica, estrutural, incêndio, outro)
3. Descrição    → campo de texto opcional (máx. 500 caracteres)
4. Mídia        → mínimo 1 foto obrigatória; até 10 fotos + 2 vídeos opcionais
5. Revisão      → exibe resumo + SeverityBadge + botão confirmar
```

### Regras críticas do fluxo

- O botão "Confirmar" na etapa 5 fica **desabilitado** enquanto não houver pelo menos 1 foto.
- GPS com precisão > 50 m exibe `AlertDialog` antes de avançar (RN-08).
- Imagens > 5 MB são comprimidas **antes** do upload com `flutter_image_compress` (qualidade mínima 80%).
- Se offline ao confirmar: inspeção salva no Drift com `is_synced = false`. SyncManager envia quando a conexão voltar.
- Após sync bem-sucedido: exibir `SnackBar` de confirmação com ID da inspeção.

---

## Modo Offline — Comportamento esperado

- `OfflineBanner` (amber, topo da tela) exibido sempre que `connectivity == none`.
- `SyncIndicator` no AppBar mostra: ✓ verde (synced) / ↻ laranja girando (syncing) / ⚠ vermelho com badge numérico (N pendentes).
- Inspeções criadas offline ficam visíveis na lista com ícone de "nuvem pendente".
- Se sem sync por > 7 dias: chip vermelho "Dados podem estar desatualizados" no card da inspeção (RN-06).
- O mapa exibe somente pontos em cache local quando offline (sem heatmap).

---

## AiResultCard — Interação do Inspetor

Após envio da foto ao HuggingFace:

```
┌─────────────────────────────────────────────────┐
│ 🤖  IA: Dano estrutural em concreto             │
│     [████████████░░░] 78% de confiança          │
│                                                  │
│  [Confirmar]        [Corrigir classificação]     │
└─────────────────────────────────────────────────┘
```

- **Score >= 0,55**: botão "Confirmar" disponível; inspetor pode aceitar ou corrigir.
- **Score < 0,55**: card exibe "Classificação incerta — revisão necessária"; botão "Confirmar" desabilitado até o inspetor inserir um label manual.
- Toda correção manual é registrada com `user_id` e `timestamp` para análise futura (RF-IA06).

---

## Endpoints que o Inspetor consome

```
POST   /api/auth/login
POST   /api/auth/refresh
POST   /api/auth/logout

POST   /api/inspections/           # criar inspeção
GET    /api/inspections/           # listar próprias inspeções
GET    /api/inspections/{id}       # detalhe
PATCH  /api/inspections/{id}       # atualizar status / confirmar label IA
POST   /api/inspections/sync       # enviar batch offline

POST   /api/media/presign          # obter URL de upload
GET    /api/media/{id}/url         # URL de download (TTL 1h)

POST   /api/reports/generate       # gerar laudo
GET    /api/reports/{id}           # baixar laudo
```

---

## Permissões RBAC do Inspetor

| Ação | Permitido? |
|---|---|
| Criar inspeção | ✅ |
| Editar própria inspeção | ✅ |
| Editar inspeção de outro inspetor | ❌ (403) |
| Ver inspeções de outros inspetores | ❌ salvo se `assigned_to == current_user.id` |
| Atribuir inspeção | ❌ (somente gestor/admin) |
| Gerar laudo | ✅ (para inspeções próprias ou atribuídas) |
| Ver dashboard / heatmap | ❌ |
| Exportar GeoJSON | ❌ |
| Gerenciar usuários | ❌ |
