import 'dart:io';
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../utils/database_helper.dart';

/// 物品卡片组件
class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool showSpace; // 是否显示空间信息

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
    this.showSpace = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = item.photoPath != null && item.photoPath!.isNotEmpty;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 左侧照片/占位
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  image: hasPhoto
                      ? DecorationImage(image: FileImage(File(item.photoPath!)), fit: BoxFit.cover)
                      : null,
                ),
                child: hasPhoto
                    ? null
                    : Icon(_getCategoryIcon(item.category), size: 32, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              // 中间信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    _buildTagRow(context, Icons.category_rounded, item.category),
                    const SizedBox(height: 2),
                    _buildTagRow(context, Icons.location_on_rounded, item.location),
                    // 空间信息
                    if (showSpace && item.spaceId != null)
                      FutureBuilder<String>(
                        future: _getSpacePath(item.spaceId!),
                        builder: (_, snap) {
                          if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: _buildTagRow(context, Icons.meeting_room_rounded, snap.data!),
                          );
                        },
                      ),
                    const SizedBox(height: 2),
                    Text(formatDateTime(item.createdAt), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline, fontSize: 11)),
                  ],
                ),
              ),
              // 删除
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red.shade400,
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 3),
        Flexible(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Future<String> _getSpacePath(int spaceId) async {
    final db = DatabaseHelper.instance;
    final ancestors = await db.getSpaceAncestors(spaceId);
    return ancestors.map((s) => s.name).join(' › ');
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('厨房') || lower.contains('厨') || lower.contains('food')) return Icons.kitchen_rounded;
    if (lower.contains('衣') || lower.contains('clothes') || lower.contains('服装')) return Icons.checkroom_rounded;
    if (lower.contains('工具') || lower.contains('tool')) return Icons.build_rounded;
    if (lower.contains('电') || lower.contains('electronic') || lower.contains('电器')) return Icons.electrical_services_rounded;
    if (lower.contains('药') || lower.contains('medicine')) return Icons.medical_services_rounded;
    if (lower.contains('文') || lower.contains('document') || lower.contains('文件')) return Icons.folder_rounded;
    if (lower.contains('玩具') || lower.contains('toy') || lower.contains('游戏')) return Icons.emoji_events_rounded;
    if (lower.contains('清洁') || lower.contains('clean')) return Icons.cleaning_services_rounded;
    return Icons.inventory_2_rounded;
  }
}
