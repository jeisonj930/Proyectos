class CalfEvent {
  final int? id;
  final int calfId;
  final String eventDate;
  final String eventType;
  final String description;
  final double? cost;
  final String amountType;
  final String? nextFollowUpDate;
  final String? notes;

  const CalfEvent({
    this.id,
    required this.calfId,
    required this.eventDate,
    required this.eventType,
    required this.description,
    this.cost,
    this.amountType = 'expense',
    this.nextFollowUpDate,
    this.notes,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'calf_id': calfId,
      'event_date': eventDate,
      'event_type': eventType,
      'description': description,
      'cost': cost,
      'amount_type': amountType,
      'next_follow_up_date': nextFollowUpDate,
      'notes': notes,
    };
  }

  factory CalfEvent.fromMap(Map<String, Object?> map) {
    return CalfEvent(
      id: map['id'] as int?,
      calfId: map['calf_id'] as int,
      eventDate: map['event_date'] as String,
      eventType: map['event_type'] as String,
      description: map['description'] as String,
      cost: (map['cost'] as num?)?.toDouble(),
      amountType: map['amount_type'] as String? ?? 'expense',
      nextFollowUpDate: map['next_follow_up_date'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
