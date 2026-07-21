# HomeStash API 内部接口规范

## 数据库访问接口

### DatabaseHelper
```dart
// 物品操作
Future<int> insertItem(Item item)
Future<int> updateItem(Item item)
Future<int> deleteItem(int id)
Future<Item?> getItem(int id)
Future<List<Item>> getAllItems({searchQuery, category, location, spaceId})

// 空间操作
Future<int> insertSpace(StorageSpace space)
Future<int> updateSpace(StorageSpace space)
Future<int> deleteSpace(int id)
Future<StorageSpace?> getSpace(int id)
Future<List<StorageSpace>> getAllSpaces()
Future<List<StorageSpace>> getRootSpaces()
Future<List<StorageSpace>> getChildSpaces(int parentId)
Future<List<StorageSpace>> getSpaceAncestors(int spaceId)
Future<int> getItemCountInSpace(int spaceId)
Future<int> getSpaceCount()

// 辅助
Future<List<String>> getCategories()
Future<List<String>> getLocations()
Future<int> getCount()
```

## AI 服务接口

### PhotoAnalyzerService (GLM-4V)
```dart
// 分析照片，返回物品名称和分类建议
static Future<PhotoAnalysisResult?> analyzePhoto(String imagePath)
// 返回 null 表示 API 不可用或识别失败
```

### ImageRecognitionService (本地代理 fallback)
```dart
// 通过本地 HTTP 代理进行图片分类
static Future<Map<String, String>> classifyImage(String imagePath)
// 返回 {"name": "...", "category": "..."}，失败返回空字符串
```

## 错误处理
- 所有 DB 操作返回 Future，调用方确保 try-catch
- UI 层捕获异常后显示 SnackBar
- 不可恢复错误（数据库损坏）弹出错误对话框
- AI 识别服务：网络超时 30s，失败返回 null，不影响正常使用
- 网络错误静默降级，用户可手动输入物品信息
