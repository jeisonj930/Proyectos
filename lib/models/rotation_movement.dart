class RotationMovement {
  final int? id;
  final int? fromPaddockId;
  final int? toPaddockId;
  final String? fromPaddockName;
  final String? toPaddockName;
  final String movedAt;
  final String? notes;

  const RotationMovement({
    this.id,
    this.fromPaddockId,
    this.toPaddockId,
    this.fromPaddockName,
    this.toPaddockName,
    required this.movedAt,
    this.notes,
  });

  factory RotationMovement.fromMap(Map<String, Object?> map) {
    return RotationMovement(
      id: map['id'] as int?,
      fromPaddockId: map['from_paddock_id'] as int?,
      toPaddockId: map['to_paddock_id'] as int?,
      fromPaddockName: map['from_paddock_name'] as String?,
      toPaddockName: map['to_paddock_name'] as String?,
      movedAt: map['moved_at'] as String,
      notes: map['notes'] as String?,
    );
  }
}
