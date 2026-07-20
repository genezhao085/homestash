import 'package:flutter/material.dart';
import '../models/storage_space.dart';
import '../utils/database_helper.dart';

/// 添加/编辑存储空间
class AddSpaceScreen extends StatefulWidget {
  final StorageSpace? existingSpace;
  final StorageSpace? parentSpace;

  const AddSpaceScreen({super.key, this.existingSpace, this.parentSpace});

  @override
  State<AddSpaceScreen> createState() => _AddSpaceScreenState();
}

class _AddSpaceScreenState extends State<AddSpaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _db = DatabaseHelper.instance;
  bool _saving = false;

  String _type = 'room';
  bool get _isEditing => widget.existingSpace != null;

  // 可选的子空间类型
  List<String> get _allowedTypes {
    if (_isEditing) return [widget.existingSpace!.type];
    if (widget.parentSpace != null) {
      return SpaceTypes.childrenTypes(widget.parentSpace!.type);
    }
    return [SpaceTypes.room];
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.existingSpace!.name;
      _type = widget.existingSpace!.type;
    } else if (widget.parentSpace != null) {
      _type = SpaceTypes.childrenTypes(widget.parentSpace!.type).first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final space = StorageSpace(
        id: widget.existingSpace?.id,
        name: _nameController.text.trim(),
        parentId: widget.existingSpace?.parentId ?? widget.parentSpace?.id,
        type: _type,
        createdAt: widget.existingSpace?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await _db.updateSpace(space);
      } else {
        await _db.insertSpace(space);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? '已更新空间' : '已添加空间'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'room': return Icons.meeting_room_rounded;
      case 'cabinet': return Icons.deck_rounded;
      case 'shelf': return Icons.view_list_rounded;
      case 'drawer': return Icons.draw_rounded;
      case 'box': return Icons.inventory_2_rounded;
      default: return Icons.place_rounded;
    }
  }

  String _typeHint(String type) {
    switch (type) {
      case 'room': return '例如：客厅、主卧、厨房';
      case 'cabinet': return '例如：电视柜、衣柜、书柜';
      case 'shelf': return '例如：置物架、书架';
      case 'drawer': return '例如：左边抽屉、上层抽屉';
      case 'box': return '例如：收纳箱A、工具箱';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? '编辑空间' : '添加空间';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 父空间信息
            if (widget.parentSpace != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text('位于：${widget.parentSpace!.name}', style: const TextStyle(color: Colors.blue)),
                  ],
                ),
              ),

            // 空间名称
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '空间名称 *',
                hintText: _typeHint(_type),
                prefixIcon: const Icon(Icons.edit_rounded),
              ),
              autofocus: true,
              validator: (v) => (v == null || v.trim().isEmpty) ? '请输入空间名称' : null,
            ),
            const SizedBox(height: 24),

            // 空间类型选择
            Text('空间类型', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            if (_isEditing)
              Chip(
                avatar: Icon(_typeIcon(_type), size: 18),
                label: Text(SpaceTypes.displayName(_type)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allowedTypes.map((type) => ChoiceChip(
                  avatar: Icon(_typeIcon(type), size: 18),
                  label: Text(SpaceTypes.displayName(type)),
                  selected: _type == type,
                  onSelected: (s) { if (s) setState(() => _type = type); },
                )).toList(),
              ),
            const SizedBox(height: 32),

            // 保存
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(_isEditing ? '保存修改' : '添加空间'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
