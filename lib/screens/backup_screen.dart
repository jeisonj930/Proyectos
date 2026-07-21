import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/app_database.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _database = AppDatabase.instance;
  final _importController = TextEditingController();
  String? _exportedJson;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _loadExport();
  }

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  Future<void> _loadExport() async {
    final json = await _database.exportBackupJson();
    if (!mounted) return;
    setState(() {
      _exportedJson = json;
    });
  }

  Future<void> _copyBackup() async {
    final json = _exportedJson;
    if (json == null) return;

    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Respaldo copiado al portapapeles')),
    );
  }

  Future<void> _importBackup() async {
    final backup = _importController.text.trim();
    if (backup.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pega primero el respaldo')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar respaldo'),
        content: const Text(
          'Esta acción reemplaza los datos actuales de este navegador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _working = true;
    });

    try {
      await _database.importBackupJson(backup);
      await _loadExport();
      _importController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Respaldo restaurado')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El respaldo no tiene un formato válido')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exportedJson = _exportedJson;

    return Scaffold(
      appBar: AppBar(title: const Text('Respaldo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Exportar datos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Copia este respaldo y guárdalo en un lugar seguro para restaurarlo después.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: exportedJson == null ? null : _copyBackup,
            icon: const Icon(Icons.copy),
            label: const Text('Copiar respaldo'),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                exportedJson ?? 'Generando respaldo...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Importar datos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Pega aquí un respaldo anterior para restaurar terneras, potreros, eventos, gastos, pagos y fotos.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _importController,
            minLines: 6,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Respaldo JSON',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _working ? null : _importBackup,
            icon: _working
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.restore),
            label: const Text('Restaurar respaldo'),
          ),
        ],
      ),
    );
  }
}
