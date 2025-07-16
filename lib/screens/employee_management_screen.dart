import 'package:flutter/material.dart';
import 'package:kantemba_finances/models/shop.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/models/user.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import '../providers/shop_provider.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import '../screens/employee_detail_screen.dart';

class EmployeeManagementScreen extends StatelessWidget {
  const EmployeeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersProvider>(context);
    final shopProvider = Provider.of<ShopProvider>(context);
    final users = usersProvider.users;
    final currentUser = usersProvider.currentUser;
    final businessProvider = Provider.of<BusinessProvider>(context);
    final isPremium = businessProvider.isPremium;

    return Scaffold(
      body:
          isWindows(context)
              ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search and filter row
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search employees...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                onChanged: (value) {
                                  // TODO: Implement search functionality
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.filter_list),
                              onSelected: (value) {
                                // TODO: Implement filter functionality
                              },
                              itemBuilder:
                                  (context) => [
                                    const PopupMenuItem(
                                      value: 'all',
                                      child: Text('All Employees'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'admin',
                                      child: Text('Admins Only'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'manager',
                                      child: Text('Managers Only'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'employee',
                                      child: Text('Employees Only'),
                                    ),
                                  ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          color: Colors.grey.shade100,
                          child: Row(
                            children: const [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Role',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Contact',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Shop',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 0),
                        Expanded(
                          child:
                              users.isEmpty
                                  ? const Center(
                                    child: Text('No employees found.'),
                                  )
                                  : ListView.builder(
                                    itemCount: users.length,
                                    itemBuilder: (ctx, i) {
                                      final user = users[i];
                                      final shop = shopProvider.shops
                                          .firstWhere(
                                            (shop) => shop.id == user.shopId,
                                            orElse:
                                                () => Shop(
                                                  id: '',
                                                  name: 'Unassigned',
                                                  businessId: '',
                                                ),
                                          );
                                      return InkWell(
                                        onTap:
                                            () => _showEmployeeDetails(
                                              context,
                                              user,
                                              shop,
                                            ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Text(user.name),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(user.role),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(user.contact),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  shop.name,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter and search bar
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search employees...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            onChanged: (value) {
                              // TODO: Implement search functionality
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.filter_list),
                          onSelected: (value) {
                            // TODO: Implement filter functionality
                          },
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'all',
                                  child: Text('All Employees'),
                                ),
                                const PopupMenuItem(
                                  value: 'admin',
                                  child: Text('Admins Only'),
                                ),
                                const PopupMenuItem(
                                  value: 'manager',
                                  child: Text('Managers Only'),
                                ),
                                const PopupMenuItem(
                                  value: 'employee',
                                  child: Text('Employees Only'),
                                ),
                              ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: users.length,
                        itemBuilder:
                            (ctx, i) => _buildEmployeeCard(
                              context,
                              users[i],
                              shopProvider,
                              usersProvider,
                              businessProvider,
                              currentUser,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            () => _showUserDialog(
                              context,
                              usersProvider,
                              businessProvider,
                            ),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Add Employee',
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
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => _showUserDialog(context, usersProvider, businessProvider),
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmployeeCard(
    BuildContext context,
    User user,
    ShopProvider shopProvider,
    UsersProvider usersProvider,
    BusinessProvider businessProvider,
    User? currentUser,
  ) {
    final shop = shopProvider.shops.firstWhere(
      (shop) => shop.id == user.shopId,
      orElse: () => Shop(id: '', name: 'Unassigned', businessId: ''),
    );

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEmployeeDetails(context, user, shop),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                    child: Icon(
                      _getRoleIcon(user.role),
                      color: _getRoleColor(user.role),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(
                                  user.role,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getRoleColor(user.role),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.contact,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.store,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              shop.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Permissions chips
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children:
                    user.permissions.map((permission) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          permission,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (currentUser?.id != user.id) ...[
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete Employee',
                      onPressed:
                          () => _showDeleteConfirmation(
                            context,
                            user,
                            usersProvider,
                          ),
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    tooltip: 'Edit Employee',
                    onPressed:
                        () => _showUserDialog(
                          context,
                          usersProvider,
                          businessProvider,
                          user: user,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.blue),
                    tooltip: 'View Details',
                    onPressed: () => _showEmployeeDetails(context, user, shop),
                  ),
                  if (currentUser?.id != user.id)
                    IconButton(
                      icon: const Icon(Icons.login, color: Colors.green),
                      tooltip: 'Switch to this user',
                      onPressed: () => usersProvider.setCurrentUser(user),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmployeeDetails(BuildContext context, User user, Shop shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: _getRoleColor(
                              user.role,
                            ).withOpacity(0.2),
                            child: Icon(
                              _getRoleIcon(user.role),
                              color: _getRoleColor(user.role),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  user.role.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _getRoleColor(user.role),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  user.contact,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildDetailSection(
                        'Assigned Shop',
                        shop.name,
                        Icons.store,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        'Permissions',
                        user.permissions.join(', '),
                        Icons.security,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Performance Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final salesProvider = Provider.of<SalesProvider>(
                            context,
                            listen: false,
                          );
                          final expensesProvider =
                              Provider.of<ExpensesProvider>(
                                context,
                                listen: false,
                              );
                          final userSales =
                              salesProvider.sales
                                  .where((sale) => sale.createdBy == user.id)
                                  .toList();
                          final userExpenses =
                              expensesProvider.expenses
                                  .where((exp) => exp.createdBy == user.id)
                                  .toList();
                          final totalSales = userSales.fold<double>(
                            0.0,
                            (sum, sale) => sum + (sale.grandTotal),
                          );
                          final totalExpenses = userExpenses.fold<double>(
                            0.0,
                            (sum, exp) => sum + (exp.amount),
                          );
                          return Row(
                            children: [
                              Expanded(
                                child: _buildPerformanceCard(
                                  'Sales',
                                  'K${totalSales.toStringAsFixed(2)}',
                                  Icons.trending_up,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPerformanceCard(
                                  'Expenses',
                                  'K${totalExpenses.toStringAsFixed(2)}',
                                  Icons.trending_down,
                                  Colors.red,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => EmployeeDetailScreen(user: user),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'View Full Performance Report',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildDetailSection(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    User user,
    UsersProvider usersProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Employee'),
            content: Text(
              'Are you sure you want to delete ${user.name}? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  usersProvider.deleteUser(user.id);
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case "admin":
        return Colors.green;
      case "manager":
        return Colors.orange;
      case "employee":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case "admin":
        return Icons.verified_user;
      case "manager":
        return Icons.manage_accounts;
      case "employee":
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  void _showUserDialog(
    BuildContext context,
    UsersProvider usersProvider,
    BusinessProvider businessProvider, {
    User? user,
  }) {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final nameController = TextEditingController(text: user?.name ?? '');
    final passwordController = TextEditingController();
    final contactController = TextEditingController(text: user?.contact ?? '');
    String role = user?.role ?? 'employee';
    final permissions = Set<String>.from(user?.permissions ?? ['sales']);
    String? selectedShopId = user?.shopId;
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(user == null ? 'Add Employee' : 'Edit Employee'),
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
                        DropdownButtonFormField<String>(
                          value: role,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              ['admin', 'manager', 'employee']
                                  .map(
                                    (r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(r.toUpperCase()),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                role = val;
                                if (val == "admin") {
                                  selectedShopId = null;
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        if (role == "manager" || role == "employee")
                          DropdownButtonFormField<String>(
                            value: selectedShopId,
                            decoration: const InputDecoration(
                              labelText: 'Assign to Shop',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                shopProvider.shops
                                    .map(
                                      (shop) => DropdownMenuItem(
                                        value: shop.id,
                                        child: Text(shop.name),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedShopId = val;
                              });
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
                              UserPermissions.viewSales,
                              permissions,
                              setState,
                            ),
                            _buildPermissionChip(
                              UserPermissions.addSales,
                              permissions,
                              setState,
                            ),
                            _buildPermissionChip(
                              UserPermissions.viewInventory,
                              permissions,
                              setState,
                            ),
                            _buildPermissionChip(
                              UserPermissions.addInventory,
                              permissions,
                              setState,
                            ),
                            _buildPermissionChip(
                              UserPermissions.viewExpenses,
                              permissions,
                              setState,
                            ),
                            _buildPermissionChip(
                              UserPermissions.addExpense,
                              permissions,
                              setState,
                            ),
                            _buildPermissionChip(
                              UserPermissions.viewReports,
                              permissions,
                              setState,
                            ),
                            _buildPermissionChip(
                              UserPermissions.manageUsers,
                              permissions,
                              setState,
                            ),
                            _buildPermissionChip(
                              UserPermissions.manageSettings,
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

                        // Validate shop assignment for manager/employee
                        if ((role == "manager" || role == "employee") &&
                            selectedShopId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please assign a shop for manager/employee roles',
                              ),
                            ),
                          );
                          return;
                        }

                        final newUser = User(
                          id:
                              user?.id ??
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text.trim(),
                          contact: contactController.text.trim(),
                          role: role,
                          permissions: permissions.toList(),
                          shopId:
                              (role == "manager" || role == "employee")
                                  ? selectedShopId
                                  : null,
                          businessId: businessProvider.id!,
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
        case UserPermissions.all:
          return 'All Permissions';
        case UserPermissions.viewSales:
          return 'View Sales';
        case UserPermissions.addSales:
          return 'Add Sales';
        case UserPermissions.viewInventory:
          return 'View Inventory';
        case UserPermissions.addInventory:
          return 'Add Inventory';
        case UserPermissions.viewExpenses:
          return 'View Expenses';
        case UserPermissions.addExpense:
          return 'Add Expenses';
        case UserPermissions.viewReports:
          return 'View Reports';
        case UserPermissions.manageUsers:
          return 'Manage Users';
        case UserPermissions.manageSettings:
          return 'Manage Settings';
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
}
