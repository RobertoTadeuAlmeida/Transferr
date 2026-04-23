import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class PersonalInfoStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Map<String, TextEditingController> controllers;
  final String selectedProfile;
  final ValueChanged<String?> onProfileChanged;

  const PersonalInfoStep({
    super.key,
    required this.formKey,
    required this.controllers,
    required this.selectedProfile,
    required this.onProfileChanged,
  });

  @override
  State<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends State<PersonalInfoStep> {
  final _maskCpf = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
  final _maskCnpj = MaskTextInputFormatter(mask: '##.###.###/####-##', filter: {"#": RegExp(r'[0-9]')});
  final _maskPhone = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  final FocusNode _docFocusNode = FocusNode();
  String? _documentError;
  bool _isValidating = false;

  bool _isCnpj = false;

  @override
  void initState() {
    super.initState();
    _docFocusNode.addListener(_onDocFocusChange);
  }

  @override
  void dispose() {
    _docFocusNode.removeListener(_onDocFocusChange);
    _docFocusNode.dispose();
    super.dispose();
  }

  /// Valida a unicidade do documento quando o usuário sai do campo.
  void _onDocFocusChange() async {
    if (!_docFocusNode.hasFocus) {
      final doc = widget.controllers['document']?.text ?? '';
      if (doc.length >= 14) { // Tamanho mínimo de um CPF com máscara
        setState(() => _isValidating = true);
        final error = await context.read<AuthProvider>().validateDocument(doc);
        setState(() {
          _documentError = error;
          _isValidating = false;
        });
        
        // Se houver erro, força a revalidação do formulário para exibir a mensagem
        if (error != null) {
          widget.formKey.currentState?.validate();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.selectedProfile == 'ADMIN';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                isAdmin ? Icons.business_center_outlined : Icons.person_search_outlined, 
                size: 64, 
                color: Colors.blue
              )
            ),
            const SizedBox(height: 24),
            
            const Text("Tipo de Cadastro", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: widget.selectedProfile,
              decoration: const InputDecoration(
                labelText: 'Eu sou...',
                prefixIcon: Icon(Icons.account_circle_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ADMIN', child: Text("Dono de Agência (Organizador)")),
                DropdownMenuItem(value: 'AGENTE', child: Text("Agente / Guia / Colaborador")),
              ],
              onChanged: (v) {
                widget.onProfileChanged(v);
                if (v == 'AGENTE') {
                  widget.controllers['company']?.clear();
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: widget.controllers['company'],
              decoration: InputDecoration(
                labelText: isAdmin ? 'Nome da sua Empresa' : 'Nome Profissional (Opcional)',
                hintText: isAdmin ? 'Ex: Agência de Viagens Sol' : 'Ex: Guia João Santos',
                prefixIcon: const Icon(Icons.storefront_outlined),
                border: const OutlineInputBorder(),
                helperText: isAdmin ? 'Sua empresa será criada com este nome.' : 'Use um nome que facilite ser achado por agências.',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (isAdmin && (v == null || v.isEmpty)) {
                  return 'Como Organizador, você deve informar o nome da sua empresa.';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),
            const Text("Documentação Identificadora", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('CPF'), icon: Icon(Icons.person_outline)),
                ButtonSegment(value: true, label: Text('CNPJ'), icon: Icon(Icons.business_outlined)),
              ],
              selected: {_isCnpj},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isCnpj = newSelection.first;
                  widget.controllers['document']?.clear();
                  _documentError = null; // Limpa erro ao trocar tipo
                });
              },
            ),
            
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.controllers['document'],
              focusNode: _docFocusNode,
              inputFormatters: [_isCnpj ? _maskCnpj : _maskCpf],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _isCnpj ? 'CNPJ' : 'CPF',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: const OutlineInputBorder(),
                hintText: _isCnpj ? "00.000.000/0000-00" : "000.000.000-00",
                suffixIcon: _isValidating 
                  ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))) 
                  : (_documentError != null ? const Icon(Icons.error_outline, color: Colors.red) : null),
              ),
              onChanged: (v) {
                if (_documentError != null) setState(() => _documentError = null);
              },
              validator: (v) {
                if (v == null || v.isEmpty) return 'Obrigatório para segurança dos dados.';
                if (_isCnpj && v.length < 18) return 'CNPJ incompleto';
                if (!_isCnpj && v.length < 14) return 'CPF incompleto';
                return _documentError; // Retorna o erro vindo do Firebase
              },
            ),

            const SizedBox(height: 32),
            const Text("Informações de Contato", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: widget.controllers['name'],
              decoration: const InputDecoration(
                labelText: 'Seu Nome Completo',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v!.isEmpty ? 'Informe seu nome' : null,
            ),
            
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.controllers['phone'],
              inputFormatters: [_maskPhone],
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp / Celular',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
                hintText: "(00) 00000-0000",
              ),
              validator: (v) => v!.length < 14 ? 'Telefone incompleto' : null,
            ),
          ],
        ),
      ),
    );
  }
}
