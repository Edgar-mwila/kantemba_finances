enum UserRole { owner, employee }

class UserPermissions {
  static const String all = 'all';
  static const String viewSales = 'view_sales';
  static const String addSales = 'add_sales';
  static const String viewInventory = 'view_inventory';
  static const String addInventory = 'add_inventory';
  static const String viewExpenses = 'view_expenses';
  static const String addExpense = 'add_expense';
  static const String manageUsers = 'manage_users';
  static const String viewReports = 'view_reports';
  static const String manageSettings = 'manage_settings';
  static const String viewPremium = 'view_premium';
}

class User {
  final String id;
  final String name;
  final UserRole role;
  final List<String> permissions;

  User({
    required this.id,
    required this.name,
    required this.role,
    required this.permissions,
  });

  bool hasPermission(String permission) {
    return permissions.contains(UserPermissions.all) ||
        permissions.contains(permission);
  }
}
