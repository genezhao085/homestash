import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// 调用本地翻译代理进行图片智能识别
class ImageRecognitionService {
  static const _proxyUrl = 'http://127.0.0.1:8091/v1/classify';

  /// 识别图片中的物品，返回 {name, category}
  static Future<Map<String, String>> classifyImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        return {'name': '', 'category': ''};
      }

      // 压缩图片到合适大小
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_base64': base64}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'name': data['name'] as String? ?? '',
            'category': data['category'] as String? ?? '',
          };
        }
      }
    } catch (e) {
      // 识别失败不影响正常使用
      print('Image classification error: $e');
    }
    return {'name': '', 'category': ''};
  }
}
