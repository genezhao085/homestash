import 'package:flutter/material.dart';
import '../models/item.dart';
import '../utils/database_helper.dart';
import '../widgets/item_card.dart';
import '../widgets/shimmer_loading.dart';
import 'item_detail_screen.dart';

/// 过期物品列表页
/// 支持按过期状态筛选、按过期时间/名称排序
class ExpiringItemsScreen extends StatefulWidget {
  const ExpiringItemsScreen({super.key});

  @override
  State<ExpiringItemsScreen> createState() => _ExpiringItemsScreenState();
}

class _ExpiringItemsScreenState extends State<ExpiringItemsScreen> {
  final _db = DatabaseHelper.instance;
  List<Item> _items = [];
  bool _isLoading = true;

  String _filter = 'all'; // 'all' | 'expired' | 'expiring_soon'
  String _sortBy = 'expiry_asc'; // 'expiry_asc' | 'expiry_desc' | 'name_asc'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final items = await _db.getItemsWithExpiry(
        filter: _filter,
        sortBy: _sortBy,
      );
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载失败: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getFilterLabel() {
    switch (_filter) {
      case 'expired':
        return '已过期';
      case 'expiring_soon':
        return '即将过期';
      default:
        return '全部';
    }
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'expiry_desc':
        return '过期时间 ↓';
      case 'name_asc':
        return '名称 ↑';
      default:
        return '过期时间 ↑';
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('筛选条件',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('状态', style: Theme.of(ctx).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('全部'),
                  selected: _filter == 'all',
                  onSelected: (_) => setState(() => _filter = 'all'),
                ),
                FilterChip(
                  label: const Text('已过期'),
                  selected: _filter == 'expired',
                  onSelected: (_) => setState(() => _filter = 'expired'),
                ),
                FilterChip(
                  label: const Text('即将过期（7天内）'),
                  selected: _filter == 'expiring_soon',
                  onSelected: (_) =>
                      setState(() => _filter = 'expiring_soon'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('排序', style: Theme.of(ctx).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('过期时间 ↑（最近）'),
                  selected: _sortBy == 'expiry_asc',
                  onSelected: (_) =>
                      setState(() => _sortBy = 'expiry_asc'),
                ),
                FilterChip(
                  label: const Text('过期时间 ↓（最远）'),
                  selected: _sortBy == 'expiry_desc',
                  onSelected: (_) =>
                      setState(() => _sortBy = 'expiry_desc'),
                ),
                FilterChip(
                  label: const Text('名称 ↑'),
                  selected: _sortBy == 'name_asc',
                  onSelected: (_) =>
                      setState(() => _sortBy = 'name_asc'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filter = 'all';
                      _sortBy = 'expiry_asc';
                    });
                    _loadData();
                    Navigator.pop(ctx);
                  },
                  child: const Text('重置'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    _loadData();
                    Navigator.pop(ctx);
                  },
                  child: const Text('应用'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(Item item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${item.name}」吗？\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('过期物品管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: '筛选与排序',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // 状态栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  _filter == 'expired'
                      ? Icons.warning_rounded
                      : Icons.event_busy,
                  size: 18,
                  color: _filter == 'expired' ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_getFilterLabel()} · ${_getSortLabel()} · ${_items.length} 件',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // 列表
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
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    switch (_filter) {
      case 'expired':
        message = '太棒了！没有已过期的物品';
        icon = Icons.celebration;
        break;
      case 'expiring_soon':
        message = '近期没有即将过期的物品';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = '还没有设置过期日期的物品';
        icon = Icons.event_note;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '为物品添加过期日期可在此处查看',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
