import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/database_helper.dart';
import '../models/item.dart';
import '../models/storage_space.dart';

/// AI 自然语言查询结果
class NLQueryResult {
  /// 友好显示的消息（AI 对查询的总结和回答）
  final String message;

  /// 命中的物品列表
  final List<Item> items;

  /// 原始 SQL 查询参数（调试用）
  final String? rawIntent;

  const NLQueryResult({
    required this.message,
    this.items = const [],
    this.rawIntent,
  });
}

/// AI 自然语言查询服务
///
/// 接收用户自然语言输入（如"帮我找充电器"、"快过期的食品"），
/// 调用 DeepSeek 解析意图，转换为结构化数据库查询并执行。
class NLQueryService {
  static const _apiUrl = 'https://api.deepseek.com/v1/chat/completions';
  static const _model = 'deepseek-chat';
  static const _timeout = Duration(seconds: 15);

  /// 获取 API Key 的 Sources（按优先级）
  /// 使用编译时常量，通过 --dart-define 传入：
  ///   flutter run --dart-define=DEEPSEEK_API_KEY=sk-xxx
  /// 也支持 OPENROUTER_API_KEY 作为备选
  static List<String> _apiKeySources() {
    return const [
      'QWEN_API_KEY',
      'DEEPSEEK_API_KEY',
      'OPENROUTER_API_KEY',
    ];
  }

  static String? _resolveApiKey() {
    for (final source in _apiKeySources()) {
      final key = String.fromEnvironment(source);
      if (key.isNotEmpty) {
        if (source == 'QWEN_API_KEY') {
          _currentApiUrl = 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions';
          _currentModel = 'qwen3.8-max';
        }
        return key;
      }
    }
    return null;
  }

  static String _currentApiUrl = _apiUrl;
  static String _currentModel = _model;

  /// 解释自然语言查询，返回结构化结果
  static Future<NLQueryResult> interpret(String query) async {
    // 1. 收集数据库上下文（分类列表、空间树、总物品数）
    final db = DatabaseHelper.instance;
    final categories = await db.getCategories();
    final totalItems = await db.getCount();
    final spaces = await db.getAllSpaces();

    // 2. 构建 AI prompt
    final prompt = _buildPrompt(query, categories, spaces, totalItems);

    // 3. 调用 DeepSeek API
    final apiKey = _resolveApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      // Fallback: 简单关键词搜索
      return _keywordFallback(query);
    }

    try {
      final response = await http
          .post(
            Uri.parse(_currentApiUrl),
            headers: {
              'Content-Type': 'application/json',
              if (_currentApiUrl.contains('dashscope'))
                'Authorization': 'Bearer $apiKey'
              else
                'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': _currentModel,
              'messages': [
                {
                  'role': 'system',
                  'content': _systemPrompt(),
                },
                {
                  'role': 'user',
                  'content': prompt,
                },
              ],
              'temperature': 0.1,
              'max_tokens': 1000,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final content = body['choices'][0]['message']['content'] as String;
        return _parseResponse(content, query);
      } else {
        // API 失败，降级到关键词搜索
        return _keywordFallback(query);
      }
    } catch (_) {
      // 网络错误，降级
      return _keywordFallback(query);
    }
  }

  static String _systemPrompt() {
    return '''你是一个家庭物品管理助手的意图解析器。你的任务是将用户的自然语言查询转换为结构化的数据库查询参数。

数据库中有两张表：

1. items（物品）字段：id, name(名称), category(分类), location(位置描述), space_id(空间ID), barcode(条码), note(备注), expiry_date(过期日期 YYYY-MM-DD), created_at, updated_at
2. spaces（存储空间）字段：id, name(空间名), parent_id(父空间ID), type(类型: room/cabinet/shelf/drawer/box), sort_order

Item 模型还有一个别名字段：通过空间层级可以找到物品在哪个房间/柜子/抽屉。
类别列表和空间树会在每次查询时提供。

你只输出 JSON，不要输出其他内容。JSON 格式：
{
  "intent": "search|count|expiring|expired|summary",
  "keywords": ["关键词1", "关键词2"],
  "category": "分类名或null",
  "space_name": "空间名或null",
  "expiry_days": 数字或null,
  "sort_by": "name|expiry_date|category|created_at",
  "sort_order": "asc|desc",
  "response_message": "用中文回答用户，友好简洁"
}

intent 含义：
- search: 搜索物品（默认）
- count: 统计数量（如"我有多少件物品？"）
- expiring: 即将过期（N天内）
- expired: 已过期
- summary: 汇总统计

response_message 是用中文写的对用户的友好回答，要自然简洁。''';
  }

  static String _buildPrompt(
    String query,
    List<String> categories,
    List<StorageSpace> spaces,
    int totalItems,
  ) {
    final catStr = categories.isEmpty ? '（暂无数据）' : categories.join(', ');
    final spaceTree = _buildSpaceTree(spaces);

    return '''用户查询: "$query"

数据库概况:
- 总物品数: $totalItems
- 已有分类: $catStr
- 空间层级:
$spaceTree

请输出 JSON 格式的意图解析结果。''';
  }

  static String _buildSpaceTree(List<StorageSpace> spaces) {
    if (spaces.isEmpty) return '（暂无空间）';
    final rootSpaces = spaces.where((s) => s.parentId == null).toList();
    final buffer = StringBuffer();
    for (final root in rootSpaces) {
      _appendSpaceTree(spaces, root, 0, buffer);
    }
    return buffer.toString();
  }

  static void _appendSpaceTree(
    List<StorageSpace> spaces,
    StorageSpace space,
    int depth,
    StringBuffer buffer,
  ) {
    buffer.writeln('${'  ' * depth}- ${space.name} (${space.type})');
    final children = spaces.where((s) => s.parentId == space.id).toList();
    for (final child in children) {
      _appendSpaceTree(spaces, child, depth + 1, buffer);
    }
  }

  static Future<NLQueryResult> _parseResponse(String content, String originalQuery) async {
    // 提取 JSON
    final jsonStart = content.indexOf('{');
    final jsonEnd = content.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1) {
      return _keywordFallback(originalQuery);
    }

    try {
      final json = jsonDecode(content.substring(jsonStart, jsonEnd + 1));
      final intent = json['intent'] as String? ?? 'search';
      final keywords = (json['keywords'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final category = json['category'] as String?;
      final spaceName = json['space_name'] as String?;
      final expiryDays = json['expiry_days'] as int?;
      final sortBy = json['sort_by'] as String? ?? 'name';
      final sortOrder = json['sort_order'] as String? ?? 'asc';
      final responseMessage =
          json['response_message'] as String? ?? _defaultResponse(intent);

      // 根据意图执行查询
      final db = DatabaseHelper.instance;

      if (intent == 'expired') {
        return await _queryExpired(db, responseMessage);
      } else if (intent == 'expiring') {
        return await _queryExpiring(db, expiryDays ?? 7, responseMessage);
      } else if (intent == 'count') {
        return await _queryCount(db, keywords, category, spaceName, responseMessage);
      } else if (intent == 'summary') {
        return await _querySummary(db, responseMessage);
      } else {
        // search
        return await _querySearch(
          db,
          keywords,
          category,
          spaceName,
          sortBy,
          sortOrder,
          responseMessage,
        );
      }
    } catch (_) {
      return _keywordFallback(originalQuery);
    }
  }

  static String _defaultResponse(String intent) {
    switch (intent) {
      case 'expired':
        return '以下是已过期的物品，建议尽快处理。';
      case 'expiring':
        return '以下是即将过期的物品，请注意。';
      case 'count':
        return '这是统计结果。';
      case 'summary':
        return '这是你的物品概况。';
      default:
        return '这是搜索结果。';
    }
  }

  // ═══════════════════════════════════════════
  //  查询执行器
  // ═══════════════════════════════════════════

  static Future<NLQueryResult> _querySearch(
    DatabaseHelper db,
    List<String> keywords,
    String? category,
    String? spaceName,
    String sortBy,
    String sortOrder,
    String message,
  ) async {
    // 用关键词搜索
    final searchQuery = keywords.join(' ');
    var items = await db.getAllItems(
      searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      category: category,
    );

    // 按空间名过滤
    if (spaceName != null && items.isNotEmpty) {
      final allSpaces = await db.getAllSpaces();
      final matchedSpaces = allSpaces
          .where((s) => s.name.contains(spaceName))
          .toList();
      if (matchedSpaces.isNotEmpty) {
        final spaceIds = matchedSpaces.map((s) => s.id).toSet();
        items = items.where((i) => i.spaceId != null && spaceIds.contains(i.spaceId)).toList();
      }
    }

    // 排序
    _sortItems(items, sortBy, sortOrder);

    final msg = items.isEmpty
        ? '没有找到匹配的物品。试试换个说法，或者检查输入的关键词。'
        : message.replaceAll('{count}', items.length.toString());

    return NLQueryResult(
      message: msg,
      items: items,
      rawIntent: 'search(category=$category, space=$spaceName, sort=$sortBy)',
    );
  }

  static Future<NLQueryResult> _queryExpired(
    DatabaseHelper db,
    String message,
  ) async {
    final all = await db.getAllItems();
    final expired = all.where((i) => i.isExpired).toList();
    _sortItems(expired, 'expiry_date', 'asc');

    final msg = expired.isEmpty
        ? '🎉 没有已过期的物品，你的物品都还在保质期内！'
        : message + ' 共 ${expired.length} 件。';

    return NLQueryResult(
      message: msg,
      items: expired,
      rawIntent: 'expired',
    );
  }

  static Future<NLQueryResult> _queryExpiring(
    DatabaseHelper db,
    int days,
    String message,
  ) async {
    final all = await db.getAllItems();
    final now = DateTime.now();
    final threshold = DateTime(now.year, now.month, now.day).add(Duration(days: days));
    final today = DateTime(now.year, now.month, now.day);

    final expiring = all.where((i) {
      if (i.expiryDate == null) return false;
      final expiryDay = DateTime(i.expiryDate!.year, i.expiryDate!.month, i.expiryDate!.day);
      return !expiryDay.isBefore(today) && !expiryDay.isAfter(threshold);
    }).toList();

    _sortItems(expiring, 'expiry_date', 'asc');

    final msg = expiring.isEmpty
        ? '✅ 未来 $days 天内没有物品即将过期。'
        : message.replaceAll('{days}', days.toString()) +
            ' 共 ${expiring.length} 件。';

    return NLQueryResult(
      message: msg,
      items: expiring,
      rawIntent: 'expiring($days days)',
    );
  }

  static Future<NLQueryResult> _queryCount(
    DatabaseHelper db,
    List<String> keywords,
    String? category,
    String? spaceName,
    String message,
  ) async {
    final searchQuery = keywords.join(' ');
    final items = await db.getAllItems(
      searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      category: category,
    );

    final total = await db.getCount();
    final msg = items.isEmpty
        ? '当前共有 $total 件物品。'
        : '找到 ${items.length} 件物品（共 $total 件）';

    return NLQueryResult(
      message: msg,
      items: items,
      rawIntent: 'count',
    );
  }

  static Future<NLQueryResult> _querySummary(
    DatabaseHelper db,
    String message,
  ) async {
    final all = await db.getAllItems();
    final total = all.length;
    final expired = all.where((i) => i.isExpired).length;
    final expiring = all.where((i) => i.isExpiringSoon).length;
    final categories = all.map((i) => i.category).toSet().length;

    // 按分类统计
    final catCounts = <String, int>{};
    for (final item in all) {
      catCounts[item.category] = (catCounts[item.category] ?? 0) + 1;
    }
    final topCats = catCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCatStr = topCats.take(5).map((e) => '${e.key}(${e.value}件)').join('、');

    final msg = message + '\n'
        '📊 共 $total 件物品，$categories 个分类\n'
        '🔴 已过期 $expired 件 | 🟡 $expiring 件即将过期\n'
        '📂 热门分类：$topCatStr';

    return NLQueryResult(
      message: msg,
      items: all,
      rawIntent: 'summary',
    );
  }

  // ═══════════════════════════════════════════
  //  辅助方法
  // ═══════════════════════════════════════════

  static void _sortItems(List<Item> items, String sortBy, String order) {
    final asc = order == 'asc';
    switch (sortBy) {
      case 'name':
        items.sort((a, b) => asc
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name));
        break;
      case 'expiry_date':
        items.sort((a, b) {
          if (a.expiryDate == null && b.expiryDate == null) return 0;
          if (a.expiryDate == null) return asc ? 1 : -1;
          if (b.expiryDate == null) return asc ? -1 : 1;
          return asc
              ? a.expiryDate!.compareTo(b.expiryDate!)
              : b.expiryDate!.compareTo(a.expiryDate!);
        });
        break;
      case 'category':
        items.sort((a, b) => asc
            ? a.category.compareTo(b.category)
            : b.category.compareTo(a.category));
        break;
      default:
        items.sort((a, b) => asc
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt));
    }
  }

  /// 关键词搜索降级方案（无 API Key 时使用）
  static Future<NLQueryResult> _keywordFallback(String query) async {
    final db = DatabaseHelper.instance;
    final items = await db.getAllItems(searchQuery: query);

    if (items.isEmpty) {
      return NLQueryResult(
        message: '没有找到匹配的物品。试试其他关键词？',
        items: [],
        rawIntent: 'keyword_fallback',
      );
    }

    return NLQueryResult(
      message: '找到 ${items.length} 件相关物品。',
      items: items,
      rawIntent: 'keyword_fallback',
    );
  }
}
