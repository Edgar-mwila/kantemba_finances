import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/models/user.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:kantemba_finances/screens/settings/backup_settings_screen.dart';
import 'package:kantemba_finances/screens/settings/security_settings_screen.dart';
import 'package:kantemba_finances/screens/settings/tax_compliance_settings_screen.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersProvider>(context);
    final users = usersProvider.users;
    final currentUser = usersProvider.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Users',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder:
                    (ctx, i) => Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Icon(
                          users[i].role == UserRole.owner
                              ? Icons.verified_user
                              : Icons.person,
                          color:
                              users[i].role == UserRole.owner
                                  ? Colors.green
                                  : Colors.blue,
                        ),
                        title: Text(users[i].name),
                        subtitle: Text(
                          '${users[i].role.name.toUpperCase()}\nPermissions: ${users[i].permissions.join(", ")}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (currentUser?.id != users[i].id)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => usersProvider.deleteUser(users[i].id),
                              ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.orange,
                              ),
                              onPressed:
                                  () => _showUserDialog(
                                    context,
                                    usersProvider,
                                    user: users[i],
                                  ),
                            ),
                            if (currentUser?.id != users[i].id)
                              IconButton(
                                icon: const Icon(
                                  Icons.login,
                                  color: Colors.green,
                                ),
                                tooltip: 'Switch to this user',
                                onPressed:
                                    () =>
                                        usersProvider.setCurrentUser(users[i]),
                              ),
                          ],
                        ),
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showUserDialog(context, usersProvider),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add User',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Other Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            _buildSettingItem(context, Icons.cloud_upload, 'Data & Backup', () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackupSettingsScreen()));
            }),
            _buildSettingItem(context, Icons.receipt_long, 'Tax Compliance Settings', () {
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TaxComplianceSettingsScreen()));
            }),
            _buildSettingItem(context, Icons.security, 'Security Settings', () {
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()));
            }),
          ],
        ),
      ),
    );
  }

  void _showUserDialog(
    BuildContext context,
    UsersProvider usersProvider, {
    User? user,
  }) {
    final nameController = TextEditingController(text: user?.name ?? '');
    UserRole role = user?.role ?? UserRole.employee;
    final permissions = Set<String>.from(user?.permissions ?? ['sales']);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(user == null ? 'Add User' : 'Edit User'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 10),
                DropdownButton<UserRole>(
                  value: role,
                  items:
                      UserRole.values
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      role = val;
                    }
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildPermissionChip('sales', permissions),
                    _buildPermissionChip('inventory', permissions),
                    _buildPermissionChip('expenses', permissions),
                    _buildPermissionChip('reports', permissions),
                    _buildPermissionChip('users', permissions),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newUser = User(
                    id:
                        user?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    role: role,
                    permissions: permissions.toList(),
                  );
                  if (user == null) {
                    usersProvider.addUser(newUser, "user");
                  } else {
                    usersProvider.editUser(user.id, newUser);
                  }
                  Navigator.of(ctx).pop();
                },
                child: Text(user == null ? 'Add' : 'Save'),
              ),
            ],
          ),
    );
  }

  Widget _buildPermissionChip(String permission, Set<String> permissions) {
    return FilterChip(
      label: Text(permission),
      selected: permissions.contains(permission) || permissions.contains('all'),
      onSelected: (selected) {
        if (permissions.contains('all')) return;
        if (selected) {
          permissions.add(permission);
        } else {
          permissions.remove(permission);
        }
      },
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: Colors.green.shade600),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}
