import 'dart:convert';
import '../models/item.dart';
import '../models/storage_space.dart';
import '../utils/database_helper.dart';

/// 导出/导入结果
class ImportResult {
  final int itemsImported;
  final int spacesImported;
  final int itemsSkipped;
  final List<String> errors;

  const ImportResult({
    this.itemsImported = 0,
    this.spacesImported = 0,
    this.itemsSkipped = 0,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
}

/// 备份数据的 JSON 结构
class BackupData {
  final int version;
  final String exportedAt;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> spaces;

  const BackupData({
    required this.version,
    required this.exportedAt,
    required this.items,
    required this.spaces,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'exported_at': exportedAt,
        'items': items,
        'spaces': spaces,
      };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as int? ?? 1,
      exportedAt: json['exported_at'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      spaces: (json['spaces'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}

/// 数据导出/导入服务
class ExportImportService {
  static const int _backupVersion = 1;

  // ========================= 导出 =========================

  /// 将所有数据（物品 + 空间）导出为 JSON 字符串
  static String exportToJson({
    required List<Item> items,
    required List<StorageSpace> spaces,
  }) {
    final backup = BackupData(
      version: _backupVersion,
      exportedAt: DateTime.now().toIso8601String(),
      items: items.map((e) => _itemToExportMap(e)).toList(),
      spaces: spaces.map((e) => e.toMap()).toList(),
    );
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backup.toJson());
  }

  /// 仅导出物品为 CSV 字符串
  static String exportItemsToCsv(List<Item> items) {
    final buffer = StringBuffer();

    // CSV 表头
    buffer.writeln('name,category,location,space_id,photo_path,note,created_at,updated_at');

    for (final item in items) {
      buffer.writeln(_itemToCsvRow(item));
    }

    return buffer.toString();
  }

  /// 导出完整数据（物品 + 空间展平）为 CSV
  /// 分为两个 section：spaces 和 items
  static String exportFullToCsv({
    required List<Item> items,
    required List<StorageSpace> spaces,
  }) {
    final buffer = StringBuffer();

    // Spaces section
    buffer.writeln('# spaces');
    buffer.writeln('id,name,parent_id,type,icon_name,sort_order,created_at');
    for (final space in spaces) {
      buffer.writeln(_spaceToCsvRow(space));
    }

    buffer.writeln();
    buffer.writeln('# items');
    buffer.writeln('id,name,category,location,space_id,photo_path,note,created_at,updated_at');
    for (final item in items) {
      buffer.writeln(_itemToCsvRowFull(item));
    }

    return buffer.toString();
  }

  // ========================= 导入 =========================

  /// 从 JSON 备份文件导入数据
  /// [strategy] - 'merge'：合并（保留已有数据）；'replace'：先清空再导入
  static Future<ImportResult> importFromJson({
    required String jsonString,
    required DatabaseHelper dbHelper,
    required String strategy, // 'merge' or 'replace'
  }) async {
    final errors = <String>[];
    int itemsImported = 0;
    int spacesImported = 0;
    int itemsSkipped = 0;

    try {
      final decoded = json.decode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        errors.add('JSON 格式无效：根节点必须是对象');
        return ImportResult(errors: errors);
      }

      final backup = BackupData.fromJson(decoded);

      if (backup.version > _backupVersion) {
        errors.add('备份文件版本 ($backup.version) 高于当前支持版本 ($_backupVersion)，可能不兼容');
      }

      // 导入空间
      if (backup.spaces.isNotEmpty) {
        spacesImported = await _importSpaces(
          backup.spaces,
          dbHelper,
          strategy: strategy,
          errors: errors,
        );
      }

      // 导入物品
      if (backup.items.isNotEmpty) {
        final result = await _importItems(
          backup.items,
          dbHelper,
          strategy: strategy,
          errors: errors,
        );
        itemsImported = result['imported'];
        itemsSkipped = result['skipped'];
      }
    } on FormatException catch (e) {
      errors.add('JSON 解析失败：${e.message}');
    } catch (e) {
      errors.add('导入失败：$e');
    }

    return ImportResult(
      itemsImported: itemsImported,
      spacesImported: spacesImported,
      itemsSkipped: itemsSkipped,
      errors: errors,
    );
  }

  /// 从 CSV 文件导入数据
  static Future<ImportResult> importFromCsv({
    required String csvString,
    required DatabaseHelper dbHelper,
    required String strategy, // 'merge' or 'replace'
  }) async {
    final errors = <String>[];
    int itemsImported = 0;
    int itemsSkipped = 0;

    try {
      final lines = csvString
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (lines.isEmpty) {
        errors.add('CSV 文件为空');
        return ImportResult(errors: errors);
      }

      // 解析 CSV 行（简单实现，处理引号包裹的字段）
      List<String> parseCsvLine(String line) {
        final fields = <String>[];
        var current = '';
        var inQuotes = false;

        for (var i = 0; i < line.length; i++) {
          final char = line[i];
          if (char == '"') {
            inQuotes = !inQuotes;
          } else if (char == ',' && !inQuotes) {
            fields.add(current.trim());
            current = '';
          } else {
            current += char;
          }
        }
        fields.add(current.trim());
        return fields;
      }

      // 检查是否包含 header
      final firstLine = lines.first.toLowerCase();
      if (!firstLine.contains('name') || !firstLine.contains('category')) {
        errors.add('CSV 格式无效：缺少表头行');
        return ImportResult(errors: errors);
      }

      // 解析表头确定列索引
      final headers = parseCsvLine(lines.first);
      final nameIdx = headers.indexWhere((h) => h.toLowerCase() == 'name');
      final categoryIdx = headers.indexWhere((h) => h.toLowerCase() == 'category');
      final locationIdx = headers.indexWhere((h) => h.toLowerCase() == 'location');

      if (nameIdx < 0 || categoryIdx < 0) {
        errors.add('CSV 缺少必要列（name, category）');
        return ImportResult(errors: errors);
      }

      final spaceIdIdx = headers.indexWhere((h) => h.toLowerCase() == 'space_id');
      final photoPathIdx = headers.indexWhere((h) => h.toLowerCase() == 'photo_path');
      final noteIdx = headers.indexWhere((h) => h.toLowerCase() == 'note');

      // 逐行导入
      for (var i = 1; i < lines.length; i++) {
        try {
          final fields = parseCsvLine(lines[i]);
          if (fields.length < headers.length) continue;

          final name = fields[nameIdx];
          final category = fields[categoryIdx];
          final location = locationIdx >= 0 ? fields[locationIdx] : '未知';

          if (name.isEmpty) {
            itemsSkipped++;
            continue;
          }

          final item = Item(
            name: name,
            category: category.isNotEmpty ? category : '其他',
            location: location.isNotEmpty ? location : '未知',
            spaceId: spaceIdIdx >= 0 ? int.tryParse(fields[spaceIdIdx]) : null,
            photoPath: photoPathIdx >= 0 && fields[photoPathIdx].isNotEmpty
                ? fields[photoPathIdx]
                : null,
            note: noteIdx >= 0 && fields[noteIdx].isNotEmpty
                ? fields[noteIdx]
                : null,
            createdAt: DateTime.now(),
          );

          if (strategy == 'replace') {
            await dbHelper.insertItem(item);
          } else {
            // merge 策略：直接插入
            await dbHelper.insertItem(item);
          }
          itemsImported++;
        } catch (e) {
          itemsSkipped++;
          errors.add('第 $i 行导入失败：$e');
        }
      }
    } catch (e) {
      errors.add('CSV 解析失败：$e');
    }

    return ImportResult(
      itemsImported: itemsImported,
      itemsSkipped: itemsSkipped,
      errors: errors,
    );
  }

  // ========================= 内部方法 =========================

  static Map<String, dynamic> _itemToExportMap(Item item) {
    return {
      'name': item.name,
      'category': item.category,
      'location': item.location,
      'space_id': item.spaceId,
      'photo_path': item.photoPath,
      'note': item.note,
      'created_at': item.createdAt.toIso8601String(),
      'updated_at': item.updatedAt?.toIso8601String(),
    };
  }

  static String _csvEscape(String? value) {
    if (value == null || value.isEmpty) return '';
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _itemToCsvRow(Item item) {
    return [
      _csvEscape(item.name),
      _csvEscape(item.category),
      _csvEscape(item.location),
      item.spaceId?.toString() ?? '',
      _csvEscape(item.photoPath),
      _csvEscape(item.note),
      item.createdAt.toIso8601String(),
      item.updatedAt?.toIso8601String() ?? '',
    ].join(',');
  }

  static String _itemToCsvRowFull(Item item) {
    return [
      item.id?.toString() ?? '',
      _csvEscape(item.name),
      _csvEscape(item.category),
      _csvEscape(item.location),
      item.spaceId?.toString() ?? '',
      _csvEscape(item.photoPath),
      _csvEscape(item.note),
      item.createdAt.toIso8601String(),
      item.updatedAt?.toIso8601String() ?? '',
    ].join(',');
  }

  static String _spaceToCsvRow(StorageSpace space) {
    return [
      space.id?.toString() ?? '',
      _csvEscape(space.name),
      space.parentId?.toString() ?? '',
      _csvEscape(space.type),
      _csvEscape(space.iconName),
      space.sortOrder.toString(),
      space.createdAt.toIso8601String(),
    ].join(',');
  }

  /// 导入空间数据
  static Future<int> _importSpaces(
    List<Map<String, dynamic>> spaces,
    DatabaseHelper dbHelper, {
    required String strategy,
    required List<String> errors,
  }) async {
    int imported = 0;

    if (strategy == 'replace') {
      // 清空现有空间
      try {
        final existingSpaces = await dbHelper.getAllSpaces();
        for (final space in existingSpaces) {
          await dbHelper.deleteSpace(space.id!);
        }
      } catch (e) {
        errors.add('清空空间数据失败：$e');
      }
    }

    for (final spaceMap in spaces) {
      try {
        final space = StorageSpace.fromMap(spaceMap);
        await dbHelper.insertSpace(space);
        imported++;
      } catch (e) {
        errors.add('导入空间 "${spaceMap['name']}" 失败：$e');
      }
    }

    return imported;
  }

  /// 导入物品数据
  static Future<Map<String, int>> _importItems(
    List<Map<String, dynamic>> items,
    DatabaseHelper dbHelper, {
    required String strategy,
    required List<String> errors,
  }) async {
    int imported = 0;
    int skipped = 0;

    if (strategy == 'replace') {
      // 清空现有物品
      try {
        final existingItems = await dbHelper.getAllItems();
        for (final item in existingItems) {
          await dbHelper.deleteItem(item.id!);
        }
      } catch (e) {
        errors.add('清空物品数据失败：$e');
      }
    }

    for (final itemMap in items) {
      try {
        final item = Item.fromMap(itemMap);
        await dbHelper.insertItem(item);
        imported++;
      } catch (e) {
        skipped++;
        errors.add('导入物品 "${itemMap['name']}" 失败：$e');
      }
    }

    return {'imported': imported, 'skipped': skipped};
  }
}
