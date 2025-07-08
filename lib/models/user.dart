enum UserRole { admin, manager, employee }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.manager:
        return 'manager';
      case UserRole.employee:
        return 'employee';
    }
  }
}

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
}

class User {
  final String id;
  final String name;
  final String contact;
  final UserRole role;
  final List<String> permissions;
  final String? shopId;
  final String businessId;

  User({
    required this.id,
    required this.name,
    required this.contact,
    required this.role,
    required this.permissions,
    this.shopId,
    required this.businessId,
  });

  bool hasPermission(String permission) {
    return permissions.contains(UserPermissions.all) ||
        permissions.contains(permission);
  }
}
