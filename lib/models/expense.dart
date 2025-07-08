class Expense {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final String shopId;
  final String createdBy;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.category = 'Uncategorized',
    required this.shopId,
    required this.createdBy,
  });
}
