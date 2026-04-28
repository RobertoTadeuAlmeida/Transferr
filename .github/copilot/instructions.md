# Refatoração: Padronização da variável `company`

## Contexto identificado

O projeto apresenta uso inconsistente da variável `company` no model `User` e em múltiplas camadas do sistema.

### Problemas encontrados

1. **Conflito de responsabilidade**

    * `company` representa a empresa ativa do usuário
    * `companies` representa múltiplas empresas
    * `roles` já resolve associação usuário-empresa

2. **Uso inconsistente no código**

    * UI depende de `user.company` como empresa ativa
    * Services usam `companies` + `roles`
    * Validators misturam `company` com `companies`
    * Repositories usam `companyId` como fonte de verdade

3. **Acoplamento crítico**

    * Telas dependem diretamente de `user.company`
    * Providers usam `companyId` derivado de `user.company`
    * Lógica de negócio mistura empresa ativa com estrutura de dados

---

## Definição de padrão (DECISÃO)

A variável `company` será tratada como:

> ✅ **empresa ativa do usuário (currentCompanyId)**

E NÃO mais como fonte de verdade de relacionamento.

---

## Nova regra de arquitetura

### Fonte de verdade:

* `companies` → lista de empresas do usuário
* `roles` → papel do usuário por empresa

### Estado derivado:

* `company` → empresa atualmente selecionada (ativa no app)

---

## Regras obrigatórias de uso

### ✔ `company`

* Usar APENAS como empresa ativa
* Nunca usar para validar pertencimento
* Nunca usar como fonte de dados persistente principal

---

### ✔ `companies`

* Fonte oficial de vínculo com empresas
* Sempre usada para validação

Exemplo correto:

```dart
user.companies.contains(companyId)
```

---

### ✔ `roles`

* Fonte oficial de permissões
* Sempre indexado por companyId

Exemplo:

```dart
user.roles[companyId]
```

---

## Refatorações obrigatórias

### 1. Substituir validações incorretas

❌ ERRADO:

```dart
if (user.company == companyId)
```

✔ CORRETO:

```dart
if (user.companies.contains(companyId))
```

---

### 2. Corrigir uso em validators

Arquivo:

* `lib/validators/user_validator.dart`

Regra:

* Não confiar apenas em `user.company`
* Validar com `companies` + `roles`

---

### 3. Ajustar services críticos

Arquivo:

* `lib/services/user_service.dart`

Problema:

```dart
if (targetUser.company == companyId)
```

Correção:

* Usar `companies.contains(companyId)`
* `company` apenas para definir empresa ativa

---

### 4. Ajustar UI (sem quebrar comportamento)

Arquivos afetados:

* `home_page.dart`
* `excursion_pages`
* `passenger_pages`
* `finance_page.dart`

Regra:

* Pode continuar usando `user.company` como empresa ativa
* NÃO usar para validação de acesso

---

### 5. Ajustar modo demo

Arquivos:

* `demo_user_service.dart`

Regra:

* `company` deve ser coerente com `companies`

Exemplo correto:

```dart
company: 'c_demo',
companies: ['c_demo'],
roles: {'c_demo': 'OWNER'}
```

---

## Regras de segurança

* NÃO remover `company` neste momento
* NÃO quebrar compatibilidade com código existente
* NÃO alterar estrutura do Firebase ainda

---

## Objetivo desta etapa

* Eliminar inconsistências de uso
* Padronizar sem quebrar o sistema
* Preparar base para refatoração futura

---

## Resultado esperado

* Uso consistente de `company`
* Separação clara entre:

    * estado (empresa ativa)
    * dados (empresas e permissões)
* Redução de bugs relacionados a multi-tenant
