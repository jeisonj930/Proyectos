import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../database/app_database.dart';
import '../models/calf.dart';

class CalfFormScreen extends StatefulWidget {
  final Calf? calf;

  const CalfFormScreen({super.key, this.calf});

  @override
  State<CalfFormScreen> createState() => _CalfFormScreenState();
}

class _CalfFormScreenState extends State<CalfFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _database = AppDatabase.instance;
  final _picker = ImagePicker();

  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _healthStatusController;
  late final TextEditingController _sellerNameController;
  late final TextEditingController _notesController;

  String? _imagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final calf = widget.calf;
    _codeController = TextEditingController(text: calf?.code ?? '');
    _nameController = TextEditingController(text: calf?.name ?? '');
    _breedController = TextEditingController(text: calf?.breed ?? '');
    _birthDateController = TextEditingController(text: calf?.birthDate ?? '');
    _ageController = TextEditingController(text: calf?.age ?? '');
    _weightController =
        TextEditingController(text: calf?.weight?.toString() ?? '');
    _healthStatusController =
        TextEditingController(text: calf?.healthStatus ?? '');
    _sellerNameController =
        TextEditingController(text: calf?.sellerName ?? '');
    _notesController = TextEditingController(text: calf?.notes ?? '');
    _imagePath = calf?.imagePath;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    _birthDateController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _healthStatusController.dispose();
    _sellerNameController.dispose();
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

    final calf = Calf(
      id: widget.calf?.id,
      code: _codeController.text.trim(),
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      breed:
          _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
      birthDate: _birthDateController.text.trim().isEmpty
          ? null
          : _birthDateController.text.trim(),
      age: _ageController.text.trim().isEmpty ? null : _ageController.text.trim(),
      weight: _weightController.text.trim().isEmpty
          ? null
          : double.tryParse(_weightController.text.trim()),
      healthStatus: _healthStatusController.text.trim().isEmpty
          ? null
          : _healthStatusController.text.trim(),
      sellerName: _sellerNameController.text.trim().isEmpty
          ? null
          : _sellerNameController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      imagePath: _imagePath,
    );

    if (widget.calf == null) {
      await _database.insertCalf(calf);
    } else {
      await _database.updateCalf(calf);
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.calf != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar ternera' : 'Nueva ternera'),
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
                    width: 140,
                    height: 140,
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
                              Text('Agregar foto'),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Código o identificación',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el código';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(
                  labelText: 'Raza',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birthDateController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de nacimiento',
                  hintText: 'YYYY-MM-DD',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Edad',
                  hintText: 'Ejemplo: 3 meses',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Peso',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _healthStatusController,
                decoration: const InputDecoration(
                  labelText: 'Estado de salud',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sellerNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del vendedor',
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
                label: Text(isEditing ? 'Guardar cambios' : 'Guardar ternera'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
