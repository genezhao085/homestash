# HomeStash 架构设计文档

## 技术栈
| 层 | 技术 | 说明 |
|:---|:---|:---|
| UI 框架 | Flutter 3.x + Material Design 3 | 跨平台 UI |
| 本地存储 | SQLite (sqflite) | 离线数据库 |
| 相机/相册 | image_picker | 拍照记录 |
| 条形码扫描 | mobile_scanner | 扫码入库 |
| AI 视觉识别 | GLM-4V API (智谱) | 拍照自动识别物品名称和分类 |
| 网络 | http | AI 识别 API 调用 |
| 日期格式化 | intl | 时间显示 |
| 路径处理 | path_provider | 文件系统路径 |
| 状态管理 | setState + FutureBuilder | 轻量级状态（计划迁移 Provider） |
| 构建工具 | Flutter CLI + Gradle | Android 构建 |

## 架构分层

```
┌──────────────────────────────────────┐
│            Presentation              │
│  screens/  widgets/                  │
│  ┌────────────────────────────────┐  │
│  │ home_screen  storage_screen    │  │
│  │ add_item_screen  item_detail   │  │
│  │ barcode_scanner_screen         │  │
│  │ splash_screen  shimmer_loading │  │
│  └────────────────────────────────┘  │
├──────────────────────────────────────┤
│              Models                   │
│  item.dart  storage_space.dart        │
├──────────────────────────────────────┤
│              Services                 │
│  ┌────────────────────────────────┐  │
│  │ database_helper.dart           │  │
│  │ photo_analyzer_service.dart    │  │
│  │   └─ GLM-4V 视觉识别          │  │
│  │ image_recognition_service.dart │  │
│  │   └─ 本地代理 fallback         │  │
│  └────────────────────────────────┘  │
├──────────────────────────────────────┤
│              Storage                  │
│  SQLite (sqflite)  File System        │
└──────────────────────────────────────┘
```

## 数据模型

### Item (物品)
```
id: INTEGER PK
name: TEXT NOT NULL
category: TEXT NOT NULL
location: TEXT NOT NULL
space_id: INTEGER FK → spaces.id
photo_path: TEXT
note: TEXT
created_at: TEXT (ISO8601)
updated_at: TEXT (ISO8601)
```

### StorageSpace (存储空间)
```
id: INTEGER PK
name: TEXT NOT NULL
parent_id: INTEGER FK → spaces.id (nullable)
type: TEXT (room/cabinet/shelf/drawer/box)
icon_name: TEXT
sort_order: INTEGER
created_at: TEXT (ISO8601)
```

## 安全设计
- 核心数据（物品、空间）存储在本地 SQLite，离线可用
- 照片存储于应用沙盒目录，不自动上传
- AI 照片识别功能需用户主动触发，图片经 HTTPS 发送至 GLM-4V API
  - 仅传输单张照片的 Base64 编码，不附带用户身份信息
  - API Key 通过环境变量 `GLM_API_KEY` 配置，不硬编码
- 条形码扫描完全本地处理，不联网
- 无敏感用户数据收集或分析

## 已知技术债务 (2026-07-21)

| ID | 严重度 | 描述 | 建议 |
|:---|:---:|:---|:---|
| TD-03 | 🟡 | API Key 路径硬编码 (~/.hermes/.env) | 迁移到 flutter_dotenv |
| TD-04 | 🟡 | GLM API URL/模型名硬编码 | 提取到配置文件 |
| TD-05 | 🟡 | 本地代理端口硬编码 (127.0.0.1:8091) | 提取到配置 |
| TD-06 | 🟡 | 无状态管理库 | 计划引入 Provider |
| TD-07 | 🟡 | Item.location 与 space_id 语义冗余 | 明确设计意图，消除歧义 |
| TD-08 | 🟡 | pubspec.yaml http 依赖重复声明 | 删除重复行 |
| TD-09 | 🟢 | 测试覆盖极低 | 增加单元测试 |
| TD-10 | 🟢 | 数据库 migration 静默吞错 | 增强错误处理 |
| TD-11 | 🟢 | 图片分析无本地缓存 | 增加结果缓存 |
| TD-12 | 🟢 | 无 CI/CD | 添加 GitHub Actions |

> 完整审查报告见 `docs/ARCHITECTURE_REVIEW.md`
