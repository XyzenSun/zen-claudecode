#!/bin/bash
set -euo pipefail

# ============================================================
# headlesstask - 包装 `claude --print` 无头执行
# ------------------------------------------------------------
# 用法:
#   run.sh <perm> <task> [options...]
#
# 权限控制 (位置参数 1):
#   yolo                          允许所有权限 (--dangerously-skip-permissions)
#                                 仅此模式会附加 IS_SANDBOX=1 环境变量
#   --allowedtools "Read,Bash"    自定义工具白名单
#   <其他>                        视为任务,走默认 --allowedTools "Read,Edit,Bash"
#
# 任务描述 (位置参数 2,或权限缺省时为位置参数 1)
#
# 预设选项:
#   --max-turns <N>     默认 1000
#   --max-budget <USD>  默认不设限
#   --output <fmt>      text | json | stream-json,默认 text
#   --add-dir <path>    可重复
#   --effort <level>    low|medium|high|xhigh|max
#   --system <text>     追加到系统提示 (--append-system-prompt)
#
# 其他参数原样透传给 `claude --print`。
# ============================================================

DEFAULT_TOOLS="Read,Edit,Bash"

PERM_MODE=""
ALLOWED_TOOLS=""
TASK=""
MAX_TURNS=1000
MAX_BUDGET=""
OUTPUT_FORMAT="text"
EFFORT=""
SYSTEM_PROMPT=""
ADD_DIRS=()
EXTRA_ARGS=()

usage() {
  sed -n '4,27p' "$0" >&2
}

die() {
  echo "Error: $*" >&2
  exit 1
}

# ---------- 第 1 步:解析权限控制 ----------
if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

case "$1" in
  yolo)
    PERM_MODE="yolo"
    shift
    ;;
  --allowedtools)
    shift
    [[ $# -gt 0 ]] || die "--allowedtools requires a value"
    PERM_MODE="allowedtools"
    ALLOWED_TOOLS="$1"
    shift
    ;;
  *)
    PERM_MODE="default"
    ALLOWED_TOOLS="$DEFAULT_TOOLS"
    ;;
esac

# ---------- 第 2 步:任务描述 ----------
[[ $# -gt 0 ]] || die "task description required"
TASK="$1"
shift

# ---------- 第 3 步:剩余参数 ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-turns)
      [[ $# -ge 2 ]] || die "--max-turns requires a value"
      MAX_TURNS="$2"; shift 2 ;;
    --max-budget)
      [[ $# -ge 2 ]] || die "--max-budget requires a value"
      MAX_BUDGET="$2"; shift 2 ;;
    --output)
      [[ $# -ge 2 ]] || die "--output requires a value"
      OUTPUT_FORMAT="$2"; shift 2 ;;
    --add-dir)
      [[ $# -ge 2 ]] || die "--add-dir requires a value"
      ADD_DIRS+=("$2"); shift 2 ;;
    --effort)
      [[ $# -ge 2 ]] || die "--effort requires a value"
      EFFORT="$2"; shift 2 ;;
    --system)
      [[ $# -ge 2 ]] || die "--system requires a value"
      SYSTEM_PROMPT="$2"; shift 2 ;;
    *)
      EXTRA_ARGS+=("$1"); shift ;;
  esac
done

# ---------- 第 4 步:互斥校验 ----------
if [[ "$PERM_MODE" == "yolo" && ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  for arg in "${EXTRA_ARGS[@]}"; do
    case "$arg" in
      --allowedTools|--disallowedTools|--tools|--permission-mode|--dangerously-skip-permissions)
        die "yolo mode is incompatible with '$arg'"
        ;;
    esac
  done
fi

# ---------- 第 5 步:组装命令 ----------
CMD=(claude --print)

case "$PERM_MODE" in
  yolo)
    CMD+=(--dangerously-skip-permissions)
    ;;
  allowedtools|default)
    CMD+=(--allowedTools "$ALLOWED_TOOLS")
    ;;
esac

CMD+=(--max-turns "$MAX_TURNS")
CMD+=(--output-format "$OUTPUT_FORMAT")

if [[ -n "$MAX_BUDGET" ]]; then
  CMD+=(--max-budget-usd "$MAX_BUDGET")
fi

if [[ ${#ADD_DIRS[@]} -gt 0 ]]; then
  for d in "${ADD_DIRS[@]}"; do
    CMD+=(--add-dir "$d")
  done
fi

if [[ -n "$EFFORT" ]]; then
  CMD+=(--effort "$EFFORT")
fi

if [[ -n "$SYSTEM_PROMPT" ]]; then
  CMD+=(--append-system-prompt "$SYSTEM_PROMPT")
fi

if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  CMD+=("${EXTRA_ARGS[@]}")
fi

CMD+=("$TASK")

# ---------- 第 6 步:执行 (yolo 才加 IS_SANDBOX=1) ----------
if [[ "$PERM_MODE" == "yolo" ]]; then
  exec env IS_SANDBOX=1 "${CMD[@]}"
else
  exec "${CMD[@]}"
fi
