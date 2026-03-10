# 🚌 Transferr - Gestão de Excursões e Viagens

O **Transferr** é um ecossistema completo desenvolvido em Flutter para organizadores de excursões. O aplicativo permite a gestão ponta a ponta, desde o cadastro de passageiros e reserva de poltronas até o controle financeiro e check-in em tempo real durante a operação.

---

## ✨ Funcionalidades Principais

### 📋 Gestão de Excursões
- **Dashboard Operacional:** Visão geral do faturamento, ocupação e status da viagem.
- **Mapa de Assentos:** Interface visual interativa para reserva e visualização de poltronas no ônibus.
- **Controle de Despesas:** Registro e categorização de gastos (combustível, motorista, taxas) por viagem.

### 👥 Gestão de Passageiros (CRM)
- **Base Global:** Cadastro único de passageiros para reutilização em múltiplas viagens.
- **Financeiro Individual:** Sistema de baixa total ou parcial de pagamentos com indicadores de progresso.
- **Histórico de Viagens:** Acompanhamento de todas as excursões que o passageiro participou.

### 🚀 Operação em Tempo Real
- **Check-in Dinâmico:** Controle de status de embarque (Aguardando, Embarcou, Parada, Desembarcou).
- **Sincronização Cloud:** Dados atualizados instantaneamente via Firebase para todos os agentes.

---

## 🛠️ Tecnologias Utilizadas

- **Framework:** [Flutter](https://flutter.dev/) (Android/iOS)
- **Backend:** [Firebase](https://firebase.google.com/) (Firestore, Auth)
- **Gerenciamento de Estado:** [Provider](https://pub.dev/packages/provider)
- **Design:** Dark Mode personalizado focado em usabilidade noturna/estrada.

---

## 🏗️ Arquitetura do Projeto

O projeto segue uma arquitetura em camadas para garantir escalabilidade e fácil manutenção:
1. **Models:** Representação das entidades (Excursion, Passenger, Expense, Enums).
2. **Repositories:** Comunicação isolada com o Firebase Firestore.
3. **Services:** Lógica de negócio, cálculos financeiros e sincronização de contadores.
4. **Providers:** Gerenciamento de estado reativo e ponte entre lógica e UI.
5. **Screens/Widgets:** Interface do usuário modular e componentizada.

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
- Flutter SDK instalado.
- Projeto Firebase configurado.

### Instalação
1. Clone o repositório:
   ```bash
   git clone https://github.com/seu-usuario/transferr.git
   ```
2. Instale as dependências:
   ```bash
   flutter pub get
   ```
3. Execute o projeto:
   ```bash
   flutter run
   ```

---

## 📄 Licença
Este projeto está sob a licença [MIT](LICENSE).
