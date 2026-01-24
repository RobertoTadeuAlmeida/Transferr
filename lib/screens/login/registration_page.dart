import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../providers/registration_provider.dart';

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegistrationProvider(),
      child: const _RegistrationContent(),
    );
  }
}

class _RegistrationContent extends StatefulWidget {
  const _RegistrationContent();

  @override
  State<_RegistrationContent> createState() => _RegistrationContentState();
}

class _RegistrationContentState extends State<_RegistrationContent> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  final maskCpf = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final maskPhone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final maskCEP = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: provider.pageIndex > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => provider.previousPage(),
              )
            : null,
      ),
      body: Column(
        children: [
          // Barra de progresso sutil
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (provider.pageIndex + 1) / 3,
                minHeight: 6,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ),
          ),

          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildCurrentStep(provider),
                  ),
                ),
              ),
            ),
          ),

          _buildFooter(context, provider),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(RegistrationProvider provider) {
    switch (provider.pageIndex) {
      case 0:
        return _PersonalInfoStep(
          key: const ValueKey('step1'),
          formKey: _formKey1,
          maskCpf: maskCpf,
          maskPhone: maskPhone,
        );
      case 1:
        return _AddressStep(
          key: const ValueKey('step2'),
          formKey: _formKey2,
          maskCEP: maskCEP,
        );
      case 2:
        return _CredentialsStep(
          key: const ValueKey('step3'),
          formKey: _formKey3,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFooter(BuildContext context, RegistrationProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
              ),
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      // VALIDAÇÃO SEGURA POR PASSO
                      bool isValid = false;
                      if (provider.pageIndex == 0) {
                        isValid = _formKey1.currentState?.validate() ?? false;
                      } else if (provider.pageIndex == 1) {
                        isValid = _formKey2.currentState?.validate() ?? false;
                      } else if (provider.pageIndex == 2) {
                        isValid = _formKey3.currentState?.validate() ?? false;
                      }

                      if (!isValid) return;

                      // SE NÃO FOR O ÚLTIMO PASSO, APENAS AVANÇA
                      if (provider.pageIndex < 2) {
                        provider.nextPage();
                        return;
                      }

                      // SE FOR O ÚLTIMO PASSO, ENVIA O CADASTRO
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      final success = await provider.submitRegistration();

                      if (!mounted) return;

                      if (success) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Bem-vindo ao Transferr!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        navigator.pushNamedAndRemoveUntil(
                          '/',
                          (route) => false,
                        );
                      } else if (provider.errorMessage != null) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(provider.errorMessage!),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      provider.pageIndex == 2 ? 'CRIAR CONTA' : 'PRÓXIMO PASSO',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          if (provider.pageIndex == 0) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Já possui uma conta? Faça login'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PersonalInfoStep extends StatelessWidget {  final GlobalKey<FormState> formKey;
final MaskTextInputFormatter maskCpf;
final MaskTextInputFormatter maskPhone;

const _PersonalInfoStep({
  required this.formKey,
  required this.maskCpf,
  required this.maskPhone,
  required ValueKey<String> key,
}) : super(key: key);

@override
Widget build(BuildContext context) {
  final provider = context.watch<RegistrationProvider>(); // Use watch para atualizar a UI ao trocar o perfil

  return Form(
    key: formKey,
    child: Column(
      children: [
        const Icon(Icons.business_center_outlined, size: 60, color: Colors.blue),
        const SizedBox(height: 16),
        const Text(
          'Dados da Empresa',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        // --- CAMPO DE PERFIL (ADICIONADO) ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: provider.selectedProfile,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'ADMIN',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.blue),
                      SizedBox(width: 10),
                      Text("Perfil: Administrador / Dono"),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'AGENTE',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.green),
                      SizedBox(width: 10),
                      Text("Perfil: Agente / Guia"),
                    ],
                  ),
                ),
              ],
              onChanged: (value) => provider.setSelectedProfile(value),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "O Administrador pode criar excursões e gerenciar finanças. O Agente foca na lista de passageiros.",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 24),

        TextFormField(
          controller: provider.companyController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nome da Empresa',
            prefixIcon: Icon(Icons.business),
            border: OutlineInputBorder(),
          ),
          validator: (val) => val!.isEmpty ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: provider.documentController,
          inputFormatters: [maskCpf],
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'CPF do Responsável',
            prefixIcon: Icon(Icons.badge_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (val) => val!.length < 14 ? 'CPF incompleto' : null,
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        TextFormField(
          controller: provider.nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Seu Nome Completo',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          validator: (val) => val!.trim().split(' ').length < 2
              ? 'Informe nome e sobrenome'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: provider.phoneController,
          inputFormatters: [maskPhone],
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Telefone / WhatsApp',
            prefixIcon: Icon(Icons.phone_iphone),
            border: OutlineInputBorder(),
          ),
          validator: (val) => val!.length < 15 ? 'Telefone inválido' : null,
        ),
      ],
    ),
  );
}
}
class _AddressStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final MaskTextInputFormatter maskCEP;

  const _AddressStep({
    required this.formKey,
    required this.maskCEP,
    required ValueKey<String> key,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RegistrationProvider>();
    return Form(
      key: formKey,
      child: Column(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 60,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          const Text(
            'Onde você está?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: provider.zipCodeController,
                  inputFormatters: [maskCEP],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CEP',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  validator: (val) => val!.length < 9 ? 'Incompleto' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: provider.stateController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'UF',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 2,
                  validator: (val) => val!.length < 2 ? 'Erro' : null,
                  buildCounter:
                      (
                        a, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: provider.cityController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Cidade',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city),
            ),
            validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: provider.addressController,
                  decoration: const InputDecoration(
                    labelText: 'Rua / Av',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: provider.numberController,
                  decoration: const InputDecoration(
                    labelText: 'Nº',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? 'Erro' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CredentialsStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;

  const _CredentialsStep({required this.formKey, required ValueKey<String> key});

  @override
  State<_CredentialsStep> createState() => _CredentialsStepState();
}

class _CredentialsStepState extends State<_CredentialsStep> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RegistrationProvider>();
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 60,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          const Text(
            'Acesso ao Sistema',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: provider.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail Profissional',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (val) =>
                (val == null || !val.contains('@')) ? 'E-mail inválido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: provider.passwordController,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Senha de Acesso',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (val) =>
                (val == null || val.length < 6) ? 'Mínimo 6 caracteres' : null,
          ),
        ],
      ),
    );
  }
}
