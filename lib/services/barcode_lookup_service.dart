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
  String toString() => 'ProductInfo(name: $name, category: $category, brand: $brand)';
}

/// 条码查询服务 —— 基于 Open Food Facts 免费 API
class BarcodeLookupService {
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  /// 根据条码查询商品信息，返回 [ProductInfo]。
  /// 查询失败或未找到时返回 [ProductInfo.empty]。
  static Future<ProductInfo> lookup(String barcode) async {
    try {
      final uri = Uri.parse('$_baseUrl/$barcode');
      final response = await http.get(uri, headers: {
        'User-Agent': 'HomeStash - 家庭储物管理/1.0',
      });

      if (response.statusCode != 200) {
        return ProductInfo.empty();
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 1) {
        // 产品未找到
        return ProductInfo.empty();
      }

      final product = data['product'] as Map<String, dynamic>?;
      if (product == null) {
        return ProductInfo.empty();
      }

      final name = _bestString(
        product['product_name'],
        product['generic_name'],
        product['product_name_zh'],
      );
      final category = _bestString(
        product['categories_tags'] is List
            ? _parseCategory((product['categories_tags'] as List).cast<String>())
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

  /// 解析分类标签（取第一项并格式化）
  static String _parseCategory(List<String> tags) {
    if (tags.isEmpty) return '';
    return tags
        .map((t) => t.replaceAll('en:', '').replaceAll('zh:', '').replaceAll('-', ' '))
        .first;
  }

  /// 取第一个非空字符串
  static String _bestString(dynamic a, dynamic b, [dynamic c]) {
    for (final v in [a, b, c]) {
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return '';
  }
}
