import 'package:flutter/material.dart';

class CredentialsStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Map<String, TextEditingController> controllers;const CredentialsStep({super.key, required this.formKey, required this.controllers});

  @override
  State<CredentialsStep> createState() => _CredentialsStepState();
}

class _CredentialsStepState extends State<CredentialsStep> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: widget.formKey,
        child: Column(
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.green),
            const SizedBox(height: 24),
            TextFormField(
              controller: widget.controllers['email'],
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
              validator: (v) => !v!.contains('@') ? 'E-mail inválido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.controllers['password'],
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
            ),
          ],
        ),
      ),
    );
  }
}