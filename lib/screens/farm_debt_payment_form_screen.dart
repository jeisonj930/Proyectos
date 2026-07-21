import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/farm_debt_payment.dart';

class FarmDebtPaymentFormScreen extends StatefulWidget {
  final FarmDebtPayment? payment;

  const FarmDebtPaymentFormScreen({super.key, this.payment});

  @override
  State<FarmDebtPaymentFormScreen> createState() => _FarmDebtPaymentFormScreenState();
}

class _FarmDebtPaymentFormScreenState extends State<FarmDebtPaymentFormScreen> {
  static const _paymentMethods = [
    'Efectivo',
    'Transferencia',
    'Cheque',
    'Consignación',
    'Otro',
  ];

  final _database = AppDatabase.instance;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _paymentDate;
  String? _paymentMethod;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final payment = widget.payment;
    _paymentDate = DateTime.tryParse(payment?.paymentDate ?? '') ?? DateTime.now();
    _amountController.text = payment?.amount.toString() ?? '';
    _descriptionController.text = payment?.description ?? '';
    _paymentMethod = payment?.paymentMethod;
    _notesController.text = payment?.notes ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _paymentDate = picked;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    final payment = FarmDebtPayment(
      id: widget.payment?.id,
      paymentDate: _formatDate(_paymentDate),
      amount: double.tryParse(_amountController.text.trim()) ?? 0,
      description: _emptyToNull(_descriptionController.text),
      paymentMethod: _paymentMethod,
      notes: _emptyToNull(_notesController.text),
    );

    if (widget.payment == null) {
      await _database.insertFarmDebtPayment(payment);
    } else {
      await _database.updateFarmDebtPayment(payment);
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.payment != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar abono' : 'Nuevo abono'),
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
                title: const Text('Fecha del abono'),
                subtitle: Text(_formatDate(_paymentDate)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor del abono',
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
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ejemplo: abono inicial',
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
                label: Text(isEditing ? 'Guardar cambios' : 'Guardar abono'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
