import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/calf_event.dart';

class CalfEventFormScreen extends StatefulWidget {
  final int calfId;
  final CalfEvent? event;

  const CalfEventFormScreen({
    super.key,
    required this.calfId,
    this.event,
  });

  @override
  State<CalfEventFormScreen> createState() => _CalfEventFormScreenState();
}

class _CalfEventFormScreenState extends State<CalfEventFormScreen> {
  static const _eventTypes = [
    'Compra',
    'Venta',
    'Medicina',
    'Vacuna',
    'Baño',
    'Monta',
    'Desparasitación',
    'Alimentación',
    'Enfermedad',
    'Tratamiento',
    'Insumo',
    'Observación',
  ];

  final _database = AppDatabase.instance;
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _eventDate;
  DateTime? _nextFollowUpDate;
  late String _eventType;
  late String _amountType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _eventDate = DateTime.tryParse(event?.eventDate ?? '') ?? DateTime.now();
    _nextFollowUpDate = DateTime.tryParse(event?.nextFollowUpDate ?? '');
    _eventType = event?.eventType ?? _eventTypes.first;
    _amountType = event?.amountType ?? _defaultAmountType(_eventType);
    _descriptionController.text = event?.description ?? '';
    _costController.text = event?.cost?.toString() ?? '';
    _notesController.text = event?.notes ?? '';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _defaultAmountType(String eventType) {
    if (eventType == 'Venta') return 'income';
    if (eventType == 'Monta' || eventType == 'Observación') return 'neutral';
    return 'expense';
  }

  String _amountTypeLabel(String value) {
    return switch (value) {
      'income' => 'Ingreso',
      'neutral' => 'Neutro',
      _ => 'Gasto',
    };
  }

  Future<void> _pickEventDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _eventDate = picked;
    });
  }

  Future<void> _pickFollowUpDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextFollowUpDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _nextFollowUpDate = picked;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    final event = CalfEvent(
      id: widget.event?.id,
      calfId: widget.calfId,
      eventDate: _formatDate(_eventDate),
      eventType: _eventType,
      description: _descriptionController.text.trim(),
      cost: _costController.text.trim().isEmpty
          ? null
          : double.tryParse(_costController.text.trim()),
      amountType: _amountType,
      nextFollowUpDate:
          _nextFollowUpDate == null ? null : _formatDate(_nextFollowUpDate!),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (widget.event == null) {
      await _database.insertCalfEvent(event);
    } else {
      await _database.updateCalfEvent(event);
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar evento' : 'Nuevo evento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: const Text('Fecha del evento'),
                subtitle: Text(_formatDate(_eventDate)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: _pickEventDate,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _eventType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de evento',
                  border: OutlineInputBorder(),
                ),
                items: _eventTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _eventType = value;
                    _amountType = _defaultAmountType(value);
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _amountType,
                decoration: const InputDecoration(
                  labelText: 'Movimiento económico',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'expense', child: Text('Gasto')),
                  DropdownMenuItem(value: 'income', child: Text('Ingreso')),
                  DropdownMenuItem(value: 'neutral', child: Text('Neutro')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _amountType = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  helperText: 'Se registrará como ${_amountTypeLabel(_amountType)}',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available),
                title: const Text('Próximo seguimiento'),
                subtitle: Text(
                  _nextFollowUpDate == null
                      ? 'Sin seguimiento programado'
                      : _formatDate(_nextFollowUpDate!),
                ),
                trailing: _nextFollowUpDate == null
                    ? const Icon(Icons.add)
                    : IconButton(
                        onPressed: () {
                          setState(() {
                            _nextFollowUpDate = null;
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
                onTap: _pickFollowUpDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas',
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
                label: Text(isEditing ? 'Guardar cambios' : 'Guardar evento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
