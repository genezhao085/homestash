import 'dart:io';
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../utils/database_helper.dart';
import 'add_item_screen.dart';

/// 物品详情页面
class ItemDetailScreen extends StatefulWidget {
  final Item item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _db = DatabaseHelper.instance;
  String _spacePath = '';

  @override
  void initState() {
    super.initState();
    _loadSpacePath();
  }

  Future<void> _loadSpacePath() async {
    if (widget.item.spaceId != null) {
      final ancestors = await _db.getSpaceAncestors(widget.item.spaceId!);
      if (mounted) {
        setState(() => _spacePath = ancestors.map((s) => s.name).join(' › '));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasPhoto = item.photoPath != null && item.photoPath!.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: hasPhoto ? 300 : 0,
            pinned: true,
            flexibleSpace: hasPhoto
                ? FlexibleSpaceBar(
                    background: Image.file(
                      File(item.photoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  )
                : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddItemScreen(existingItem: item),
                    ),
                  );
                  if (result == true) {
                    final updated = await _db.getItem(item.id!);
                    if (updated != null && mounted) {
                      Navigator.pop(context, true);
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.red),
                onPressed: () => _showDeleteDialog(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  _InfoCard(
                    icon: Icons.category_rounded,
                    label: '分类',
                    value: item.category,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.location_on_rounded,
                    label: '位置标识',
                    value: item.location,
                    color: Theme.of(context).colorScheme.secondary,
                  ),

                  if (item.spaceId != null && _spacePath.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.meeting_room_rounded,
                      label: '存储空间',
                      value: _spacePath,
                      color: Colors.teal,
                    ),
                  ],

                  if (item.note != null && item.note!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.note_outlined,
                      label: '备注',
                      value: item.note!,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ],

                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.access_time_rounded,
                    label: '记录时间',
                    value: formatDateTime(item.createdAt),
                    color: Theme.of(context).colorScheme.outline,
                  ),

                  if (item.updatedAt != null) ...[
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.update_rounded,
                      label: '最后更新',
                      value: formatDateTime(item.updatedAt!),
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${widget.item.name}」吗？\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.deleteItem(widget.item.id!);
              if (context.mounted) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已删除物品'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
