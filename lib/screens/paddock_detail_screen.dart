import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/paddock.dart';
import '../models/paddock_event.dart';
import 'paddock_event_form_screen.dart';
import 'paddock_form_screen.dart';

class PaddockDetailScreen extends StatefulWidget {
  final int paddockId;

  const PaddockDetailScreen({super.key, required this.paddockId});

  @override
  State<PaddockDetailScreen> createState() => _PaddockDetailScreenState();
}

class _PaddockDetailScreenState extends State<PaddockDetailScreen> {
  final _database = AppDatabase.instance;
  late Future<_PaddockDetailData> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _loadData();
  }

  Future<_PaddockDetailData> _loadData() async {
    final paddock = await _database.getPaddockById(widget.paddockId);
    final events = await _database.getPaddockEvents(widget.paddockId);
    final expenseTotal = await _database.getPaddockExpenseTotal(widget.paddockId);
    final incomeTotal = await _database.getPaddockIncomeTotal(widget.paddockId);
    return _PaddockDetailData(
      paddock: paddock,
      events: events,
      expenseTotal: expenseTotal,
      incomeTotal: incomeTotal,
    );
  }

  Future<void> _edit(Paddock paddock) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaddockFormScreen(paddock: paddock)),
    );
    if (!mounted) return;
    setState(_load);
  }

  Future<void> _openEventForm({PaddockEvent? event}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaddockEventFormScreen(
          paddockId: widget.paddockId,
          event: event,
        ),
      ),
    );
    if (!mounted) return;
    setState(_load);
  }

  Future<void> _deleteEvent(PaddockEvent event) async {
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
    await _database.deletePaddockEvent(event.id!);
    if (!mounted) return;
    setState(_load);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evento eliminado')),
    );
  }

  String _formatMoney(double value) {
    return '\$${value.toStringAsFixed(0)}';
  }

  String _eventAmountLabel(PaddockEvent event) {
    final value = event.cost;
    if (value == null) return 'Sin valor';
    if (event.amountType == 'income') return '+${_formatMoney(value)}';
    if (event.amountType == 'neutral') return _formatMoney(value);
    return '-${_formatMoney(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de potrero')),
      body: FutureBuilder<_PaddockDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final paddock = data.paddock;
          if (paddock == null) {
            return const Center(child: Text('Potrero no encontrado'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (paddock.imagePath != null && paddock.imagePath!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    paddock.imagePath!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 220,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.grass_outlined, size: 72),
                ),
              const SizedBox(height: 20),
              Text(paddock.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              _InfoRow(label: 'Descripción', value: paddock.description),
              _InfoRow(label: 'Área', value: paddock.area),
              _InfoRow(label: 'Tiempo de pastoreo', value: paddock.grazingTime),
              _InfoRow(label: 'Días de recuperación', value: paddock.recoveryDays?.toString()),
              _InfoRow(label: 'Observaciones', value: paddock.notes),
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
                              _formatMoney(data.incomeTotal - data.expenseTotal),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Text('Balance del potrero'),
                            Text('Gastos: ${_formatMoney(data.expenseTotal)}'),
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
                    onPressed: () => _edit(paddock),
                    icon: const Icon(Icons.edit),
                    tooltip: 'Editar potrero',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Historial', style: Theme.of(context).textTheme.titleMedium),
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
                      leading: const Icon(Icons.event_note_outlined),
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
    );
  }
}

class _PaddockDetailData {
  final Paddock? paddock;
  final List<PaddockEvent> events;
  final double expenseTotal;
  final double incomeTotal;

  const _PaddockDetailData({
    required this.paddock,
    required this.events,
    required this.expenseTotal,
    required this.incomeTotal,
  });
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value?.isNotEmpty == true ? value! : 'Sin dato'),
        ],
      ),
    );
  }
}
