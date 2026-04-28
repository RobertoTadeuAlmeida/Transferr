Relatório: Revisão de Ações — Modo Demo

Objetivo
--------
Implementar um Modo Demo que permita ao app funcionar sem Firebase, usando dados mockados para demonstração, seguindo .github/copilot/instructions.md.

Conformidade com as regras obrigatórias
--------------------------------------
- Não quebrar funcionalidades existentes.
- Não substituir lógica atual; apenas adicionar suporte ao modo demo.
- Respeitar arquitetura (Providers, Services, Repositories).
- Usar injeção de dependência e separar responsabilidades.

Lista de arquivos sugeridos (criar/alterar)
-------------------------------------------
- lib/config/demo_config.dart           — flag global e helpers
- lib/providers/demo_mode_provider.dart  — Provider para isDemoMode
- lib/mock/                              — diretório com JSON e fixtures
  - lib/mock/company.json
  - lib/mock/users.json
  - lib/mock/passengers.json
  - lib/mock/trips.json
  - lib/mock/finance.json
- lib/repositories/*_mock.dart           — versões mock dos repositories
  - lib/repositories/passenger_repository_mock.dart
  - lib/repositories/user_repository_mock.dart
- lib/services/repository_factory.dart   — fábrica que devolve impl. real ou mock
- lib/ui/login/demo_toggle_button.dart   — botão alternar modo demo (tela de login)
- android/ios: (opcional) instruções para builds locais

Trechos de código sugeridos (exemplos)
--------------------------------------
// lib/config/demo_config.dart
class DemoConfig {
  static bool isDemoMode = false; // inicializar via Provider/prefs
}

// Exemplo fábrica simples
abstract class RepositoryFactory {
  static T create<T>(T real, T mock) => DemoConfig.isDemoMode ? mock : real;
}

Decisões e justificativas
-------------------------
- Provider global facilita injeção e reatividade (recomenda-se ChangeNotifier).
- Dados mockados em JSON mantêm-se fáceis de editar e revisar.
- Repositories mock retornam modelos idênticos aos reais para evitar branching em UI.
- Persistência do estado (SharedPreferences) opcional, recomendado para UX consistente.

Critérios de aceitação
----------------------
- Com modo demo ativo, nenhum código do Firebase é chamado.
- Navegação e telas funcionam com dados mockados.
- Troca entre modo real/demo é simples e reversível.

Próximos passos
---------------
1. Criar estrutura de mock e exemplos de repositorios mock.
2. Implementar DemoMode provider e fábrica de repositories.
3. Adicionar botão de ativação na tela de login e persistência via SharedPreferences.
4. Testar fluxos principais (login, listar passageiros, ver excursões) em modo demo.

Assinado por: Copilot (documentação gerada seguindo .github/copilot/instructions.md)
