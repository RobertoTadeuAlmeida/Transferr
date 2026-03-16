import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AddressStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Map<String, TextEditingController> controllers;

  const AddressStep({super.key, required this.formKey, required this.controllers});

  @override
  State<AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<AddressStep> {
  final _maskCEP = MaskTextInputFormatter(mask: '#####-###', filter: {"#": RegExp(r'[0-9]')});
  bool _isSearchingCEP = false;

  /// Busca automática de endereço via API ViaCEP
  Future<void> _searchCEP(String cep) async {
    final cleanCEP = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCEP.length != 8) return;

    setState(() => _isSearchingCEP = true);

    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cleanCEP/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['erro'] == null) {
          setState(() {
            widget.controllers['address']?.text = data['logradouro'] ?? '';
            widget.controllers['neighborhood']?.text = data['bairro'] ?? '';
            widget.controllers['city']?.text = data['localidade'] ?? '';
            widget.controllers['state']?.text = data['uf'] ?? '';
          });
          // Foca no campo número após preencher o endereço
          FocusScope.of(context).nextFocus();
        }
      }
    } catch (e) {
      debugPrint("Erro ao buscar CEP: $e");
    } finally {
      setState(() => _isSearchingCEP = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: widget.formKey,
        child: Column(
          children: [
            const Icon(Icons.map_outlined, size: 64, color: Colors.orange),
            const SizedBox(height: 8),
            const Text(
              "Onde sua empresa está localizada?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: widget.controllers['zipCode'],
              inputFormatters: [_maskCEP],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'CEP',
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: _isSearchingCEP 
                  ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))) 
                  : null,
                border: const OutlineInputBorder(),
                helperText: "Preenchimento automático ao digitar o CEP",
              ),
              onChanged: (val) {
                if (val.length == 9) _searchCEP(val);
              },
              validator: (v) => v!.length < 9 ? 'CEP incompleto' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: widget.controllers['city'],
                    decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: widget.controllers['state'],
                    maxLength: 2,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'UF', border: OutlineInputBorder(), counterText: ""),
                    validator: (v) => v!.length < 2 ? 'UF?' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.controllers['address'],
              decoration: const InputDecoration(labelText: 'Logradouro (Rua/Av)', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: widget.controllers['neighborhood'],
                    decoration: const InputDecoration(labelText: 'Bairro', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: widget.controllers['number'],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nº', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Nº?' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
