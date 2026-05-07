# zen-learn --update

## 任务目标

持久化本次学习会话的产物：写 note、追加 quiz、更新 progress，并在最后提示用户 `/clear` 释放上下文。

涉及文件：

- 新建或更新：`./zen-learn/note/<slug>.md`
- 新建或追加：`./zen-learn/quiz/<slug>-quiz.md`
- 更新：`./zen-learn/status/progress.md`
- 仅当用户明确要求时更新：`./zen-learn/status/plan.md`

## 前置检查

1. 调用 Bash `date +%Y-%m-%d` 获取当前日期，记作 `today`
2. 确认 `./zen-learn/status/progress.md` 存在——不存在说明用户未 init，提示 `/zen-learn --init` 并中止
3. **识别本次学习内容**：扫描当前对话上下文，判断用户本次学到/讨论了什么
   - 若对话中**未识别到任何学习内容**（例如刚 init 完就 update），向用户说明并询问是否继续，不要强行产出空记录

## Step 0: 加载现有状态

按顺序 Read：

- `./zen-learn/status/progress.md` —— 定位 `current_stage` 与"进行中"的小节
- `./zen-learn/status/plan.md` —— 了解总体方针
- `./zen-learn/status/about_user.md` —— 参考用户学习风格写 note/quiz 时调整语气
- `./zen-learn/status/progress-schema.md`（如存在）—— slug 命名规则
- `./zen-learn/status/user_provide_docs_struct.md`（如存在）—— 资料索引

## Step 1: 识别 slug 与学习内容

1. **slug 归属**
   - 优先：匹配 `progress.md` 中状态为"进行中"且位于 `current_stage` 下的小节
   - 次选：匹配 progress 里其他"进行中"或"未开始"的小节
   - 新建：对话涉及 progress 未列出的主题 → 按 `progress-schema.md` 规则（或资料章节）生成新 slug，并在 progress 表中追加一行

2. **提炼内容**（ 从对话中自动提取）
   - 关键知识点列表（多条）
   - 一句话 `章节概要`（填入 progress 表）
   - 一句话 `describe`（填入 note/quiz 的 frontmatter）
   - 主观反馈：是否需复习、理解深浅等（填入 progress 表的"备注"列）
   - 本次是否**完成**该小节（影响 progress 状态）

## Step 2: 写 / 更新 note

路径：`./zen-learn/note/<slug>.md`

### 若文件不存在（首次学习该 slug）

创建：

```markdown
---
topic: {{slug 对应的主题名}}
describe: {{一句话概括}}
created_at: {{today}}
updated_at: {{today}}
---

## 笔记速览-摘要
{{用精炼的话概括笔记核心}}

## 笔记内容-详细
{{完整笔记，按讲解脉络组织：核心概念 → 为什么 → 怎么做 → 易混点}}
```

### 若文件已存在

- 更新 frontmatter 的 `updated_at`
- `describe` 字段：若本次内容扩展了主题范围，修订该字段；否则保持
- **追加**新内容到"笔记内容-详细"下，用子标题分段



## Step 3: 更新 progress.md

### 3.1 进度总览表

定位本次 slug 对应的行，按需更新：

| 列 | 更新规则 |
|---|---|
| 状态 | "已完成"→`完成`；"还没学透"→保持`进行中`（若原为"未开始"则改为`进行中`）|
| 完成日期 | 仅当状态变为"完成"时填 `today` |
| 章节概要 | 写/更新本小节一句话总结（来自 Step 1 的提炼） |
| 备注 | 写主观反馈（如"理解不深，需复习"）——无反馈则留空 |

### 3.2 统计信息

- **已完成章节**：扫描进度总览表，一个"章节"下所有小节状态都为"完成"时，该章节计入分子。每次 update 后重算一次而非 +1
- **当前学习章节**：若本次推进到了新章节，更新此字段与 frontmatter 的 `current_stage`
- **总学习天数**：学习日志表中**不同日期**的行数

### 3.3 学习日志追加一行

```
| {{today}} | {{本次学习的小节名}} | {{2-3 条关键收获精简句}} | {{推断的下一步}} |
```

**下一步**的生成规则：

1. Claude 根据 progress 扫描下一个"未开始"的小节（通常是当前完成项的下一行），形成推断
2. 把推断结果**展示给用户并请求确认**：
   > 我准备把下一步写为："继续学习 X.Y 小节"。你确认这是下一步吗？或者你想先学其他章节？
3. 得到用户确认（或修正）后才写入学习日志

### 3.4 frontmatter `updated_at`

更新为 `today`。

## Step 5: plan 修订判断

检查本次对话中用户**是否明确要求**修订 plan（如说"改一下 step2"、"加一个新的 step"）：

- **有明确要求**：按要求修订 `./zen-learn/status/plan.md`，更新其 `updated_at`
- **无明确要求**：**不要**动 plan.md，即便你觉得 plan 需要调整也只是提示用户，由用户下次 update 时明确要求

## Step 6: Git提交与push

将新增的文件添加到git，简要总结本次学习内容（三十字以内）后 git commit -m "本次学习内容总结"，然后使用git remote -v 查询是否配置了远程仓库 ：
如果未配置远程仓库，询问用户是否添加远程仓库push到远程仓库，如果用户拒绝，跳过push
如果配置了远程仓库且唯一，git push
如果配置了多个远程仓库： 询问用户push到哪一个
## Step 7: 展示与引导 /clear

向用户汇报：

1. 本次 update 涉及的文件列表（带路径）
2. note 和 quiz 的核心新增内容（摘要式展示，不要贴整份文件）
3. progress 总览表里**本次变化的那一行**（完整列出）
4. 学习日志追加的那一行（含下一步）

收尾：

> 本次学习已持久化到 `./zen-learn/`。建议运行 `/clear` 释放当前上下文，下次学习时运行 `/zen-learn --continue` 继续学习

## 风格约束

 `zen-learn-teaching-style.md`
