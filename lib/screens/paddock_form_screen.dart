import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../database/app_database.dart';
import '../models/paddock.dart';

class PaddockFormScreen extends StatefulWidget {
  final Paddock? paddock;

  const PaddockFormScreen({super.key, this.paddock});

  @override
  State<PaddockFormScreen> createState() => _PaddockFormScreenState();
}

class _PaddockFormScreenState extends State<PaddockFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _database = AppDatabase.instance;
  final _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _areaController;
  late final TextEditingController _grazingTimeController;
  late final TextEditingController _fertilizersController;
  late final TextEditingController _expensesController;
  late final TextEditingController _recoveryDaysController;
  late final TextEditingController _notesController;

  String? _imagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final paddock = widget.paddock;
    _nameController = TextEditingController(text: paddock?.name ?? '');
    _descriptionController =
        TextEditingController(text: paddock?.description ?? '');
    _areaController = TextEditingController(text: paddock?.area ?? '');
    _grazingTimeController =
        TextEditingController(text: paddock?.grazingTime ?? '');
    _fertilizersController =
        TextEditingController(text: paddock?.fertilizers ?? '');
    _expensesController =
        TextEditingController(text: paddock?.expenses?.toString() ?? '');
    _recoveryDaysController =
        TextEditingController(text: paddock?.recoveryDays?.toString() ?? '');
    _notesController = TextEditingController(text: paddock?.notes ?? '');
    _imagePath = paddock?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _areaController.dispose();
    _grazingTimeController.dispose();
    _fertilizersController.dispose();
    _expensesController.dispose();
    _recoveryDaysController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final mimeType = picked.mimeType ?? 'image/jpeg';
    final imageData = 'data:$mimeType;base64,${base64Encode(bytes)}';

    setState(() {
      _imagePath = imageData;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    final paddock = Paddock(
      id: widget.paddock?.id,
      name: _nameController.text.trim(),
      description: _emptyToNull(_descriptionController.text),
      area: _emptyToNull(_areaController.text),
      grazingTime: _emptyToNull(_grazingTimeController.text),
      fertilizers: _emptyToNull(_fertilizersController.text),
      expenses: _expensesController.text.trim().isEmpty
          ? null
          : double.tryParse(_expensesController.text.trim()),
      recoveryDays: _recoveryDaysController.text.trim().isEmpty
          ? null
          : int.tryParse(_recoveryDaysController.text.trim()),
      notes: _emptyToNull(_notesController.text),
      imagePath: _imagePath,
    );

    if (widget.paddock == null) {
      await _database.insertPaddock(paddock);
    } else {
      await _database.updatePaddock(paddock);
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    Navigator.pop(context);
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.paddock != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar potrero' : 'Nuevo potrero'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      image: _imagePath != null
                          ? DecorationImage(
                              image: NetworkImage(_imagePath!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imagePath == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_camera_outlined, size: 40),
                              SizedBox(height: 8),
                              Text('Agregar foto del potrero'),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del potrero',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre del potrero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción del potrero',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'Área',
                  hintText: 'Ejemplo: 2 hectáreas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _grazingTimeController,
                decoration: const InputDecoration(
                  labelText: 'Tiempo de pastoreo',
                  hintText: 'Ejemplo: 5 días',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fertilizersController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Abonos usados',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expensesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Gastos generales',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _recoveryDaysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Días de recuperación',
                  hintText: 'Ejemplo: 21',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isEditing ? 'Guardar cambios' : 'Guardar potrero'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
