---
name: headlesstask
description: 启动headless模式，并从args获取权限控制参数以及任务
disable-model-invocation: true
argument-hint: "[--yolo | --auto | --whitelist[]] [任务描述]"
---
## 任务
### Step1：解析参数
首先解析用户输入的参数,参数一为权限控制参数，选项：
yolo：允许所有权限
whitelist[]：仅允许[]中的权限
auto：由你推断权限控制参数，基于任务描述和你的理解来决定使用哪种权限控制
### Step2：执行任务
