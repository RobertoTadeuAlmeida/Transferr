import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AddressStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final Map<String, TextEditingController> controllers;

  AddressStep({super.key, required this.formKey, required this.controllers});

  final maskCEP = MaskTextInputFormatter(mask: '#####-###');

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            const Icon(Icons.location_on, size: 64, color: Colors.orange),
            const SizedBox(height: 24),
            TextFormField(
              controller: controllers['zipCode'],
              inputFormatters: [maskCEP],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'CEP', border: OutlineInputBorder()),
              validator: (v) => v!.length < 9 ? 'CEP inválido' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: controllers['city'],
                    decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controllers['state'],
                    maxLength: 2,
                    decoration: const InputDecoration(labelText: 'UF', border: OutlineInputBorder(), counterText: ""),
                    validator: (v) => v!.length < 2 ? 'Erro' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controllers['address'],
              decoration: const InputDecoration(labelText: 'Endereço (Rua/Av)', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controllers['number'],
              decoration: const InputDecoration(labelText: 'Número', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
          ],
        ),
      ),
    );
  }
}
