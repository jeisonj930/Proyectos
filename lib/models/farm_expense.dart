class FarmExpense {
  final int? id;
  final String expenseDate;
  final String category;
  final String description;
  final double amount;
  final String? supplier;
  final String? paymentMethod;
  final String? notes;

  const FarmExpense({
    this.id,
    required this.expenseDate,
    required this.category,
    required this.description,
    required this.amount,
    this.supplier,
    this.paymentMethod,
    this.notes,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'expense_date': expenseDate,
      'category': category,
      'description': description,
      'amount': amount,
      'supplier': supplier,
      'payment_method': paymentMethod,
      'notes': notes,
    };
  }

  factory FarmExpense.fromMap(Map<String, Object?> map) {
    return FarmExpense(
      id: map['id'] as int?,
      expenseDate: map['expense_date'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      supplier: map['supplier'] as String?,
      paymentMethod: map['payment_method'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
