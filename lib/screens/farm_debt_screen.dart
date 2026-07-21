import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/farm_debt_payment.dart';
import '../models/farm_debt_summary.dart';
import 'farm_debt_payment_form_screen.dart';

class FarmDebtScreen extends StatefulWidget {
  const FarmDebtScreen({super.key});

  @override
  State<FarmDebtScreen> createState() => _FarmDebtScreenState();
}

class _FarmDebtScreenState extends State<FarmDebtScreen> {
  final _database = AppDatabase.instance;
  late Future<_FarmDebtData> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _loadData();
  }

  Future<_FarmDebtData> _loadData() async {
    final summary = await _database.getFarmDebtSummary();
    final payments = await _database.getFarmDebtPayments();
    return _FarmDebtData(summary: summary, payments: payments);
  }

  String _formatMoney(double value) {
    return '\$${value.toStringAsFixed(0)}';
  }

  Future<void> _editTotalValue(double currentValue) async {
    final controller = TextEditingController(
      text: currentValue > 0 ? currentValue.toStringAsFixed(0) : '',
    );
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valor total de la finca'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Valor total',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, double.tryParse(controller.text.trim()) ?? 0);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null) return;
    await _database.saveFarmDebtTotalValue(result);
    if (!mounted) return;
    setState(_reload);
  }

  Future<void> _openPaymentForm({FarmDebtPayment? payment}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FarmDebtPaymentFormScreen(payment: payment),
      ),
    );
    if (!mounted) return;
    setState(_reload);
  }

  Future<void> _deletePayment(FarmDebtPayment payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar abono'),
        content: const Text('¿Seguro que quieres eliminar este abono?'),
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
    await _database.deleteFarmDebtPayment(payment.id!);
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abono eliminado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago de finca'),
      ),
      body: FutureBuilder<_FarmDebtData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Control de deuda',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _editTotalValue(data.summary.totalValue),
                            icon: const Icon(Icons.edit),
                            tooltip: 'Editar valor total',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _MoneyLine(
                        label: 'Valor finca',
                        value: _formatMoney(data.summary.totalValue),
                      ),
                      _MoneyLine(
                        label: 'Abonado',
                        value: _formatMoney(data.summary.paidValue),
                      ),
                      _MoneyLine(
                        label: 'Saldo pendiente',
                        value: _formatMoney(data.summary.pendingValue),
                        isStrong: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _openPaymentForm(),
                icon: const Icon(Icons.add),
                label: const Text('Agregar abono'),
              ),
              const SizedBox(height: 20),
              Text(
                'Historial de abonos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (data.payments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Todavía no hay abonos registrados'),
                )
              else
                ...data.payments.map(
                  (payment) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.payments_outlined),
                      title: Text('${payment.paymentDate} • ${_formatMoney(payment.amount)}'),
                      subtitle: Text(
                        [
                          if ((payment.description ?? '').isNotEmpty)
                            payment.description,
                          if ((payment.paymentMethod ?? '').isNotEmpty)
                            payment.paymentMethod,
                        ].whereType<String>().join(' • '),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openPaymentForm(payment: payment);
                          } else if (value == 'delete') {
                            _deletePayment(payment);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPaymentForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo abono'),
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isStrong;

  const _MoneyLine({
    required this.label,
    required this.value,
    this.isStrong = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isStrong
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _FarmDebtData {
  final FarmDebtSummary summary;
  final List<FarmDebtPayment> payments;

  const _FarmDebtData({
    required this.summary,
    required this.payments,
  });
}
