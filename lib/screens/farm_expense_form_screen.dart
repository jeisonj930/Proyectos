import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/farm_expense.dart';

class FarmExpenseFormScreen extends StatefulWidget {
  final FarmExpense? expense;

  const FarmExpenseFormScreen({super.key, this.expense});

  @override
  State<FarmExpenseFormScreen> createState() => _FarmExpenseFormScreenState();
}

class _FarmExpenseFormScreenState extends State<FarmExpenseFormScreen> {
  static const _categories = [
    'Sal mineral',
    'Abonos',
    'Estacones',
    'Alambrado',
    'Mangueras',
    'Herramientas',
    'Mano de obra',
    'Transporte',
    'Arriendo / costo finca',
    'Servicios',
    'Veterinaria general',
    'Otros',
  ];

  static const _paymentMethods = [
    'Efectivo',
    'Transferencia',
    'Tarjeta',
    'Crédito',
    'Otro',
  ];

  final _database = AppDatabase.instance;
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _expenseDate;
  late String _category;
  String? _paymentMethod;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _expenseDate = DateTime.tryParse(expense?.expenseDate ?? '') ?? DateTime.now();
    _category = expense?.category ?? _categories.first;
    _paymentMethod = expense?.paymentMethod;
    _descriptionController.text = expense?.description ?? '';
    _amountController.text = expense?.amount.toString() ?? '';
    _supplierController.text = expense?.supplier ?? '';
    _notesController.text = expense?.notes ?? '';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _expenseDate = picked;
    });
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    final expense = FarmExpense(
      id: widget.expense?.id,
      expenseDate: _formatDate(_expenseDate),
      category: _category,
      description: _descriptionController.text.trim(),
      amount: double.tryParse(_amountController.text.trim()) ?? 0,
      supplier: _emptyToNull(_supplierController.text),
      paymentMethod: _paymentMethod,
      notes: _emptyToNull(_notesController.text),
    );

    if (widget.expense == null) {
      await _database.insertFarmExpense(expense);
    } else {
      await _database.updateFarmExpense(expense);
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar gasto' : 'Nuevo gasto'),
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
                title: const Text('Fecha'),
                subtitle: Text(_formatDate(_expenseDate)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _category = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
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
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa un valor válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Proveedor / persona',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Forma de pago',
                  border: OutlineInputBorder(),
                ),
                items: _paymentMethods
                    .map(
                      (method) => DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value;
                  });
                },
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
                label: Text(isEditing ? 'Guardar cambios' : 'Guardar gasto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
