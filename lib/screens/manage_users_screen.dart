import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/models/user.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:kantemba_finances/screens/settings/backup_settings_screen.dart';
import 'package:kantemba_finances/screens/settings/security_settings_screen.dart';
import 'package:kantemba_finances/screens/settings/tax_compliance_settings_screen.dart';
import 'package:kantemba_finances/providers/business_provider.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersProvider>(context);
    final users = usersProvider.users;
    final currentUser = usersProvider.currentUser;
    final businessProvider = Provider.of<BusinessProvider>(context);
    final isPremium = businessProvider.isPremium;

    return Scaffold(
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
                                    businessProvider,
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
                onPressed:
                    isPremium
                        ? () => _showUserDialog(
                          context,
                          usersProvider,
                          businessProvider,
                        )
                        : () => _showUpgradeDialog(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add User (Employee)',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isPremium ? Colors.green.shade700 : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    isPremium
                        ? () {
                          /* TODO: Add multi-shop logic */
                        }
                        : () => _showUpgradeDialog(context),
                icon: const Icon(Icons.store, color: Colors.white),
                label: const Text(
                  'Add Shop (Multi-Shop)',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isPremium ? Colors.blue.shade700 : Colors.grey,
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
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BackupSettingsScreen()),
              );
            }),
            _buildSettingItem(
              context,
              Icons.receipt_long,
              'Tax Compliance Settings',
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TaxComplianceSettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(context, Icons.security, 'Security Settings', () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SecuritySettingsScreen(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showUserDialog(
    BuildContext context,
    UsersProvider usersProvider,
    BusinessProvider businessProvider, {
    User? user,
  }) {
    final nameController = TextEditingController(text: user?.name ?? '');
    final passwordController = TextEditingController();
    final contactController = TextEditingController();
    UserRole role = user?.role ?? UserRole.employee;
    final permissions = Set<String>.from(user?.permissions ?? ['sales']);
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(user == null ? 'Add User' : 'Edit User'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (user == null) ...[
                          TextField(
                            controller: contactController,
                            decoration: const InputDecoration(
                              labelText: 'Contact (Phone/Email)',
                              border: OutlineInputBorder(),
                              hintText: 'Enter phone number or email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        DropdownButtonFormField<UserRole>(
                          value: role,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            border: OutlineInputBorder(),
                          ),
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
                              setState(() {
                                role = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Permissions:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _buildPermissionChip(
                              'sales',
                              permissions,
                              setState,
                            ),
                            _buildPermissionChip(
                              'inventory',
                              permissions,
                              setState,
                            ),
                            _buildPermissionChip(
                              'expenses',
                              permissions,
                              setState,
                            ),
                            _buildPermissionChip(
                              'reports',
                              permissions,
                              setState,
                            ),
                            _buildPermissionChip(
                              'users',
                              permissions,
                              setState,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Validation
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a name'),
                            ),
                          );
                          return;
                        }

                        if (user == null) {
                          // For new users, validate required fields
                          if (contactController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter contact information',
                                ),
                              ),
                            );
                            return;
                          }
                          if (passwordController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a password'),
                              ),
                            );
                            return;
                          }
                        }

                        final newUser = User(
                          id:
                              user?.id ??
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text.trim(),
                          role: role,
                          permissions: permissions.toList(),
                        );

                        if (user == null) {
                          // Adding new user
                          final businessId = businessProvider.id ?? '';
                          if (businessId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No business selected'),
                              ),
                            );
                            return;
                          }
                          usersProvider.addUser(
                            newUser,
                            passwordController.text.trim(),
                            contactController.text.trim(),
                            businessId,
                          );
                        } else {
                          // Editing existing user
                          usersProvider.editUser(user.id, newUser);
                        }
                        Navigator.of(ctx).pop();
                      },
                      child: Text(user == null ? 'Add' : 'Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildPermissionChip(
    String permission,
    Set<String> selected,
    StateSetter setState,
  ) {
    final label = () {
      switch (permission) {
        case 'all':
          return 'All Permissions';
        case 'sales':
          return 'Sales';
        case 'inventory':
          return 'Inventory';
        case 'expenses':
          return 'Expenses';
        case 'reports':
          return 'Reports';
        case 'users':
          return 'Manage Users';
        default:
          return permission;
      }
    }();

    return FilterChip(
      label: Text(label),
      selected: selected.contains(permission),
      onSelected: (val) {
        setState(() {
          if (val) {
            selected.add(permission);
          } else {
            selected.remove(permission);
          }
        });
      },
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
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

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Premium Feature'),
            content: const Text('Upgrade to premium to access this feature.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
