import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PersonalInfoStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final Map<String, TextEditingController> controllers;
  final String selectedProfile;
  final ValueChanged<String?> onProfileChanged;

  PersonalInfoStep({
    super.key,
    required this.formKey,
    required this.controllers,
    required this.selectedProfile,
    required this.onProfileChanged,
  });

  final maskCpf = MaskTextInputFormatter(mask: '###.###.###-##');
  final maskPhone = MaskTextInputFormatter(mask: '(##) #####-####');

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            const Icon(Icons.business, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: selectedProfile,
              decoration: const InputDecoration(labelText: 'Seu Perfil', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'ADMIN', child: Text("Administrador")),
                DropdownMenuItem(value: 'AGENTE', child: Text("Agente / Guia")),
              ],
              onChanged: onProfileChanged,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controllers['company'],
              decoration: const InputDecoration(labelText: 'Nome da Empresa', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controllers['document'],
              inputFormatters: [maskCpf],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'CPF do Responsável', border: OutlineInputBorder()),
              validator: (v) => v!.length < 14 ? 'CPF inválido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controllers['name'],
              decoration: const InputDecoration(labelText: 'Seu Nome Completo', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controllers['phone'],
              inputFormatters: [maskPhone],
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'WhatsApp', border: OutlineInputBorder()),
              validator: (v) => v!.length < 14 ? 'Telefone inválido' : null,
            ),
          ],
        ),
      ),
    );
  }
}