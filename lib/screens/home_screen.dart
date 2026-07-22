import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/item.dart';
import '../utils/database_helper.dart';
import '../utils/app_theme.dart';
import '../services/export_import_service.dart';
import '../widgets/item_card.dart';
import '../widgets/shimmer_loading.dart';
import 'add_item_screen.dart';
import 'ai_query_screen.dart';
import 'barcode_scanner_screen.dart';
import 'item_detail_screen.dart';
import 'storage_screen.dart';

/// 导出/导入操作类型
enum _ExportAction {
  exportJson,
  exportCsv,
  importBackup,
}

/// 首页 - 底部导航容器
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1;

  final _pages = <Widget>[
    const _ItemListPage(),
    const StorageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.inventory_2_rounded), label: '物品'),
          NavigationDestination(
              icon: Icon(Icons.meeting_room_rounded), label: '空间'),
        ],
      ),
    );
  }
}

/// 物品列表页（原 HomeScreen 的内容）
class _ItemListPage extends StatefulWidget {
  const _ItemListPage();

  @override
  State<_ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<_ItemListPage> {
  final _db = DatabaseHelper.instance;
  List<Item> _items = [];
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedLocation;
  List<String> _categories = [];
  List<String> _locations = [];
  bool _isLoading = true;
  bool _isFabOpen = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final items = await _db.getAllItems(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _selectedCategory,
        location: _selectedLocation,
      );
      final categories = await _db.getCategories();
      final locations = await _db.getLocations();
      if (mounted) {
        setState(() {
          _items = items;
          _categories = categories;
          _locations = locations;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('_loadData error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleFab() {
    setState(() => _isFabOpen = !_isFabOpen);
  }

  void _showDeleteConfirm(Item item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${item.name}」吗？\n此操作不可撤销。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _db.deleteItem(item.id!);
              _loadData();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('筛选条件', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('分类', style: Theme.of(ctx).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                    label: const Text('全部'),
                    selected: _selectedCategory == null,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = null)),
                ..._categories.map((cat) => FilterChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat))),
              ],
            ),
            const SizedBox(height: 16),
            Text('位置', style: Theme.of(ctx).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                    label: const Text('全部'),
                    selected: _selectedLocation == null,
                    onSelected: (_) =>
                        setState(() => _selectedLocation = null)),
                ..._locations.map((loc) => FilterChip(
                    label: Text(loc),
                    selected: _selectedLocation == loc,
                    onSelected: (_) =>
                        setState(() => _selectedLocation = loc))),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                        _selectedLocation = null;
                      });
                      _loadData();
                      Navigator.pop(ctx);
                    },
                    child: const Text('清除筛选')),
                FilledButton(
                    onPressed: () {
                      _loadData();
                      Navigator.pop(ctx);
                    },
                    child: const Text('应用')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('家庭储物管家'),
        actions: [
          PopupMenuButton<_ExportAction>(
            icon: const Icon(Icons.more_vert),
            tooltip: '更多操作',
            onSelected: _handleExportAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _ExportAction.exportJson,
                child: ListTile(
                  leading: Icon(Icons.code),
                  title: Text('导出 JSON 备份'),
                  subtitle: Text('包含所有物品和空间数据'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _ExportAction.exportCsv,
                child: ListTile(
                  leading: Icon(Icons.table_chart),
                  title: Text('导出 CSV'),
                  subtitle: Text('仅物品数据'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _ExportAction.importBackup,
                child: ListTile(
                  leading: Icon(Icons.file_upload),
                  title: Text('导入备份'),
                  subtitle: Text('从 JSON/CSV 文件恢复数据'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterSheet,
              tooltip: '筛选'),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索物品名称、分类、位置...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          _loadData();
                        }),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.green100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                      ),
                      tooltip: 'AI 自然语言查询',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AIQueryScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v);
                _loadData();
              },
            ),
          ),
          if (_selectedCategory != null || _selectedLocation != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text('共 ${_items.length} 件物品',
                      style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = null;
                          _selectedLocation = null;
                        });
                        _loadData();
                      },
                      child: const Text('清除筛选')),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? ShimmerLoading.itemCards()
                : _items.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return ItemCard(
                              index: index,
                              item: item,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ItemDetailScreen(item: item),
                                  ),
                                );
                                if (result == true) _loadData();
                              },
                              onDelete: () => _showDeleteConfirm(item),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 展开的子 FAB 按钮
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.bottomCenter,
            child: _isFabOpen
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 扫码入库
                        _SubFab(
                          icon: Icons.qr_code_scanner_rounded,
                          label: '扫码入库',
                          onTap: () async {
                            _toggleFab();
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const BarcodeScannerScreen(),
                              ),
                            );
                            if (result == true) _loadData();
                          },
                        ),
                        const SizedBox(height: 10),
                        // 添加物品
                        _SubFab(
                          icon: Icons.add_photo_alternate_rounded,
                          label: '添加物品',
                          onTap: () async {
                            _toggleFab();
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddItemScreen(),
                              ),
                            );
                            if (result == true) _loadData();
                          },
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // 主 FAB —— 展开/收起
          FloatingActionButton.extended(
            onPressed: _toggleFab,
            icon: AnimatedRotation(
              turns: _isFabOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.add_rounded),
            ),
            label: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilter = _searchQuery.isNotEmpty ||
        _selectedCategory != null ||
        _selectedLocation != null;

    if (hasFilter) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIllustration(icon: Icons.search_off, color: AppColors.warmGray400),
              const SizedBox(height: 20),
              Text('没有找到匹配的物品',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '试试调整搜索条件或清除筛选',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.outline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = null;
                    _selectedLocation = null;
                  });
                  _loadData();
                },
                child: const Text('清除所有条件'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIllustration(
                icon: Icons.inventory_2_rounded,
                color: AppColors.primary),
            const SizedBox(height: 20),
            Text('欢迎使用家庭储物管家',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '还没有记录任何物品，现在开始整理你的家庭储物吧',
              style:
                  TextStyle(color: Theme.of(context).colorScheme.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddItemScreen()),
              ),
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('添加第一个物品'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建装饰性插画外框
  Widget _buildIllustration({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withAlpha(40),
            color.withAlpha(20),
          ],
        ),
        border: Border.all(
          color: color.withAlpha(60),
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: 54,
        color: color.withAlpha(180),
      ),
    );
  }

  // ====================== 导出/导入 ======================

  void _handleExportAction(_ExportAction action) {
    switch (action) {
      case _ExportAction.exportJson:
        _exportJson();
      case _ExportAction.exportCsv:
        _exportCsv();
      case _ExportAction.importBackup:
        _importBackup();
    }
  }

  Future<void> _exportJson() async {
    try {
      final items = await _db.getAllItems();
      final spaces = await _db.getAllSpaces();
      final jsonStr = ExportImportService.exportToJson(
        items: items,
        spaces: spaces,
      );

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final file = File('${dir.path}/homestash_backup_$timestamp.json');
      await file.writeAsString(jsonStr);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '家庭储物管家备份',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('导出失败：$e');
      }
    }
  }

  Future<void> _exportCsv() async {
    try {
      final items = await _db.getAllItems();
      final csvStr = ExportImportService.exportItemsToCsv(items);

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final file = File('${dir.path}/homestash_items_$timestamp.csv');
      await file.writeAsString(csvStr);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '家庭储物管家 - 物品列表',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('导出失败：$e');
      }
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final ext = result.files.single.extension?.toLowerCase();

      // 询问导入策略
      final strategy = await _showStrategyDialog();
      if (strategy == null) return; // 用户取消

      ImportResult importResult;
      if (ext == 'json') {
        importResult = await ExportImportService.importFromJson(
          jsonString: content,
          dbHelper: _db,
          strategy: strategy,
        );
      } else {
        importResult = await ExportImportService.importFromCsv(
          csvString: content,
          dbHelper: _db,
          strategy: strategy,
        );
      }

      if (mounted) {
        _showImportResultDialog(importResult);
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('导入失败：$e');
      }
    }
  }

  Future<String?> _showStrategyDialog() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入方式'),
        content: const Text('请选择数据导入方式：\n\n• 合并：保留现有数据，追加导入\n• 替换：先清空所有数据，再导入'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, 'merge'),
            child: const Text('合并'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'replace'),
            child: const Text('替换'),
          ),
        ],
      ),
    );
  }

  void _showImportResultDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.hasErrors ? Icons.warning_amber : Icons.check_circle,
              color: result.hasErrors ? Colors.orange : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(result.hasErrors ? '导入完成（有警告）' : '导入成功'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.itemsImported > 0)
              Text('✓ 导入物品：${result.itemsImported} 件'),
            if (result.spacesImported > 0)
              Text('✓ 导入空间：${result.spacesImported} 个'),
            if (result.itemsSkipped > 0)
              Text('⚠ 跳过：${result.itemsSkipped} 件'),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              ...result.errors.take(5).map((e) => Text('• $e',
                  style: const TextStyle(fontSize: 12, color: Colors.red))),
              if (result.errors.length > 5)
                Text('...及其他 ${result.errors.length - 5} 条错误',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 子 FAB 按钮 —— 带标签的小型悬浮菜单项
class _SubFab extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SubFab({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: cs.onSecondaryContainer),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
