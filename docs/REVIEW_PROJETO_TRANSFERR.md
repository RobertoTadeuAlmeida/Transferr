# REVIEW_PROJETO_TRANSFERR

Data: 2026-04-22

Resumo rápido
------------
Projeto Flutter (Transferr) com arquitetura aproximada a Clean Architecture + DDD, usando Provider para estado e Firebase (Auth, Firestore) como backend. Estrutura organizada em models, repositories, services, providers, screens, validators e widgets. Boa cobertura de testes unitários em serviços/providers/models.

1. Arquitetura identificada no projeto
------------------------------------
- Padrão: Clean-like / DDD (camadas separadas por responsabilidade). Evidências: pastas `models`, `repositories`, `services`, `providers`, `validators`, `screens` e fluxo declarado no README (`UI ➔ Provider ➔ Service ➔ Validator ➔ Repository ➔ Firebase`).
- Organização atual: código modularizado por domínio (excursions, passengers, users, finance, settings). Providers fazem ligação entre UI e serviços; repositories encapsulam acesso ao Firebase.
- Problemas e inconsistências:
  - Possível mistura de responsabilidades em Services (ver nota: README menciona refatoração do AuthService para orquestrador — revisar serviços para garantir single responsibility).
  - Padronização de nomes e localização de widgets menores (algumas telas têm widgets internos, outras usam widgets globais) — documentar convenção.

2. Estado atual do projeto
--------------------------
- Funcionalidades implementadas (evidências no `lib/screens`):
  - Autenticação (login, pending company flow, auth wrapper)
  - Registro multi-step
  - Gestão de passageiros (CRUD, CRM)
  - Gestão de excursões (criar, histórico, dashboard, mapa de assentos, check-in)
  - Gestão financeira por excursão
  - Usuários/empresas e troca de contexto multi-tenant (conforme README)
- Qualidade do código:
  - Estrutura clara e lints ativados (analysis_options inclui flutter_lints).
  - Testes unitários presentes (tests para services, providers, models, screens básicos).
  - Uso consistente de Provider, separação de validação em `validators` aumenta testabilidade.
- Pontos fortes:
  - Arquitetura modular e bem segmentada.
  - Testes presentes, facilitando mudanças.
  - Documentação interna (README e DOCS.md) descrevendo decisões arquiteturais.
- Pontos fracos:
  - Ausência aparente de integração/e2e tests (não verificado na raiz dos testes).
  - Falta de evidência de CI/CD (workflows) e scripts para builds de release automatizados.
  - Possível dependência forte de Firebase sem camadas de abstração suficientes para swaps de backend — revisar interfaces de repositório.

3. O que falta para ser um MVP apresentável
-------------------------------------------
- Funcionalidades essenciais ausentes (baseado no código atual):
  - Fluxos de onboarding e demos com dados mock para apresentações (modo demo).
  - Cobertura de testes E2E para fluxos críticos (login, reserva, check-in).
- Melhorias mínimas de interface:
  - Telas de onboarding e primeiros passos com textos de ajuda/contexto.
  - Estados de carregamento e placeholder uniformes (usar shimmer já presente onde necessário).
- Ajustes para demonstração:
  - Script para popular dados de demonstração no Firestore (seed script) ou mock provider.
  - Tela de administração para alternar empresas/tenants em demo.

4. O que falta para publicação nas lojas
----------------------------------------
- Requisitos técnicos:
  - Configurar signing (Android keystore; iOS provisioning/profile) e variáveis de ambiente para chaves.
  - Configurar flavors ou build-variants (staging/prod) e arquivos `google-services` adequados.
- Performance:
  - Auditar uso de Streams/Listeners do Firebase para evitar leaks; garantir cancelamento de subscriptions nos providers.
  - Analisar imagens/assets e comprimir quando necessário; revisar rebuilds desnecessários na árvore de widgets.
- Segurança:
  - Regras do Firestore revisadas e aplicadas por ambiente (prod vs staging).
  - Evitar hardcode de keys; usar `package_info_plus`/runtime configs para separar endpoints.
- Tratamento de erros:
  - Centralizar captura de erros não tratáveis (crashlytics) e mostrar UIs amigáveis em falhas de rede.
- Configuração de produção:
  - Integração com CI para builds e testes automáticos; geração de artefatos.
  - Política de releases (changelog, versioning automatizado).

5. Prioridade de implementação
------------------------------
Alta prioridade
- Configurar build de release (signing, flavors) e integração com CI
- Seed/demo data e modo demo para apresentações
- Garantir regras de segurança do Firestore para produção
- Revisar e corrigir leaks de Streams/Subscriptions

Média prioridade
- Criar testes E2E para caminhos críticos (login, reserva, check-in)
- Melhorar padronização de nomes e convenções de pastas/widgets
- Centralizar tratamento de erros e integração com Crashlytics

Baixa prioridade
- Otimizações visuais e refinamentos de UI
- Suporte offline avançado / sincronização
- Migração para arquitetura de estado alternativa (se necessário)

6. Sugestões de melhoria
------------------------
- Arquitetura:
  - Formalizar contratos (interfaces) para repositories e services; garantir inversão de dependência para facilitar mocks e trocas de backend.
- Refatoração:
  - Auditar services e extrair responsabilidades cruzadas (ex.: separar pure business logic de orquestração de I/O).
  - Padronizar criação de widgets/reutilizáveis (pasta `widgets` já existe; definir guidelines).
- Boas práticas:
  - Adicionar CI (GitHub Actions) com passos: flutter analyze, flutter test, build APK/IPA for staging.
  - Implementar scripts de seed e de limpeza de dados de demo.
  - Documentar convenções (naming, arquitetura, guidelines de commits) em DOCS.md ou CONTRIBUTING.md.

Anexos e evidências rápidas
---------------------------
- Dependências principais (pubspec.yaml): firebase_core, cloud_firestore, firebase_auth, provider, google_sign_in, intl, uuid.
- Estrutura chave: `lib/models`, `lib/providers`, `lib/services`, `lib/repositories`, `lib/screens`, `lib/validators`.
- Tests: várias unidades em `test/` cobrindo providers, services e modelos.

Conclusão
---------
O projeto está em estado avançado com arquitetura adequada para escalar. Priorizar preparação para build/CI, segurança Firestore e demo seeds permitirá transformar o estado atual em um MVP apresentável em poucas semanas de esforço focalizado.


---
Relatório gerado automaticamente com base no estado do código fonte presente no repositório local.
