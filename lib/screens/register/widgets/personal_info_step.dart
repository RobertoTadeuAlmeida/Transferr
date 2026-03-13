import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

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

  bool _isCnpj = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Icon(Icons.business_center_outlined, size: 64, color: Colors.blue)),
            const SizedBox(height: 24),
            
            const Text("Informações de Acesso", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: widget.selectedProfile,
              decoration: const InputDecoration(
                labelText: 'Eu sou...',
                prefixIcon: Icon(Icons.account_circle_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ADMIN', child: Text("Dono de Agência (Admin)")),
                DropdownMenuItem(value: 'AGENTE', child: Text("Agente / Guia Independente")),
              ],
              onChanged: widget.onProfileChanged,
            ),
            
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.controllers['company'],
              decoration: const InputDecoration(
                labelText: 'Nome da Empresa / Nome Fantasia',
                prefixIcon: Icon(Icons.storefront_outlined),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v!.isEmpty ? 'Informe o nome da empresa' : null,
            ),

            const SizedBox(height: 24),
            const Text("Documentação", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            
            // Seletor de CPF / CNPJ
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
                });
              },
            ),
            
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.controllers['document'],
              inputFormatters: [_isCnpj ? _maskCnpj : _maskCpf],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _isCnpj ? 'CNPJ da Empresa' : 'CPF do Responsável',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: const OutlineInputBorder(),
                hintText: _isCnpj ? "00.000.000/0000-00" : "000.000.000-00",
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Obrigatório';
                if (_isCnpj && v.length < 18) return 'CNPJ incompleto';
                if (!_isCnpj && v.length < 14) return 'CPF incompleto';
                return null;
              },
            ),

            const SizedBox(height: 24),
            const Text("Contato Pessoal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
