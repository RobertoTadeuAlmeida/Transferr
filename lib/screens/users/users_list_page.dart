import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipe e Operadores'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Informativo com a nova API de Cores
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.primaryColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: theme.primaryColor),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Gerencie os administradores e agentes que operam o sistema.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),

          // Barra de Busca
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => userProvider.searchUsers(value),
              decoration: InputDecoration(
                hintText: 'Buscar por nome, e-mail ou CPF...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      userProvider.searchUsers('');
                    })
                    : null,
                filled: true,
                fillColor: Colors.grey[900]!.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: userProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : userProvider.users.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: userProvider.usersCount,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = userProvider.users[index];
                return _UserCard(user: user);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implementar convite de novo operador
        },
        label: const Text('Novo Operador'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
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
    final bool isAdmin = user.isAdmin;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: isAdmin
              ? Colors.amber.withValues(alpha: 0.2)
              : theme.primaryColor.withValues(alpha: 0.2),
          child: Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
            color: isAdmin ? Colors.amber : theme.primaryColor,
          ),
        ),
        title: Text(
            user.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: const TextStyle(fontSize: 12)),
            if (!user.isActive)
              const Text(
                  'CONTA DESATIVADA',
                  style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)
              ),
          ],
        ),
        trailing: _RoleBadge(isAdmin: isAdmin),
        onTap: () => _showUserActions(context, user),
      ),
    );
  }

  void _showUserActions(BuildContext context, User user) {
    final provider = context.read<UserProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(user.isAdmin ? 'Alterar para Agente' : 'Promover a Admin'),
              onTap: () {
                provider.updateUserRole(user.id, user.isAdmin ? 'agente' : 'admin');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                user.isActive ? Icons.person_off_outlined : Icons.person_outline,
                color: user.isActive ? Colors.red : Colors.green,
              ),
              title: Text(user.isActive ? 'Desativar Operador' : 'Ativar Operador'),
              onTap: () {
                provider.toggleUserStatus(user.id, user.isActive);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final bool isAdmin;
  const _RoleBadge({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final color = isAdmin ? Colors.amber : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        isAdmin ? 'ADMIN' : 'AGENTE',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}