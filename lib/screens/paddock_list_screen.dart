import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/paddock.dart';
import '../models/paddock_state.dart';
import 'paddock_detail_screen.dart';
import 'paddock_form_screen.dart';

class PaddockListScreen extends StatefulWidget {
  const PaddockListScreen({super.key});

  @override
  State<PaddockListScreen> createState() => _PaddockListScreenState();
}

class _PaddockListScreenState extends State<PaddockListScreen> {
  final _database = AppDatabase.instance;
  late Future<List<PaddockState>> _paddocksFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _paddocksFuture = _database.getPaddockStates();
  }

  Future<void> _openForm({Paddock? paddock}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaddockFormScreen(paddock: paddock),
      ),
    );
    if (!mounted) return;
    setState(_reload);
  }

  Future<void> _deletePaddock(Paddock paddock) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar potrero'),
        content: Text('¿Seguro que quieres eliminar ${paddock.name}?'),
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

    await _database.deletePaddock(paddock.id!);
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Potrero eliminado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Potreros'),
      ),
      body: FutureBuilder<List<PaddockState>>(
        future: _paddocksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final paddocks = snapshot.data ?? [];
          if (paddocks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.grass_outlined, size: 72),
                    const SizedBox(height: 12),
                    const Text(
                      'Todavía no hay potreros registrados',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar potrero'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: paddocks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final state = paddocks[index];
              final paddock = state.paddock;
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundImage:
                        paddock.imagePath != null && paddock.imagePath!.isNotEmpty
                            ? NetworkImage(paddock.imagePath!)
                            : null,
                    child: paddock.imagePath == null || paddock.imagePath!.isEmpty
                        ? const Icon(Icons.grass_outlined)
                        : null,
                  ),
                  title: Text(paddock.name),
                  subtitle: Text(
                    [
                      state.status,
                      if ((paddock.description ?? '').isNotEmpty)
                        paddock.description,
                      if ((paddock.area ?? '').isNotEmpty) paddock.area,
                      if ((paddock.grazingTime ?? '').isNotEmpty)
                        paddock.grazingTime,
                      if (paddock.expenses != null)
                        '\$${paddock.expenses!.toStringAsFixed(0)}',
                    ].whereType<String>().join(' • '),
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PaddockDetailScreen(paddockId: paddock.id!),
                      ),
                    );
                    if (!mounted) return;
                    setState(_reload);
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openForm(paddock: paddock);
                      } else if (value == 'delete') {
                        _deletePaddock(paddock);
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
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo potrero'),
      ),
    );
  }

}
