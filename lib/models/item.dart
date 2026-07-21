/// 物品数据模型
class Item {
  final int? id;
  final String name;
  final String category;
  final String location;
  final int? spaceId; // 关联的存储空间ID
  final String? barcode; // 商品条码
  final String? photoPath;
  final String? note;
  final DateTime? expiryDate; // 过期日期
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Item({
    this.id,
    required this.name,
    required this.category,
    required this.location,
    this.spaceId,
    this.barcode,
    this.photoPath,
    this.note,
    this.expiryDate,
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
      barcode: map['barcode'] as String?,
      photoPath: map['photo_path'] as String?,
      note: map['note'] as String?,
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
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
      'barcode': barcode,
      'photo_path': photoPath,
      'note': note,
      'expiry_date': expiryDate?.toIso8601String(),
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
    String? barcode,
    String? photoPath,
    String? note,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      spaceId: spaceId ?? this.spaceId,
      barcode: barcode ?? this.barcode,
      photoPath: photoPath ?? this.photoPath,
      note: note ?? this.note,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 是否已过期
  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  /// 是否即将过期（7天内）
  bool get isExpiringSoon =>
      expiryDate != null &&
      !isExpired &&
      expiryDate!.difference(DateTime.now()).inDays <= 7;

  /// 距离过期还有多少天（正数=未过期天数，0=今天，负数=已过期天数）
  int get daysUntilExpiry {
    if (expiryDate == null) return 0;
    // 用日期级别比较（忽略时分秒）
    final now = DateTime.now();
    final expiryDay = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    return expiryDay.difference(today).inDays;
  }
}
