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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos watch para reagir a mudanças na lista e no estado de loading
    final userProvider = context.watch<UserProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Equipe e Operadores'), elevation: 0),
      body: Column(
        children: [
          // Header Informativo
          _buildHeader(theme),

          // Barra de Busca Reativa
          _buildSearchBar(userProvider),

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
                      return _UserCard(user: userProvider.users[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteInfo(context),
        label: const Text('Novo Operador'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.primaryColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: theme.primaryColor, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Gerencie as permissões e o acesso dos administradores e agentes ao painel.',
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
          hintText: 'Buscar por nome, e-mail ou CPF...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    provider.searchUsers('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 64,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum operador encontrado.',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  void _showInviteInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'A funcionalidade de convite será implementada em breve.',
        ),
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
      color: user.isActive ? null : Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: user.isActive
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.red.withValues(alpha: 0.2),
        ),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: user.isActive ? null : Colors.grey,
            decoration: user.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: const TextStyle(fontSize: 12)),
            if (!user.isActive)
              const Text(
                'ACESSO BLOQUEADO',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
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

    final bool isAdmin = user.isAdmin;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),

            // Ação de Alterar Perfil (Refatorada para o novo método do Repository)
            ListTile(
              leading: Icon(
                isAdmin
                    ? Icons.person_outline
                    : Icons.admin_panel_settings_outlined,
              ),
              title: Text(
                user.isAdmin
                    ? 'Rebaixar para Agente'
                    : 'Promover a Administrador',
              ),
              onTap: () async {
                final newRole = user.isAdmin ? 'AGENTE' : 'ADMIN';
                // Certifique-se que o UserProvider tem o método saveUser chamando o repository.saveUserData
                final updatedUser = user.copyWith(profile: newRole);
                await provider.saveUser(updatedUser);
                if (context.mounted) Navigator.pop(context);
              },
            ),

            // Ação de Ativar/Desativar
            ListTile(
              leading: Icon(
                user.isActive ? Icons.block : Icons.check_circle_outline,
                color: user.isActive ? Colors.red : Colors.green,
              ),
              title: Text(
                user.isActive ? 'Bloquear Acesso' : 'Desbloquear Acesso',
              ),
              onTap: () async {
                await provider.toggleUserStatus(user.id, user.isActive);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
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
