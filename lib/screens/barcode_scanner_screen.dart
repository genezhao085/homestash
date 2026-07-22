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

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  String? _barcode;
  bool _scanned = false;
  bool _lookingUp = false;
  ProductInfo? _product;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode != null && barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
      final raw = barcode.rawValue!;
      setState(() {
        _barcode = raw;
        _scanned = true;
        _lookingUp = true;
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
          ),
          // 扫描框指示
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _scanned ? Colors.blue : Colors.green,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // 顶部提示
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
