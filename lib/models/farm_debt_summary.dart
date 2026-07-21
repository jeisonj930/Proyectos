class FarmDebtSummary {
  final double totalValue;
  final double paidValue;

  const FarmDebtSummary({
    required this.totalValue,
    required this.paidValue,
  });

  double get pendingValue => totalValue - paidValue;
}
