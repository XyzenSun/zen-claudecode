# learn.ps1 — /learn 参数解析器 (Windows PowerShell 版)
# 用法: pwsh ./learn.ps1 [--init|--continue|--update|--review|--quiz|--status|--help] [额外命令...]
# 输出三行键值 (stdout):
#   action=<匹配到的动作, 默认 help>
#   guide=<同级目录下 zen-learn-<action>.md 的绝对路径>
#   extra=<其他位置参数, 以空格拼接>
# 找不到指引文件时, 以 stderr 输出 error=guide_not_found 并 exit 2。

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

$ErrorActionPreference = 'Stop'

$Dir = $PSScriptRoot
$action = ''
$extra = @()

foreach ($a in $Rest) {
    if ($a -match '^--(init|continue|update|review|quiz|status|help)$') {
        $action = $Matches[1]
    } else {
        $extra += $a
    }
}

if (-not $action) { $action = 'help' }
$guide = Join-Path $Dir "zen-learn-$action.md"

"action=$action"
"guide=$guide"
"extra=$($extra -join ' ')"

if (-not (Test-Path -LiteralPath $guide)) {
    [Console]::Error.WriteLine('error=guide_not_found')
    exit 2
}
