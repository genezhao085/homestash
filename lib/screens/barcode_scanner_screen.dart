import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/barcode_lookup_service.dart';
import 'add_item_screen.dart';

/// 条形码扫描页面 —— 扫描后自动查询商品信息
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController();
  String? _barcode;
  bool _scanned = false;
  bool _lookingUp = false;
  ProductInfo? _product;
  bool _cameraError = false;
  bool _invalidFormat = false;

  // 扫描框脉冲动画
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// 应用生命周期回调 —— 切后台回来时重置扫描状态
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _scanned && !_lookingUp) {
      // 如果之前已扫描但还在等待用户选择，保持当前状态
    }
  }

  /// 校验条码格式：仅接受数字（EAN/UPC）或常见条码字符
  bool _isValidBarcode(String code) {
    // EAN-13: 13位数字, UPC-A: 12位数字, EAN-8: 8位数字
    // 也接受 ISBN、ITF 等纯数字条码
    final digitsOnly = RegExp(r'^\d{8,14}$');
    // 部分条码可能含字母（Code 128 等），但至少 6 位
    final generalBarcode = RegExp(r'^[A-Za-z0-9\-]{6,}$');
    return digitsOnly.hasMatch(code) || generalBarcode.hasMatch(code);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode != null && barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
      final raw = barcode.rawValue!;
      if (!_isValidBarcode(raw)) {
        // 无效条码格式：闪烁提示
        if (!_invalidFormat) {
          setState(() => _invalidFormat = true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _invalidFormat = false);
          });
        }
        return;
      }
      setState(() {
        _barcode = raw;
        _scanned = true;
        _lookingUp = true;
        _invalidFormat = false;
      });
      HapticFeedback.mediumImpact();
      _lookupProduct(raw);
    }
  }

  /// 调用 API 查询商品信息
  Future<void> _lookupProduct(String barcode) async {
    final product = await BarcodeLookupService.lookup(barcode);
    if (!mounted) return;
    setState(() {
      _lookingUp = false;
      _product = product.isEmpty ? null : product;
    });
  }

  /// 确认使用查询到的商品信息 → 直接导航到 AddItemScreen
  void _confirmProduct() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(
          prefillBarcode: _barcode,
          prefillName: _product?.name,
          prefillCategory: _product?.category,
          prefillBrand: _product?.brand,
          prefillImageUrl: _product?.imageUrl,
        ),
      ),
    );
  }

  /// 仅使用条码号 → 直接导航到 AddItemScreen
  void _useBarcodeOnly() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(prefillBarcode: _barcode),
      ),
    );
  }

  /// 重新扫描
  void _scanAgain() {
    setState(() {
      _barcode = null;
      _scanned = false;
      _lookingUp = false;
      _product = null;
      _invalidFormat = false;
      _cameraError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描条码'),
        actions: [
          if (_scanned)
            TextButton(
              onPressed: _scanAgain,
              child: const Text('重新扫描'),
            ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              // 相机权限被拒等错误的引导提示
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_cameraError) {
                  setState(() => _cameraError = true);
                }
              });
              return child ?? _buildCameraErrorView();
            },
          ),
          // 扫描框指示（带脉冲动画）
          if (!_scanned)
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 250 * _pulseAnimation.value,
                    height: 250 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green.withValues(alpha: _pulseAnimation.value),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  );
                },
              ),
            ),
          // 扫描成功时的框
          if (_scanned)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          // 无效条码提示
          if (_invalidFormat)
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        '无效条码格式，请扫描有效条码',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 相机错误引导
          if (_cameraError) _buildCameraErrorView(),
          // 顶部提示
          if (!_cameraError)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '将条码对准扫描框',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          // 底部结果卡片
          if (_scanned)
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: _buildResultCard(),
            ),
        ],
      ),
    );
  }

  /// 相机权限被拒时的引导视图
  Widget _buildCameraErrorView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '无法访问相机',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '请在系统设置中允许 HomeStash 访问相机权限，然后重新进入此页面。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 条码号
            Text(
              '条码: $_barcode',
              style: const TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),

            if (_lookingUp) ...[
              // 查询中
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 8),
              const Text('正在查询商品信息...', style: TextStyle(color: Colors.grey)),
            ] else if (_product != null && !_product!.isEmpty) ...[
              // 查询成功 —— 显示商品信息
              const Icon(Icons.check_circle, color: Colors.green, size: 36),
              const SizedBox(height: 8),
              Row(
                children: [
                  // 商品图片
                  if (_product!.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _product!.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(width: 60, height: 60),
                      ),
                    ),
                  if (_product!.imageUrl != null) const SizedBox(width: 12),
                  // 商品文本信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _product!.name.isNotEmpty ? _product!.name : '未知商品',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_product!.brand.isNotEmpty)
                          Text(_product!.brand, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        if (_product!.category.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _product!.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _confirmProduct,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('使用此商品信息'),
              ),
            ] else ...[
              // 未找到商品
              const Icon(Icons.search_off, color: Colors.orange, size: 36),
              const SizedBox(height: 8),
              const Text('未找到商品信息', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              const Text(
                '该条码不在商品数据库中',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _useBarcodeOnly,
                    child: const Text('仅使用条码号'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _scanAgain,
                    child: const Text('重新扫描'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
