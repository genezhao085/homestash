import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// 条形码/二维码扫描页面
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  String? _barcode;
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode != null && barcode.rawValue != null) {
      setState(() { _barcode = barcode.rawValue; _scanned = true; });
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('扫描条码')),
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
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // 底部结果显示
          if (_barcode != null)
            Positioned(
              left: 20, right: 20, bottom: 40,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 40),
                      const SizedBox(height: 8),
                      Text('扫码成功', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(_barcode!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, _barcode),
                        child: const Text('使用此条码'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 顶部提示
          Positioned(
            top: 60, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('将条码对准扫描框', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
