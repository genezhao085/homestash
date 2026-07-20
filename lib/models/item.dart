/// 物品数据模型
class Item {
  final int? id;
  final String name;
  final String category;
  final String location;
  final int? spaceId; // 关联的存储空间ID
  final String? photoPath;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Item({
    this.id,
    required this.name,
    required this.category,
    required this.location,
    this.spaceId,
    this.photoPath,
    this.note,
    required this.createdAt,
    this.updatedAt,
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      location: map['location'] as String,
      spaceId: map['space_id'] as int?,
      photoPath: map['photo_path'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'location': location,
      'space_id': spaceId,
      'photo_path': photoPath,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Item copyWith({
    int? id,
    String? name,
    String? category,
    String? location,
    int? spaceId,
    String? photoPath,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      spaceId: spaceId ?? this.spaceId,
      photoPath: photoPath ?? this.photoPath,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
