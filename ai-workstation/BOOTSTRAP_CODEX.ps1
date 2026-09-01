# AI实战飞书 GPT 工作站：本机 Codex 引导器
# 本脚本不包含任何密钥。它只安装/调用 Node.js 与 Codex，在指定目录生成工作站文件。
#requires -Version 5.1

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$SpecUrl = 'https://raw.githubusercontent.com/guojianghong0202/project-kickoff-skill/ai-workstation-codex/ai-workstation/CODEX_SPEC.md'
$Target = if (Test-Path 'D:\') { 'D:\AI_ShiZhan_Workstation' } else { Join-Path $env:USERPROFILE 'AI_ShiZhan_Workstation' }
$Desktop = [Environment]::GetFolderPath('Desktop')
$LogPath = Join-Path $Desktop ('AI实战_Codex部署日志_' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.txt')
$TranscriptStarted = $false

function Test-Administrator {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Refresh-Path {
  $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
  $user = [Environment]::GetEnvironmentVariable('Path', 'User')
  $env:Path = "$machine;$user"
}

function Stage([string]$Text) {
  Write-Host ''
  Write-Host ('=' * 68) -ForegroundColor DarkCyan
  Write-Host $Text -ForegroundColor Cyan
  Write-Host ('=' * 68) -ForegroundColor DarkCyan
}

if (-not (Test-Administrator)) {
  if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
    throw '请先把脚本保存为 .ps1 文件，再以管理员方式运行。'
  }
  $args = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
  Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $args
  exit 0
}

try {
  Start-Transcript -Path $LogPath -Force | Out-Null
  $TranscriptStarted = $true

  Stage '1/6 检查 Node.js 22+'
  $node = Get-Command node -ErrorAction SilentlyContinue
  $needsNode = $true
  if ($node) {
    try { $needsNode = [int]((& node -p "process.versions.node.split('.')[0]").Trim()) -lt 22 } catch {}
  }
  if ($needsNode) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
      throw '未找到 Node.js 22+，也未找到 winget。请先从 Node.js 官方安装 LTS 版。'
    }
    if ($node) {
      & winget upgrade --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements --silent
    } else {
      & winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements --silent
    }
    if ($LASTEXITCODE -ne 0) { throw "Node.js 安装或升级失败，winget 退出码：$LASTEXITCODE" }
    Refresh-Path
  }
  if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'Node.js 安装后仍不可用。请重启 Windows 后重新运行本脚本。' }
  $major = [int]((& node -p "process.versions.node.split('.')[0]").Trim())
  if ($major -lt 22) { throw "当前 Node.js 主版本为 $major，需要 22 或更高版本。" }
  Write-Host "Node.js: $(& node --version)"

  Stage '2/6 安装或更新 OpenAI Codex CLI'
  if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { throw '找不到 npm。Node.js 安装不完整。' }
  & npm install -g @openai/codex@latest --no-audit --no-fund
  if ($LASTEXITCODE -ne 0) { throw "Codex 安装失败，npm 退出码：$LASTEXITCODE" }
  Refresh-Path
  if (-not (Get-Command codex -ErrorAction SilentlyContinue)) { throw 'Codex 安装后仍不在 PATH。请重启 Windows 后重新运行。' }
  Write-Host "Codex: $(& codex --version)"

  Stage '3/6 检查 Codex 登录'
  & codex login status 2>$null
  if ($LASTEXITCODE -ne 0) {
    Write-Host '浏览器将打开 Codex 登录流程。请使用你自己的 ChatGPT/OpenAI 账号完成授权。' -ForegroundColor Yellow
    & codex login
    if ($LASTEXITCODE -ne 0) { throw 'Codex 登录未完成。' }
  }

  Stage '4/6 下载任务书并让 Codex生成工作站'
  New-Item -ItemType Directory -Path $Target -Force | Out-Null
  $specPath = Join-Path $Target 'CODEX_DEPLOYMENT_SPEC.md'
  Invoke-WebRequest -UseBasicParsing -Uri $SpecUrl -OutFile $specPath
  if (-not (Test-Path $specPath)) { throw '任务书下载失败。' }
  $prompt = @"
严格执行当前目录中的 CODEX_DEPLOYMENT_SPEC.md。你已经获得用户授权在当前工作目录创建并测试项目。不要只解释；请实际生成全部文件、安装项目本地依赖、运行检查和测试并修复问题。不得读取当前目录之外的个人文件，不得使用危险的无沙箱模式。完成后给出简洁部署报告。
"@
  $env:npm_config_cache = Join-Path $Target '.npm-cache'
  $prompt | & codex --ask-for-approval never --sandbox workspace-write exec --cd $Target --color never --ephemeral --skip-git-repo-check --config 'sandbox_workspace_write.network_access=true' -
  if ($LASTEXITCODE -ne 0) { throw "Codex 生成工作站失败，退出码：$LASTEXITCODE" }

  Stage '5/6 验证生成结果'
  $required = @(
    'package.json', 'INSTALL_AND_CONFIGURE.cmd', 'CREATE_FEISHU_APP.cmd',
    'START_HIDDEN.cmd', 'CHECK_STATUS.cmd', 'scripts\install.ps1',
    'src\index.mjs', 'tests\smoke.mjs'
  )
  foreach ($relative in $required) {
    if (-not (Test-Path (Join-Path $Target $relative))) { throw "Codex 未生成必要文件：$relative" }
  }
  Push-Location $Target
  try {
    & npm install --omit=dev --ignore-scripts --no-audit --no-fund
    if ($LASTEXITCODE -ne 0) { throw 'npm install 失败。' }
    & npm test
    if ($LASTEXITCODE -ne 0) { throw '工作站 smoke tests 未通过。' }
    & npm ls --depth=0
    if ($LASTEXITCODE -ne 0) { throw '依赖树不完整。' }
  } finally {
    Pop-Location
  }

  Stage '6/6 启动交互式安装配置'
  $installer = Join-Path $Target 'INSTALL_AND_CONFIGURE.cmd'
  Write-Host '接下来安装窗口会要求你本人输入 OpenAI API Key，并完成飞书管理员扫码/发布。' -ForegroundColor Yellow
  Start-Process -FilePath $installer -WorkingDirectory $Target
  Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $Target + '"')
  Write-Host ''
  Write-Host 'Codex 已生成并验证本地工作站，交互式配置窗口已经打开。' -ForegroundColor Green
  Write-Host "目录：$Target"
  Write-Host "日志：$LogPath"
} catch {
  Write-Host ''
  Write-Host "部署中断：$($_.Exception.Message)" -ForegroundColor Red
  Write-Host "日志：$LogPath" -ForegroundColor Yellow
  exit 1
} finally {
  if ($TranscriptStarted) { try { Stop-Transcript | Out-Null } catch {} }
}
