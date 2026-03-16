import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  User? _foundUser;
  bool _isSearching = false;

  Future<void> _searchUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSearching = true;
      _foundUser = null;
    });

    final provider = context.read<UserProvider>();
    
    try {
      final user = await provider.findUserByEmail(_emailController.text.trim());
      
      setState(() {
        _foundUser = user;
        _isSearching = false;
      });

      if (user == null && mounted) {
        _showSnackBar("Nenhum usuário encontrado com este e-mail.", isError: true);
      }
    } catch (e) {
      setState(() => _isSearching = false);
      _showSnackBar("Erro ao buscar usuário. Verifique sua conexão.", isError: true);
    }
  }

  Future<void> _sendInvite() async {
    if (_foundUser == null) return;

    final auth = context.read<AuthProvider>();
    final provider = context.read<UserProvider>();

    try {
      await provider.sendInvite(
        fromCompanyId: auth.currentUser!.company,
        fromCompanyName: auth.currentUser!.name, 
        toUserId: _foundUser!.id,
        currentUserId: auth.currentUser!.id,
      );

      if (mounted) {
        _showSnackBar("Convite enviado com sucesso! Aguarde o aceite do operador.");
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Convidar Operador')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Envie um convite para que um colaborador se junte à sua equipe.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-mail do Operador',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _isSearching ? null : _searchUser,
                  ),
                ),
                validator: (v) => v!.isEmpty || !v.contains('@') ? 'E-mail inválido' : null,
                onFieldSubmitted: (_) => _searchUser(),
              ),
            ),
            const SizedBox(height: 32),
            if (_isSearching)
              const Center(child: CircularProgressIndicator())
            else if (_foundUser != null)
              _buildUserFoundCard(theme, userProvider.isLoading)
            else
              _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserFoundCard(ThemeData theme, bool isLoading) {
    return Card(
      color: theme.primaryColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
            const SizedBox(height: 16),
            Text(_foundUser!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(_foundUser!.email, style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _sendInvite,
                icon: isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.send_rounded),
                label: Text(isLoading ? "ENVIANDO..." : "ENVIAR CONVITE DE EQUIPE"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Por segurança, o operador deve aceitar seu convite para que os dados da empresa sejam compartilhados.",
              style: TextStyle(fontSize: 13, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
