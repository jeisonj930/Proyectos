import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

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

  SupabaseClient get _client => Supabase.instance.client;

  Map<String, Object?> _withoutId(Map<String, Object?> map) {
    final copy = Map<String, Object?>.from(map);
    copy.remove('id');
    return copy;
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

  List<Map<String, Object?>> _readList(Map<String, dynamic> data, String key) {
    return (data[key] as List? ?? const [])
        .map((item) => (item as Map).cast<String, Object?>())
        .toList();
  }

  Future<List<Calf>> getAllCalves() async {
    final rows = await _client.from('calves').select().order('id', ascending: false);
    return rows.map((row) => Calf.fromMap(row)).toList();
  }

  Future<Calf?> getCalfById(int id) async {
    final row = await _client.from('calves').select().eq('id', id).maybeSingle();
    return row == null ? null : Calf.fromMap(row);
  }

  Future<int> insertCalf(Calf calf) async {
    final row = await _client
        .from('calves')
        .insert(_withoutId(calf.toMap()))
        .select('id')
        .single();
    return row['id'] as int;
  }

  Future<int> updateCalf(Calf calf) async {
    await _client.from('calves').update(_withoutId(calf.toMap())).eq('id', calf.id!);
    return 1;
  }

  Future<int> deleteCalf(int id) async {
    await _client.from('calves').delete().eq('id', id);
    return 1;
  }

  Future<List<CalfEvent>> getCalfEvents(int calfId) async {
    final rows = await _client
        .from('calf_events')
        .select()
        .eq('calf_id', calfId)
        .order('event_date', ascending: false)
        .order('id', ascending: false);
    return rows.map((row) => CalfEvent.fromMap(row)).toList();
  }

  Future<double> getCalfInvestmentTotal(int calfId) async {
    final events = await getCalfEvents(calfId);
    return events
        .where((event) => event.amountType == 'expense')
        .fold<double>(0.0, (sum, event) => sum + (event.cost ?? 0));
  }

  Future<double> getCalfIncomeTotal(int calfId) async {
    final events = await getCalfEvents(calfId);
    return events
        .where((event) => event.amountType == 'income')
        .fold<double>(0.0, (sum, event) => sum + (event.cost ?? 0));
  }

  Future<double> getTotalCalfInvestment() async {
    final rows = await _client.from('calf_events').select('cost').eq('amount_type', 'expense');
    return rows.fold<double>(
      0.0,
      (sum, row) => sum + ((row['cost'] as num?)?.toDouble() ?? 0),
    );
  }

  Future<double> getTotalCalfIncome() async {
    final rows = await _client.from('calf_events').select('cost').eq('amount_type', 'income');
    return rows.fold<double>(
      0.0,
      (sum, row) => sum + ((row['cost'] as num?)?.toDouble() ?? 0),
    );
  }

  Future<int> getPendingCalfFollowUpsCount() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await _client
        .from('calf_events')
        .select('id')
        .not('next_follow_up_date', 'is', null)
        .lte('next_follow_up_date', today);
    return rows.length;
  }

  Future<int> insertCalfEvent(CalfEvent event) async {
    final row = await _client
        .from('calf_events')
        .insert(_withoutId(event.toMap()))
        .select('id')
        .single();
    return row['id'] as int;
  }

  Future<int> updateCalfEvent(CalfEvent event) async {
    await _client.from('calf_events').update(_withoutId(event.toMap())).eq('id', event.id!);
    return 1;
  }

  Future<int> deleteCalfEvent(int id) async {
    await _client.from('calf_events').delete().eq('id', id);
    return 1;
  }

  Future<List<Paddock>> getAllPaddocks() async {
    final rows = await _client.from('paddocks').select().order('id', ascending: false);
    return rows.map((row) => Paddock.fromMap(row)).toList();
  }

  Future<Paddock?> getPaddockById(int id) async {
    final row = await _client.from('paddocks').select().eq('id', id).maybeSingle();
    return row == null ? null : Paddock.fromMap(row);
  }

  Future<int> insertPaddock(Paddock paddock) async {
    final row = await _client
        .from('paddocks')
        .insert(_withoutId(paddock.toMap()))
        .select('id')
        .single();
    return row['id'] as int;
  }

  Future<int> updatePaddock(Paddock paddock) async {
    await _client.from('paddocks').update(_withoutId(paddock.toMap())).eq('id', paddock.id!);
    return 1;
  }

  Future<int> deletePaddock(int id) async {
    await _client.from('paddocks').delete().eq('id', id);
    return 1;
  }

  Future<List<PaddockEvent>> getPaddockEvents(int paddockId) async {
    final rows = await _client
        .from('paddock_events')
        .select()
        .eq('paddock_id', paddockId)
        .order('event_date', ascending: false)
        .order('id', ascending: false);
    return rows.map((row) => PaddockEvent.fromMap(row)).toList();
  }

  Future<double> getPaddockExpenseTotal(int paddockId) async {
    final events = await getPaddockEvents(paddockId);
    return events
        .where((event) => event.amountType == 'expense')
        .fold<double>(0.0, (sum, event) => sum + (event.cost ?? 0));
  }

  Future<double> getPaddockIncomeTotal(int paddockId) async {
    final events = await getPaddockEvents(paddockId);
    return events
        .where((event) => event.amountType == 'income')
        .fold<double>(0.0, (sum, event) => sum + (event.cost ?? 0));
  }

  Future<double> getTotalPaddockExpenses() async {
    final rows = await _client.from('paddock_events').select('cost').eq('amount_type', 'expense');
    return rows.fold<double>(
      0.0,
      (sum, row) => sum + ((row['cost'] as num?)?.toDouble() ?? 0),
    );
  }

  Future<double> getTotalPaddockIncome() async {
    final rows = await _client.from('paddock_events').select('cost').eq('amount_type', 'income');
    return rows.fold<double>(
      0.0,
      (sum, row) => sum + ((row['cost'] as num?)?.toDouble() ?? 0),
    );
  }

  Future<int> insertPaddockEvent(PaddockEvent event) async {
    final row = await _client
        .from('paddock_events')
        .insert(_withoutId(event.toMap()))
        .select('id')
        .single();
    return row['id'] as int;
  }

  Future<int> updatePaddockEvent(PaddockEvent event) async {
    await _client
        .from('paddock_events')
        .update(_withoutId(event.toMap()))
        .eq('id', event.id!);
    return 1;
  }

  Future<int> deletePaddockEvent(int id) async {
    await _client.from('paddock_events').delete().eq('id', id);
    return 1;
  }

  Future<List<PaddockState>> getPaddockStates() async {
    final paddocks = await getAllPaddocks();
    final active = await getActiveRotationSession();
    return paddocks.map((paddock) {
      if (active != null && active.paddockId == paddock.id) {
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
    final rows = await _client.from('farm_expenses').select().order('id', ascending: false);
    return rows.map((row) => FarmExpense.fromMap(row)).toList();
  }

  Future<double> getTotalFarmExpenses() async {
    final rows = await _client.from('farm_expenses').select('amount');
    return rows.fold<double>(
      0.0,
      (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0),
    );
  }

  Future<int> insertFarmExpense(FarmExpense expense) async {
    final row = await _client
        .from('farm_expenses')
        .insert(_withoutId(expense.toMap()))
        .select('id')
        .single();
    return row['id'] as int;
  }

  Future<int> updateFarmExpense(FarmExpense expense) async {
    await _client
        .from('farm_expenses')
        .update(_withoutId(expense.toMap()))
        .eq('id', expense.id!);
    return 1;
  }

  Future<int> deleteFarmExpense(int id) async {
    await _client.from('farm_expenses').delete().eq('id', id);
    return 1;
  }

  Future<FarmDebtSummary> getFarmDebtSummary() async {
    final settings = await _client
        .from('farm_settings')
        .select('farm_debt_total_value')
        .eq('id', 1)
        .maybeSingle();
    final totalValue = ((settings?['farm_debt_total_value'] as num?) ?? 0).toDouble();
    final paid = await getFarmDebtPaidValue();
    return FarmDebtSummary(totalValue: totalValue, paidValue: paid);
  }

  Future<double> getFarmDebtPaidValue() async {
    final rows = await _client.from('farm_debt_payments').select('amount');
    return rows.fold<double>(
      0.0,
      (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0),
    );
  }

  Future<List<FarmDebtPayment>> getFarmDebtPayments() async {
    final rows = await _client.from('farm_debt_payments').select().order('id', ascending: false);
    return rows.map((row) => FarmDebtPayment.fromMap(row)).toList();
  }

  Future<void> saveFarmDebtTotalValue(double totalValue) async {
    await _client.from('farm_settings').upsert({
      'id': 1,
      'farm_debt_total_value': totalValue,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> insertFarmDebtPayment(FarmDebtPayment payment) async {
    final row = await _client
        .from('farm_debt_payments')
        .insert(_withoutId(payment.toMap()))
        .select('id')
        .single();
    return row['id'] as int;
  }

  Future<int> updateFarmDebtPayment(FarmDebtPayment payment) async {
    await _client
        .from('farm_debt_payments')
        .update(_withoutId(payment.toMap()))
        .eq('id', payment.id!);
    return 1;
  }

  Future<int> deleteFarmDebtPayment(int id) async {
    await _client.from('farm_debt_payments').delete().eq('id', id);
    return 1;
  }

  Future<RotationSession?> getActiveRotationSession() async {
    final row = await _client
        .from('rotation_sessions')
        .select()
        .filter('ended_at', 'is', null)
        .order('id', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : RotationSession.fromMap(row);
  }

  Future<int> startRotation({
    required int paddockId,
    required int plannedDays,
    String? notes,
  }) async {
    final row = await _client
        .from('rotation_sessions')
        .insert({
          'paddock_id': paddockId,
          'started_at': DateTime.now().toIso8601String(),
          'planned_days': plannedDays,
          'notes': notes,
        })
        .select('id')
        .single();
    return row['id'] as int;
  }

  Future<int> moveHerd({
    int? fromPaddockId,
    required int toPaddockId,
    required int plannedDays,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    final active = await getActiveRotationSession();
    int? effectiveFrom = fromPaddockId;
    if (active != null) {
      effectiveFrom = active.paddockId;
      await _client
          .from('rotation_sessions')
          .update({'ended_at': now})
          .eq('id', active.id!);
    }

    final fromPaddock = effectiveFrom == null ? null : await getPaddockById(effectiveFrom);
    final toPaddock = await getPaddockById(toPaddockId);

    await _client.from('rotation_movements').insert({
      'from_paddock_id': effectiveFrom,
      'to_paddock_id': toPaddockId,
      'from_paddock_name': fromPaddock?.name,
      'to_paddock_name': toPaddock?.name,
      'moved_at': now,
      'notes': notes,
    });

    final row = await _client
        .from('rotation_sessions')
        .insert({
          'paddock_id': toPaddockId,
          'started_at': now,
          'planned_days': plannedDays,
          'notes': notes,
        })
        .select('id')
        .single();
    return row['id'] as int;
  }

  Future<List<RotationMovement>> getRecentMovements({int limit = 8}) async {
    final rows = await _client
        .from('rotation_movements')
        .select()
        .order('id', ascending: false)
        .limit(limit);
    return rows.map((row) => RotationMovement.fromMap(row)).toList();
  }

  Future<int> getCalvesCount() async {
    final rows = await _client.from('calves').select('id');
    return rows.length;
  }

  Future<int> getPaddocksCount() async {
    final rows = await _client.from('paddocks').select('id');
    return rows.length;
  }

  Future<DashboardData> getDashboardData() async {
    final activeSession = await getActiveRotationSession();
    final farmDebtSummary = await getFarmDebtSummary();
    final paddockStates = await getPaddockStates();
    return DashboardData(
      calvesCount: await getCalvesCount(),
      paddocksCount: await getPaddocksCount(),
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
    final farmDebt = await getFarmDebtSummary();
    final encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert({
      'calves': (await getAllCalves()).map((item) => item.toMap()).toList(),
      'calf_events': [
        for (final calf in await getAllCalves())
          ...(await getCalfEvents(calf.id!)).map((item) => item.toMap()),
      ],
      'paddocks': (await getAllPaddocks()).map((item) => item.toMap()).toList(),
      'paddock_events': [
        for (final paddock in await getAllPaddocks())
          ...(await getPaddockEvents(paddock.id!)).map((item) => item.toMap()),
      ],
      'farm_expenses': (await getAllFarmExpenses()).map((item) => item.toMap()).toList(),
      'farm_debt_payments': (await getFarmDebtPayments()).map((item) => item.toMap()).toList(),
      'rotation_sessions': [
        if (await getActiveRotationSession() case final active?)
          active.toMap(),
      ],
      'rotation_movements': (await getRecentMovements(limit: 1000)).map(_rotationMovementToMap).toList(),
      'farm_debt_total_value': farmDebt.totalValue,
    });
  }

  Future<void> importBackupJson(String backupJson) async {
    final decoded = jsonDecode(backupJson) as Map<String, dynamic>;

    await saveFarmDebtTotalValue(
      (decoded['farm_debt_total_value'] as num?)?.toDouble() ?? 0,
    );

    for (final calfMap in _readList(decoded, 'calves')) {
      await _client.from('calves').upsert(calfMap);
    }
    for (final eventMap in _readList(decoded, 'calf_events')) {
      await _client.from('calf_events').upsert(eventMap);
    }
    for (final paddockMap in _readList(decoded, 'paddocks')) {
      await _client.from('paddocks').upsert(paddockMap);
    }
    for (final eventMap in _readList(decoded, 'paddock_events')) {
      await _client.from('paddock_events').upsert(eventMap);
    }
    for (final expenseMap in _readList(decoded, 'farm_expenses')) {
      await _client.from('farm_expenses').upsert(expenseMap);
    }
    for (final paymentMap in _readList(decoded, 'farm_debt_payments')) {
      await _client.from('farm_debt_payments').upsert(paymentMap);
    }
    for (final sessionMap in _readList(decoded, 'rotation_sessions')) {
      await _client.from('rotation_sessions').upsert(sessionMap);
    }
    for (final movementMap in _readList(decoded, 'rotation_movements')) {
      await _client.from('rotation_movements').upsert(movementMap);
    }
  }
}
