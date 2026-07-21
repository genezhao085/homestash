# HomeStash 任务交付规范（Kanban → GitHub）

> 每个 Kanban 任务完成时必须将产物交付到 GitHub。

## 交付流程

```
Kanban 任务 → 创建功能分支 → 开发/修改 → 提交+Push → 创建 PR → 合并 → 完成任务
```

## 分支命名规范

| 类型 | 格式 | 示例 |
|:---|:---|:---|
| 新功能 | `feat/<简短描述>` | `feat/expiry-reminder` |
| 修复 | `fix/<问题描述>` | `fix/barcode-crash` |
| 重构 | `refactor/<模块名>` | `refactor/database-layer` |
| 文档 | `docs/<内容>` | `docs/api-spec-update` |
| 发布 | `release/<版本号>` | `release/v1.1.0` |

## 针对每个 Profile 的交付规范

### PM（项目经理）
- 交付物：PRD.md、迭代计划、验收标准
- 分支：`docs/prd-<版本>`
- 提交说明：`docs: 更新 vX.X PRD — <变更摘要>`
- PR 标题：`📋 [PM] 迭代计划：vX.X`

### Architect（架构师）
- 交付物：ARCHITECTURE.md、API_SPEC.md、ADR 决策记录
- 分支：`docs/arch-<内容>`
- 提交说明：`docs: <架构决策/API变更摘要>`
- PR 标题：`🏗️ [架构] <架构变更摘要>`

### Developer（开发者）
- 交付物：功能代码、单元测试、更新文档
- 分支：`feat/<功能名>`
- 提交说明：`feat: <功能描述>`（按 Conventional Commits）
- PR 标题：`✨ [开发] <功能描述>`
- 提交流程：
  1. `git checkout -b feat/<name>`
  2. 开发 + 本地测试
  3. `git add` + `git commit -m "feat: ..."`
  4. `git push origin feat/<name>`
  5. `gh pr create --title "✨ [开发] ..." --body "关联看板: <task_id>"`

### Reviewer（审查者）
- 交付物：审查报告（PR 评论）
- 分支：不需要（直接在 PR 上评论）
- PR Review：`Approve` 或 `Request Changes`
- 完成 Kanban 时记录审查摘要

### Tester（测试者）
- 交付物：测试报告、测试用例
- 分支：`docs/test-<版本>`
- 提交说明：`test: <测试变更摘要>`
- PR 标题：`🧪 [测试] <版本> 回归测试报告`

### Ops（运维工程师）
- 交付物：构建产物、发布标签、CHANGELOG
- 流程：
  1. 合并所有 PR 到 main
  2. `git tag v<版本号>`
  3. `git push origin --tags`
  4. GitHub Release 创建
  5. 构建 APK 并上传到 Release

## Kanban 完成任务时的 GitHub 操作

每个 Worker profile 完成任务时，必须在 `kanban_complete()` 的 metadata 中包含：

```python
kanban_complete(
    summary="<交付摘要>",
    metadata={
        "github": {
            "branch": "feat/xxx",        # 功能分支名
            "commits": ["abc1234"],       # 提交 SHA
            "pr_number": 42,             # PR 编号（如果有）
            "pr_url": "https://github.com/genezhao085/homestash/pull/42",
        },
        "test_results": {
            "passed": 15,
            "failed": 0,
        }
    }
)
```

## 快速创建 PR 的 alias

在项目根目录执行：

```bash
# 通用 PR 创建
gh pr create \
  --title "<emoji> [角色] <标题>" \
  --body "## 关联任务\n看板任务: \`<task_id>\`\n\n## 变更内容\n- <变更1>\n- <变更2>\n\n## 验证\n- [ ] 本地测试通过\n- [ ] 代码审查通过"
```
