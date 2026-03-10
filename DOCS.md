# 📄 Documentação Técnica - Transferr

Este documento detalha a arquitetura, os requisitos e as regras de negócio que sustentam o ecossistema Transferr.

---

## 🏗️ Arquitetura do Sistema

O projeto adota uma variação da **Clean Architecture**, dividida em camadas para facilitar a manutenção e escalabilidade:

1.  **Models (Entidades):** Classes puras que representam os dados (Excursion, Passenger, Expense, Enums).
2.  **Repositories:** Camada de acesso a dados isolada. Responsável por traduzir as chamadas do Firebase Firestore para o domínio do app.
3.  **Services (Lógica de Negócio):** Onde residem os cálculos complexos, transações de banco de dados (Batch Writes) e sincronização de contadores.
4.  **Providers (Estado):** Utiliza o pacote `Provider` para gerenciar o estado reativo da UI e injetar dependências.
5.  **UI (Screens & Widgets):** Componentes visuais desacoplados da lógica de dados.

---

## 🎯 Requisitos Funcionais (RF)

- **RF01 - Autenticação:** Cadastro e login de organizadores/agentes.
- **RF02 - Mapa de Assentos:** Interface interativa para alocação visual de passageiros.
- **RF03 - CRM Global:** Base centralizada para reutilização de dados de passageiros.
- **RF04 - Controle Financeiro:** Sistema de quitação (baixa total) e controle de depósitos.
- **RF05 - Check-in em Tempo Real:** Controle de embarque e status operacional durante a viagem.
- **RF06 - Dashboard:** Visão consolidada de faturamento e ocupação.

## ⚙️ Requisitos Não Funcionais (RNF)

- **RNF01 - Tempo Real:** Uso de `Streams` para sincronização instantânea via Firebase.
- **RNF02 - Usabilidade Noturna:** Interface nativa em Dark Mode para uso em estradas.
- **RNF03 - Performance:** Otimização de busca $O(1)$ no mapa de assentos.

## ⚖️ Regras de Negócio (RN)

- **RN01:** Proibição de alocação de dois passageiros na mesma poltrona.
- **RN02:** Quitação automática ao atingir o `basePrice` da excursão.
- **RN03:** Sincronização atômica de contadores globais ao alterar pagamentos individuais.
- **RN04:** Persistência de dados do passageiro no CRM mesmo após remoção de uma excursão específica.

---

## 💾 Estrutura de Dados (Firestore)

- `excursoes/`: Documentos principais das viagens.
- `excursoes/{id}/vagas/`: Sub-coleção com o vínculo passageiro-poltrona.
- `excursoes/{id}/despesas/`: Sub-coleção de gastos da viagem.
- `passageiros/`: CRM Global com dados mestres dos clientes.
