## 家庭储物管家 (HomeStash)

一个 Flutter 跨平台应用，用于管理家庭储物。通过拍照记录物品信息，需要时可快速查找。

### 功能

- **拍照记录** — 拍照或从相册选择照片记录物品
- **分类管理** — 预设 10 种常用分类（厨房、衣物、工具等），支持自定义
- **位置标记** — 预设 10 种家庭位置（客厅、卧室、厨房等），支持自定义
- **快速搜索** — 按名称、分类、位置模糊搜索
- **筛选过滤** — 按分类或位置筛选
- **离线可用** — 所有数据存储在本地 SQLite 数据库

### 技术栈

- **Flutter** (Dart) — 跨平台 UI 框架
- **sqflite** — SQLite 本地数据库
- **image_picker** — 相机/相册拍照
- **Material Design 3** — 现代化 UI

### 项目结构

```
homestash/
├── lib/
│   ├── main.dart              # 应用入口
│   ├── models/
│   │   └── item.dart          # 物品数据模型
│   ├── screens/
│   │   ├── home_screen.dart   # 首页（列表+搜索+筛选）
│   │   ├── add_item_screen.dart  # 添加/编辑物品
│   │   └── item_detail_screen.dart # 物品详情
│   ├── widgets/
│   │   └── item_card.dart     # 物品卡片组件
│   └── utils/
│       └── database_helper.dart # 数据库操作
├── android/                   # Android 原生配置
├── pubspec.yaml               # 项目依赖
└── README.md
```

### 运行方式

#### 前置要求

1. **Flutter SDK** — 已通过 Homebrew 安装
   ```bash
   # Flutter 安装在 /opt/homebrew/share/flutter/
   # 请将以下行添加到 ~/.zshrc：
   echo 'export PATH="/opt/homebrew/share/flutter/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```

2. **Android Studio**（构建 Android 应用必需）
   - 下载：https://developer.android.com/studio
   - 安装时勾选 "Android SDK" 和 "Android Virtual Device"
   - 首次运行 Android Studio 完成 SDK 组件安装

3. **验证环境**
   ```bash
   flutter doctor
   ```

#### 运行步骤

```bash
# 1. 配置 PATH（如果还未配置）
echo 'export PATH="/opt/homebrew/share/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 2. 进入项目目录
cd ~/homestash

# 3. 获取依赖（已完成）
flutter pub get

# 4. 连接 Android 设备或启动模拟器
#    - 真机：USB 连接并开启开发者模式
#    - 模拟器：Android Studio → Tools → Device Manager → 创建虚拟设备

# 5. 运行
flutter run
```

> **注意：** 首次运行会下载 Android Gradle 插件和 SDK 组件，需要几分钟。
> 如果网络不好，可在 Android Studio 中配置国内镜像。

#### 构建 APK

```bash
# Debug 版本（用于测试）
flutter build apk

# Release 版本（用于发布）
flutter build apk --release
```

APK 文件在 `build/app/outputs/flutter-apk/` 目录下。

### 使用指南

1. **添加物品**
   - 点击首页右下角 "添加物品" 按钮
   - 点击照片区域拍照或从相册选择
   - 填写物品名称（必填）
   - 选择或输入分类
   - 选择或输入储存位置
   - 可选填写备注信息
   - 点击 "添加物品" 保存

2. **查找物品**
   - 在搜索框输入关键词（支持名称、分类、位置模糊搜索）
   - 点击筛选按钮按分类或位置过滤

3. **查看详情**
   - 点击物品卡片查看完整信息

4. **编辑/删除**
   - 进入详情页，点击右上角编辑或删除按钮

### 后续可扩展功能

- [ ] 语音输入物品名称
- [ ] 物品过期提醒（食品、药品）
- [ ] 物品借用记录
- [ ] 多设备云同步
- [ ] 导出/备份数据
- [ ] 暗色模式
