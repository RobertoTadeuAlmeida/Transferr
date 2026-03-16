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

### 👥 Módulo de Usuários e Equipe (Multi-tenant)
- **RF01 - Registro de Admin:** Um usuário pode se cadastrar como administrador, definindo o nome da sua própria empresa.
- **RF02 - Registro de Agente:** Usuários que não são administradores só podem se cadastrar se possuírem um ID de empresa de convite válido.
- **RF03 - Gestão de Perfil:** O usuário deve poder alterar seu nome e foto de perfil.
- **RF04 - Listagem de Equipe:** O administrador deve visualizar todos os membros (agentes) vinculados à sua empresa ativa.
- **RF05 - Controle de Acesso (Ativação):** O administrador deve poder ativar ou desativar o acesso de membros da sua equipe a qualquer momento.
- **RF06 - Sistema de Convites:** Envio de convites de colaboração entre empresas para usuários existentes no sistema.
- **RF07 - Troca de Contexto (Switch Company):** Usuários vinculados a múltiplas empresas devem poder alternar entre elas, mudando instantaneamente o contexto de dados do app.

### 🚌 Módulo de Excursões
- **RF08 - Mapa de Assentos:** Interface interativa para alocação visual de passageiros e reserva de poltronas.
- **RF09 - CRM Global:** Base centralizada para reutilização de dados de passageiros em múltiplas viagens.
- **RF10 - Controle Financeiro:** Gestão de pagamentos individuais, depósitos parciais e status de quitação.
- **RF11 - Check-in em Tempo Real:** Controle de embarque (Aguardando, Embarcou, Parada, Desembarcou) durante a execução da viagem.
- **RF12 - Gestão de Despesas:** Registro de gastos operacionais da viagem (Combustível, Guia, Pedágio) para cálculo de lucro líquido.
- **RF13 - Ciclo de Vida da Viagem:** Transição controlada de estados (CRIADA -> EM_ANDAMENTO -> CONCLUÍDA/CANCELADA).
- **RF14 - Dashboard Operacional:** Visão consolidada de assentos disponíveis, ocupação percentual e faturamento bruto.

---

## ⚙️ Requisitos Não Funcionais (RNF)

- **RNF01 - Isolamento de Dados:** Nenhum dado (viagens, passageiros, lucros) deve ser visível para usuários de empresas diferentes (Isolamento via Security Rules).
- **RNF02 - Tempo Real:** Uso de `Streams` para sincronização instantânea via Firebase entre todos os membros da equipe.
- **RNF03 - Usabilidade Noturna:** Interface otimizada para condições de baixa luminosidade (Dark Mode nativo).
- **RNF04 - Performance:** Otimização de busca e renderização do mapa de assentos para suportar veículos de grande porte sem latência.

---

## ⚖️ Regras de Negócio (RN)

### 🛡️ Segurança e Hierarquia
- **RN01 - Autonomia Admin:** Somente usuários com perfil `ADMIN` podem convidar novos membros ou alterar o status da equipe.
- **RN02 - Vínculo Obrigatório:** Agentes não operam de forma independente; devem estar vinculados a pelo menos uma empresa ativa.
- **RN03 - Identidade Multi-tenant:** No cadastro de um ADMIN, o ID da empresa é igual ao seu UID, garantindo um namespace único para seus dados.
- **RN04 - Aceite de Convite:** Ao aceitar um convite, a nova empresa é adicionada à lista `companies` e torna-se automaticamente a empresa ativa.

### 🚌 Operação de Excursões
- **RN05 - Unicidade de Assento:** Proibição estrita de alocação de dois passageiros na mesma poltrona dentro de uma mesma viagem.
- **RN06 - Proteção de Status:** Viagens com status `CONCLUIDA` ou `CANCELADA` não podem ser reiniciadas ou editadas financeiramente.
- **RN07 - Soft Delete:** A exclusão de excursões utiliza "deleção lógica" (`excluido: true`), preservando dados históricos para auditoria.
- **RN08 - Assentos Efetivos:** No encerramento da viagem, o sistema calcula a ocupação real baseada apenas em passageiros que realizaram o check-in.

### 💰 Financeiro e CRM
- **RN09 - Quitação Automática:** O status de "Pago" (`isPaid`) é disparado automaticamente quando o `depositValue` atinge ou supera o `basePrice` da excursão.
- **RN10 - Sincronização Atômica:** Contadores globais (faturamento e ocupação) são recalculados via transação a cada alteração em poltronas ou pagamentos.
- **RN11 - Fidelização Automática:** Ao concluir uma viagem, o CRM Global atualiza o `totalViagens` e o `tripHistory` do passageiro.
- **RN12 - Reset de Vínculo:** Após a conclusão, o registro do passageiro no CRM é limpo de dados temporários (poltrona, valor pago na viagem) para permitir novas reservas, mantendo dados mestres e histórico.

---

## 💾 Estrutura de Dados (Firestore)

- `usuario/`: Perfil, permissões e lista de empresas vinculadas.
- `convites/`: Registro de convites pendentes de colaboração.
- `excursoes/`: Dados mestres das viagens (filtrados por `empresa`).
- `excursoes/{id}/vagas/`: Sub-coleção com o vínculo passageiro-poltrona e financeiro daquela viagem.
- `excursoes/{id}/despesas/`: Sub-coleção de gastos operacionais.
- `passageiros/`: CRM Global com dados mestres e histórico de fidelidade.
