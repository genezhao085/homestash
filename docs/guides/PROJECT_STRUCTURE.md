# HomeStash 家庭储物管家

## 工程目录结构

```
homestash/
├── lib/                    # Flutter 源代码
│   ├── main.dart           # 应用入口
│   ├── models/             # 数据模型 (Item, StorageSpace)
│   ├── screens/            # 页面 (首页/添加/详情/条码扫描等)
│   ├── services/           # 服务 (AI识图/照片分析)
│   ├── utils/              # 工具 (数据库/主题)
│   └── widgets/            # UI 组件 (物品卡片/骨架屏)
├── test/                   # 测试
│   ├── unit/               # 单元测试
│   ├── integration/        # 集成测试
│   ├── mocks/              # Mock 数据
│   └── fixtures/           # 测试夹具
├── docs/                   # 文档
│   ├── PRD.md              # 产品需求文档
│   ├── ARCHITECTURE.md     # 系统架构
│   ├── API_SPEC.md         # API 规范
│   ├── REVIEW.md           # 代码审查标准
│   ├── decisions/          # 技术决策记录 (ADR)
│   ├── guides/             # 开发指南
│   └── releases/           # 发布说明
├── scripts/                # 自动化脚本
│   ├── build.sh            # 构建脚本
│   └── test.sh             # 测试脚本
├── config/                 # 环境配置模板
├── design/                 # 设计稿/原型
├── resources/              # 资源文件
│   ├── icons/              # 图标
│   ├── fonts/              # 字体
│   └── rules/              # 规则文件 (如 lint 规则)
├── assets/                 # Flutter 静态资源
├── android/                # Android 原生配置
├── macos/                  # macOS 原生配置
├── pubspec.yaml            # Flutter 依赖配置
└── README.md               # 项目说明
```

## 任务交付规范

每个 Kanban 任务完成后，必须：
1. 创建功能分支：`feat/<任务描述>`
2. 提交代码并 push 到 GitHub
3. 创建 Pull Request 到 main
4. 标记 Kanban 任务为 done
