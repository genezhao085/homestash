/// 存储空间层级模型
/// 支持多级嵌套：房间 → 柜子/架子 → 抽屉/隔层
class StorageSpace {
  final int? id;
  final String name;
  final int? parentId;      // 父空间ID，null 表示根空间（房间级）
  final String type;         // 类型：room(房间) / cabinet(柜子) / shelf(架子) / drawer(抽屉) / box(箱子)
  final String? iconName;    // 图标名称，用于前端显示
  final int sortOrder;       // 排序顺序
  final DateTime createdAt;

  const StorageSpace({
    this.id,
    required this.name,
    this.parentId,
    required this.type,
    this.iconName,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory StorageSpace.fromMap(Map<String, dynamic> map) {
    return StorageSpace(
      id: map['id'] as int?,
      name: map['name'] as String,
      parentId: map['parent_id'] as int?,
      type: map['type'] as String,
      iconName: map['icon_name'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'parent_id': parentId,
      'type': type,
      'icon_name': iconName,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  StorageSpace copyWith({
    int? id,
    String? name,
    int? parentId,
    String? type,
    String? iconName,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return StorageSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      type: type ?? this.type,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 空间类型预设
class SpaceTypes {
  static const room = 'room';
  static const cabinet = 'cabinet';
  static const shelf = 'shelf';
  static const drawer = 'drawer';
  static const box = 'box';

  static const all = [room, cabinet, shelf, drawer, box];

  static String displayName(String type) {
    switch (type) {
      case room: return '房间';
      case cabinet: return '柜子';
      case shelf: return '架子';
      case drawer: return '抽屉';
      case box: return '箱子';
      default: return type;
    }
  }

  static List<String> childrenTypes(String type) {
    switch (type) {
      case room: return [cabinet, shelf, box];
      case cabinet: return [drawer, shelf, box];
      case shelf: return [box];
      case drawer: return [box];
      case box: return [];
      default: return [];
    }
  }
}
