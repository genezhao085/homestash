#!/bin/bash
# 家庭储物管家 - 环境配置脚本

echo "=== 家庭储物管家 (HomeStash) 环境配置 ==="
echo ""

# 配置 Flutter PATH
FLUTTER_PATH="/opt/homebrew/share/flutter/bin"
if grep -q "$FLUTTER_PATH" ~/.zshrc 2>/dev/null; then
    echo "[OK] Flutter PATH 已配置"
else
    echo "export PATH=\"$FLUTTER_PATH:\$PATH\" >> ~/.zshrc"
    echo "[OK] Flutter PATH 已添加到 ~/.zshrc"
    echo "      请运行 source ~/.zshrc 生效"
fi

# 验证 Flutter
echo ""
echo "验证 Flutter 安装..."
if command -v flutter &>/dev/null; then
    flutter --version | head -1
    echo "[OK] Flutter 已安装"
else
    echo "[!] Flutter 未找到，请先运行: source ~/.zshrc"
fi

echo ""
echo "=== 下一步 ==="
echo "1. 安装 Android Studio: https://developer.android.com/studio"
echo "2. 运行 flutter doctor 检查环境"
echo "3. cd ~/homestash && flutter run"
