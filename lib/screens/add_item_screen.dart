import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item.dart';
import '../models/storage_space.dart';
import '../utils/database_helper.dart';
import 'barcode_scanner_screen.dart';

/// 添加/编辑物品页面
class AddItemScreen extends StatefulWidget {
  final Item? existingItem;
  final StorageSpace? preselectedSpace; // 从空间浏览器进入时预选

  const AddItemScreen({super.key, this.existingItem, this.preselectedSpace});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();

  String? _photoPath;
  StorageSpace? _selectedSpace;
  final _db = DatabaseHelper.instance;
  final _picker = ImagePicker();
  bool _saving = false;

  static const presetCategories = [
    '厨房用品', '衣物', '工具箱', '电子产品', '药品',
    '文件资料', '玩具游戏', '清洁用品', '装饰品', '运动器材', '其他',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSpace = widget.preselectedSpace;
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _nameController.text = item.name;
      _categoryController.text = item.category;
      _noteController.text = item.note ?? '';
      _photoPath = item.photoPath;
      _loadSelectedSpace(item.spaceId);
    }
  }

  Future<void> _loadSelectedSpace(int? spaceId) async {
    if (spaceId != null) {
      final space = await _db.getSpace(spaceId);
      if (mounted) setState(() => _selectedSpace = space);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (source == ImageSource.gallery) {
      // macOS: 使用 AppleScript 调用原生文件选择对话框
      if (!Platform.isAndroid && !Platform.isIOS) {
        try {
          final result = await Process.run('osascript', [
            '-e',
            'set filePath to choose file with prompt "选择照片" of type {"jpg","jpeg","png","gif","webp","bmp"}',
            '-e',
            'if filePath is not "" then return POSIX path of filePath',
          ]);
          if (result.exitCode == 0) {
            final path = (result.stdout as String).trim();
            if (path.isNotEmpty && mounted) {
              setState(() => _photoPath = path);
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('选择文件失败: $e'), behavior: SnackBarBehavior.floating),
            );
          }
        }
        return;
      }
      // 移动端: 使用 image_picker 从相册选择
      try {
        final XFile? photo = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
        if (photo != null && mounted) setState(() => _photoPath = photo.path);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('选择照片失败: $e'), behavior: SnackBarBehavior.floating),
          );
        }
      }
      return;
    }

    // 拍照 (仅移动端): 使用 image_picker
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final XFile? photo = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
        if (photo != null && mounted) setState(() => _photoPath = photo.path);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('拍照失败: $e'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  void _showPhotoSourceDialog() {
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 桌面平台不显示拍照按钮（无摄像头）
              if (!isDesktop)
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, size: 32),
                  title: const Text('拍照'),
                  onTap: () { Navigator.pop(ctx); _pickPhoto(ImageSource.camera); },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, size: 32),
                title: const Text('从相册选择'),
                onTap: () { Navigator.pop(ctx); _pickPhoto(ImageSource.gallery); },
              ),
              if (_photoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_rounded, size: 32, color: Colors.red),
                  title: const Text('移除照片'),
                  onTap: () { Navigator.pop(ctx); setState(() => _photoPath = null); },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectSpace() async {
    final spaces = await _db.getRootSpaces();
    if (spaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在"收纳空间"中添加空间'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (!mounted) return;

    final result = await showDialog<StorageSpace>(
      context: context,
      builder: (ctx) => _SpacePickerDialog(spaces: spaces, db: _db, selected: _selectedSpace),
    );
    if (result != null) setState(() => _selectedSpace = result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // 自动填充位置标识
    String getLocation() {
      if (_selectedSpace != null) return _selectedSpace!.name;
      return '未指定';
    }

    try {
      if (widget.existingItem != null) {
        final updated = widget.existingItem!.copyWith(
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          location: getLocation(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          photoPath: _photoPath,
          spaceId: _selectedSpace?.id,
          updatedAt: DateTime.now(),
        );
        await _db.updateItem(updated);
      } else {
        final item = Item(
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          location: getLocation(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          photoPath: _photoPath,
          spaceId: _selectedSpace?.id,
          createdAt: DateTime.now(),
        );
        await _db.insertItem(item);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingItem != null ? '已更新物品' : '已添加物品'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '编辑物品' : '添加物品')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 照片
            Center(
              child: GestureDetector(
                onTap: _showPhotoSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.5),
                    image: _photoPath != null
                        ? DecorationImage(image: FileImage(File(_photoPath!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _photoPath == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, size: 48, color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 8),
                            Text('点击拍照或选择照片', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 物品名称（带扫码入口）
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '物品名称 *', hintText: '例如：电饭煲、冬季外套',
                prefixIcon: const Icon(Icons.inventory_2_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.green),
                  tooltip: '扫描条码',
                  onPressed: () async {
                    final barcode = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
                    );
                    if (barcode != null && mounted) {
                      _nameController.text = barcode;
                    }
                  },
                ),
              ),
              textInputAction: TextInputAction.next,
              autofocus: true,
              validator: (v) => (v == null || v.trim().isEmpty) ? '请输入物品名称' : null,
            ),
            const SizedBox(height: 16),

            // 存储空间选择（新增）
            GestureDetector(
              onTap: _selectSpace,
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: '存储空间',
                    hintText: _selectedSpace?.name ?? '选择放置位置（可选）',
                    prefixIcon: Icon(
                      _selectedSpace != null ? Icons.check_circle : Icons.meeting_room_rounded,
                      color: _selectedSpace != null ? Colors.green : null,
                    ),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                ),
              ),
            ),
            if (_selectedSpace != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(
                  SpaceTypes.displayName(_selectedSpace!.type),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
                ),
              ),
            const SizedBox(height: 16),

            // 分类
            _buildCategoryField(),
            const SizedBox(height: 16),

            // 备注
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注（可选）', hintText: '品牌、颜色、规格等',
                alignLabelWithHint: true, prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),

            // 保存
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(isEditing ? '保存修改' : '添加物品'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: '分类 *', hintText: '选择或输入分类',
            prefixIcon: Icon(Icons.category_rounded),
          ),
          textInputAction: TextInputAction.next,
          validator: (v) => (v == null || v.trim().isEmpty) ? '请输入分类' : null,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 6,
          children: presetCategories.map((cat) => ActionChip(
            label: Text(cat),
            onPressed: () => setState(() => _categoryController.text = cat),
          )).toList(),
        ),
      ],
    );
  }
}

/// 空间选择器对话框 - 树形选择
class _SpacePickerDialog extends StatefulWidget {
  final List<StorageSpace> spaces;
  final DatabaseHelper db;
  final StorageSpace? selected;

  const _SpacePickerDialog({required this.spaces, required this.db, this.selected});

  @override
  State<_SpacePickerDialog> createState() => _SpacePickerDialogState();
}

class _SpacePickerDialogState extends State<_SpacePickerDialog> {
  StorageSpace? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择存储空间'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: Colors.grey),
              title: const Text('不关联空间'),
              selected: _selected == null,
              onTap: () => setState(() => _selected = null),
            ),
            ...widget.spaces.map((s) => _buildSpaceTile(s, 0)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.pop(context, _selected), child: const Text('确定')),
      ],
    );
  }

  Widget _buildSpaceTile(StorageSpace space, int depth) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16.0 + depth * 20, right: 8),
          leading: Icon(Icons.meeting_room_rounded, size: 20),
          title: Text(space.name, style: const TextStyle(fontSize: 14)),
          trailing: _selected?.id == space.id ? const Icon(Icons.check_circle, color: Colors.green, size: 20) : null,
          onTap: () => setState(() => _selected = space),
        ),
        if (widget.spaces.any((s) => s.parentId == space.id))
          FutureBuilder<List<StorageSpace>>(
            future: widget.db.getChildSpaces(space.id!),
            builder: (_, snap) {
              if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
              return Column(
                children: snap.data!.map((child) => _buildSpaceTile(child, depth + 1)).toList(),
              );
            },
          ),
      ],
    );
  }
}
