import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../models/storage_space.dart';

/// SQLite 数据库管理
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'homestash.db');

    return await openDatabase(
      path,
      version: 2, // 升级到 v2：增加 spaces 表
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            location TEXT NOT NULL,
            space_id INTEGER,
            photo_path TEXT,
            note TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE spaces (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            parent_id INTEGER,
            type TEXT NOT NULL DEFAULT 'room',
            icon_name TEXT,
            sort_order INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_spaces_parent ON spaces(parent_id)
        ''');
        await db.execute('''
          CREATE INDEX idx_items_space ON items(space_id)
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE spaces (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              parent_id INTEGER,
              type TEXT NOT NULL DEFAULT 'room',
              icon_name TEXT,
              sort_order INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('CREATE INDEX idx_spaces_parent ON spaces(parent_id)');
          await db.execute('CREATE INDEX idx_items_space ON items(space_id)');
          // 给已有 items 表加 space_id 列
          try {
            await db.execute('ALTER TABLE items ADD COLUMN space_id INTEGER');
          } catch (_) {}
        }
      },
    );
  }

  // ====================== 物品 CRUD ======================

  Future<int> insertItem(Item item) async {
    final db = await database;
    return await db.insert('items', item.toMap());
  }

  Future<int> updateItem(Item item) async {
    final db = await database;
    return await db.update(
      'items',
      item.toMap()..['id'] = item.id,
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Item>> getAllItems({
    String? searchQuery,
    String? category,
    String? location,
    int? spaceId,
  }) async {
    final db = await database;
    String where = 'i.space_id IS NOT NULL'; // 默认显示有关联空间的
    final List<dynamic> whereArgs = [];

    // 允许查看所有物品
    if (spaceId == null && searchQuery == null && category == null && location == null) {
      where = '1=1';
    }

    if (spaceId != null) {
      // 查找该空间及其所有子空间中的物品
      // 先获取所有子空间 ID
      final childIds = await _getAllChildSpaceIds(spaceId);
      final allIds = [spaceId, ...childIds];
      where = 'i.space_id IN (${allIds.map((_) => '?').join(',')})';
      whereArgs.addAll(allIds);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      where += ' AND (i.name LIKE ? OR i.category LIKE ? OR i.location LIKE ? OR i.note LIKE ?)';
      final p = '%$searchQuery%';
      whereArgs.addAll([p, p, p, p]);
    }

    if (category != null && category.isNotEmpty) {
      where += ' AND i.category = ?';
      whereArgs.add(category);
    }

    if (location != null && location.isNotEmpty) {
      where += ' AND i.location = ?';
      whereArgs.add(location);
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT i.* FROM items i WHERE $where ORDER BY i.created_at DESC',
      whereArgs,
    );

    return maps.map((m) => Item.fromMap(m)).toList();
  }

  Future<Item?> getItem(int id) async {
    final db = await database;
    final maps = await db.query('items', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Item.fromMap(maps.first);
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final maps = await db.rawQuery('SELECT DISTINCT category FROM items ORDER BY category');
    return maps.map((m) => m['category'] as String).toList();
  }

  Future<List<String>> getLocations() async {
    final db = await database;
    final maps = await db.rawQuery('SELECT DISTINCT location FROM items ORDER BY location');
    return maps.map((m) => m['location'] as String).toList();
  }

  Future<int> getCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM items');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取某个空间中的物品数量
  Future<int> getItemCountInSpace(int spaceId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM items WHERE space_id = ?', [spaceId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ====================== 空间 CRUD ======================

  Future<int> insertSpace(StorageSpace space) async {
    final db = await database;
    return await db.insert('spaces', space.toMap());
  }

  Future<int> updateSpace(StorageSpace space) async {
    final db = await database;
    return await db.update(
      'spaces',
      space.toMap()..['id'] = space.id,
      where: 'id = ?',
      whereArgs: [space.id],
    );
  }

  Future<int> deleteSpace(int id) async {
    final db = await database;
    // 先将子空间的 parent_id 设为 null
    await db.update('spaces', {'parent_id': null}, where: 'parent_id = ?', whereArgs: [id]);
    // 将该空间内的物品的 space_id 设为 null
    await db.update('items', {'space_id': null}, where: 'space_id = ?', whereArgs: [id]);
    return await db.delete('spaces', where: 'id = ?', whereArgs: [id]);
  }

  /// 获取所有顶级空间（房间）
  Future<List<StorageSpace>> getRootSpaces() async {
    final db = await database;
    final maps = await db.query(
      'spaces',
      where: 'parent_id IS NULL',
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return maps.map((m) => StorageSpace.fromMap(m)).toList();
  }

  /// 获取某个空间的子空间
  Future<List<StorageSpace>> getChildSpaces(int parentId) async {
    final db = await database;
    final maps = await db.query(
      'spaces',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return maps.map((m) => StorageSpace.fromMap(m)).toList();
  }

  /// 获取单个空间
  Future<StorageSpace?> getSpace(int id) async {
    final db = await database;
    final maps = await db.query('spaces', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return StorageSpace.fromMap(maps.first);
  }

  /// 获取某个空间的所有祖先（从根到父）
  Future<List<StorageSpace>> getSpaceAncestors(int spaceId) async {
    final ancestors = <StorageSpace>[];
    var currentId = spaceId;
    final db = await database;

    while (true) {
      final maps = await db.query('spaces', where: 'id = ?', whereArgs: [currentId]);
      if (maps.isEmpty) break;
      final space = StorageSpace.fromMap(maps.first);
      ancestors.insert(0, space);
      if (space.parentId == null) break;
      currentId = space.parentId!;
    }
    return ancestors;
  }

  /// 递归获取所有子空间 ID
  Future<List<int>> _getAllChildSpaceIds(int parentId) async {
    final ids = <int>[];
    final children = await getChildSpaces(parentId);
    for (final child in children) {
      ids.add(child.id!);
      ids.addAll(await _getAllChildSpaceIds(child.id!));
    }
    return ids;
  }

  /// 获取所有空间（用于选择器）
  Future<List<StorageSpace>> getAllSpaces() async {
    final db = await database;
    final maps = await db.query('spaces', orderBy: 'sort_order ASC, created_at ASC');
    return maps.map((m) => StorageSpace.fromMap(m)).toList();
  }

  /// 获取空间总数
  Future<int> getSpaceCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM spaces');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

String formatDateTime(DateTime dt) {
  return DateFormat('yyyy-MM-dd HH:mm').format(dt);
}
