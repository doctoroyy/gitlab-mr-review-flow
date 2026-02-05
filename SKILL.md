---
name: gitlab-mr-review-flow
description: 标准化“需求描述 → 规范检索 (QMD) → 实现改动 → GitLab MCP 创建 MR → 代码评审报告”的流程技能。
---

# GitLab MR Review Flow with QMD & Rules

## Overview

规范化执行从需求拆解到 MR 创建与代码评审的全流程。
**核心增强**：
1.  **QMD 集成**：在开发前自动检索相关的工程规范与文档。
2.  **GitLab MCP**：强制使用 MCP 工具管理 MR。
3.  **中文评审报告**：按规范输出标准化报告。

## Workflow Decision Tree

- 需要检索内部规范/文档 → 使用 `qmd` skill (search/get)。
- 需要隔离环境/并行修改 → 使用 `using-git-worktrees` skill。
- 涉及任何 git 操作 → 必须使用 `git-master` skill。
- 需要创建/更新 MR → 必须使用 GitLab MCP。
- 需要评审报告 → 使用 `requesting-code-review` skill 并输出中文报告。

## Step 1. Gather Inputs & Context

收集并确认：
- 仓库路径与目标模块范围
- 需求来源（文档/issue/日志）与验收标准
- **关键词提取**：用于 QMD 检索的关键词 (e.g., "API 规范", "数据库设计", "错误处理").

## Step 2. Retrieve Norms & Documentation (QMD)

在动手写代码前，先检索相关的业务或技术规范。

1.  **Search**: 根据提取的关键词检索文档。
    ```bash
    # 示例
    qmd search "API 规范"
    qmd search "数据库命名"
    ```
2.  **Read**: 读取最相关的 1-2 份文档，提取对本次开发有约束力的条款。
    ```bash
    qmd get "path/to/relevant-doc.md"
    ```
3.  **Context Injection**: 将提取到的规范点记录在上下文中，后续用于 Self-Check 和 Code Review。

## Step 3. Prepare Workspace & Implement

1.  读取仓库内 `AGENTS.md` 约束。
2.  如需隔离，使用 `using-git-worktrees`。
3.  实现改动，保持原子提交。
4.  执行测试并记录结果。

## Step 4. Branching & Push

### 分支命名规则
*   **Target**: `fix-{feature}-mr` 或 `feat-{feature}-mr` (空分支)
*   **Source**: `fix-{feature}` 或 `feat-{feature}` (含改动)

### 操作流程
```bash
# 1. 确保在 master
git checkout master && git pull origin master

# 2. 创建 Target 分支 (Empty)
git checkout -b {feature}-mr
git push -u origin {feature}-mr

# 3. 创建 Source 分支 (Work)
git checkout -b fix-{feature}
# ... modify & commit ...
git push -u origin fix-{feature}
```

## Step 5. Create MR via GitLab MCP

必须使用 GitLab MCP。禁止浏览器操作。

**MR 描述模板** (需包含根因、改动、**以及遵循的规范**):

```markdown
## 根因分析
- 现象：
- 根因：

## 修复方案
- 设计要点：
- **遵循规范**：(列出 Step 2 中参考的 QMD 文档/条款)

## 改动说明
- 模块：

## 测试结果
- 命令：
- 截图/日志：
```

## Step 6. Code Review Report (中文)

调用 `requesting-code-review` skill，结合 Step 2 获取的规范进行评审。

**评审重点**:
1.  是否符合 QMD 检索到的规范？
2.  是否存在逻辑漏洞？
3.  代码风格与最佳实践。

**报告模板**:

```markdown
**AI Review:** {YYYYMMDD}-{BUILD_ID}
**参考规范库**: {列出参考的 QMD 文档}

对比基准： {BASE_BRANCH}

一、规范符合度检查 (Based on QMD)
- [ ] 规范A: {检查结果}
- [ ] 规范B: {检查结果}

二、严重问题
...

三、中等问题
...

四、总结
...
```

## Step 7. Inline Code Comments (Discussions)

对于规范违例，**必须**在 MR Diff 中进行行级评论。

1.  **Locate Diff**: 获取 MR 的 DiffRefs (base_sha, head_sha, start_sha)。
2.  **Pinpoint Line**: 确定违规代码在 `bad_code.py` (或其他文件) 的具体行号。
3.  **Post Discussion**: 使用 GitLab API / Tool 发布讨论。

**API Payload Structure**:
```json
{
  "body": "❌ **Norm Violation**: {Description}\n\n(Detected by QMD via `{norm_doc}`)",
  "position": {
    "base_sha": "{base_sha}",
    "start_sha": "{start_sha}",
    "head_sha": "{head_sha}",
    "position_type": "text",
    "new_path": "{file_path}",
    "new_line": {line_number}
  }
}
```
