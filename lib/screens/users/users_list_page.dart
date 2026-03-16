import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transferr/widgets/app_drawer.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<UserProvider>().initCompanyStream(auth.currentUser!.company);
        context.read<UserProvider>().initInviteStream(auth.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Equipe'),
        elevation: 0,
        actions: [
          _buildInviteBadge(userProvider),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildHeader(theme),
          _buildSearchBar(userProvider),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (authProvider.currentUser != null) {
                  userProvider.initCompanyStream(authProvider.currentUser!.company);
                }
              },
              child: userProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : userProvider.users.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: userProvider.usersCount,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _UserCard(user: userProvider.users[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-user'),
        label: const Text('Novo Operador'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }

  Widget _buildInviteBadge(UserProvider provider) {
    final hasInvites = provider.pendingInvites.isNotEmpty;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined),
          onPressed: () => _showInvitesDialog(context, provider),
        ),
        if (hasInvites)
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
              constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
              child: Text(
                '${provider.pendingInvites.length}',
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          )
      ],
    );
  }

  void _showInvitesDialog(BuildContext context, UserProvider provider) {
    final auth = context.read<AuthProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Convites de Equipe"),
        content: provider.pendingInvites.isEmpty
            ? const Text("Nenhum convite pendente.")
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.pendingInvites.length,
                  itemBuilder: (context, index) {
                    final invite = provider.pendingInvites[index];
                    return ListTile(
                      title: Text(invite['fromCompanyName']),
                      subtitle: const Text("Deseja entrar nesta equipe?"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _respond(context, provider, auth, invite, 'aceito'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _respond(context, provider, auth, invite, 'recusado'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("FECHAR")),
        ],
      ),
    );
  }

  void _respond(BuildContext context, UserProvider provider, AuthProvider auth, Map<String, dynamic> invite, String status) async {
    try {
      await provider.respondToInvite(
        inviteId: invite['id'],
        status: status,
        currentUser: auth.currentUser!,
        companyId: invite['fromCompanyId'],
      );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'aceito' ? "Bem-vindo à nova equipe!" : "Convite recusado."),
            backgroundColor: status == 'aceito' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao responder convite.")));
    }
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.primaryColor.withValues(alpha: 0.1),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Gerencie as permissões e o acesso dos administradores e agentes da sua empresa.',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(UserProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => provider.searchUsers(value),
        decoration: InputDecoration(
          hintText: 'Buscar por nome ou e-mail...',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.grey.withValues(alpha: 0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text('Nenhum operador encontrado.', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isAdmin ? Colors.amber.withValues(alpha: 0.2) : theme.primaryColor.withValues(alpha: 0.2),
          child: Icon(user.isAdmin ? Icons.admin_panel_settings : Icons.person, color: user.isAdmin ? Colors.amber : theme.primaryColor),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(user.email),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: user.isAdmin ? Colors.amber.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(user.isAdmin ? 'ADMIN' : 'AGENTE', style: TextStyle(fontSize: 10, color: user.isAdmin ? Colors.amber : Colors.blue, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
