class Paddock {
  final int? id;
  final String name;
  final String? description;
  final String? area;
  final String? grazingTime;
  final String? fertilizers;
  final double? expenses;
  final String? notes;
  final int? recoveryDays;
  final String? imagePath;

  const Paddock({
    this.id,
    required this.name,
    this.description,
    this.area,
    this.grazingTime,
    this.fertilizers,
    this.expenses,
    this.notes,
    this.recoveryDays,
    this.imagePath,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'area': area,
      'grazing_time': grazingTime,
      'fertilizers': fertilizers,
      'expenses': expenses,
      'notes': notes,
      'recovery_days': recoveryDays,
      'image_path': imagePath,
    };
  }

  factory Paddock.fromMap(Map<String, Object?> map) {
    return Paddock(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      area: map['area'] as String?,
      grazingTime: map['grazing_time'] as String?,
      fertilizers: map['fertilizers'] as String?,
      expenses: (map['expenses'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      recoveryDays: map['recovery_days'] as int?,
      imagePath: map['image_path'] as String?,
    );
  }
}
