import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/paddock.dart';
import '../models/rotation_session.dart';

class RotationMoveScreen extends StatefulWidget {
  const RotationMoveScreen({super.key});

  @override
  State<RotationMoveScreen> createState() => _RotationMoveScreenState();
}

class _RotationMoveScreenState extends State<RotationMoveScreen> {
  final _database = AppDatabase.instance;
  final _formKey = GlobalKey<FormState>();
  final _plannedDaysController = TextEditingController();
  final _notesController = TextEditingController();

  late Future<_RotationFormData> _future;
  int? _selectedPaddockId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_RotationFormData> _load() async {
    final paddocks = await _database.getAllPaddocks();
    final activeSession = await _database.getActiveRotationSession();
    final availablePaddocks = activeSession == null
        ? paddocks
        : paddocks.where((p) => p.id != activeSession.paddockId).toList();
    _selectedPaddockId = availablePaddocks.isNotEmpty ? availablePaddocks.first.id : null;
    return _RotationFormData(
      paddocks: paddocks,
      activeSession: activeSession,
    );
  }

  Future<void> _save(_RotationFormData data) async {
    if (!_formKey.currentState!.validate()) return;
    final plannedDays = int.tryParse(_plannedDaysController.text.trim());
    if (plannedDays == null || plannedDays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un número válido de días')),
      );
      return;
    }
    if (_selectedPaddockId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un potrero')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    final activeSession = data.activeSession;
    if (activeSession == null) {
      await _database.startRotation(
        paddockId: _selectedPaddockId!,
        plannedDays: plannedDays,
        notes: notes,
      );
    } else {
      await _database.moveHerd(
        fromPaddockId: activeSession.paddockId,
        toPaddockId: _selectedPaddockId!,
        plannedDays: plannedDays,
        notes: notes,
      );
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _plannedDaysController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimiento de pastoreo'),
      ),
      body: FutureBuilder<_RotationFormData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final paddocks = data.paddocks;
          if (paddocks.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Primero crea al menos un potrero'),
              ),
            );
          }

          final activeSession = data.activeSession;
          final activePaddock = activeSession == null
              ? null
              : paddocks.where((p) => p.id == activeSession.paddockId).isNotEmpty
                  ? paddocks.firstWhere((p) => p.id == activeSession.paddockId)
                  : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activeSession != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.play_arrow),
                        title: const Text('Potrero actual'),
                        subtitle: Text(activePaddock?.name ?? 'Sin nombre'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedPaddockId,
                    decoration: const InputDecoration(
                      labelText: 'Potrero destino',
                      border: OutlineInputBorder(),
                    ),
                    items: paddocks
                        .where((p) => activeSession == null || p.id != activeSession.paddockId)
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPaddockId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _plannedDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Días de pastoreo',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Ingresa días válidos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notas del movimiento',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : () => _save(data),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_alt),
                    label: Text(activeSession == null ? 'Iniciar pastoreo' : 'Registrar movimiento'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RotationFormData {
  final List<Paddock> paddocks;
  final RotationSession? activeSession;

  const _RotationFormData({
    required this.paddocks,
    required this.activeSession,
  });
}
