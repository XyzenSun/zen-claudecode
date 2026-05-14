#!/bin/bash
# gettools.sh - 获取当前会话可用工具列表（带缓存）
set -euo pipefail

# ============================================================
# 用法:
#   gettools.sh [-cache <days> | -noncache]
#
# 参数:
#   -cache <days>  使用缓存,缓存有效期 <days> 天(默认 3)
#                  缓存不存在或超期则重新执行获取命令并更新缓存
#   -noncache      跳过缓存,强制重新执行获取命令并覆盖缓存
#
# 不传参数等同于 `-cache 3`
# 缓存文件: ~/.claude/skills/headlesstask/toolcache.json
#
# 缓存格式:
#   {
#     "time": "YYYY-MM-DD",
#     "tools": [ { "tool_name": "...", "tool_description": "..." }, ... ]
#   }
# ============================================================

CACHE_DAYS=3
FORCE_REFRESH=false
CACHE_FILE="$HOME/.claude/skills/headlesstask/toolcache.json"

# ---------- 参数解析 ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -cache)
      shift
      [[ $# -gt 0 ]] || { echo "Error: -cache requires a value" >&2; exit 1; }
      CACHE_DAYS="$1"
      FORCE_REFRESH=false
      shift
      ;;
    -noncache)
      FORCE_REFRESH=true
      shift
      ;;
    -h|--help)
      sed -n '5,20p' "$0" >&2
      exit 0
      ;;
    *)
      echo "Error: unknown argument '$1'" >&2
      exit 1
      ;;
  esac
done

# ---------- 确保 jq 可用(脚本主逻辑读取缓存 time 字段需要) ----------
command -v jq >/dev/null 2>&1 || (apt update && apt install -y jq)

# ---------- 获取工具的命令 ----------
fetch_tools() {
  (command -v jq >/dev/null 2>&1 || (apt update && apt install -y jq)) && \
  claude -p \
    --output-format json \
    --json-schema '{
      "type": "object",
      "properties": {
        "time": { "type": "string" },
        "tools": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "tool_name": { "type": "string" },
              "tool_description": { "type": "string" }
            },
            "required": ["tool_name", "tool_description"],
            "additionalProperties": false
          }
        }
      },
      "required": ["time", "tools"],
      "additionalProperties": false
    }' \
    --max-turns 10 \
    --tools "default" \
  << 'EOF' | jq '.structured_output'
首先使用 Bash 工具执行命令 `date +%Y-%m-%d` 获取当前日期（必须通过工具调用获取，不能自己编造）。

然后严格按照以下 JSON 格式输出，不要输出任何其他文字，只输出纯 JSON 对象：

{
  "time": "2026-05-14",
  "tools": [
    {
      "tool_name": "Bash",
      "tool_description": "执行任意 bash 命令"
    }
  ]
}

请确保 'time' 是通过 Bash date 命令得到的真实当前日期，并且 tools 数组列出当前会话中**所有可用工具**。
EOF
}

# ---------- 更新缓存 ----------
update_cache() {
  mkdir -p "$(dirname "$CACHE_FILE")"
  fetch_tools > "$CACHE_FILE"
}

# ---------- 主逻辑 ----------
if [[ "$FORCE_REFRESH" == "true" ]]; then
  # -noncache: 不读缓存,直接刷新
  update_cache
elif [[ ! -f "$CACHE_FILE" ]]; then
  # 缓存不存在: 执行命令并写入
  update_cache
else
  # 缓存存在: 比对时间差
  CACHE_DATE=$(jq -r '.time' "$CACHE_FILE")
  TODAY=$(date +%Y-%m-%d)
  CACHE_TS=$(date -d "$CACHE_DATE" +%s)
  TODAY_TS=$(date -d "$TODAY" +%s)
  DIFF_DAYS=$(( (TODAY_TS - CACHE_TS) / 86400 ))

  if [[ $DIFF_DAYS -gt $CACHE_DAYS ]]; then
    # 超期: 重新执行并覆盖
    update_cache
  fi
fi

# ---------- 输出缓存内容 ----------
cat "$CACHE_FILE"
