import 'package:flutter/material.dart';
import '../models/item.dart';
import '../utils/database_helper.dart';
import '../utils/app_theme.dart';
import '../widgets/item_card.dart';
import '../widgets/shimmer_loading.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';
import 'storage_screen.dart';

/// 首页 - 底部导航容器
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
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
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          _loadData();
                        })
                    : null,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
          if (result == true) _loadData();
        },
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text('添加物品'),
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
}
