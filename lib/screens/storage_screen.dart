import 'package:flutter/material.dart';
import '../models/storage_space.dart';
import '../utils/database_helper.dart';
import '../utils/app_theme.dart';
import '../widgets/shimmer_loading.dart';
import 'add_space_screen.dart';
import 'items_in_space_screen.dart';

/// 收纳空间浏览器 - 树形展示所有存储空间
class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  final _db = DatabaseHelper.instance;
  List<_SpaceNode> _rootNodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

  Future<void> _loadSpaces() async {
    setState(() => _isLoading = true);
    final roots = await _db.getRootSpaces();
    final nodes = <_SpaceNode>[];
    for (final root in roots) {
      final node = await _buildNode(root);
      nodes.add(node);
    }
    if (mounted) {
      setState(() {
        _rootNodes = nodes;
        _isLoading = false;
      });
    }
  }

  Future<_SpaceNode> _buildNode(StorageSpace space) async {
    final children = await _db.getChildSpaces(space.id!);
    final itemCount = await _db.getItemCountInSpace(space.id!);
    final childNodes = <_SpaceNode>[];
    for (final child in children) {
      childNodes.add(await _buildNode(child));
    }
    return _SpaceNode(
        space: space, children: childNodes, itemCount: itemCount);
  }

  IconData _spaceIcon(String type) {
    switch (type) {
      case 'room':
        return Icons.meeting_room_rounded;
      case 'cabinet':
        return Icons.deck_rounded;
      case 'shelf':
        return Icons.view_list_rounded;
      case 'drawer':
        return Icons.draw_rounded;
      case 'box':
        return Icons.inventory_2_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Color _spaceColor(String type) {
    switch (type) {
      case 'room':
        return Colors.blue;
      case 'cabinet':
        return Colors.orange;
      case 'shelf':
        return Colors.teal;
      case 'drawer':
        return Colors.purple;
      case 'box':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _deleteSpace(StorageSpace space) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
            '删除「${space.name}」后，其子空间将变为独立空间，其中的物品将不再关联到此空间。\n确定删除吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('删除')),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteSpace(space.id!);
      await _loadSpaces();
    }
  }

  Widget _buildSpaceTile(_SpaceNode node, int depth) {
    final space = node.space;
    final hasChildren = node.children.isNotEmpty;
    final typeName = SpaceTypes.displayName(space.type);

    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _spaceColor(space.type).withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_spaceIcon(space.type),
                color: _spaceColor(space.type), size: 24),
          ),
          title: Text(space.name,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _spaceColor(space.type).withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(typeName,
                    style: TextStyle(
                        fontSize: 11, color: _spaceColor(space.type))),
              ),
              const SizedBox(width: 8),
              Icon(Icons.inventory_2, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 3),
              Text('${node.itemCount}件',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') {
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AddSpaceScreen(existingSpace: space)));
                if (result == true) _loadSpaces();
              } else if (v == 'add_child') {
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AddSpaceScreen(parentSpace: space)));
                if (result == true) _loadSpaces();
              } else if (v == 'delete') {
                _deleteSpace(space);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                      leading: Icon(Icons.edit, size: 20),
                      title: Text('编辑'),
                      dense: true)),
              if (SpaceTypes.childrenTypes(space.type).isNotEmpty)
                const PopupMenuItem(
                    value: 'add_child',
                    child: ListTile(
                        leading: Icon(Icons.add, size: 20),
                        title: Text('添加子空间'),
                        dense: true)),
              const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                      leading: Icon(Icons.delete, size: 20, color: Colors.red),
                      title: Text('删除',
                          style: TextStyle(color: Colors.red)),
                      dense: true)),
            ],
          ),
          onTap: () async {
            final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ItemsInSpaceScreen(space: space)));
            if (result == true) _loadSpaces();
          },
          contentPadding:
              EdgeInsets.only(left: 16.0 + depth * 24, right: 4),
        ),
        if (hasChildren)
          ...node.children
              .map((child) => _buildSpaceTile(child, depth + 1)),
        if (depth == 0 || hasChildren)
          Divider(
              height: 1,
              indent: 16.0 + depth * 24,
              color: Colors.grey[200]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收纳空间'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: '添加空间',
            onPressed: () async {
              final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddSpaceScreen()));
              if (result == true) _loadSpaces();
            },
          ),
        ],
      ),
      body: _isLoading
          ? ShimmerLoading.spaceTiles()
          : _rootNodes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadSpaces,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _rootNodes
                        .map((node) => _buildSpaceTile(node, 0))
                        .toList(),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withAlpha(40),
                    AppColors.primary.withAlpha(20),
                  ],
                ),
                border: Border.all(
                  color: AppColors.primary.withAlpha(60),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.meeting_room_rounded,
                size: 54,
                color: AppColors.primary.withAlpha(180),
              ),
            ),
            const SizedBox(height: 20),
            Text('还没有配置收纳空间',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '先添加房间，再逐步细化到柜子、抽屉',
              style:
                  TextStyle(color: Theme.of(context).colorScheme.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddSpaceScreen()));
                if (result == true) _loadSpaces();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加第一个空间'),
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
}

class _SpaceNode {
  final StorageSpace space;
  final List<_SpaceNode> children;
  final int itemCount;

  const _SpaceNode(
      {required this.space, this.children = const [], this.itemCount = 0});
}
