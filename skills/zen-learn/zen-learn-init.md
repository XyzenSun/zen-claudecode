# zen-learn --init

## 任务目标

为用户初始化一个新的学习空间，在当前工作目录下生成：

- `./zen-learn/status/plan.md`：学习总体方针
- `./zen-learn/status/progress.md`：详细学习进度
- `./zen-learn/status/about_user.md`：用户的基本信息
- `./zen-learn/status/user_provide_docs_struct.md`：**仅当用户提供本地资料路径时生成**，索引本地资料
- `./zen-learn/status/progress-schema.md`：**仅当资料无章节结构时生成**
- 空目录：`./zen-learn/note/`、`./zen-learn/code/`、`./zen-learn/quiz/`

## 前置检查

1. 调用 Bash `date +%Y-%m-%d` 获取当前日期，记作 `today`（用于后续文件的模板替换）。
2. 用 Bash 检查当前工作目录下是否已存在 `./zen-learn/`：

- **不存在**：继续 Step 1
- **已存在且非空**：停下来询问用户：
  - "检测到已有 `./zen-learn/` 目录，是否继续？"
  - 选项：
    - **覆盖**：删除整个 `./zen-learn/` 后重建（会丢失已有的 note/quiz/code 等学习产物，**必须向用户二次确认**后才能执行 `rm -rf ./zen-learn/`）
    - **放弃**：取消本次 init
- 未得到明确指示前，禁止改动

## Step 1: 需求采集

按「引导式对话」方式采集以下信息——不要一次性列表式追问，优先利用用户 `--init` 后面跟的参数推断，只问缺失的部分。

需采集的字段：

| 字段 | 说明 | 举例 |
|---|---|---|
| `topic` | 学习主题 | "OAuth 2.0 with PKCE" |
| `goal` | 学到什么程度算达成 | "能独立实现带 PKCE 的 OAuth 客户端" |
| `expected_duration` | 预期投入时长 | "2 周" / "5 天" |
| `prerequisites` | 用户已有背景（自评） | "熟悉 HTTP，没接触过 OAuth" |
| `learning_style` | 学习风格/偏好 | "喜欢图解分析" / "代码实战导向" / "理论驱动" |
| `habits` | 学习习惯/可用时间段 | "每天晚上1小时" / "周末集中学习" |
| `resources` | 参考资料来源 | 本地路径 / URL / 无 |

关于 `resources`：

- 若用户给了**本地路径**：在单条消息内并发发起多个 `Agent` 调用（`subagent_type=Explore`），每个 agent 负责资料的一部分，返回后汇总为 `文件名 | 摘要 | 路径` 三列表格，写入 `./zen-learn/status/user_provide_docs_struct.md`
- 若用户给了 **URL**：用 WebFetch 抓取，若抓取失败，让用户复制页面内容发送给我，保存到本地并在 `./zen-learn/status/user_provide_docs_struct.md`中索引
- 若用户说**没有资料**：调用 `search_subagent`联网检索权威教程或官方文档，保存到本地并在 `./zen-learn/status/user_provide_docs_struct.md`中索引

## Step 2: 资料结构分析

基于 Step 1 拿到的资料内容：

### 分支 A：资料有明显章节结构（如书籍目录、分节文档）

- 提取完整的章节层级（通常 2-3 层：部分 / 章节 / 小节）
- **不**生成 `progress-schema.md`
- 直接进入 Step 3

### 分支 B：资料零散、无分节，或完全无资料

- 标记 `source_type = scattered`
- 与用户对话，对齐以下问题：
  - 按什么主轴切分？（例如"概念 → 实现 → 应用"、"协议 → 代码 → 安全"）
  - 每个 slug 约对应多少学习时长？（推荐 20–40 分钟一份）
  - slug 命名规则（例如 `<主轴缩写>-<知识点>`）
- 把对齐结果写入 `./zen-learn/status/progress-schema.md`，模板：

```markdown
---
topic: {{topic}}
created_at: {{today}}
updated_at: {{today}}
source_type: scattered
---

## 划分原则
{{与用户对齐的主轴切分思路}}

## 层级约定
- L1（部分）：...
- L2（小节，= note slug 来源）：...

## slug 命名规则
{{例如：小写连字符，格式 <主轴缩写>-<知识点>}}

## 粒度控制
每个 slug 约对应 {{X}} 分钟学习量，过大拆分，过小合并。
```

## Step 3: 生成 about_user.md

路径：`./zen-learn/status/about_user.md`

基于 Step 1 采集到的用户信息生成：

```markdown
---
created_at: {{today}}
updated_at: {{today}}
---

## 基本背景
- 已有基础：{{background}}

## 学习偏好
- 学习风格：{{learning_style}}
- 学习习惯：{{habits}}
```

## Step 4: 生成 plan.md

路径：`./zen-learn/status/plan.md`

```markdown
---
topic: {{topic}}
goal: {{goal}}
expected_duration: {{expected_duration}}
created_at: {{today}}
updated_at: {{today}}
prerequisites:
  - {{前置 1}}
resources:
  - {{资料路径或 URL}}
---

step1 {{第一阶段描述}}
step2 {{第二阶段描述}}
step3 {{...}}
stepN 最终测试
```

要点：

- `stepN` 为自由文本单行，**不**加 checkbox、**不**加判定标准
- step 数量通常 3-6 个，按学习的天然进阶拆分（如：基础 → 细节 → 实战 → 测试）
- plan 是"总体方针"，**不**与 progress 的章节一一对应

## Step 5: 生成 progress.md

路径：`./zen-learn/status/progress.md`

```markdown
---
topic: {{topic}}
current_stage: {{第一个章节名称}}
updated_at: {{today}}
---

## 进度总览

| 部分 | 章节 | 小节 | 状态 | 完成日期 | 章节概要 | 备注 |
|---|---|---|---|---|---|---|
| {{部分}} | {{章节}} | {{小节}} | 未开始 | | | |

## 统计信息
- 已完成章节：0 / {{N}}
- 当前学习章节：{{第一个章节名}}
- 总学习天数：0

## 学习日志

| 日期 | 学习内容 | 关键收获 | 下一步 |
|---|---|---|---|

## 状态说明
未开始 | 进行中 | 完成
```

生成规则：

- 模板中的 `{{部分}} / {{章节}} / {{小节}}` 为占位示意；需按分支 A 或 B 逐行展开前三列的具体内容，状态列统一填"未开始"，后三列（完成日期、章节概要、备注）留空
- 状态枚举只有三个值：**未开始 / 进行中 / 完成**——不用 emoji
- 所有小节 init 时状态均为"未开始"
- **章节概要**列留空（后续 update 时根据实际学到的内容填写）
- **备注**列留空（后续 update 时用于记录"需要复习"、"理解不深"等主观反馈）
- **学习日志**表 init 时只有表头，无数据行
- 分支 A（结构化）：按资料目录生成"部分/章节/小节"三列
- 分支 B（scattered）：按 `progress-schema.md` 的 L1/L2 约定生成两列（部分列留空或用 L1 名）

## Step 6: 创建工作目录

```bash
mkdir -p ./zen-learn/note ./zen-learn/code ./zen-learn/quiz
```

## Step 7: 回复用户

向用户展示：

1. 生成文件的列表，完整路径
2. `plan.md` 的 stepN 预览
3. `progress.md` 总览表的前 3-5 行

引导用户下一步：

> 学习环境已就绪。建议/clear清空上下文后 ：
> - `/zen-learn --continue` 开始第一次学习
> - `/zen-learn --status` 查看当前进度
> - `/zen-learn --help` 查看所有命令

## 教学风格约束

（遵循 `zen-learn-teaching-style.md`，摘要如下）

- 技术术语、字段名、路径、文件名使用英文；其他回复用中文
- 引导性提问优先于填表式追问
- 引用文件时**必须**说明完整路径（如 `./zen-learn/status/plan.md`）