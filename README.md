# 🚌 Transferr - Gestão Inteligente de Excursões

O **Transferr** é um ecossistema **SaaS (Software as a Service)** robusto, projetado para organizadores de excursões, agências de viagens e operadores logísticos. O aplicativo oferece um controle 360º da operação: desde a reserva visual de poltronas até a gestão financeira multi-tenant de equipes.

---

### 📖 Navegação Rápida
[📁 Documentação Técnica (DOCS.md)](DOCS.md) | [🚀 Guia de Instalação](#-como-executar) | [🛠️ Tecnologias](#️-tecnologias)

---

## ✨ Funcionalidades em Destaque

### 🏢 Ecossistema Multi-tenant & Autônomo
- **Cadastro Independente:** Guias, agentes e motoristas criam perfis de forma autônoma, prontos para serem recrutados por agências via convite.
- **Contexto de Atuação Dinâmico:** Alternância instantânea entre múltiplas empresas com isolamento total de dados.
- **Governança de Dados:** Filtros nativos garantem que viagens, passageiros e lucros sejam visíveis apenas para os membros da empresa ativa.

### 💰 Inteligência Financeira
- **Saúde Financeira Real:** Monitoramento em tempo real diferenciando faturamento previsto de valores efetivados em caixa.
- **Congelamento de Preço (`saleValue`):** Fixação do valor no ato da reserva, protegendo o histórico financeiro contra alterações de lotes futuros.
- **Gestão de ROI:** Planilha de despesas operacionais (combustível, pedágios, pessoal) com cálculo automático de lucratividade por viagem.

### 🚌 Logística e Operação
- **Mapa de Assentos Interativo:** Visualização física e alocação dinâmica da ocupação do veículo.
- **Check-in Multi-status:** Controle de fluxo (Aguardando, Embarcou, Parada, Desembarcou) sincronizado via Firebase.
- **CRM Global de Passageiros:** Base centralizada para reutilização inteligente de dados de clientes em múltiplas operações.

---

## 🏗️ Arquitetura e Estrutura

O projeto segue princípios de **Clean Architecture** e **DDD (Domain-Driven Design)** para garantir um código escalável e de fácil manutenção:

- **`models`**: Objetos de domínio e entidades puras.
- **`validators`**: Camada desacoplada responsável exclusivamente por regras de validação e integridade.
- **`services`**: Orquestradores de fluxo e mediadores de regras de negócio.
- **`repositories`**: Interface de comunicação direta com o Firebase/APIs.
- **`providers`**: Gerenciamento de estado e integração dos dados com a UI.
- **`screens`**: Camada de apresentação (UI) construída em Flutter.

**Fluxo de Dados:** `UI` ➔ `Provider` ➔ `Service` ➔ `Validator` ➔ `Repository` ➔ `Firebase`.

---

## 🧠 Decisões Técnicas Recentes

Para manter o nível de excelência técnica e performance mobile, o projeto passou por uma evolução estrutural significativa:

### 1. Refatoração do `AuthService`
O serviço de autenticação foi transformado de um componente denso para um **Orquestrador Lean**. 
- **Benefício:** Redução da complexidade cognitiva e melhor legibilidade para novos desenvolvedores.
- **Performance:** Fluxos de login e registro otimizados para menor latência em dispositivos mobile.

### 2. Implementação da Camada `Validators`
Extraímos toda a lógica de validação dos Services para uma camada dedicada.
- **Testabilidade:** Permite testes unitários rigorosos das regras de negócio sem a necessidade de mocks complexos de banco de dados.
- **Reuso:** As mesmas regras de validação podem ser invocadas em diferentes partes do app, garantindo a integridade dos dados (Single Source of Truth).
- **Manutenção:** Facilita a alteração de regras (ex: formato de documento ou telefone) em um único ponto centralizado.

---

## 🛠️ Tecnologias

- **Framework:** Flutter SDK (Android/iOS)
- **Backend:** Firebase (Cloud Firestore & Firebase Auth)
- **Estado:** Provider & StreamSubscriptions otimizadas.
- **Testes:** Flutter Test & Mocktail para testes unitários robustos.

---

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK instalado.
- Projeto configurado no Firebase (Firestore habilitado).

### Instalação
```bash
# Clone o repositório
git clone https://github.com/rtadeu/transferr.git

# Instale as dependências
flutter pub get

# Execute o projeto
flutter run
```

---

## 📄 Licença
Projeto desenvolvido para fins comerciais e operacionais sob licença [MIT](LICENSE).
