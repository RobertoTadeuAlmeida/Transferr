import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/demo_mode_provider.dart';

class DemoToggleButton extends StatelessWidget {
  const DemoToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DemoModeProvider>(context);
    return TextButton.icon(
      onPressed: () async {
        await provider.toggle();
        final snack = provider.isDemo ? 'Modo DEMO ativado' : 'Modo DEMO desativado';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snack)));
      },
      icon: Icon(Icons.developer_mode, color: provider.isDemo ? Colors.orange : Colors.grey),
      label: Text(provider.isDemo ? 'Demo: ON' : 'Demo: OFF'),
    );
  }
}
