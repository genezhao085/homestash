import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// 启动画面 — 绿色渐变背景 + Logo 淡入缩放动画
class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleUp;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scaleUp = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // 2.5 秒后自动跳转到主页
    _navigationTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => widget.nextScreen,
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.green800, // 深绿
              AppColors.primary,  // 品牌绿
              AppColors.green400, // 亮绿
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Logo 图标
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) => Opacity(
                  opacity: _fadeIn.value,
                  child: Transform.scale(
                    scale: _scaleUp.value,
                    child: child,
                  ),
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    size: 52,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // 应用名
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) => Opacity(
                  opacity: _fadeIn.value,
                  child: child,
                ),
                child: const Text(
                  '家庭储物管家',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) => Opacity(
                  opacity: (_fadeIn.value - 0.2).clamp(0.0, 1.0),
                  child: child,
                ),
                child: Text(
                  '拍照记录 · 快速查找',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 15,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // 底部版本信息
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) => Opacity(
                  opacity: (_fadeIn.value - 0.4).clamp(0.0, 1.0),
                  child: child,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Colors.white.withAlpha(140),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
