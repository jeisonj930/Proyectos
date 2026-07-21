class RotationSession {
  final int? id;
  final int paddockId;
  final String startedAt;
  final int plannedDays;
  final String? endedAt;
  final String? notes;

  const RotationSession({
    this.id,
    required this.paddockId,
    required this.startedAt,
    required this.plannedDays,
    this.endedAt,
    this.notes,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'paddock_id': paddockId,
      'started_at': startedAt,
      'planned_days': plannedDays,
      'ended_at': endedAt,
      'notes': notes,
    };
  }

  factory RotationSession.fromMap(Map<String, Object?> map) {
    return RotationSession(
      id: map['id'] as int?,
      paddockId: map['paddock_id'] as int,
      startedAt: map['started_at'] as String,
      plannedDays: map['planned_days'] as int,
      endedAt: map['ended_at'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
