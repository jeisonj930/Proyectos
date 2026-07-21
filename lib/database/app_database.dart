import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/calf.dart';
import '../models/calf_event.dart';
import '../models/dashboard_data.dart';
import '../models/farm_debt_payment.dart';
import '../models/farm_debt_summary.dart';
import '../models/farm_expense.dart';
import '../models/paddock.dart';
import '../models/paddock_event.dart';
import '../models/paddock_state.dart';
import '../models/rotation_movement.dart';
import '../models/rotation_session.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const _storageKey = 'control_finca_data_v1';

  final List<Calf> _calves = [];
  final List<CalfEvent> _calfEvents = [];
  final List<Paddock> _paddocks = [];
  final List<PaddockEvent> _paddockEvents = [];
  final List<FarmExpense> _farmExpenses = [];
  final List<FarmDebtPayment> _farmDebtPayments = [];
  final List<RotationSession> _rotationSessions = [];
  final List<RotationMovement> _rotationMovements = [];

  int _nextCalfId = 1;
  int _nextCalfEventId = 1;
  int _nextPaddockId = 1;
  int _nextPaddockEventId = 1;
  int _nextFarmExpenseId = 1;
  int _nextFarmDebtPaymentId = 1;
  int _nextRotationSessionId = 1;
  int _nextRotationMovementId = 1;
  double _farmDebtTotalValue = 0;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;

    final preferences = await SharedPreferences.getInstance();
    final rawData = preferences.getString(_storageKey);
    if (rawData == null || rawData.isEmpty) {
      _loaded = true;
      return;
    }

    final data = jsonDecode(rawData) as Map<String, dynamic>;
    _calves
      ..clear()
      ..addAll(_readList(data, 'calves').map(Calf.fromMap));
    _calfEvents
      ..clear()
      ..addAll(_readList(data, 'calf_events').map(CalfEvent.fromMap));
    _paddocks
      ..clear()
      ..addAll(_readList(data, 'paddocks').map(Paddock.fromMap));
    _paddockEvents
      ..clear()
      ..addAll(_readList(data, 'paddock_events').map(PaddockEvent.fromMap));
    _farmExpenses
      ..clear()
      ..addAll(_readList(data, 'farm_expenses').map(FarmExpense.fromMap));
    _farmDebtPayments
      ..clear()
      ..addAll(_readList(data, 'farm_debt_payments').map(FarmDebtPayment.fromMap));
    _rotationSessions
      ..clear()
      ..addAll(_readList(data, 'rotation_sessions').map(RotationSession.fromMap));
    _rotationMovements
      ..clear()
      ..addAll(_readList(data, 'rotation_movements').map(RotationMovement.fromMap));

    _nextCalfId = data['next_calf_id'] as int? ?? _nextId(_calves.map((item) => item.id));
    _nextCalfEventId =
        data['next_calf_event_id'] as int? ?? _nextId(_calfEvents.map((item) => item.id));
    _nextPaddockId =
        data['next_paddock_id'] as int? ?? _nextId(_paddocks.map((item) => item.id));
    _nextPaddockEventId = data['next_paddock_event_id'] as int? ??
        _nextId(_paddockEvents.map((item) => item.id));
    _nextFarmExpenseId = data['next_farm_expense_id'] as int? ??
        _nextId(_farmExpenses.map((item) => item.id));
    _nextFarmDebtPaymentId = data['next_farm_debt_payment_id'] as int? ??
        _nextId(_farmDebtPayments.map((item) => item.id));
    _nextRotationSessionId = data['next_rotation_session_id'] as int? ??
        _nextId(_rotationSessions.map((item) => item.id));
    _nextRotationMovementId = data['next_rotation_movement_id'] as int? ??
        _nextId(_rotationMovements.map((item) => item.id));
    _farmDebtTotalValue = (data['farm_debt_total_value'] as num?)?.toDouble() ?? 0;
    _loaded = true;
  }

  List<Map<String, Object?>> _readList(Map<String, dynamic> data, String key) {
    return (data[key] as List? ?? const [])
        .map((item) => (item as Map).cast<String, Object?>())
        .toList();
  }

  int _nextId(Iterable<int?> ids) {
    final validIds = ids.whereType<int>();
    if (validIds.isEmpty) return 1;
    return validIds.reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(_toBackupMap()));
  }

  Map<String, Object?> _toBackupMap() {
    return {
      'calves': _calves.map((item) => item.toMap()).toList(),
      'calf_events': _calfEvents.map((item) => item.toMap()).toList(),
      'paddocks': _paddocks.map((item) => item.toMap()).toList(),
      'paddock_events': _paddockEvents.map((item) => item.toMap()).toList(),
      'farm_expenses': _farmExpenses.map((item) => item.toMap()).toList(),
      'farm_debt_payments': _farmDebtPayments.map((item) => item.toMap()).toList(),
      'rotation_sessions': _rotationSessions.map((item) => item.toMap()).toList(),
      'rotation_movements': _rotationMovements.map(_rotationMovementToMap).toList(),
      'farm_debt_total_value': _farmDebtTotalValue,
      'next_calf_id': _nextCalfId,
      'next_calf_event_id': _nextCalfEventId,
      'next_paddock_id': _nextPaddockId,
      'next_paddock_event_id': _nextPaddockEventId,
      'next_farm_expense_id': _nextFarmExpenseId,
      'next_farm_debt_payment_id': _nextFarmDebtPaymentId,
      'next_rotation_session_id': _nextRotationSessionId,
      'next_rotation_movement_id': _nextRotationMovementId,
    };
  }

  Map<String, Object?> _rotationMovementToMap(RotationMovement movement) {
    return {
      'id': movement.id,
      'from_paddock_id': movement.fromPaddockId,
      'to_paddock_id': movement.toPaddockId,
      'from_paddock_name': movement.fromPaddockName,
      'to_paddock_name': movement.toPaddockName,
      'moved_at': movement.movedAt,
      'notes': movement.notes,
    };
  }

  Future<List<Calf>> getAllCalves() async {
    await _ensureLoaded();
    return List.unmodifiable(_calves);
  }

  Future<Calf?> getCalfById(int id) async {
    await _ensureLoaded();
    return _calves.where((calf) => calf.id == id).firstOrNull;
  }

  Future<int> insertCalf(Calf calf) async {
    await _ensureLoaded();
    final id = _nextCalfId++;
    _calves.insert(0, calf.copyWith(id: id));
    await _save();
    return id;
  }

  Future<int> updateCalf(Calf calf) async {
    await _ensureLoaded();
    final index = _calves.indexWhere((item) => item.id == calf.id);
    if (index == -1) return 0;
    _calves[index] = calf;
    await _save();
    return 1;
  }

  Future<int> deleteCalf(int id) async {
    await _ensureLoaded();
    _calfEvents.removeWhere((event) => event.calfId == id);
    final before = _calves.length;
    _calves.removeWhere((calf) => calf.id == id);
    await _save();
    return before - _calves.length;
  }

  Future<List<CalfEvent>> getCalfEvents(int calfId) async {
    await _ensureLoaded();
    return _calfEvents.where((event) => event.calfId == calfId).toList();
  }

  Future<double> getCalfInvestmentTotal(int calfId) async {
    await _ensureLoaded();
    return _calfEvents
        .where((event) => event.calfId == calfId && event.amountType == 'expense')
        .fold<double>(0.0, (sum, event) => sum + (event.cost ?? 0));
  }

  Future<double> getCalfIncomeTotal(int calfId) async {
    await _ensureLoaded();
    return _calfEvents
        .where((event) => event.calfId == calfId && event.amountType == 'income')
        .fold<double>(0.0, (sum, event) => sum + (event.cost ?? 0));
  }

  Future<double> getTotalCalfInvestment() async {
    await _ensureLoaded();
    return _calfEvents
        .where((event) => event.amountType == 'expense')
        .fold<double>(0.0, (sum, event) => sum + (event.cost ?? 0));
  }

  Future<double> getTotalCalfIncome() async {
    await _ensureLoaded();
    return _calfEvents
        .where((event) => event.amountType == 'income')
        .fold<double>(0.0, (sum, event) => sum + (event.cost ?? 0));
  }

  Future<int> getPendingCalfFollowUpsCount() async {
    await _ensureLoaded();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return _calfEvents
        .where(
          (event) =>
              event.nextFollowUpDate != null &&
              event.nextFollowUpDate!.compareTo(today) <= 0,
        )
        .length;
  }

  Future<int> insertCalfEvent(CalfEvent event) async {
    await _ensureLoaded();
    final id = _nextCalfEventId++;
    _calfEvents.insert(
      0,
      CalfEvent(
        id: id,
        calfId: event.calfId,
        eventDate: event.eventDate,
        eventType: event.eventType,
        description: event.description,
        cost: event.cost,
        amountType: event.amountType,
        nextFollowUpDate: event.nextFollowUpDate,
        notes: event.notes,
      ),
    );
    await _save();
    return id;
  }

  Future<int> updateCalfEvent(CalfEvent event) async {
    await _ensureLoaded();
    final index = _calfEvents.indexWhere((item) => item.id == event.id);
    if (index == -1) return 0;
    _calfEvents[index] = event;
    await _save();
    return 1;
  }

  Future<int> deleteCalfEvent(int id) async {
    await _ensureLoaded();
    final before = _calfEvents.length;
    _calfEvents.removeWhere((event) => event.id == id);
    await _save();
    return before - _calfEvents.length;
  }

  Future<List<Paddock>> getAllPaddocks() async {
    await _ensureLoaded();
    return List.unmodifiable(_paddocks);
  }

  Future<Paddock?> getPaddockById(int id) async {
    await _ensureLoaded();
    return _paddocks.where((paddock) => paddock.id == id).firstOrNull;
  }

  Future<int> insertPaddock(Paddock paddock) async {
    await _ensureLoaded();
    final id = _nextPaddockId++;
    _paddocks.insert(
      0,
      Paddock(
        id: id,
        name: paddock.name,
        description: paddock.description,
        area: paddock.area,
        grazingTime: paddock.grazingTime,
        fertilizers: paddock.fertilizers,
        expenses: paddock.expenses,
        notes: paddock.notes,
        recoveryDays: paddock.recoveryDays,
        imagePath: paddock.imagePath,
      ),
    );
    await _save();
    return id;
  }

  Future<int> updatePaddock(Paddock paddock) async {
    await _ensureLoaded();
    final index = _paddocks.indexWhere((item) => item.id == paddock.id);
    if (index == -1) return 0;
    _paddocks[index] = paddock;
    await _save();
    return 1;
  }

  Future<int> deletePaddock(int id) async {
    await _ensureLoaded();
    _paddockEvents.removeWhere((event) => event.paddockId == id);
    final before = _paddocks.length;
    _paddocks.removeWhere((paddock) => paddock.id == id);
    await _save();
    return before - _paddocks.length;
  }

  Future<List<PaddockEvent>> getPaddockEvents(int paddockId) async {
    await _ensureLoaded();
    return _paddockEvents.where((event) => event.paddockId == paddockId).toList();
  }

  Future<double> getPaddockExpenseTotal(int paddockId) async {
    await _ensureLoaded();
    return _paddockEvents
        .where((event) => event.paddockId == paddockId && event.amountType == 'expense')
        .fold<double>(0.0, (sum, event) => sum + (event.cost ?? 0));
  }

  Future<double> getPaddockIncomeTotal(int paddockId) async {
    await _ensureLoaded();
    return _paddockEvents
        .where((event) => event.paddockId == paddockId && event.amountType == 'income')
        .fold<double>(0.0, (sum, event) => sum + (event.cost ?? 0));
  }

  Future<double> getTotalPaddockExpenses() async {
    await _ensureLoaded();
    return _paddockEvents
        .where((event) => event.amountType == 'expense')
        .fold<double>(0.0, (sum, event) => sum + (event.cost ?? 0));
  }

  Future<double> getTotalPaddockIncome() async {
    await _ensureLoaded();
    return _paddockEvents
        .where((event) => event.amountType == 'income')
        .fold<double>(0.0, (sum, event) => sum + (event.cost ?? 0));
  }

  Future<int> insertPaddockEvent(PaddockEvent event) async {
    await _ensureLoaded();
    final id = _nextPaddockEventId++;
    _paddockEvents.insert(
      0,
      PaddockEvent(
        id: id,
        paddockId: event.paddockId,
        eventDate: event.eventDate,
        eventType: event.eventType,
        description: event.description,
        cost: event.cost,
        amountType: event.amountType,
        nextFollowUpDate: event.nextFollowUpDate,
        notes: event.notes,
      ),
    );
    await _save();
    return id;
  }

  Future<int> updatePaddockEvent(PaddockEvent event) async {
    await _ensureLoaded();
    final index = _paddockEvents.indexWhere((item) => item.id == event.id);
    if (index == -1) return 0;
    _paddockEvents[index] = event;
    await _save();
    return 1;
  }

  Future<int> deletePaddockEvent(int id) async {
    await _ensureLoaded();
    final before = _paddockEvents.length;
    _paddockEvents.removeWhere((event) => event.id == id);
    await _save();
    return before - _paddockEvents.length;
  }

  Future<List<PaddockState>> getPaddockStates() async {
    await _ensureLoaded();
    return _paddocks.map((paddock) {
      final active = _rotationSessions
          .where((session) => session.paddockId == paddock.id && session.endedAt == null)
          .firstOrNull;
      if (active != null) {
        return PaddockState(
          paddock: paddock,
          status: 'En uso',
          activeSession: active,
        );
      }
      return PaddockState(paddock: paddock, status: 'Disponible');
    }).toList();
  }

  Future<List<FarmExpense>> getAllFarmExpenses() async {
    await _ensureLoaded();
    return List.unmodifiable(_farmExpenses);
  }

  Future<double> getTotalFarmExpenses() async {
    await _ensureLoaded();
    return _farmExpenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  Future<int> insertFarmExpense(FarmExpense expense) async {
    await _ensureLoaded();
    final id = _nextFarmExpenseId++;
    _farmExpenses.insert(
      0,
      FarmExpense(
        id: id,
        expenseDate: expense.expenseDate,
        category: expense.category,
        description: expense.description,
        amount: expense.amount,
        supplier: expense.supplier,
        paymentMethod: expense.paymentMethod,
        notes: expense.notes,
      ),
    );
    await _save();
    return id;
  }

  Future<int> updateFarmExpense(FarmExpense expense) async {
    await _ensureLoaded();
    final index = _farmExpenses.indexWhere((item) => item.id == expense.id);
    if (index == -1) return 0;
    _farmExpenses[index] = expense;
    await _save();
    return 1;
  }

  Future<int> deleteFarmExpense(int id) async {
    await _ensureLoaded();
    final before = _farmExpenses.length;
    _farmExpenses.removeWhere((expense) => expense.id == id);
    await _save();
    return before - _farmExpenses.length;
  }

  Future<FarmDebtSummary> getFarmDebtSummary() async {
    await _ensureLoaded();
    final paid = await getFarmDebtPaidValue();
    return FarmDebtSummary(totalValue: _farmDebtTotalValue, paidValue: paid);
  }

  Future<double> getFarmDebtPaidValue() async {
    await _ensureLoaded();
    return _farmDebtPayments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
  }

  Future<List<FarmDebtPayment>> getFarmDebtPayments() async {
    await _ensureLoaded();
    return List.unmodifiable(_farmDebtPayments);
  }

  Future<void> saveFarmDebtTotalValue(double totalValue) async {
    await _ensureLoaded();
    _farmDebtTotalValue = totalValue;
    await _save();
  }

  Future<int> insertFarmDebtPayment(FarmDebtPayment payment) async {
    await _ensureLoaded();
    final id = _nextFarmDebtPaymentId++;
    _farmDebtPayments.insert(
      0,
      FarmDebtPayment(
        id: id,
        paymentDate: payment.paymentDate,
        amount: payment.amount,
        description: payment.description,
        paymentMethod: payment.paymentMethod,
        notes: payment.notes,
      ),
    );
    await _save();
    return id;
  }

  Future<int> updateFarmDebtPayment(FarmDebtPayment payment) async {
    await _ensureLoaded();
    final index = _farmDebtPayments.indexWhere((item) => item.id == payment.id);
    if (index == -1) return 0;
    _farmDebtPayments[index] = payment;
    await _save();
    return 1;
  }

  Future<int> deleteFarmDebtPayment(int id) async {
    await _ensureLoaded();
    final before = _farmDebtPayments.length;
    _farmDebtPayments.removeWhere((payment) => payment.id == id);
    await _save();
    return before - _farmDebtPayments.length;
  }

  Future<RotationSession?> getActiveRotationSession() async {
    await _ensureLoaded();
    return _rotationSessions.where((session) => session.endedAt == null).firstOrNull;
  }

  Future<int> startRotation({
    required int paddockId,
    required int plannedDays,
    String? notes,
  }) async {
    await _ensureLoaded();
    final id = _nextRotationSessionId++;
    _rotationSessions.insert(
      0,
      RotationSession(
        id: id,
        paddockId: paddockId,
        startedAt: DateTime.now().toIso8601String(),
        plannedDays: plannedDays,
        notes: notes,
      ),
    );
    await _save();
    return id;
  }

  Future<int> moveHerd({
    int? fromPaddockId,
    required int toPaddockId,
    required int plannedDays,
    String? notes,
  }) async {
    await _ensureLoaded();
    final now = DateTime.now().toIso8601String();
    final active = await getActiveRotationSession();
    int? effectiveFrom = fromPaddockId;
    if (active != null) {
      effectiveFrom = active.paddockId;
      final index = _rotationSessions.indexWhere((session) => session.id == active.id);
      _rotationSessions[index] = RotationSession(
        id: active.id,
        paddockId: active.paddockId,
        startedAt: active.startedAt,
        plannedDays: active.plannedDays,
        endedAt: now,
        notes: active.notes,
      );
    }

    _rotationMovements.insert(
      0,
      RotationMovement(
        id: _nextRotationMovementId++,
        fromPaddockId: effectiveFrom,
        toPaddockId: toPaddockId,
        fromPaddockName: _paddocks.where((p) => p.id == effectiveFrom).firstOrNull?.name,
        toPaddockName: _paddocks.where((p) => p.id == toPaddockId).firstOrNull?.name,
        movedAt: now,
        notes: notes,
      ),
    );
    final id = _nextRotationSessionId++;
    _rotationSessions.insert(
      0,
      RotationSession(
        id: id,
        paddockId: toPaddockId,
        startedAt: now,
        plannedDays: plannedDays,
        notes: notes,
      ),
    );
    await _save();
    return id;
  }

  Future<List<RotationMovement>> getRecentMovements({int limit = 8}) async {
    await _ensureLoaded();
    return _rotationMovements.take(limit).toList();
  }

  Future<int> getCalvesCount() async {
    await _ensureLoaded();
    return _calves.length;
  }

  Future<int> getPaddocksCount() async {
    await _ensureLoaded();
    return _paddocks.length;
  }

  Future<DashboardData> getDashboardData() async {
    await _ensureLoaded();
    final activeSession = await getActiveRotationSession();
    final farmDebtSummary = await getFarmDebtSummary();
    final paddockStates = await getPaddockStates();
    return DashboardData(
      calvesCount: _calves.length,
      paddocksCount: _paddocks.length,
      totalCalfInvestment: await getTotalCalfInvestment(),
      totalFarmExpenses: await getTotalFarmExpenses(),
      farmDebtPending: farmDebtSummary.pendingValue,
      pendingCalfFollowUps: await getPendingCalfFollowUpsCount(),
      activeSession: activeSession,
      activePaddock: activeSession == null ? null : await getPaddockById(activeSession.paddockId),
      recentMovements: await getRecentMovements(limit: 5),
      paddockStates: paddockStates,
    );
  }

  Future<String?> saveImageToAppDirectory(String sourcePath) async {
    return sourcePath;
  }

  Future<String> exportBackupJson() async {
    await _ensureLoaded();
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(_toBackupMap());
  }

  Future<void> importBackupJson(String backupJson) async {
    final decoded = jsonDecode(backupJson) as Map<String, dynamic>;

    _calves
      ..clear()
      ..addAll(_readList(decoded, 'calves').map(Calf.fromMap));
    _calfEvents
      ..clear()
      ..addAll(_readList(decoded, 'calf_events').map(CalfEvent.fromMap));
    _paddocks
      ..clear()
      ..addAll(_readList(decoded, 'paddocks').map(Paddock.fromMap));
    _paddockEvents
      ..clear()
      ..addAll(_readList(decoded, 'paddock_events').map(PaddockEvent.fromMap));
    _farmExpenses
      ..clear()
      ..addAll(_readList(decoded, 'farm_expenses').map(FarmExpense.fromMap));
    _farmDebtPayments
      ..clear()
      ..addAll(_readList(decoded, 'farm_debt_payments').map(FarmDebtPayment.fromMap));
    _rotationSessions
      ..clear()
      ..addAll(_readList(decoded, 'rotation_sessions').map(RotationSession.fromMap));
    _rotationMovements
      ..clear()
      ..addAll(_readList(decoded, 'rotation_movements').map(RotationMovement.fromMap));

    _nextCalfId = decoded['next_calf_id'] as int? ?? _nextId(_calves.map((item) => item.id));
    _nextCalfEventId =
        decoded['next_calf_event_id'] as int? ?? _nextId(_calfEvents.map((item) => item.id));
    _nextPaddockId =
        decoded['next_paddock_id'] as int? ?? _nextId(_paddocks.map((item) => item.id));
    _nextPaddockEventId = decoded['next_paddock_event_id'] as int? ??
        _nextId(_paddockEvents.map((item) => item.id));
    _nextFarmExpenseId = decoded['next_farm_expense_id'] as int? ??
        _nextId(_farmExpenses.map((item) => item.id));
    _nextFarmDebtPaymentId = decoded['next_farm_debt_payment_id'] as int? ??
        _nextId(_farmDebtPayments.map((item) => item.id));
    _nextRotationSessionId = decoded['next_rotation_session_id'] as int? ??
        _nextId(_rotationSessions.map((item) => item.id));
    _nextRotationMovementId = decoded['next_rotation_movement_id'] as int? ??
        _nextId(_rotationMovements.map((item) => item.id));
    _farmDebtTotalValue = (decoded['farm_debt_total_value'] as num?)?.toDouble() ?? 0;
    _loaded = true;
    await _save();
  }
}
