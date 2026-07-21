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
Future<List<StorageSpace>> getRootSpaces()
Future<List<StorageSpace>> getChildSpaces(int parentId)
Future<List<StorageSpace>> getSpaceAncestors(int spaceId)
Future<int> getItemCountInSpace(int spaceId)

// 辅助
Future<List<String>> getCategories()
Future<List<String>> getLocations()
Future<int> getCount()
```

## 错误处理
- 所有 DB 操作返回 Future，调用方确保 try-catch
- UI 层捕获异常后显示 SnackBar
- 不可恢复错误（数据库损坏）弹出错误对话框
