import 'package:flutter/material.dart';
import '../services/nl_query_service.dart';
import '../models/item.dart';
import '../utils/app_theme.dart';
import 'item_detail_screen.dart';

/// AI 自然语言查询页面
///
/// 提供类似聊天界面的交互：用户输入自然语言 → AI 理解意图 → 显示搜索结果。
class AIQueryScreen extends StatefulWidget {
  const AIQueryScreen({super.key});

  @override
  State<AIQueryScreen> createState() => _AIQueryScreenState();
}

class _AIQueryScreenState extends State<AIQueryScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];

  // 预设示例查询
  static const _suggestions = [
    '帮我在冰箱里找一个充电器',
    '有哪些快过期的食品？',
    '我有多少件物品？',
    '展示所有厨房用品',
    '哪些东西已经过期了？',
    '汇总一下我的物品概况',
    '找找客厅柜子里有什么',
    '我想要一份冰箱的食品清单',
  ];

  @override
  void initState() {
    super.initState();
    // 初始欢迎消息
    _messages.add(_ChatMessage(
      text: '👋 你好！我是 AI 助手，可以用自然语言帮你查找和管理物品。\n\n'
          '试试说：\n'
          '• "帮我在厨房找一个充电器"\n'
          '• "有哪些快过期的东西？"\n'
          '• "我有多少件物品？"',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendQuery(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: query, isUser: true));
      _messages.add(_ChatMessage(text: '', isUser: false, isLoading: true));
    });
    _textController.clear();
    _scrollToBottom();

    _executeQuery(query);
  }

  Future<void> _executeQuery(String query) async {
    try {
      final result = await NLQueryService.interpret(query);

      if (!mounted) return;

      setState(() {
        // 移除 loading
        _messages.removeLast();

        // 添加 AI 回复
        _messages.add(_ChatMessage(
          text: result.message,
          isUser: false,
          items: result.items,
          rawIntent: result.rawIntent,
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add(_ChatMessage(
          text: '抱歉，查询出错了：$e',
          isUser: false,
        ));
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _navigateToItem(Item item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.green100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('AI 查询'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: '示例查询',
            onPressed: _showSuggestions,
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: _messages.length == 1
                ? _buildWelcomeSuggestions(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _ChatBubble(
                        message: _messages[index],
                        theme: theme,
                        onTapItem: _navigateToItem,
                      );
                    },
                  ),
          ),

          // 输入栏
          _buildInputBar(theme),
        ],
      ),
    );
  }

  Widget _buildWelcomeSuggestions(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        // 欢迎消息
        _ChatBubble(
          message: _messages.first,
          theme: theme,
          onTapItem: null,
        ),
        const SizedBox(height: 24),
        // 示例查询
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '试试这些查询 👇',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.warmGray600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions.map((s) {
            return ActionChip(
              avatar: const Icon(Icons.chat_bubble_outline, size: 16),
              label: Text(s, style: const TextStyle(fontSize: 13)),
              onPressed: () => _sendQuery(s),
              backgroundColor: AppColors.green50,
              side: BorderSide(color: AppColors.green200.withAlpha(100)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: AppColors.warmGray200.withAlpha(100)),
        ),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (v) => _sendQuery(v),
              decoration: InputDecoration(
                hintText: '用自然语言查询物品...',
                hintStyle: TextStyle(color: AppColors.warmGray400, fontSize: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.warmGray100.withAlpha(150),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: FilledButton(
              onPressed: () => _sendQuery(_textController.text),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuggestions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '示例查询',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '试试这些自然语言查询，了解 AI 能做什么',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.warmGray600,
                    ),
              ),
              const SizedBox(height: 16),
              ..._suggestions.map((s) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.chat_bubble_outline, size: 20),
                    title: Text(s, style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      _sendQuery(s);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
//  消息模型
// ═══════════════════════════════════════════

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isLoading;
  final List<Item> items;
  final String? rawIntent;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false,
    this.items = const [],
    this.rawIntent,
  });
}

// ═══════════════════════════════════════════
//  聊天气泡组件
// ═══════════════════════════════════════════

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  final ThemeData theme;
  final void Function(Item item)? onTapItem;

  const _ChatBubble({
    required this.message,
    required this.theme,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _userBubble(context);
    } else if (message.isLoading) {
      return _loadingBubble();
    } else {
      return _aiBubble(context);
    }
  }

  Widget _userBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: Radius.zero,
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }

  Widget _loadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.green50,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: Radius.zero,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.green600,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '正在分析...',
              style: TextStyle(
                color: AppColors.warmGray600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            decoration: BoxDecoration(
              color: AppColors.green50,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomLeft: Radius.zero,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF1B3A1B),
                  ),
                ),
                if (message.rawIntent != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '🔍 ${message.rawIntent}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warmGray400,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 如果有查询结果物品，显示列表
          if (message.items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
              child: Text(
                '共 ${message.items.length} 件物品',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.warmGray600,
                ),
              ),
            ),
            ...message.items.take(10).map((item) => _resultItemCard(item, context)),
            if (message.items.length > 10)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  '...还有 ${message.items.length - 10} 件',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warmGray400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _resultItemCard(Item item, BuildContext context) {
    final isExpired = item.isExpired;
    final isExpiring = item.isExpiringSoon;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onTapItem?.call(item),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.82,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isExpired
                    ? Colors.red.withAlpha(80)
                    : isExpiring
                        ? Colors.orange.withAlpha(80)
                        : AppColors.warmGray200.withAlpha(80),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // 状态指示器
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.red
                        : isExpiring
                            ? Colors.orange
                            : AppColors.green400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                // 图标
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.warmGray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: item.photoPath != null && item.photoPath!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.photoPath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.inventory_2_outlined, size: 20),
                          ),
                        )
                      : const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.warmGray600),
                ),
                const SizedBox(width: 10),
                // 文字
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            item.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.warmGray600,
                            ),
                          ),
                          if (item.expiryDate != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: isExpired
                                  ? Colors.red
                                  : isExpiring
                                      ? Colors.orange
                                      : AppColors.warmGray400,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _expiryText(item),
                              style: TextStyle(
                                fontSize: 11,
                                color: isExpired
                                    ? Colors.red
                                    : isExpiring
                                        ? Colors.orange
                                        : AppColors.warmGray400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.warmGray400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _expiryText(Item item) {
    if (item.expiryDate == null) return '';
    final days = item.daysUntilExpiry;
    if (days < 0) return '已过期${-days}天';
    if (days == 0) return '今天过期';
    return '剩$days天';
  }
}
