# zen-learn --help

## 任务目标

向用户展示 zen-learn 的命令总览与推荐使用流程。无需调用任何工具，直接按下面文本回复用户。

## 回复内容


````markdown
## zen-learn 命令介绍

| 命令 | 用途 |
|---|---|
| `/zen-learn --init` | 初始化学习主题，采集 topic / goal / 资料来源，生成 `plan.md` 与 `progress.md` 骨架 |
| `/zen-learn --continue` | 继续上次学习：从 `progress.md` 定位小节 → 收集资料 → 进入教学对话 |
| `/zen-learn --update` | 持久化本次学习产物：写 `note/<slug>.md`、更新 `progress.md` 的进度表与学习日志 |
| `/zen-learn --quiz` | 针对当前或指定小节生成自测题，追加到 `quiz/<slug>-quiz.md` |
| `/zen-learn --status` | 查看总体进度：已完成章节、小节分布、最近学习记录 |
| `/zen-learn --help` | 查看本帮助 |

### 推荐使用流程

**初次使用**

1. `/zen-learn --init` — 建立学习空间，告诉我主题、目标、资料来源
2. `/clear` — 释放上下文
3. `/zen-learn --continue` — 开始第一次学习

**日常学习循环**

1. `/zen-learn --continue` — 继续学习，我会从 `progress.md` 找到当前小节
2. 学到自然停止点 → `/zen-learn --update` 持久化
3. `/clear` — 释放上下文
4. （可选）`/zen-learn --quiz`  产生一些题目来学习
5. 下次再用 `/zen-learn --continue`

**随时查看进度**

`/zen-learn --status` — 只读，不改文件

### 工作区路径

所有产出落在当前目录 `./zen-learn/`：

- `status/plan.md` — 总体方针
- `status/progress.md` — 进度地图与学习日志
- `status/about_user.md` — 用户背景与偏好
- `note/<slug>.md` — 逐小节笔记
- `quiz/<slug>-quiz.md` — 逐小节测验
````

## 约束

- 不调用任何工具
- 不要改写、省略、翻译上面表格与列表
- 不要在末尾加「希望对你有帮助」等客套话
