#!/usr/bin/env bash
# 停止头脑风暴服务器并清理
# 用法：stop-server.sh <session_dir>
#
# 杀死服务器进程。仅在会话目录位于 /tmp（临时）下时
# 删除会话目录。持久目录（brainstorm/）被保留，
# 以便模型可以在之后被查看。

SESSION_DIR="$1"

if [[ -z "$SESSION_DIR" ]]; then
  echo '{"error": "用法：stop-server.sh <session_dir>"}'
  exit 1
fi

STATE_DIR="${SESSION_DIR}/state"
PID_FILE="${STATE_DIR}/server.pid"

if [[ -f "$PID_FILE" ]]; then
  pid=$(cat "$PID_FILE")

  # 尝试优雅停止，如果仍然存活则回退到强制停止
  kill "$pid" 2>/dev/null || true

  # 等待优雅关闭（最多约2秒）
  for i in {1..20}; do
    if ! kill -0 "$pid" 2>/dev/null; then
      break
    fi
    sleep 0.1
  done

  # 如果仍在运行，升级为 SIGKILL
  if kill -0 "$pid" 2>/dev/null; then
    kill -9 "$pid" 2>/dev/null || true

    # 给 SIGKILL 一些时间生效
    sleep 0.1
  fi

  if kill -0 "$pid" 2>/dev/null; then
    echo '{"status": "failed", "error": "进程仍在运行"}'
    exit 1
  fi

  rm -f "$PID_FILE" "${STATE_DIR}/server.log"

  # 仅删除临时 /tmp 目录
  if [[ "$SESSION_DIR" == /tmp/* ]]; then
    rm -rf "$SESSION_DIR"
  fi

  echo '{"status": "stopped"}'
else
  echo '{"status": "not_running"}'
fi