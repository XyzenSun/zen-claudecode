# run.sh 使用说明

`run.sh` 是 `claude --print`(无头模式)的薄封装,采用「**全标志任意顺序 + 末尾 task**」的 CLI 设计,便于在脚本/CI/skill 中调用。

---

## 一、命令形式

```bash
./run.sh [options...] <task>
```

最终展开为:

```bash
[env IS_SANDBOX=1] claude --print <权限标志> <预设标志> <透传标志> <task>
```

`IS_SANDBOX=1` **仅在 `--yolo` 模式自动注入**,其它模式不带。

---

## 二、参数模型

`run.sh` 采用「**所有标志任意顺序 + task 必须是最后一个参数**」的设计。除 task 外,其它标志(包括权限控制)的出现顺序不影响最终展开结果。

### 2.1 任务描述 (位置:命令行最后一个参数)

- 只能放在**最末**位置。
- 不能为空字符串。
- 不能以 `--` 开头(否则与标志冲突,直接报错退出)。

### 2.2 权限控制 (任意位置,二选一,缺省走默认)

| 形式 | 展开 | 备注 |
|---|---|---|
| `--yolo` | `--dangerously-skip-permissions` | 危险,自动追加 `IS_SANDBOX=1` |
| `--allowedtools "Read,Bash"` | `--allowedTools "Read,Bash"` | 显式白名单 |
| 都不指定 | `--allowedTools "Read,Edit,Bash"` | 默认权限 |

> `--yolo` 与 `--allowedtools` **互斥**,同时出现会报错退出。
> 注意:`--allowedtools`(全小写)是 run.sh 自己消费的预设标志;`--allowedTools`(驼峰)若出现在透传里,会被原样递给 `claude`。

### 2.3 例:顺序无关性

下列两条命令展开**完全等价**:

```bash
./run.sh --yolo --effort max "你好"
./run.sh --effort max --yolo "你好"
# 都展开为: env IS_SANDBOX=1 claude --print --dangerously-skip-permissions \
#           --max-turns 1000 --output-format text --effort max "你好"
```

---

## 三、预设短标志(脚本内置)

下列标志由 run.sh 直接消费,**不会**进入透传列表。

| 短标志 | 映射到 | 默认值 | 说明 |
|---|---|---|---|
| `--max-turns <N>` | `--max-turns` | `1000` | 防失控 |
| `--max-budget <USD>` | `--max-budget-usd` | 不设 | 防爆账单 |
| `--output <fmt>` | `--output-format` | `text` | `text` / `json` / `stream-json` |
| `--add-dir <path>` | `--add-dir` | 不设 | **可重复多次** |
| `--effort <level>` | `--effort` | 不设 | `low`/`medium`/`high`/`xhigh`/`max` |
| `--append-system <text>` | `--append-system-prompt` | 不设 | 追加文本到默认系统提示 |
| `--append-system-file <path>` | `--append-system-prompt-file` | 不设 | 从文件读取内容追加到默认系统提示 |
| `--replace-system <text>` | `--system-prompt` | 不设 | **替换**整个系统提示 |
| `--replace-system-file <path>` | `--system-prompt-file` | 不设 | 从文件读取内容**替换**整个系统提示 |

> 所有预设标志都是「带值」的,缺值会报错退出。
>
> `--append-system*` 与 `--replace-system*` 共四个标志**互斥**,同时只能使用其中之一,否则报错退出。

---

## 四、透传机制

任何**没被预设短标志匹配**的参数都会原样追加到 `claude --print` 命令行,顺序保持输入顺序。

典型透传用法:

| 场景 | 透传写法 |
|---|---|
| 切换模型 | `--model sonnet` / `--model opus` |
| 加载 MCP | `--mcp-config ./mcp.json` |
| 打开调试 | `--debug "api,mcp"` |
| 详细输出 | `--verbose` |
| 指定会话 ID | `--session-id <uuid>` |
| 续接会话 | `--resume <id>` |
| 限制可见工具 | `--tools "Bash,Edit"` |

> 透传机制不做合法性校验,**不存在的标志会让 `claude` 自己报错退出**(脚本会按 `claude` 的退出码透传)。

---

## 五、互斥规则

### 5.1 权限模式互斥

`--yolo` 与 `--allowedtools` 同时出现 → 直接报错退出:

```
Error: --yolo conflicts with --allowedtools
Error: --allowedtools conflicts with --yolo
```

(报错信息取决于哪个先被解析到。)

此外,`--yolo` 模式下,如果**透传**里出现以下任一标志,也会直接报错退出:

- `--allowedTools` (驼峰版,与 run.sh 的 `--allowedtools` 不同)
- `--disallowedTools`
- `--tools`
- `--permission-mode`
- `--dangerously-skip-permissions`

理由:`--yolo` 已经表达了「全开权限」语义,再叠加任何权限相关标志只会引发歧义。

### 5.2 系统提示四选一

下列四个标志同时只能使用一个,否则报错退出:

- `--append-system <text>`
- `--append-system-file <path>`
- `--replace-system <text>`
- `--replace-system-file <path>`

理由:`append` 是「追加到默认系统提示」,`replace` 是「整体替换默认系统提示」,文本与文件来源也属于不同输入路径,叠加任意两个都会引发歧义。

### 5.3 task 校验

- task 必须是命令行最后一个参数。
- task 不能为空字符串(报错: `task description cannot be empty`)。
- task 不能以 `--` 开头(报错: `task description cannot start with '--' (got: '...')`)。

> 这条隐含约束:如果你忘了写 task,最末参数会是某个标志名,脚本立即报错而不会把它当作 task 错误执行。

---

## 六、错误退出码

| 情况 | 退出码 |
|---|---|
| 缺参数 / 缺值 | `1`(脚本自身) |
| yolo 互斥冲突 | `1`(脚本自身) |
| `claude` 自身错误(如未知标志、API 失败) | `claude` 的原退出码 |

---

## 七、示例

### 7.1 最小示例(默认权限)

```bash
./run.sh "解释 src/utils.ts 的逻辑"
# → claude --print --allowedTools "Read,Edit,Bash" --max-turns 1000 --output-format text "解释 src/utils.ts 的逻辑"
```

### 7.2 --yolo + 预设(顺序无关)

```bash
./run.sh --yolo --max-turns 50 --effort high "重构整个 utils 模块"
# 与下面这条等价:
./run.sh --max-turns 50 --effort high --yolo "重构整个 utils 模块"
# → env IS_SANDBOX=1 claude --print --dangerously-skip-permissions \
#     --max-turns 50 --output-format text --effort high "重构整个 utils 模块"
```

### 7.3 自定义白名单 + 透传模型

```bash
./run.sh --allowedtools "Read,Grep" --output json --model sonnet "审计权限相关代码"
# → claude --print --allowedTools "Read,Grep" --max-turns 1000 \
#     --output-format json --model sonnet "审计权限相关代码"
```

### 7.4 多目录 + 系统提示注入

```bash
# 追加文本到默认系统提示
./run.sh --add-dir ../lib --add-dir ../docs --append-system "用中文输出,markdown 格式" "总结全部代码"

# 从文件读取并追加
./run.sh --append-system-file ./extra-rules.txt "总结全部代码"

# 用自定义文本完全替换默认系统提示
./run.sh --replace-system "You are a Python expert" "解释这段 Python"

# 从文件读取并完全替换
./run.sh --replace-system-file ./custom-prompt.txt "审计代码"
```

> 四个 system 标志互斥,同时只能用一个;混用会报错退出。

### 7.5 互斥触发(会报错)

```bash
./run.sh --yolo --allowedtools "Read" "task"
# Error: --allowedtools conflicts with --yolo
# 退出码 1

./run.sh --yolo --tools "Bash" "task"
# Error: yolo mode is incompatible with '--tools'
# 退出码 1

./run.sh --append-system "A" --replace-system "B" "task"
# Error: --append-system / --append-system-file / --replace-system / --replace-system-file are mutually exclusive
# 退出码 1

./run.sh --yolo --effort
# Error: task description cannot start with '--' (got: '--effort')
# 退出码 1
```
