class Expense {
  final int? id;
  final String title;
  final double amount;
  final String? category;
  final DateTime expenseDate;
  final String? notes;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    this.category,
    required this.expenseDate,
    this.notes,
  });
}
