# 🚌 Transferr - Gestão Inteligente de Excursões

O **Transferr** é um ecossistema **SaaS (Software as a Service)** robusto, projetado para organizadores de excursões, agências de viagens e operadores logísticos. O aplicativo oferece um controle 360º da operação: desde a reserva visual de poltronas até a gestão financeira multi-tenant de equipes.

---

### 📖 Navegação Rápida
[📁 Documentação Técnica (DOCS.md)](DOCS.md) | [🚀 Guia de Instalação](#-como-executar) | [🛠️ Tecnologias](#️-tecnologias)

---

## ✨ Funcionalidades em Destaque

### 🏢 Ecossistema Aberto & Multi-tenant
- **Cadastro Independente:** Guiais, agentes e motoristas podem criar seus perfis de forma autônoma, ficando disponíveis para serem recrutados por agências através de convites por e-mail.
- **Contexto de Atuação:** Usuários podem estar vinculados a múltiplas empresas e alternar o contexto de dados instantaneamente.
- **Isolamento de Dados:** Filtros nativos garantem que viagens, passageiros e lucros sejam visíveis apenas para os membros da empresa ativa.

### 💰 Financeiro de Alta Precisão
- **Saúde Financeira Real:** Monitoramento de caixa em tempo real, diferenciando faturamento previsto de valores efetivamente recebidos.
- **Congelamento de Preço (`saleValue`):** O valor da passagem é fixado no momento da reserva, permitindo lotes promocionais sem corromper o histórico financeiro.
- **Planilha de Despesas:** Gestão de custos operacionais (combustível, guias, pedágios) com cálculo automático de ROI.

### 🚌 Operação e Logística
- **Mapa de Assentos Interativo:** Visualização física da ocupação do veículo e alocação dinâmica.
- **Check-in Multi-status:** Controle de fluxo (Aguardando, Embarcou, Parada, Desembarcou) sincronizado via Firebase.
- **CRM Global de Passageiros:** Base centralizada para reutilização de dados de clientes em múltiplas viagens.

---

## 🛠️ Tecnologias e Padrões

O projeto utiliza tecnologias de ponta para garantir performance e segurança:
- **Framework:** Flutter SDK (Android/iOS)
- **Backend:** Firebase (Cloud Firestore & Firebase Auth)
- **Estado:** Provider & StreamSubscriptions otimizadas.
- **Arquitetura:** Clean Architecture (Domain-Driven Design).

---

## 🏗️ Estrutura do Projeto
O Transferr organiza as responsabilidades de forma desacoplada:
`Models` ➔ `Repositories` ➔ `Services` ➔ `Providers` ➔ `UI`.

Consulte o [DOCS.md](DOCS.md) para detalhes sobre as Regras de Negócio e Requisitos.

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
