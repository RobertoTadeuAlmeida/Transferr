import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../config/theme/app_theme.dart';

class PendingCompanyPage extends StatefulWidget {
  const PendingCompanyPage({super.key});

  @override
  State<PendingCompanyPage> createState() => _PendingCompanyPageState();
}

class _PendingCompanyPageState extends State<PendingCompanyPage> {
  final TextEditingController _companyNameController = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null && user.id.isNotEmpty) {
        context.read<UserProvider>().initInviteStream(user.id);
      }
    });
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _createCompany() async {
    final name = _companyNameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar("Por favor, informe o nome da sua agência.", isError: true);
      return;
    }

    setState(() => _isCreating = true);
    try {
      // O método createCompany no AuthProvider agora está alinhado com o AuthService
      final auth = context.read<AuthProvider>();
      // Certifique-se que o AuthProvider tenha esse método atualizado
      await auth.createCompany(name);
    } catch (e) {
      if (mounted) _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vínculo de Empresa"),
        actions: [
          IconButton(
            tooltip: "Sair da conta",
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.business_center_outlined, size: 64, color: theme.primaryColor),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Olá, ${user?.name.split(' ').first ?? 'Agente'}!",
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Sua conta está pronta. Agora você precisa se vincular a uma empresa para começar.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),

            _buildSectionHeader(context, "CONVITES PENDENTES", Icons.mail_outline),
            const SizedBox(height: 16),
            if (userProvider.pendingInvites.isEmpty)
              _buildEmptyState(
                "Nenhum convite recebido.",
                "Solicite ao seu administrador que envie um convite para o seu e-mail: ${user?.email ?? ''}",
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: userProvider.pendingInvites.length,
                itemBuilder: (context, index) {
                  return _InviteCard(invite: userProvider.pendingInvites[index]);
                },
              ),

            const SizedBox(height: 48),

            _buildSectionHeader(context, "SOU UM ORGANIZADOR", Icons.add_business_outlined),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      "Se você possui sua própria agência, crie uma organização agora e convide sua equipe.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _companyNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: "Nome Fantasia da Empresa",
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCreating ? null : _createCompany,
                        child: _isCreating 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                          : const Text("CRIAR MINHA ORGANIZAÇÃO"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty_rounded, color: Colors.grey.withOpacity(0.3), size: 48),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final Map<String, dynamic> invite;
  const _InviteCard({required this.invite});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.business_outlined, color: Colors.green),
        title: Text(invite['fromCompanyName'] ?? "Empresa"),
        subtitle: const Text("Deseja convidar você para a equipe"),
        trailing: ElevatedButton(
          onPressed: () async {
            try {
              await userProvider.respondToInvite(
                inviteId: invite['id'],
                status: 'ACEITO',
                currentUser: auth.currentUser!,
                companyId: invite['fromCompanyId'],
              );
              await auth.refreshUser();
            } catch (e) {
              debugPrint("Erro ao aceitar convite: $e");
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text("ACEITAR"),
        ),
      ),
    );
  }
}
