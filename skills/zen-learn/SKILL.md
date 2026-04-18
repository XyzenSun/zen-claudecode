---
name: learn
description: 你是一个学习助手
argument-hint: "[--init | --continue | --update | --review | --quiz | --status | --help] [额外参数]"

disable-model-invocation: true
---

# 学习助手入口

你的职责：根据 `$ARGUMENTS` 挑选对应的指引文件并执行其中的流程。
真正的流程写在同级目录的 `zen-learn-<action>.md` 里，本文件只做分发。

## 解析步骤

1. 在本 skill 所在目录运行解析脚本（任选其一）：
   - Linux / macOS：`bash ./learn.sh $ARGUMENTS`
   - Windows：`pwsh ./learn.ps1 $ARGUMENTS`
2. 脚本会在 stdout 输出三行键值：
   - `action=xxx`：匹配到的动作（`init` / `continue` / `update` / `review` / `quiz` / `status` / `help`，未匹配默认为 `help`）
   - `guide=/绝对路径/zen-learn-xxx.md`：本次要阅读的指引文件
   - `extra=...`：用户附带的额外命令，可能为空
3. 读取 `guide` 指向的文件，严格按其中指引处理用户请求；若 `extra` 非空，把它当作用户的补充说明一并纳入处理。
4. 若脚本在 stderr 输出 `error=guide_not_found`，说明该动作尚未配置指引文件：直接告知用户该动作未实现，并回退到 `zen-learn-help.md` 的流程。

## 参数对照

| 参数 | 指引文件 | 用途 |
| --- | --- | --- |
| `--init` | `zen-learn-init.md` | 初始化学习主题 |
| `--continue` | `zen-learn-continue.md` | 继续上次学习 |
| `--update` | `zen-learn-update.md` | 更新学习资料 |
| `--review` | `zen-learn-review.md` | 复习已学内容 |
| `--quiz` | `zen-learn-quiz.md` | 自测 |
| `--status` | `zen-learn-status.md` | 查看学习进度 |
| `--help`（默认） | `zen-learn-help.md` | 查看帮助 |
