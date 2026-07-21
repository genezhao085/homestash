import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// AI 照片分析服务 — 使用 GLM 视觉识别物品名称和分类
class PhotoAnalyzerService {
  static const String _apiUrl = 'https://open.bigmodel.cn/api/paas/v4/chat/completions';
  static const String _model = 'glm-4v'; // 使用 GLM-4V 视觉模型

  /// 从 .env 文件读取 API Key
  static Future<String?> _loadApiKey() async {
    try {
      final envFile = File('${Platform.environment['HOME'] ?? '.'}/.hermes/.env');
      if (await envFile.exists()) {
        final lines = await envFile.readAsLines();
        for (final line in lines) {
          if (line.startsWith('GLM_API_KEY=')) {
            return line.substring('GLM_API_KEY='.length).trim();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// 分析照片并返回建议的名称和分类
  static Future<PhotoAnalysisResult?> analyzePhoto(String imagePath) async {
    final apiKey = await _loadApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      // 读取图片并转 Base64
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final ext = imagePath.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

      final body = jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:$mimeType;base64,$base64Image'}
              },
              {
                'type': 'text',
                'text': '请识别这张照片中的物品，用JSON格式回复，包含两个字段：'
                    '"name"（物品名称，中文，简洁），'
                    '"category"（最适合的分类，从以下选择：'
                    '厨房用品、衣物、工具箱、电子产品、药品、'
                    '文件资料、玩具游戏、清洁用品、装饰品、运动器材、其他）。'
                    '仅返回JSON，不要其他文字。'
              }
            ]
          }
        ],
        'max_tokens': 200,
      });

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final content = data['choices']?[0]?['message']?['content'] ?? '';

      // 解析 JSON 响应
      try {
        final parsed = jsonDecode(content);
        return PhotoAnalysisResult(
          name: parsed['name']?.toString().trim() ?? '',
          category: parsed['category']?.toString().trim() ?? '',
        );
      } catch (_) {
        // 尝试从文本中提取 JSON
        final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(content);
        if (jsonMatch != null) {
          final parsed = jsonDecode(jsonMatch.group(0)!);
          return PhotoAnalysisResult(
            name: parsed['name']?.toString().trim() ?? '',
            category: parsed['category']?.toString().trim() ?? '',
          );
        }
      }
    } catch (_) {}

    return null;
  }
}

class PhotoAnalysisResult {
  final String name;
  final String category;

  const PhotoAnalysisResult({required this.name, required this.category});

  bool get isValid => name.isNotEmpty;
}
