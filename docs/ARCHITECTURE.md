# HomeStash 架构设计文档

## 技术栈
| 层 | 技术 | 说明 |
|:---|:---|:---|
| UI 框架 | Flutter 3.x + Material Design 3 | 跨平台 UI |
| 本地存储 | SQLite (sqflite) | 离线数据库 |
| 相机/相册 | image_picker | 拍照记录 |
| 状态管理 | setState + FutureBuilder | 轻量级状态 |
| 构建工具 | Flutter CLI + Gradle | Android 构建 |

## 架构分层

```
┌──────────────────────────────────────┐
│            Presentation              │
│  screens/  widgets/                  │
├──────────────────────────────────────┤
│              Models                   │
│  item.dart  storage_space.dart        │
├──────────────────────────────────────┤
│              Services                 │
│  database_helper.dart                 │
├──────────────────────────────────────┤
│              Storage                  │
│  SQLite (sqflite)  File System       │
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
- 所有数据存储在本地 SQLite，无需网络权限
- 照片存储于应用沙盒目录
- 无敏感用户数据收集
