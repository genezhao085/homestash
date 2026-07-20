import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/storage_space.dart';
import '../utils/database_helper.dart';
import '../widgets/item_card.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

/// 空间中的物品列表
class ItemsInSpaceScreen extends StatefulWidget {
  final StorageSpace space;

  const ItemsInSpaceScreen({super.key, required this.space});

  @override
  State<ItemsInSpaceScreen> createState() => _ItemsInSpaceScreenState();
}

class _ItemsInSpaceScreenState extends State<ItemsInSpaceScreen> {
  final _db = DatabaseHelper.instance;
  List<Item> _items = [];
  List<StorageSpace> _subSpaces = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final items = await _db.getAllItems(
      spaceId: widget.space.id,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      category: _selectedCategory,
    );
    final subSpaces = await _db.getChildSpaces(widget.space.id!);
    final categories = await _db.getCategories();
    if (mounted) setState(() { _items = items; _subSpaces = subSpaces; _categories = categories; _isLoading = false; });
  }

  void _deleteItem(Item item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${item.name}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('删除')),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteItem(item.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.space.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: '添加物品到此空间',
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddItemScreen(preselectedSpace: widget.space),
              ));
              if (result == true) _loadData();
            },
          ),
        ],
        bottom: _categories.isNotEmpty ? PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('全部'),
                    selected: _selectedCategory == null,
                    onSelected: (_) { setState(() => _selectedCategory = null); _loadData(); },
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 6),
                  ..._categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(cat),
                      selected: _selectedCategory == cat,
                      onSelected: (_) { setState(() => _selectedCategory = cat); _loadData(); },
                      visualDensity: VisualDensity.compact,
                    ),
                  )),
                ],
              ),
            ),
          ),
        ) : null,
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索此空间中的物品',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { setState(() => _searchQuery = ''); _loadData(); })
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) { setState(() => _searchQuery = v); _loadData(); },
            ),
          ),

          // Sub-spaces section
          if (_subSpaces.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                itemCount: _subSpaces.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final ss = _subSpaces[i];
                  return _SubSpaceChip(
                    space: ss,
                    onTap: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ItemsInSpaceScreen(space: ss),
                      ));
                      if (result == true) _loadData();
                    },
                  );
                },
              ),
            ),

          // Items
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory_2_rounded, size: 64, color: Theme.of(context).colorScheme.outline),
                              const SizedBox(height: 12),
                              Text(_searchQuery.isNotEmpty ? '没有找到匹配的物品' : '此空间还没有物品', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 16),
                              if (_searchQuery.isEmpty)
                                FilledButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => AddItemScreen(preselectedSpace: widget.space),
                                    ));
                                    if (result == true) _loadData();
                                  },
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('添加物品到此空间'),
                                ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final item = _items[i];
                            return ItemCard(
                              item: item,
                              onTap: () async {
                                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)));
                                if (result == true) _loadData();
                              },
                              onDelete: () => _deleteItem(item),
                              showSpace: false,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(
            builder: (_) => AddItemScreen(preselectedSpace: widget.space),
          ));
          if (result == true) _loadData();
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _SubSpaceChip extends StatelessWidget {
  final StorageSpace space;
  final VoidCallback onTap;

  const _SubSpaceChip({required this.space, required this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (space.type) {
      case 'cabinet': icon = Icons.deck_rounded; break;
      case 'shelf': icon = Icons.view_list_rounded; break;
      case 'drawer': icon = Icons.draw_rounded; break;
      case 'box': icon = Icons.inventory_2_rounded; break;
      default: icon = Icons.place_rounded;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(space.name, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
