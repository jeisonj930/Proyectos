import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';
import '../models/dashboard_data.dart';
import '../models/paddock_state.dart';
import 'backup_screen.dart';
import 'calf_list_screen.dart';
import 'farm_debt_screen.dart';
import 'farm_expense_list_screen.dart';
import 'paddock_list_screen.dart';
import 'reports_screen.dart';
import 'rotation_move_screen.dart';

class HomeMenuScreen extends StatefulWidget {
  const HomeMenuScreen({super.key});

  @override
  State<HomeMenuScreen> createState() => _HomeMenuScreenState();
}

class _HomeMenuScreenState extends State<HomeMenuScreen> {
  final _database = AppDatabase.instance;
  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _database.getDashboardData();
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
    if (!mounted) return;
    setState(_reload);
  }

  int _daysSince(String isoDate) {
    final started = DateTime.tryParse(isoDate);
    if (started == null) return 0;
    return DateTime.now().difference(started).inDays + 1;
  }

  int _daysLeft(int plannedDays, String startedAt) {
    final spent = _daysSince(startedAt);
    final left = plannedDays - spent;
    return left < 0 ? 0 : left;
  }

  double _progress(int plannedDays, String startedAt) {
    final spent = _daysSince(startedAt);
    if (plannedDays <= 0) return 0;
    final value = spent / plannedDays;
    return value.clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('San Pedro'),
        actions: [
          IconButton(
            onPressed: () {
              setState(_reload);
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
          IconButton(
            onPressed: () => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: FutureBuilder<DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final activeSession = data.activeSession;
          final activePaddock = data.activePaddock;
          final activeDaysLeft = activeSession == null
              ? null
              : _daysLeft(activeSession.plannedDays, activeSession.startedAt);

          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Tablero de rotación',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      label: 'Terneras',
                      value: data.calvesCount.toString(),
                      icon: Icons.pets_outlined,
                    ),
                    _StatCard(
                      label: 'Potreros',
                      value: data.paddocksCount.toString(),
                      icon: Icons.grass_outlined,
                    ),
                    _StatCard(
                      label: 'Inversión',
                      value: '\$${data.totalCalfInvestment.toStringAsFixed(0)}',
                      icon: Icons.payments_outlined,
                    ),
                    _StatCard(
                      label: 'Gastos finca',
                      value: '\$${data.totalFarmExpenses.toStringAsFixed(0)}',
                      icon: Icons.receipt_long_outlined,
                    ),
                    _StatCard(
                      label: 'Saldo finca',
                      value: '\$${data.farmDebtPending.toStringAsFixed(0)}',
                      icon: Icons.account_balance_outlined,
                    ),
                    _StatCard(
                      label: 'Seguimientos',
                      value: data.pendingCalfFollowUps.toString(),
                      icon: Icons.event_available,
                    ),
                    _StatCard(
                      label: 'En uso',
                      value: activePaddock?.name ?? 'Libre',
                      icon: Icons.terrain_outlined,
                    ),
                    _StatCard(
                      label: 'Días restantes',
                      value: activeDaysLeft?.toString() ?? '-',
                      icon: Icons.schedule_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeSession == null
                              ? 'No hay pastoreo activo'
                              : 'Rotación actual',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeSession == null
                              ? 'Inicia un ciclo para comenzar a controlar el tiempo de ocupación.'
                              : '${activePaddock?.name ?? 'Potrero'} • ${_daysSince(activeSession.startedAt)} de ${activeSession.plannedDays} días',
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: activeSession == null
                              ? 0
                              : _progress(activeSession.plannedDays, activeSession.startedAt),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _openPage(const RotationMoveScreen()),
                          icon: const Icon(Icons.sync_alt),
                          label: Text(activeSession == null
                              ? 'Iniciar pastoreo'
                              : 'Mover a otro potrero'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.pets_outlined,
                        title: 'Terneras',
                        subtitle: 'Inventario y fotos',
                        onTap: () => _openPage(const CalfListScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.grass_outlined,
                        title: 'Potreros',
                        subtitle: 'Datos y recuperación',
                        onTap: () => _openPage(const PaddockListScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Gastos de finca',
                  subtitle: 'Sales, abonos, alambre, mangueras y costos generales',
                  onTap: () => _openPage(const FarmExpenseListScreen()),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.account_balance_outlined,
                  title: 'Pago de finca',
                  subtitle: 'Valor total, abonos realizados y saldo pendiente',
                  onTap: () => _openPage(const FarmDebtScreen()),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.analytics_outlined,
                  title: 'Reportes',
                  subtitle: 'Balance de terneras, potreros, finca y deuda',
                  onTap: () => _openPage(const ReportsScreen()),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.backup_outlined,
                  title: 'Respaldo',
                  subtitle: 'Exportar o restaurar datos de este navegador',
                  onTap: () => _openPage(const BackupScreen()),
                ),
                const SizedBox(height: 20),
                Text(
                  'Estado de potreros',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...data.paddockStates.take(5).map(_buildPaddockStateCard),
                const SizedBox(height: 20),
                Text(
                  'Movimientos recientes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (data.recentMovements.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Todavía no hay movimientos registrados'),
                  )
                else
                  ...data.recentMovements.map(
                    (movement) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.swap_horiz),
                        title: Text(
                          '${movement.fromPaddockName ?? 'Inicio'} -> ${movement.toPaddockName ?? 'Potrero'}',
                        ),
                        subtitle: Text(
                          movement.notes?.isNotEmpty == true
                              ? '${movement.movedAt} • ${movement.notes}'
                              : movement.movedAt,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaddockStateCard(PaddockState state) {
    final statusColor = switch (state.status) {
      'En uso' => Colors.green,
      'En recuperación' => Colors.orange,
      _ => Colors.blueGrey,
    };

    final extraText = state.status == 'En recuperación'
        ? 'Restan ${state.daysRemaining ?? 0} días'
        : state.status == 'En uso'
            ? 'Listo para seguimiento'
            : 'Disponible para usar';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(Icons.grass_outlined, color: statusColor),
        ),
        title: Text(state.paddock.name),
        subtitle: Text(extraText),
        trailing: Chip(
          label: Text(state.status),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
      ),
    );
  }
}
