# zen-learn --continue

## 任务目标

继续上次学习——定位本次学习点、收集相关资料、以教学风格与用户进入学习对话。

**主会话做「读资料 + 讲解」**；**subagent 做「扫描 + 筛选」

## 前置任务

1. 用 Bash 检查 `./zen-learn/status/progress.md` 是否存在——不存在提示 `/zen-learn --init` 并中止

## Step 1: 定位学习点

阅读 `./zen-learn/status/progress.md` 和用户指令

按以下优先级确定本次学习的小节 slug，任一一条匹配成功则终止：
1. 如果用户明确指定了slug，直接使用。
2. 状态为 **进行中** 的小节。
3. 若无"进行中" ， 第一个 **未开始** 的小节
4. 若全部 **完成** → 告知用户"学习计划已全部完成"，建议运行 `/zen-learn --status` 查看

## Step 2：分支工作流程
用 Bash 检查 ./zen-learn/status/user_provide_docs_struct.md是否存在，如果存在，执行 Step 3B，否则执行 Step 3A ，执行Step 3B后，若subagent返回need_web_search: yes，则执行Step 3A

## Step 3A: 从网络获取资料
用 `Agent` 工具调用 search_subagent ，prompt 使用以下完整内容：

## Step 3B: 从本地获取资料


用 `Agent` 工具发起一次调用（`subagent_type: Explore`），prompt 使用以下完整内容：

````
你是 zen-learn 资料检索员。为用户本次学习准备资料清单。

## 本次学习点

- slug / 小节名：{{Step 1 定位到的小节}}
- 对应 progress 行的"章节概要"（若有）：{{从 progress 表取，没有就写"无"}}
- 该小节所属章节：{{章节名}}
- plan.md 的 goal：{{从 plan.md 取}}

## 工作内容

请依次执行：

- 阅读 ./zen-learn/status/user_provide_docs_struct.md文件，获取文件名 | 摘要 | 路径三列索引
- 根据本次学习点的主题，筛出相关的本地文档路径
- 输出"本地资料"清单：每项含 `path` 和 `相关段落/理由`
- 若本地资料不充足，请输出"need_web_search: yes"，否则输出"need_web_search: no"
```

## 输出格式（严格按此结构）

```markdown
## 本次学习定位
- slug: {{...}}
- 所属章节: {{...}}
- need_web_search: yes/no
## 需读取的资料

### 本地资料
- `./path/to/file.md` — 相关段落 3.2-3.4
- `./path/to/other.pdf` — 全文相关

```

### 约束

- 不要 Read 资料的**正文**，只读索引 / frontmatter
- 不要自己去教用户；你只是资料检索员
````


## Step 4: 阅读资料


阅读Step 3A 与Step 3B  的输出



## 核心任务：教学

### 开场

向用户报告：

> 我们将继续学习 `{{本次 slug 名称}}`

## 教学风格


### 教学过程

遵循 `zen-learn-teaching-style.md`（摘要）：

- 用引导性提问开场（例：「在我们进入 X 之前，你觉得 Y 要解决什么问题？」）
- 通过清晰解释 + 现实案例 + 恰当类比帮助理解
- 用户掌握某概念后，停用该类比，转入技术语言
- 根据用户反馈调整节奏：用户迟疑 → 换角度再讲；用户秒懂 → 加速前进
- 引用资料时说明完整路径（如 `./zen-learn/note/xxx.md:12`）
- 不要一次讲完所有内容，**分段讲 → 问 → 讲** 的循环

### 判断是否停止学习
  当获取到下面信息之一时，询问用户是否停止学习
- 用户表示疲劳、想休息
- 完成一个相对独立的子主题
- 对话长度已较多，建议用户执行/zen-learn --update 持久化学习进度

如果用户想要停止学习：
询问用户
> 今天学的不错！建议运行 `/zen-learn --update` 把本次学习持久化到 `./zen-learn/note/` 和 `progress.md`，然后 `/clear` 释放上下文，需要我帮你执行吗？

如果用户回答是的，执行 `/zen-learn --update`，否则跳过。




