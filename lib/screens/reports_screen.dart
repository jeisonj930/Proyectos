import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/farm_debt_summary.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _database = AppDatabase.instance;
  late Future<_ReportsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_ReportsData> _loadData() async {
    final calvesCount = await _database.getCalvesCount();
    final paddocksCount = await _database.getPaddocksCount();
    final calfExpenses = await _database.getTotalCalfInvestment();
    final calfIncome = await _database.getTotalCalfIncome();
    final paddockExpenses = await _database.getTotalPaddockExpenses();
    final paddockIncome = await _database.getTotalPaddockIncome();
    final farmExpenses = await _database.getTotalFarmExpenses();
    final farmDebt = await _database.getFarmDebtSummary();

    return _ReportsData(
      calvesCount: calvesCount,
      paddocksCount: paddocksCount,
      calfExpenses: calfExpenses,
      calfIncome: calfIncome,
      paddockExpenses: paddockExpenses,
      paddockIncome: paddockIncome,
      farmExpenses: farmExpenses,
      farmDebt: farmDebt,
    );
  }

  String _money(double value) {
    return '\$${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: FutureBuilder<_ReportsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final operatingBalance = data.totalIncome - data.totalExpenses;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(
                title: 'Balance general',
                value: _money(operatingBalance),
                subtitle: 'Ingresos menos gastos registrados',
                icon: operatingBalance >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                positive: operatingBalance >= 0,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Terneras',
                      value: data.calvesCount.toString(),
                      icon: Icons.pets_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Potreros',
                      value: data.paddocksCount.toString(),
                      icon: Icons.grass_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionTitle(title: 'Terneras'),
              _AmountRow(label: 'Gastos e inversión', value: data.calfExpenses),
              _AmountRow(label: 'Ingresos', value: data.calfIncome),
              _AmountRow(
                label: 'Balance terneras',
                value: data.calfIncome - data.calfExpenses,
                highlight: true,
              ),
              const SizedBox(height: 16),
              _SectionTitle(title: 'Potreros'),
              _AmountRow(label: 'Gastos', value: data.paddockExpenses),
              _AmountRow(label: 'Ingresos', value: data.paddockIncome),
              _AmountRow(
                label: 'Balance potreros',
                value: data.paddockIncome - data.paddockExpenses,
                highlight: true,
              ),
              const SizedBox(height: 16),
              _SectionTitle(title: 'Finca'),
              _AmountRow(label: 'Gastos generales', value: data.farmExpenses),
              _AmountRow(label: 'Valor finca', value: data.farmDebt.totalValue),
              _AmountRow(label: 'Abonos finca', value: data.farmDebt.paidValue),
              _AmountRow(
                label: 'Saldo pendiente finca',
                value: data.farmDebt.pendingValue,
                highlight: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReportsData {
  final int calvesCount;
  final int paddocksCount;
  final double calfExpenses;
  final double calfIncome;
  final double paddockExpenses;
  final double paddockIncome;
  final double farmExpenses;
  final FarmDebtSummary farmDebt;

  const _ReportsData({
    required this.calvesCount,
    required this.paddocksCount,
    required this.calfExpenses,
    required this.calfIncome,
    required this.paddockExpenses,
    required this.paddockIncome,
    required this.farmExpenses,
    required this.farmDebt,
  });

  double get totalIncome => calfIncome + paddockIncome;

  double get totalExpenses => calfExpenses + paddockExpenses + farmExpenses;
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool positive;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final color = positive ? Colors.green : Colors.red;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double value;
  final bool highlight;

  const _AmountRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = highlight ? Theme.of(context).textTheme.titleMedium : null;
    return Card(
      child: ListTile(
        title: Text(label, style: style),
        trailing: Text(
          '\$${value.toStringAsFixed(0)}',
          style: style,
        ),
      ),
    );
  }
}
