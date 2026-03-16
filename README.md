# 🚌 Transferr

O **Transferr** é um ecossistema completo para organizadores de excursões e viagens. O aplicativo permite a gestão de passageiros, alocação de poltronas, controle financeiro e check-in em tempo real.

---

### 📖 Navegação Rápida
[📁 Documentação Técnica (DOCS.md)](DOCS.md) | [🚀 Guia de Instalação](#-como-executar) | [🛠️ Tecnologias](#️-tecnologias)

---

## ✨ Funcionalidades

### 📋 Gestão de Excursões
- **Dashboard:** Visão consolidada de faturamento e ocupação.
- **Mapa de Assentos:** Interface interativa para reserva de poltronas.
- **Financeiro:** Controle de despesas e lucros por viagem.

### 👥 CRM de Passageiros
- **Base Global:** Cadastro único de passageiros para reutilização em múltiplas viagens.
- **Controle de Quitação:** Sistema de baixa total ou parcial de passagens.

### 🚀 Operação em Tempo Real
- **Check-in Dinâmico:** Controle de embarque sincronizado instantaneamente via Firebase Cloud.

---

## 🛠️ Tecnologias

O projeto utiliza o estado da arte do desenvolvimento mobile:
- **Framework:** Flutter (Android/iOS)
- **Backend:** Firebase (Firestore & Auth)
- **Estado:** Provider
- **Design:** Dark Mode personalizado

---

## 🏗️ Arquitetura
O Transferr adota uma variação da **Clean Architecture**, dividida em:
`Models` ➔ `Repositories` ➔ `Services` ➔ `Providers` ➔ `UI`.

Para detalhes sobre a implementação técnica, consulte o [Arquivo de Documentação](DOCS.md).

---

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK & Firebase CLI.

### Instalação Rápida
```bash
git clone https://github.com/seu-usuario/transferr.git
flutter pub get
flutter run
```

---

## 📄 Licença
Projeto sob licença [MIT](LICENSE).
