# 📄 Documentação Técnica - Transferr

Este documento detalha a arquitetura, os requisitos e as regras de negócio que sustentam o ecossistema **Transferr**.

---

## 🏗️ Arquitetura do Sistema

O projeto adota uma variação da **Clean Architecture**, dividida em camadas para facilitar a manutenção e escalabilidade:

1.  **Models (Entidades):** Classes puras que representam os dados (Excursion, Passenger, User, Enums).
2.  **Repositories:** Camada de acesso a dados isolada (Firestore/Auth).
3.  **Services (Lógica de Negócio):** Onde residem cálculos financeiros e transações atômicas de banco de dados.
4.  **Providers (Estado):** Gerenciamento reativo via `Provider` para desacoplar lógica da UI.
5.  **UI (Screens & Widgets):** Componentes visuais modernos com suporte a Dark Mode.

---

## 🎯 Requisitos Funcionais (RF)

### 👥 Módulo de Usuários e Equipe (SaaS Aberto)
- **RF01 - Registro de Admin:** Um usuário pode se cadastrar como administrador, criando automaticamente uma nova organização/empresa.
- **RF02 - Registro de Agente Independente:** Usuários (Guias/Motoristas) podem se cadastrar sem vínculo inicial, permanecendo em uma "base global" do app.
- **RF03 - Gestão de Atuação (Switch Company):** O usuário pode visualizar todas as empresas que faz parte e alternar sua "atuação ativa" para filtrar dados do app.
- **RF04 - Sistema de Convite por E-mail:** Admins convidam novos membros através do e-mail. O vínculo só é criado após o aceite do convidado.
- **RF05 - Gestão de Equipe:** Visualização e ativação/desativação de operadores vinculados à empresa ativa.

### 🚌 Módulo de Excursões e Operações
- **RF06 - Saúde Financeira em Tempo Real:** Dashboard que diferencia Faturamento Previsto vs. Total Recebido (Caixa Real).
- **RF07 - Mapa de Assentos Interativo:** Alocação visual e dinâmica de poltronas.
- **RF08 - Congelamento de Preço de Venda:** Armazenamento do valor da passagem no ato da reserva (`saleValue`).
- **RF09 - CRM Global:** Base centralizada de passageiros reutilizável.
- **RF10 - Gestão de Despesas:** Registro de custos operacionais com cálculo automático de ROI.

---

## ⚖️ Regras de Negócio (RN)

### 🛡️ Segurança e Hierarquia
- **RN01 - Isolamento Multi-tenant:** Toda consulta a dados operacionais **deve** incluir obrigatoriamente o filtro por `empresa`.
- **RN02 - Autonomia Administrativa:** Somente usuários com perfil `ADMIN` na empresa ativa podem convidar novos membros ou gerenciar o financeiro.
- **RN03 - Aceite Obrigatório:** Um usuário só compartilha seus dados com uma empresa após aceitar formalmente o convite via app.
- **RN04 - Unicidade de Assento:** Proibição de alocação de dois passageiros na mesma poltrona na mesma viagem.

### 💰 Financeiro e CRM
- **RN05 - Integridade de Venda (`saleValue`):** Uma vez que um passageiro é vinculado a uma poltrona, o valor da venda não muda se o preço base da excursão for alterado posteriormente.
- **RN06 - Status de Quitação:** O status de "Pago" é disparado quando o `depositValue` atinge o `saleValue` daquele registro específico de vaga.
- **RN07 - Atualização de Fidelidade:** Ao concluir uma viagem, o CRM Global atualiza o contador de viagens do passageiro.

---

## 💾 Estrutura de Dados (Firestore)

- `usuario/`: Documento mestre do usuário (contém campo `empresa` ativa e lista `empresas` vinculadas).
- `excursoes/`: Raiz das viagens (filtradas por `empresa`).
- `excursoes/{id}/vagas/`: Sub-coleção com vínculos passageiro-poltrona (armazena o `saleValue`).
- `excursoes/{id}/despesas/`: Registro de gastos da viagem.
- `passageiros/`: CRM Global compartilhado por empresa.
- `convites/`: Armazena convites pendentes indexados pelo e-mail/ID do destinatário.

---

## ⚙️ Requisitos Não Funcionais (RNF)

- **RNF01 - Estabilização de Conexões:** Uso de caches de Stream no Provider para evitar re-assinaturas desnecessárias ao Firebase.
- **RNF02 - Usabilidade Noturna:** Interface 100% Dark Mode.
- **RNF03 - Performance de Lista:** Uso de `cacheExtent` e extração de sub-widgets para garantir 60 FPS em listas longas.
- **RNF04 - Modernização Flutter:** Substituição global de `withOpacity` por `withValues`.
