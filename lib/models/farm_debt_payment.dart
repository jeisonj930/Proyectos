class FarmDebtPayment {
  final int? id;
  final String paymentDate;
  final double amount;
  final String? description;
  final String? paymentMethod;
  final String? notes;

  const FarmDebtPayment({
    this.id,
    required this.paymentDate,
    required this.amount,
    this.description,
    this.paymentMethod,
    this.notes,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'payment_date': paymentDate,
      'amount': amount,
      'description': description,
      'payment_method': paymentMethod,
      'notes': notes,
    };
  }

  factory FarmDebtPayment.fromMap(Map<String, Object?> map) {
    return FarmDebtPayment(
      id: map['id'] as int?,
      paymentDate: map['payment_date'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String?,
      paymentMethod: map['payment_method'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
