# 视觉伴侣指南

基于浏览器的视觉头脑风暴伴侣，用于展示模型、图表和选项。

## 使用时机

按问题决定，而非按会话决定。判断标准：**用户看到它是否比阅读它更容易理解？**

**使用浏览器** 当内容本身是视觉的：

- **UI 模型** — 线框图、布局、导航结构、组件设计
- **架构图** — 系统组件、数据流、关系图
- **并排视觉比较** — 比较两种布局、两种配色方案、两种设计方向
- **设计精修** — 当问题关乎外观和感觉、间距、视觉层级
- **空间关系** — 状态机、流程图、实体关系渲染为图表

**使用终端** 当内容是文本或表格的：

- **需求和范围问题** — "X是什么意思？"、"哪些功能在范围内？"
- **概念性 A/B/C 选择** — 在用文字描述的方案之间选择
- **权衡列表** — 优缺点、比较表
- **技术决策** — API 设计、数据建模、架构方案选择
- **澄清问题** — 答案是文字而非视觉偏好的任何问题

关于 UI 主题的问题不自动是视觉问题。"你想要什么样的向导？"是概念性的——使用终端。"这些向导布局哪个感觉合适？"是视觉性的——使用浏览器。

## 工作原理

服务器监视一个目录中的 HTML 文件，并将最新的文件提供给浏览器。你将 HTML 内容写入 `screen_dir`，用户在浏览器中看到它并可以点击选择选项。选择结果记录到 `state_dir/events`，你在下一轮读取。

**内容片段 vs 完整文档：** 如果你的 HTML 文件以 `<!DOCTYPE` 或 `<html` 开头，服务器按原样提供（仅注入辅助脚本）。否则，服务器自动将你的内容包装在框架模板中——添加头部、CSS 主题、选择指示器和所有交互基础设施。**默认编写内容片段。** 仅在需要完全控制页面时编写完整文档。

## 启动会话

```bash
# 启动带持久化的服务器（模型保存到项目）
scripts/start-server.sh --project-dir /path/to/project

# 返回：{"type":"server-started","port":52341,"url":"http://localhost:52341",
#           "screen_dir":"/path/to/project/brainstorm/12345-1706000000/content",
#           "state_dir":"/path/to/project/brainstorm/12345-1706000000/state"}
```

保存响应中的 `screen_dir` 和 `state_dir`。告诉用户打开该 URL。

**查找连接信息：** 服务器将启动 JSON 写入 `$STATE_DIR/server-info`。如果你在后台启动了服务器但没有捕获 stdout，读取该文件获取 URL 和端口。使用 `--project-dir` 时，在 `<project>/brainstorm/` 中查找会话目录。

**注意：** 将项目根目录作为 `--project-dir` 传入，以便模型持久化在 `./brainstorm/` 中并在服务器重启后保留。否则文件会存到 `/tmp` 并被清理。提醒用户如果尚未添加，将 `brainstorm/` 加入 `.gitignore`。

**按平台启动服务器：**

**Claude Code (macOS / Linux)：**
```bash
# 默认模式可用 — 脚本自行将服务器置于后台
scripts/start-server.sh --project-dir /path/to/project
```

**Claude Code (Windows)：**
```bash
# Windows 自动检测并使用前台模式，这会阻塞工具调用。
# 在 Bash 工具调用上设置 run_in_background: true，使服务器在
# 对话轮次之间保持存活。
scripts/start-server.sh --project-dir /path/to/project
```
通过 Bash 工具调用此命令时，设置 `run_in_background: true`。然后在下一轮读取 `$STATE_DIR/server-info` 获取 URL 和端口。

**Codex：**
```bash
# Codex 会回收后台进程。脚本自动检测 CODEX_CI 并
# 切换到前台模式。正常运行即可 — 不需要额外标志。
scripts/start-server.sh --project-dir /path/to/project
```

**Gemini CLI：**
```bash
# 使用 --foreground 并在 shell 工具调用上设置 is_background: true
# 使进程在轮次间保持存活
scripts/start-server.sh --project-dir /path/to/project --foreground
```

**其他环境：** 服务器必须在对话轮次间保持后台运行。如果你的环境回收分离的进程，使用 `--foreground` 并通过你平台的后台执行机制启动命令。

如果 URL 无法从你的浏览器访问（在远程/容器化环境中常见），绑定非回环地址主机：

```bash
scripts/start-server.sh \
  --project-dir /path/to/project \
  --host 0.0.0.0 \
  --url-host localhost
```

使用 `--url-host` 控制返回 URL JSON 中打印的主机名。

## 循环流程

1. **检查服务器是否存活**，然后**写入 HTML** 到 `screen_dir` 中的新文件：
   - 每次写入前，检查 `$STATE_DIR/server-info` 是否存在。如果不存在（或 `$STATE_DIR/server-stopped` 存在），服务器已关闭 — 在继续前用 `start-server.sh` 重启。服务器在30分钟不活动后自动退出。
   - 使用语义化文件名：`platform.html`、`visual-style.html`、`layout.html`
   - **永远不要重复使用文件名** — 每个屏幕使用新文件
   - 使用 Write 工具 — **永远不要用 cat/heredoc**（会将噪音输出到终端）
   - 服务器自动提供最新文件

2. **告诉用户会看到什么并结束你的回合：**
   - 提醒他们 URL（每一步都提醒，不只是第一次）
   - 给出屏幕上内容的简短文字摘要（例如"正在展示首页的3种布局选项"）
   - 请他们在终端中回复："看一看并告诉我你的想法。如果你想选择某个选项，可以点击选择。"

3. **在你的下一轮** — 用户在终端中回复后：
   - 如果 `$STATE_DIR/events` 存在则读取它 — 包含用户的浏览器交互（点击、选择）作为 JSON 行
   - 与用户的终端文字合并以获取完整信息
   - 终端消息是主要反馈；`state_dir/events` 提供结构化交互数据

4. **迭代或推进** — 如果反馈改变了当前屏幕，写入新文件（例如 `layout-v2.html`）。仅在当前步骤验证后才推进到下一个问题。

5. **返回终端时卸载浏览器** — 当下一步不需要浏览器时（例如一个澄清问题、一个权衡讨论），推送一个等待屏幕以清除过时内容：

   ```html
   <!-- 文件名: waiting.html (或 waiting-2.html 等) -->
   <div style="display:flex;align-items:center;justify-content:center;min-height:60vh">
     <p class="subtitle">继续在终端中进行...</p>
   </div>
   ```

   这防止用户盯着一个已解决的选择而对话已经继续。当下一个视觉问题出现时，按正常方式推送新内容文件。

6. 重复直到完成。

## 编写内容片段

只编写放入页面内的内容。服务器自动将其包装在框架模板中（头部、主题 CSS、选择指示器和所有交互基础设施）。

**最小示例：**

```html
<h2>哪种布局更好？</h2>
<p class="subtitle">考虑可读性和视觉层级</p>

<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content">
      <h3>单列布局</h3>
      <p>干净、专注的阅读体验</p>
    </div>
  </div>
  <div class="option" data-choice="b" onclick="toggleSelect(this)">
    <div class="letter">B</div>
    <div class="content">
      <h3>双列布局</h3>
      <p>侧边栏导航搭配主内容区</p>
    </div>
  </div>
</div>
```

就是这样。不需要 `<html>`、不需要 CSS、不需要 `<script>` 标签。服务器提供所有这些。

## 可用 CSS 类

框架模板为你的内容提供以下 CSS 类：

### 选项（A/B/C 选择）

```html
<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content">
      <h3>标题</h3>
      <p>描述</p>
    </div>
  </div>
</div>
```

**多选：** 在容器上添加 `data-multiselect` 让用户选择多个选项。每次点击切换该项。指示条显示选中数量。

```html
<div class="options" data-multiselect>
  <!-- 同样的选项标记 — 用户可以选择/取消选择多个 -->
</div>
```

### 卡片（视觉设计）

```html
<div class="cards">
  <div class="card" data-choice="design1" onclick="toggleSelect(this)">
    <div class="card-image"><!-- 模型内容 --></div>
    <div class="card-body">
      <h3>名称</h3>
      <p>描述</p>
    </div>
  </div>
</div>
```

### 模型容器

```html
<div class="mockup">
  <div class="mockup-header">预览：仪表盘布局</div>
  <div class="mockup-body"><!-- 你的模型 HTML --></div>
</div>
```

### 分割视图（并排比较）

```html
<div class="split">
  <div class="mockup"><!-- 左侧 --></div>
  <div class="mockup"><!-- 右侧 --></div>
</div>
```

### 优缺点

```html
<div class="pros-cons">
  <div class="pros"><h4>优点</h4><ul><li>益处</li></ul></div>
  <div class="cons"><h4>缺点</h4><ul><li>弊端</li></ul></div>
</div>
```

### 模拟元素（线框构建块）

```html
<div class="mock-nav">Logo | 首页 | 关于 | 联系</div>
<div style="display: flex;">
  <div class="mock-sidebar">导航</div>
  <div class="mock-content">主内容区</div>
</div>
<button class="mock-button">操作按钮</button>
<input class="mock-input" placeholder="输入框">
<div class="placeholder">占位区</div>
```

### 排版和分节

- `h2` — 页面标题
- `h3` — 分节标题
- `.subtitle` — 标题下方次要文字
- `.section` — 带底部边距的内容块
- `.label` — 小号大写标签文字

## 浏览器事件格式

当用户在浏览器中点击选项时，他们的交互记录到 `$STATE_DIR/events`（每行一个 JSON 对象）。当你推送新屏幕时，文件自动清除。

```jsonl
{"type":"click","choice":"a","text":"选项 A - 简单布局","timestamp":1706000101}
{"type":"click","choice":"c","text":"选项 C - 复杂网格","timestamp":1706000108}
{"type":"click","choice":"b","text":"选项 B - 混合布局","timestamp":1706000115}
```

完整事件流展示用户的探索路径——他们可能在确定之前点击多个选项。最后一个 `choice` 事件通常是最终选择，但点击模式可能揭示犹豫或偏好，值得进一步询问。

如果 `$STATE_DIR/events` 不存在，用户没有与浏览器交互 — 仅使用他们的终端文字。

## 设计技巧

- **精度适配问题** — 布局问题用线框图，精修问题用精细模型
- **在每个页面上解释问题** — "哪种布局感觉更专业？"而不是只说"选一个"
- **在推进前迭代** — 如果反馈改变了当前屏幕，写入新版本
- **每个屏幕最多2-4个选项**
- **重要时使用真实内容** — 对于摄影作品集，使用真实图片（Unsplash）。占位内容会掩盖设计问题。
- **保持模型简洁** — 聚焦于布局和结构，而非像素级完美设计

## 文件命名

- 使用语义化名称：`platform.html`、`visual-style.html`、`layout.html`
- 永远不要重复使用文件名 — 每个屏幕必须是新文件
- 迭代版本：添加版本后缀如 `layout-v2.html`、`layout-v3.html`
- 服务器按修改时间提供最新文件

## 清理

```bash
scripts/stop-server.sh $SESSION_DIR
```

如果会话使用了 `--project-dir`，模型文件持久化在 `./brainstorm/` 中供后续参考。仅 `/tmp` 会话在停止时被删除。

## 参考

- 框架模板（CSS 参考）：`scripts/frame-template.html`
- 辅助脚本（客户端）：`scripts/helper.js`