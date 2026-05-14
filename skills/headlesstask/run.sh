#!/bin/bash
set -euo pipefail

# ============================================================
# headlesstask - 包装 `claude --print` 无头执行
# ------------------------------------------------------------
# 用法:
#   run.sh [options...] <task>
#
# task 是命令行最后一个参数,且不能以 '--' 开头。
# 所有标志可以任意顺序混排,只要 task 在最末即可。
#
# 权限控制 (任意位置,二选一,缺省走默认):
#   --yolo                        允许所有权限 (--dangerously-skip-permissions)
#                                 仅此模式会附加 IS_SANDBOX=1 环境变量
#   --allowedtools "Read,Bash"    自定义工具白名单
#   <都不指定>                    走默认 --allowedTools "Read,Edit,Bash"
#
# 预设选项:
#   --max-turns <N>              默认 1000
#   --max-budget <USD>           默认不设限
#   --output <fmt>               text | json | stream-json,默认 text
#   --add-dir <path>             可重复
#   --effort <level>             low|medium|high|xhigh|max
#   --append-system <text>       追加到默认系统提示 (--append-system-prompt)
#   --append-system-file <path>  从文件读取内容追加到默认系统提示 (--append-system-prompt-file)
#   --replace-system <text>      用自定义文本替换整个系统提示 (--system-prompt)
#   --replace-system-file <path> 从文件读取内容替换整个系统提示 (--system-prompt-file)
#
# 其他参数原样透传给 `claude --print`。
# 注:--append-system / --append-system-file / --replace-system / --replace-system-file
#    四者互斥,同时只能使用其中之一。
# ============================================================

DEFAULT_TOOLS="Read,Edit,Bash"

PERM_MODE=""
ALLOWED_TOOLS=""
TASK=""
MAX_TURNS=1000
MAX_BUDGET=""
OUTPUT_FORMAT="text"
EFFORT=""
APPEND_SYSTEM=""
APPEND_SYSTEM_FILE=""
REPLACE_SYSTEM=""
REPLACE_SYSTEM_FILE=""
ADD_DIRS=()
EXTRA_ARGS=()

usage() {
  sed -n '4,33p' "$0" >&2
}

die() {
  echo "Error: $*" >&2
  exit 1
}

# ---------- 第 1 步:取末尾参数作为 task ----------
if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

TASK="${!#}"
[[ -n "$TASK" ]] || die "task description cannot be empty"
[[ "$TASK" != --* ]] || die "task description cannot start with '--' (got: '$TASK')"
set -- "${@:1:$(($#-1))}"

# ---------- 第 2 步:解析所有标志 (任意顺序) ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yolo)
      [[ -z "$PERM_MODE" || "$PERM_MODE" == "yolo" ]] || die "--yolo conflicts with --allowedtools"
      PERM_MODE="yolo"; shift ;;
    --allowedtools)
      [[ $# -ge 2 ]] || die "--allowedtools requires a value"
      [[ -z "$PERM_MODE" || "$PERM_MODE" == "allowedtools" ]] || die "--allowedtools conflicts with --yolo"
      PERM_MODE="allowedtools"; ALLOWED_TOOLS="$2"; shift 2 ;;
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
    --append-system)
      [[ $# -ge 2 ]] || die "--append-system requires a value"
      APPEND_SYSTEM="$2"; shift 2 ;;
    --append-system-file)
      [[ $# -ge 2 ]] || die "--append-system-file requires a value"
      APPEND_SYSTEM_FILE="$2"; shift 2 ;;
    --replace-system)
      [[ $# -ge 2 ]] || die "--replace-system requires a value"
      REPLACE_SYSTEM="$2"; shift 2 ;;
    --replace-system-file)
      [[ $# -ge 2 ]] || die "--replace-system-file requires a value"
      REPLACE_SYSTEM_FILE="$2"; shift 2 ;;
    *)
      EXTRA_ARGS+=("$1"); shift ;;
  esac
done

# 缺省权限模式
if [[ -z "$PERM_MODE" ]]; then
  PERM_MODE="default"
  ALLOWED_TOOLS="$DEFAULT_TOOLS"
fi

# ---------- 第 3 步:互斥校验 ----------
if [[ "$PERM_MODE" == "yolo" && ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  for arg in "${EXTRA_ARGS[@]}"; do
    case "$arg" in
      --allowedTools|--disallowedTools|--tools|--permission-mode|--dangerously-skip-permissions)
        die "yolo mode is incompatible with '$arg'"
        ;;
    esac
  done
fi

# 系统提示四选一互斥
SYSTEM_OPTS_COUNT=0
[[ -n "$APPEND_SYSTEM" ]] && SYSTEM_OPTS_COUNT=$((SYSTEM_OPTS_COUNT + 1))
[[ -n "$APPEND_SYSTEM_FILE" ]] && SYSTEM_OPTS_COUNT=$((SYSTEM_OPTS_COUNT + 1))
[[ -n "$REPLACE_SYSTEM" ]] && SYSTEM_OPTS_COUNT=$((SYSTEM_OPTS_COUNT + 1))
[[ -n "$REPLACE_SYSTEM_FILE" ]] && SYSTEM_OPTS_COUNT=$((SYSTEM_OPTS_COUNT + 1))
if [[ "$SYSTEM_OPTS_COUNT" -gt 1 ]]; then
  die "--append-system / --append-system-file / --replace-system / --replace-system-file are mutually exclusive"
fi

# ---------- 第 4 步:组装命令 ----------
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

if [[ -n "$APPEND_SYSTEM" ]]; then
  CMD+=(--append-system-prompt "$APPEND_SYSTEM")
elif [[ -n "$APPEND_SYSTEM_FILE" ]]; then
  CMD+=(--append-system-prompt-file "$APPEND_SYSTEM_FILE")
elif [[ -n "$REPLACE_SYSTEM" ]]; then
  CMD+=(--system-prompt "$REPLACE_SYSTEM")
elif [[ -n "$REPLACE_SYSTEM_FILE" ]]; then
  CMD+=(--system-prompt-file "$REPLACE_SYSTEM_FILE")
fi

if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  CMD+=("${EXTRA_ARGS[@]}")
fi

CMD+=("$TASK")

# ---------- 第 5 步:执行 (yolo 才加 IS_SANDBOX=1) ----------
if [[ "$PERM_MODE" == "yolo" ]]; then
  exec env IS_SANDBOX=1 "${CMD[@]}"
else
  exec "${CMD[@]}"
fi
