#!/bin/bash
# HomeStash 测试脚本
# 用法: ./scripts/test.sh [unit|integration|all]

set -e

MODE="${1:-all}"

echo "🧪 HomeStash Test: $MODE"

case "$MODE" in
  unit)
    flutter test test/unit/
    ;;
  integration)
    flutter test test/integration/
    ;;
  all|"")
    flutter test
    ;;
  *)
    echo "❌ Unknown: $MODE. Use: unit, integration, all"
    exit 1
    ;;
esac

echo "✅ Tests passed"
