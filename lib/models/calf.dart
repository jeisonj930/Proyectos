class Calf {
  final int? id;
  final String code;
  final String? name;
  final String? breed;
  final String? birthDate;
  final String? age;
  final double? weight;
  final String? healthStatus;
  final String? sellerName;
  final String? notes;
  final String? imagePath;

  const Calf({
    this.id,
    required this.code,
    this.name,
    this.breed,
    this.birthDate,
    this.age,
    this.weight,
    this.healthStatus,
    this.sellerName,
    this.notes,
    this.imagePath,
  });

  Calf copyWith({
    int? id,
    String? code,
    String? name,
    String? breed,
    String? birthDate,
    String? age,
    double? weight,
    String? healthStatus,
    String? sellerName,
    String? notes,
    String? imagePath,
  }) {
    return Calf(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      healthStatus: healthStatus ?? this.healthStatus,
      sellerName: sellerName ?? this.sellerName,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'breed': breed,
      'birth_date': birthDate,
      'age': age,
      'weight': weight,
      'health_status': healthStatus,
      'seller_name': sellerName,
      'notes': notes,
      'image_path': imagePath,
    };
  }

  factory Calf.fromMap(Map<String, Object?> map) {
    return Calf(
      id: map['id'] as int?,
      code: map['code'] as String,
      name: map['name'] as String?,
      breed: map['breed'] as String?,
      birthDate: map['birth_date'] as String?,
      age: map['age'] as String?,
      weight: (map['weight'] as num?)?.toDouble(),
      healthStatus: map['health_status'] as String?,
      sellerName: map['seller_name'] as String?,
      notes: map['notes'] as String?,
      imagePath: map['image_path'] as String?,
    );
  }
}
