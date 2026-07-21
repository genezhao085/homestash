#!/bin/bash
# HomeStash 构建脚本
# 用法: ./scripts/build.sh [android|macos|ios|all]

set -e

MODE="${1:-android}"

echo "📦 HomeStash Build: $MODE"

case "$MODE" in
  android)
    flutter build apk --release
    echo "✅ Android APK: build/app/outputs/flutter-apk/app-release.apk"
    ;;
  macos)
    flutter build macos --release
    echo "✅ macOS: build/macos/Build/Products/Release/"
    ;;
  ios)
    flutter build ios --release
    echo "✅ iOS: build/ios/iphoneos/"
    ;;
  all)
    flutter build apk --release
    flutter build macos --release
    echo "✅ All builds completed"
    ;;
  *)
    echo "❌ Unknown: $MODE. Use: android, macos, ios, all"
    exit 1
    ;;
esac
