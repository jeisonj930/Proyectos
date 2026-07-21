import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/farm_expense.dart';
import 'farm_expense_form_screen.dart';

class FarmExpenseListScreen extends StatefulWidget {
  const FarmExpenseListScreen({super.key});

  @override
  State<FarmExpenseListScreen> createState() => _FarmExpenseListScreenState();
}

class _FarmExpenseListScreenState extends State<FarmExpenseListScreen> {
  final _database = AppDatabase.instance;
  late Future<_FarmExpenseListData> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _loadData();
  }

  Future<_FarmExpenseListData> _loadData() async {
    final expenses = await _database.getAllFarmExpenses();
    final total = await _database.getTotalFarmExpenses();
    return _FarmExpenseListData(expenses: expenses, total: total);
  }

  Future<void> _openForm({FarmExpense? expense}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FarmExpenseFormScreen(expense: expense),
      ),
    );
    if (!mounted) return;
    setState(_reload);
  }

  Future<void> _deleteExpense(FarmExpense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Seguro que quieres eliminar ${expense.description}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await _database.deleteFarmExpense(expense.id!);
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gasto eliminado')),
    );
  }

  String _formatMoney(double value) {
    return '\$${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos de finca'),
      ),
      body: FutureBuilder<_FarmExpenseListData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          if (data.expenses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 72),
                    const SizedBox(height: 12),
                    const Text(
                      'Todavía no hay gastos generales registrados',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar gasto'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.expenses.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatMoney(data.total),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Text('Total gastos de finca'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final expense = data.expenses[index - 1];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text('${expense.expenseDate} • ${expense.category}'),
                  subtitle: Text(
                    [
                      expense.description,
                      if ((expense.supplier ?? '').isNotEmpty) expense.supplier,
                      if ((expense.paymentMethod ?? '').isNotEmpty)
                        expense.paymentMethod,
                    ].whereType<String>().join(' • '),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_formatMoney(expense.amount)),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openForm(expense: expense);
                          } else if (value == 'delete') {
                            _deleteExpense(expense);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo gasto'),
      ),
    );
  }
}

class _FarmExpenseListData {
  final List<FarmExpense> expenses;
  final double total;

  const _FarmExpenseListData({
    required this.expenses,
    required this.total,
  });
}
