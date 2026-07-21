import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/calf.dart';
import '../models/calf_event.dart';
import 'calf_event_form_screen.dart';
import 'calf_form_screen.dart';

class CalfDetailScreen extends StatefulWidget {
  final int calfId;

  const CalfDetailScreen({super.key, required this.calfId});

  @override
  State<CalfDetailScreen> createState() => _CalfDetailScreenState();
}

class _CalfDetailScreenState extends State<CalfDetailScreen> {
  final _database = AppDatabase.instance;
  late Future<_CalfDetailData> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _loadData();
  }

  Future<_CalfDetailData> _loadData() async {
    final calf = await _database.getCalfById(widget.calfId);
    final events = await _database.getCalfEvents(widget.calfId);
    final investmentTotal = await _database.getCalfInvestmentTotal(widget.calfId);
    final incomeTotal = await _database.getCalfIncomeTotal(widget.calfId);
    return _CalfDetailData(
      calf: calf,
      events: events,
      investmentTotal: investmentTotal,
      incomeTotal: incomeTotal,
    );
  }

  Future<void> _edit(Calf calf) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalfFormScreen(calf: calf),
      ),
    );
    if (!mounted) return;
    setState(_load);
  }

  Future<void> _openEventForm({CalfEvent? event}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalfEventFormScreen(
          calfId: widget.calfId,
          event: event,
        ),
      ),
    );
    if (!mounted) return;
    setState(_load);
  }

  Future<void> _deleteEvent(CalfEvent event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: const Text('¿Seguro que quieres eliminar este registro?'),
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
    await _database.deleteCalfEvent(event.id!);
    if (!mounted) return;
    setState(_load);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evento eliminado')),
    );
  }

  String _formatMoney(double value) {
    return '\$${value.toStringAsFixed(0)}';
  }

  String _eventAmountLabel(CalfEvent event) {
    final value = event.cost;
    if (value == null) return 'Sin valor';
    if (event.amountType == 'income') return '+${_formatMoney(value)}';
    if (event.amountType == 'neutral') return _formatMoney(value);
    return '-${_formatMoney(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de ternera'),
      ),
      body: FutureBuilder<_CalfDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final calf = data.calf;
          if (calf == null) {
            return const Center(child: Text('Ternera no encontrada'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (calf.imagePath != null && calf.imagePath!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    calf.imagePath!,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 240,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.terrain_outlined, size: 72),
                ),
              const SizedBox(height: 20),
              Text(
                calf.code,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _InfoRow(label: 'Nombre', value: calf.name),
              _InfoRow(label: 'Raza', value: calf.breed),
              _InfoRow(label: 'Fecha nacimiento', value: calf.birthDate),
              _InfoRow(label: 'Edad', value: calf.age),
              _InfoRow(
                label: 'Peso',
                value: calf.weight?.toStringAsFixed(1),
              ),
              _InfoRow(label: 'Salud', value: calf.healthStatus),
              _InfoRow(label: 'Vendedor', value: calf.sellerName),
              _InfoRow(label: 'Observaciones', value: calf.notes),
              const SizedBox(height: 12),
              Card(
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
                              _formatMoney(data.incomeTotal - data.investmentTotal),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Text('Balance'),
                            Text('Gastos: ${_formatMoney(data.investmentTotal)}'),
                            Text('Ingresos: ${_formatMoney(data.incomeTotal)}'),
                          ],
                        ),
                      ),
                      Text('${data.events.length} eventos'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openEventForm(),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar evento'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: () => _edit(calf),
                    icon: const Icon(Icons.edit),
                    tooltip: 'Editar ternera',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Historial',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (data.events.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Todavía no hay eventos registrados'),
                )
              else
                ...data.events.map(
                  (event) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.medical_services_outlined),
                      title: Text('${event.eventDate} • ${event.eventType}'),
                      subtitle: Text(
                        [
                          event.description,
                          _eventAmountLabel(event),
                          if ((event.nextFollowUpDate ?? '').isNotEmpty)
                            'Seguimiento: ${event.nextFollowUpDate}',
                        ].join(' • '),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openEventForm(event: event);
                          } else if (value == 'delete') {
                            _deleteEvent(event);
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
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CalfDetailData {
  final Calf? calf;
  final List<CalfEvent> events;
  final double investmentTotal;
  final double incomeTotal;

  const _CalfDetailData({
    required this.calf,
    required this.events,
    required this.investmentTotal,
    required this.incomeTotal,
  });
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(value?.isNotEmpty == true ? value! : 'Sin dato'),
        ],
      ),
    );
  }
}
