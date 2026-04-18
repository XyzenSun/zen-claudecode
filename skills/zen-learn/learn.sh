#!/usr/bin/env bash
# learn.sh — /learn 参数解析器
# 用法: ./learn.sh [--init|--continue|--update|--review|--quiz|--status|--help] [额外命令...]
# 输出三行键值 (stdout):
#   action=<匹配到的动作, 默认 help>
#   guide=<同级目录下 zen-learn-<action>.md 的绝对路径>
#   extra=<其他位置参数, 以空格拼接>
# 找不到指引文件时, 以 stderr 输出 error=guide_not_found 并 exit 2。

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

action=""
extra=""

for arg in "$@"; do
    case "$arg" in
        --init|--continue|--update|--review|--quiz|--status|--help)
            action="${arg#--}"
            ;;
        *)
            if [[ -z "$extra" ]]; then
                extra="$arg"
            else
                extra="$extra $arg"
            fi
            ;;
    esac
done

if [[ -z "$action" ]]; then
    action="help"
fi

guide="$DIR/zen-learn-${action}.md"

echo "action=${action}"
echo "guide=${guide}"
echo "extra=${extra}"

if [[ ! -f "$guide" ]]; then
    echo "error=guide_not_found" >&2
    exit 2
fi
