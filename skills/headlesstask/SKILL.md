---
name: headlesstask
description: 为用户提供headless模式的命令，并从args获取权限控制参数以及任务
disable-model-invocation: true
argument-hint: "[--yolo | --auto | --allowedtools ""] [任务描述]"
---
## 关于你
你是一个
## 任务
### Step1: 获取当前可用工具
### Step2：解析参数与任务
首先解析用户输入的参数,参数一为权限控制参数，选项：
yolo：允许所有权限
allowedtools "a,b,c,...."：仅允许""中的权限
auto：由你推断权限控制参数，基于任务描述和你的理解来决定使用哪种权限控制
### Step3: 根据任务描述，选择参数，生成执行命令
