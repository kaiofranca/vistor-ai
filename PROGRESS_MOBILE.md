# Vistor AI Mobile — Progress

Arquivo de atualização de todo o desenvolvimento do **Vistor AI Mobile**. Esse documento
foca exclusivamente na camada `mobile`. Para visualizar o `backend`, acesse o [`./PROGRESS.md`](./PROGRESS.md).

---

## Status das Sprints

| Sprint | Descrição | Status | Concluída em |
|---|---|---|---|
| 9 | Setup Mobile (Deps, Theme, App, Router, API, Local) | ✅ Concluído | 01/06/2026 |
| 10 | Autenticação + Core Services | ⬜ Pendente | — |
| 11 | Home + Lista de Inspeções | ⬜ Pendente | — |
| 12 | Fluxo de Criação de Inspeção | ⬜ Pendente | — |
| 13 | Mapa + Heatmap | ⬜ Pendente | — |
| 14 | Offline + Sincronização | ⬜ Pendente | — |
| 15 | Laudos + PDF Viewer | ⬜ Pendente | — |
| 16 | Gestão de Equipe + Usuários | ⬜ Pendente | — |

---

## Task 01

**Data:** 01/06/2026

**Sprint:** 9 - Setup Mobile
**Sessão:** Configuração de Dependências

### O que foi feito

- Preenchimento do `pubspec.yaml` com todas as dependências de produção (flutter_bloc, go_router, dio, drift, etc).
- Configuração de dependências de desenvolvimento (freezed, mocktail, bloc_test, etc).
- Adição de `dependency_overrides` para resolver conflitos entre as versões estáveis solicitadas e o Flutter SDK.
- Configuração de assets para imagens e fontes.

### Estado dos arquivos tocados

- `mobile/pubspec.yaml` — completo e validado.
- `mobile/pubspec.lock` — gerado via `flutter pub get`.

### Validações que passaram

- `flutter pub get` executado sem erros após ajustes de versão.

---

## Task 02

**Data:** 01/06/2026

**Sprint:** 9 - Setup Mobile
**Sessão:** Código Base (Theme, App, Main)

### O que foi feito

- Implementação do `lib/app/theme.dart` como fonte da verdade de design (cores, estilos, tokens).
- Configuração do `lib/app/app.dart` com `MaterialApp.router`, suporte a Dark Mode e localização (pt-BR).
- Implementação do `lib/main.dart` com inicialização do Hive e stub do Service Locator (GetIt).
- Adição da dependência `flutter_localizations` al `pubspec.yaml`.

### Estado dos arquivos tocados

- `mobile/lib/app/theme.dart` — completo.
- `mobile/lib/app/app.dart` — completo.
- `mobile/lib/main.dart` — completo.

### Validações que passaram

- `flutter analyze` sem erros nos arquivos criados.

---

## Task 03

**Data:** 01/06/2026

**Sprint:** 9 - Setup Mobile
**Sessão:** Navegação e Roteamento (GoRouter)

### O que foi feito

- Implementação do `lib/app/router.dart` com todas as 13 rotas do sistema.
- Configuração de `StatefulShellRoute` para as 4 abas principais: Inspeções, Mapa, Laudos e Perfil.
- Criação do `AppScaffold` com `BottomNavigationBar` utilizando `LucideIcons`.
- Implementação de telas placeholder para todas as rotas para permitir navegação funcional.
- Estrutura do guard de autenticação preparada (comentada) para ativação na Sprint 10.

### Estado dos arquivos tocados

- `mobile/lib/app/router.dart` — completo.
- `mobile/lib/app/app.dart` — atualizado para usar `buildRouter()`.

### Validações que passaram

- `flutter analyze` sem erros. Navegação entre as 4 abas funcionais via placeholders.

---

## Task 04

**Data:** 01/06/2026

**Sprint:** 9 - Setup Mobile
**Sessão:** Comunicação Core API (Dio, JWT, Storage)

### O que foi feito

- Implementação do `ApiClient` utilizando a biblioteca `Dio` para centralizar as requisições HTTP.
- Configuração de interceptores para injeção automática de tokens JWT no header `Authorization`.
- Implementação de lógica de **Refresh Token** automatizada para renovação de sessões expiradas.
- Criação do `TokenStorage` utilizando `FlutterSecureStorage` para armazenamento criptografado de tokens.
- Mapeamento completo dos endpoints do backend em `AppEndpoints`.
- Configuração de variáveis de ambiente (`API_BASE_URL`) via `envied`.

### Estado dos arquivos tocados

- `mobile/lib/core/api/api_client.dart` — completo.
- `mobile/lib/core/api/token_storage.dart` — completo.
- `mobile/lib/core/api/endpoints.dart` — completo.
- `mobile/lib/core/utils/env.dart` — completo.
- `mobile/pubspec.yaml` — atualizado com pins para compatibilidade de build.

### Validações que passaram

- `flutter analyze` sem erros.
- Geração de código `build_runner` concluída com sucesso (`env.g.dart`).
- Teste de instanciação do `ApiClient` validado.

---

## Task 05

**Data:** 01/06/2026

**Sprint:** 9 - Setup Mobile
**Sessão:** Local DB (Drift) e GPS Service

### O que foi feito

- Implementação do `GpsService` com captura de posição, validação de precisão (RN-08) e stream contínuo.
- Configuração do banco de dados local com `Drift` (`AppDatabase`) e tabela `local_inspections` para suporte offline.
- Implementação do `InspectionDao` para persistência local de inspeções pendentes de sincronização.
- Definição de exceções customizadas para falhas de GPS.

### Estado dos arquivos tocados

- `mobile/lib/core/services/gps_service.dart` — completo.
- `mobile/lib/core/local/database.dart` — completo.
- `mobile/lib/core/local/inspection_dao.dart` — completo.

### Validações que passaram

- `flutter analyze` sem erros.
- Geração de código `build_runner` (`database.g.dart`) concluída com sucesso.

### Próxima ação

Concluir a Sprint 9 (Task 6) ou iniciar a Sprint 10 (Autenticação).
