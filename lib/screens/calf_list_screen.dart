import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/calf.dart';
import 'calf_detail_screen.dart';
import 'calf_form_screen.dart';

class CalfListScreen extends StatefulWidget {
  const CalfListScreen({super.key});

  @override
  State<CalfListScreen> createState() => _CalfListScreenState();
}

class _CalfListScreenState extends State<CalfListScreen> {
  final AppDatabase _database = AppDatabase.instance;
  late Future<List<Calf>> _calvesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _calvesFuture = _database.getAllCalves();
  }

  Future<void> _openForm({Calf? calf}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalfFormScreen(calf: calf),
      ),
    );
    setState(_reload);
  }

  Future<void> _deleteCalf(Calf calf) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ternera'),
        content: Text('¿Seguro que quieres eliminar ${calf.code}?'),
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

    await _database.deleteCalf(calf.id!);
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ternera eliminada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Terneras'),
      ),
      body: FutureBuilder<List<Calf>>(
        future: _calvesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final calves = snapshot.data ?? [];
          if (calves.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pets_outlined, size: 72),
                    const SizedBox(height: 12),
                    const Text(
                      'Todavía no hay terneras registradas',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar ternera'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: calves.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final calf = calves[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundImage:
                        calf.imagePath != null && calf.imagePath!.isNotEmpty
                            ? NetworkImage(calf.imagePath!)
                            : null,
                    child: calf.imagePath == null || calf.imagePath!.isEmpty
                        ? const Icon(Icons.terrain_outlined)
                        : null,
                  ),
                  title: Text(calf.code),
                  subtitle: Text(
                    [
                      if ((calf.name ?? '').isNotEmpty) calf.name,
                      if ((calf.breed ?? '').isNotEmpty) calf.breed,
                      if ((calf.healthStatus ?? '').isNotEmpty) calf.healthStatus,
                    ].whereType<String>().join(' • '),
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CalfDetailScreen(calfId: calf.id!),
                      ),
                    );
                    setState(_reload);
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openForm(calf: calf);
                      } else if (value == 'delete') {
                        _deleteCalf(calf);
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
        label: const Text('Nueva ternera'),
      ),
    );
  }

}
