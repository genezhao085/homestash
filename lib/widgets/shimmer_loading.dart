import 'package:flutter/material.dart';

/// 骨架屏加载占位组件
///
/// 在数据加载时显示闪烁动画的占位形状，比单纯的 CircularProgressIndicator
/// 更有质感，让用户感知到内容即将出现的区域。
class ShimmerLoading extends StatefulWidget {
  /// 骨架项的构建器
  final Widget Function(BuildContext context) builder;

  /// 列表项数量
  final int itemCount;

  /// 是否显示为列表
  final bool asList;

  /// 列表项间距
  final double spacing;

  const ShimmerLoading({
    super.key,
    required this.builder,
    this.itemCount = 1,
    this.asList = true,
    this.spacing = 8,
  });

  /// 预设：物品卡片骨架（5项）
  factory ShimmerLoading.itemCards({Key? key}) {
    return ShimmerLoading(
      key: key,
      itemCount: 5,
      builder: (_) => const _ItemCardShimmer(),
    );
  }

  /// 预设：空间列表骨架（4项）
  factory ShimmerLoading.spaceTiles({Key? key}) {
    return ShimmerLoading(
      key: key,
      itemCount: 4,
      builder: (_) => const _SpaceTileShimmer(),
    );
  }

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final children = List.generate(widget.itemCount, (index) {
      return AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  isDark ? Colors.white12 : Colors.grey[200]!,
                  isDark ? Colors.white24 : Colors.grey[100]!,
                  isDark ? Colors.white12 : Colors.grey[200]!,
                ],
                stops: [
                  _shimmerController.value - 0.3,
                  _shimmerController.value,
                  _shimmerController.value + 0.3,
                ].map((s) => s.clamp(0.0, 1.0)).toList(),
              ).createShader(bounds);
            },
            child: child!,
          );
        },
        child: widget.builder(context),
      );
    });

    if (widget.asList) {
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.itemCount,
        separatorBuilder: (_, __) => SizedBox(height: widget.spacing),
        itemBuilder: (_, i) => children[i],
      );
    }
    return Column(children: children);
  }
}

/// 物品卡片骨架
class _ItemCardShimmer extends StatelessWidget {
  const _ItemCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white10
          : Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 照片占位
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            // 文字占位
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 空间列表骨架
class _SpaceTileShimmer extends StatelessWidget {
  const _SpaceTileShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 图标占位
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 140,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white10
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      height: 12,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white10
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 12,
                      width: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white10
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
