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
  final String role; // 'admin' | 'manager' | 'employee'
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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      contact: json['contact'] as String,
      role: json['role'] as String,
      permissions: List<String>.from(json['permissions'] ?? []),
      shopId: json['shopId'] as String?,
      businessId: json['businessId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'role': role,
      'permissions': permissions,
      'shopId': shopId,
      'businessId': businessId,
    };
  }
}
