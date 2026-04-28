Resumo de Ações — Modo Demo

Visão geral
-----------
Resumo do que foi feito/planejado com base em .github/copilot/instructions.md para implementar o Modo Demo.

Ações realizadas / recomendadas
-------------------------------
- Flag global de modo demo: Definida a necessidade de um controle central (ex: DemoConfig / DemoModeProvider).
- Provider global: Recomendado uso de ChangeNotifier (lib/providers/demo_mode_provider.dart) para expor `isDemoMode` e métodos `enable/disable`.
- Dados mockados: Estrutura proposta em `lib/mock/` com JSONs realistas para empresa, usuários, passageiros, excursões e financeiro.
- Repositories mock: Criar implementações mock que retornam os mesmos modelos que os repositories reais (ex: PassengerRepositoryMock).
- Fábrica de repositórios: Implementar `RepositoryFactory` que escolhe mock ou real de acordo com `isDemoMode`.
- Ativação: Botão simples na tela de login (`lib/ui/login/demo_toggle_button.dart`) e/ou configuração acessível para QA.
- Persistência (recomendada): Salvar preferência em SharedPreferences para manter estado entre execuções.

Como testar (passos rápidos)
---------------------------
1. Ativar o modo demo na tela de login.
2. Navegar pelos fluxos principais: listar passageiros, abrir detalhes de excursões, fluxo financeiro (se aplicável).
3. Verificar que não há chamadas ao Firebase (monitoramento de logs ou interceptadores).
4. Desativar modo demo e confirmar que fluxos voltam a utilizar Firebase.

Observações técnicas
--------------------
- Mock repositories devem usar os mesmos DTOs/Modelos para evitar condicionais nas camadas superiores.
- Evitar duplicação: implementar camadas auxiliares reutilizáveis para ler JSONs de mock e mapear para modelos.
- Separar claramente a inicialização do app para injetar implementações corretas (ex: ServiceLocator ou padrão Provider).

Registros e próximos passos
--------------------------
- A documentação e a lista de arquivos estão em docs/REVIE_ACTIONS_MODO_DEMO.md.
- Próxima tarefa: criar os arquivos de mock e implementar a fábrica de repositories.

Gerado seguindo: .github/copilot/instructions.md
