import 'dart:convert';
import 'package:http/http.dart' as http;

/// 商品条码查询结果
class ProductInfo {
  final String name;
  final String category;
  final String brand;
  final String? imageUrl;
  final String? description;

  const ProductInfo({
    required this.name,
    required this.category,
    required this.brand,
    this.imageUrl,
    this.description,
  });

  factory ProductInfo.empty() {
    return const ProductInfo(name: '', category: '', brand: '');
  }

  bool get isEmpty => name.isEmpty;

  @override
  String toString() =>
      'ProductInfo(name: $name, category: $category, brand: $brand)';
}

/// 条码查询服务 —— 多源免费 API + 降级策略
class BarcodeLookupService {
  static const _timeout = Duration(seconds: 5);
  static const _ua = 'HomeStash - 家庭储物管理/1.1';

  // ─── Open Food Facts ────────────────────────────────────────────
  static const _offBase = 'https://world.openfoodfacts.org/api/v2/product';

  /// 根据条码查询商品信息。按以下顺序降级查询：
  /// 1. Open Food Facts（免费，食品覆盖好）
  /// 2. 中国物品编码中心（anccnet，国内商品）
  /// 3. UPCDatabase.org（通用，免费额度有限）
  /// 4. 返回空结果 → 调用方仅用条码号
  static Future<ProductInfo> lookup(String barcode) async {
    // 1. Open Food Facts
    final offResult = await _queryOpenFoodFacts(barcode);
    if (!offResult.isEmpty) return offResult;

    // 2. 中国物品编码中心
    final cnResult = await _queryChineseDB(barcode);
    if (!cnResult.isEmpty) return cnResult;

    // 3. UPCDatabase
    final upcResult = await _queryUPCDatabase(barcode);
    if (!upcResult.isEmpty) return upcResult;

    // 4. 无结果
    return ProductInfo.empty();
  }

  // ── Source 1: Open Food Facts ────────────────────────────────────
  static Future<ProductInfo> _queryOpenFoodFacts(String barcode) async {
    try {
      final uri = Uri.parse('$_offBase/$barcode');
      final response = await http
          .get(uri, headers: {'User-Agent': _ua})
          .timeout(_timeout);

      if (response.statusCode != 200) return ProductInfo.empty();

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 1) return ProductInfo.empty();

      final product = data['product'] as Map<String, dynamic>?;
      if (product == null) return ProductInfo.empty();

      final name = _bestString(
        product['product_name'],
        product['generic_name'],
        product['product_name_zh'],
      );
      final category = _bestString(
        product['categories_tags'] is List
            ? _parseCategory(
                (product['categories_tags'] as List).cast<String>())
            : null,
        product['pnns_groups_1'],
        product['categories'],
      );
      final brand = _bestString(
        product['brands'],
        product['brand_owner'],
      );
      final imageUrl = product['image_front_small_url'] as String?;
      final description = _bestString(
        product['generic_name'],
        product['ingredients_text'],
      );

      return ProductInfo(
        name: name,
        category: category,
        brand: brand,
        imageUrl: imageUrl,
        description: description,
      );
    } catch (_) {
      return ProductInfo.empty();
    }
  }

  // ── Source 2: 中国物品编码中心 ────────────────────────────────────
  static Future<ProductInfo> _queryChineseDB(String barcode) async {
    // 优先尝试 anccnet 搜索页面（HTML 解析）
    try {
      final uri = Uri.parse(
          'https://search.anccnet.com/searchResult2.aspx?keyword=$barcode');
      final response = await http
          .get(uri, headers: {'User-Agent': _ua})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final result = _parseAnccnetHtml(response.body, barcode);
        if (result != null) return result;
      }
    } catch (_) {
      // 降级到下一个源
    }

    // 备选源：tiaoma.cnaidc.com
    try {
      final uri = Uri.parse('https://www.tiaoma.cnaidc.com/$barcode.html');
      final response = await http
          .get(uri, headers: {'User-Agent': _ua})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final result = _parseTiaomaHtml(response.body, barcode);
        if (result != null) return result;
      }
    } catch (_) {
      // 降级
    }

    return ProductInfo.empty();
  }

  /// 解析 anccnet 搜索结果页
  static ProductInfo? _parseAnccnetHtml(String html, String barcode) {
    // 尝试从 HTML 中提取商品名称和厂商
    String name = '';
    String brand = '';
    String category = '';

    // 简单的 HTML 内容提取 —— 查找表格中的数据
    // anccnet 返回表格包含：条码、名称、规格、企业名称
    final tablePattern = RegExp(
      r'<td[^>]*>\s*${RegExp.escape(barcode)}\s*</td>'
      r'[^<]*<td[^>]*>\s*([^<]+)\s*</td>'
      r'[^<]*<td[^>]*>\s*([^<]*)\s*</td>'
      r'[^<]*<td[^>]*>\s*([^<]+)\s*</td>',
      dotAll: true,
    );

    final match = tablePattern.firstMatch(html);
    if (match != null) {
      name = match.group(1)?.trim() ?? '';
      // group(2) is 规格 (specs), group(3) is 企业名称 (company)
      brand = match.group(3)?.trim() ?? '';
      if (match.group(2)?.trim().isNotEmpty == true) {
        category = '日用品';
      }
    }

    // 备选：查找标题中的商品信息
    if (name.isEmpty) {
      final titlePattern = RegExp(
        r'条码\s*${RegExp.escape(barcode)}\s*[：:]\s*([^<\n]+)',
        dotAll: true,
      );
      final titleMatch = titlePattern.firstMatch(html);
      if (titleMatch != null) {
        name = titleMatch.group(1)?.trim() ?? '';
      }
    }

    if (name.isEmpty) return null;

    return ProductInfo(name: name, category: category, brand: brand);
  }

  /// 解析 tiaoma.cnaidc.com 页面
  static ProductInfo? _parseTiaomaHtml(String html, String barcode) {
    // tiaoma 页面结构相对简单
    String name = '';
    String brand = '';

    // 查找页面标题或商品名称
    final namePatterns = [
      RegExp(r'<h1[^>]*>([^<]+)</h1>'),
      RegExp(r'商品名称[：:]\s*([^<\n]+)'),
      RegExp(r'产品名称[：:]\s*([^<\n]+)'),
      RegExp(r'企业名称[：:]\s*([^<\n]+)'),
    ];

    for (final pattern in namePatterns) {
      final match = pattern.firstMatch(html);
      if (match != null) {
        final text = match.group(1)?.trim() ?? '';
        if (text.isNotEmpty && !text.contains('条码') && !text.contains('查询')) {
          name = text;
          break;
        }
      }
    }

    // 企业名
    final brandPattern = RegExp(r'企业名称[：:]\s*([^<\n]+)');
    final brandMatch = brandPattern.firstMatch(html);
    if (brandMatch != null) {
      brand = brandMatch.group(1)?.trim() ?? '';
    }

    if (name.isEmpty) return null;

    return ProductInfo(
      name: name,
      category: '日用品',
      brand: brand,
    );
  }

  // ── Source 3: UPCDatabase.org ────────────────────────────────────
  static Future<ProductInfo> _queryUPCDatabase(String barcode) async {
    try {
      final uri = Uri.parse('https://api.upcdatabase.org/product/$barcode');
      final response = await http
          .get(uri, headers: {'User-Agent': _ua})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success'] == true || data['title'] != null) {
            return ProductInfo(
              name: (data['title'] as String?) ?? '',
              category: (data['category'] as String?) ?? '',
              brand: (data['brand'] as String?) ?? '',
              description: (data['description'] as String?) ?? '',
            );
          }
        } catch (_) {
          // JSON 解析失败
        }
      }
    } catch (_) {
      // 降级
    }

    // 备选：go-upc.com HTML 查询
    try {
      final uri = Uri.parse('https://go-upc.com/search?q=$barcode');
      final response = await http
          .get(uri, headers: {'User-Agent': _ua})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        // 尝试提取商品名称
        final namePattern =
            RegExp(r'<h1[^>]*class="[^"]*product-name[^"]*"[^>]*>([^<]+)</h1>',
                dotAll: true);
        final match = namePattern.firstMatch(response.body);
        if (match != null) {
          return ProductInfo(
            name: match.group(1)?.trim() ?? '',
            category: '',
            brand: '',
          );
        }
      }
    } catch (_) {
      // 降级
    }

    return ProductInfo.empty();
  }

  // ── Helpers ──────────────────────────────────────────────────────
  static String _parseCategory(List<String> tags) {
    if (tags.isEmpty) return '';
    return tags
        .map((t) =>
            t.replaceAll('en:', '').replaceAll('zh:', '').replaceAll('-', ' '))
        .first;
  }

  static String _bestString(dynamic a, dynamic b, [dynamic c]) {
    for (final v in [a, b, c]) {
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return '';
  }
}
