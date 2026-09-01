# AI实战共享工单中心：本机 Codex 一键引导器
# 不包含任何密钥；不调用 OpenAI API；模型任务使用 ChatGPT Work / Codex 登录。
#requires -Version 5.1

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$SpecUrl = 'https://raw.githubusercontent.com/guojianghong0202/project-kickoff-skill/6a4c4807303554cb852e4ebbb96359ef37caea3b/ai-shizhan-shared-work-center/CODEX_SPEC.md'
$Target = if (Test-Path 'D:\') { 'D:\AI_ShiZhan_Shared_Work_Center' } else { Join-Path $env:USERPROFILE 'AI_ShiZhan_Shared_Work_Center' }
$Desktop = [Environment]::GetFolderPath('Desktop')
$LogPath = Join-Path $Desktop ('AI实战_共享工单中心_Codex部署日志_' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.txt')
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
  Write-Host ('=' * 72) -ForegroundColor DarkCyan
  Write-Host $Text -ForegroundColor Cyan
  Write-Host ('=' * 72) -ForegroundColor DarkCyan
}

function Remove-ApiEnvironment {
  foreach ($name in @('OPENAI_API_KEY','AZURE_OPENAI_API_KEY','OPENAI_BASE_URL','OPENAI_ORG_ID','OPENAI_PROJECT_ID')) {
    Remove-Item "Env:$name" -ErrorAction SilentlyContinue
  }
}

if (-not (Test-Administrator)) {
  if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
    throw '请先把脚本保存为 .ps1 文件，再运行。'
  }
  $arguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
  Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments
  exit 0
}

try {
  Start-Transcript -Path $LogPath -Force | Out-Null
  $TranscriptStarted = $true

  Stage '1/7 检查 Node.js 22 或更高版本'
  $node = Get-Command node -ErrorAction SilentlyContinue
  $needNode = $true
  if ($node) {
    try { $needNode = [int]((& node -p "process.versions.node.split('.')[0]").Trim()) -lt 22 } catch {}
  }
  if ($needNode) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
      throw '未找到 Node.js 22+，也未找到 winget。请先安装当前 Node.js LTS。'
    }
    if ($node) {
      & winget upgrade --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements --silent
    } else {
      & winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements --silent
    }
    if ($LASTEXITCODE -ne 0) { throw "Node.js 安装或升级失败，winget 退出码：$LASTEXITCODE" }
    Refresh-Path
  }
  if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'Node.js 安装后仍不可用，请重启 Windows 后重新运行。' }
  $nodeMajor = [int]((& node -p "process.versions.node.split('.')[0]").Trim())
  if ($nodeMajor -lt 22) { throw "当前 Node.js 主版本为 $nodeMajor，需要 22 或更高。" }
  Write-Host "Node.js: $(& node --version)"

  Stage '2/7 安装或更新官方 OpenAI Codex CLI'
  if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { throw '找不到 npm，Node.js 安装不完整。' }
  & npm install -g @openai/codex@latest --no-audit --no-fund
  if ($LASTEXITCODE -ne 0) { throw "Codex 安装失败，npm 退出码：$LASTEXITCODE" }
  Refresh-Path
  if (-not (Get-Command codex -ErrorAction SilentlyContinue)) { throw 'Codex 安装后不在 PATH，请重启 Windows 后重新运行。' }
  Write-Host "Codex: $(& codex --version)"

  Stage '3/7 建立仅使用 ChatGPT 登录的 Codex 配置'
  $CodexHome = Join-Path $env:LOCALAPPDATA 'AI_ShiZhan\codex-owner'
  New-Item -ItemType Directory -Path $CodexHome -Force | Out-Null
  $env:CODEX_HOME = $CodexHome
  @'
forced_login_method = "chatgpt"
cli_auth_credentials_store = "file"
'@.Replace('\"','"') | Set-Content -Path (Join-Path $CodexHome 'config.toml') -Encoding UTF8
  Remove-ApiEnvironment
  & codex login status 2>$null
  if ($LASTEXITCODE -ne 0) {
    Write-Host '浏览器将打开。请由套餐所有者本人使用自己的 ChatGPT 账号完成 Codex 登录。' -ForegroundColor Yellow
    & codex login
    if ($LASTEXITCODE -ne 0) { throw 'Codex 的 ChatGPT 登录未完成。' }
  }
  Remove-ApiEnvironment
  & codex login status
  if ($LASTEXITCODE -ne 0) { throw 'Codex 登录状态验证失败。' }

  Stage '4/7 下载固定版本部署任务书'
  New-Item -ItemType Directory -Path $Target -Force | Out-Null
  $SpecPath = Join-Path $Target 'CODEX_DEPLOYMENT_SPEC.md'
  Invoke-WebRequest -UseBasicParsing -Uri $SpecUrl -OutFile $SpecPath
  if (-not (Test-Path $SpecPath)) { throw '部署任务书下载失败。' }
  Write-Host "任务书：$SpecPath"

  Stage '5/7 让本机 Codex 创建并测试完整工作站'
  $LastMessage = Join-Path $Target 'CODEX_DEPLOYMENT_REPORT.txt'
  $Prompt = @"
严格执行当前目录中的 CODEX_DEPLOYMENT_SPEC.md。用户已经授权你在当前工作目录创建、安装和测试项目。不要只解释方案：请实际生成全部文件，安装项目本地依赖，运行静态检查和 smoke tests，修复失败，直到通过。普通任务必须采用 ChatGPT Work + Slack 事件触发；本地项目任务必须经过飞书群主批准后才调用本机 Codex。禁止 OpenAI API，禁止收集 OPENAI_API_KEY，禁止危险的无沙箱模式。只操作当前工作目录和安装过程明确创建的目录，不读取无关个人文件。完成后输出部署报告。
"@
  $env:npm_config_cache = Join-Path $Target '.npm-cache'
  Remove-ApiEnvironment
  $Prompt | & codex exec --cd $Target --sandbox workspace-write --color never --ephemeral --skip-git-repo-check --ignore-user-config --ignore-rules --config 'approval_policy="never"' --config 'sandbox_workspace_write.network_access=true' --output-last-message $LastMessage -
  if ($LASTEXITCODE -ne 0) { throw "Codex 生成工作站失败，退出码：$LASTEXITCODE" }

  Stage '6/7 验证生成结果与零 API 约束'
  $required = @(
    'package.json','INSTALL_AND_CONFIGURE.cmd','CREATE_FEISHU_APP.cmd',
    'OPEN_SLACK_SETUP.cmd','OPEN_CHATGPT_WORK_SETUP.cmd','START_HIDDEN.cmd',
    'CHECK_STATUS.cmd','CHECK_CLOSED_LOOP.cmd','scripts\install.ps1',
    'src\index.mjs','src\codex-runner.mjs','tests\smoke.mjs'
  )
  foreach ($relative in $required) {
    if (-not (Test-Path (Join-Path $Target $relative))) { throw "Codex 未生成必要文件：$relative" }
  }

  $packageText = Get-Content (Join-Path $Target 'package.json') -Raw
  if ($packageText -match '"openai"\s*:') { throw '安全检查失败：package.json 出现 OpenAI API SDK 依赖。' }
  $sourceFiles = Get-ChildItem (Join-Path $Target 'src') -Filter '*.mjs' -Recurse -File
  foreach ($file in $sourceFiles) {
    $text = Get-Content $file.FullName -Raw
    if ($text -match 'api\.openai\.com|OPENAI_API_KEY') { throw "安全检查失败：$($file.FullName) 出现 API 调用或 API Key。" }
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

  Stage '7/7 打开交互式安全授权和配置入口'
  $Installer = Join-Path $Target 'INSTALL_AND_CONFIGURE.cmd'
  Start-Process -FilePath $Installer -WorkingDirectory $Target
  Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $Target + '"')
  Write-Host ''
  Write-Host '本机 Codex 已生成并验证共享工单中心。交互式配置窗口已经打开。' -ForegroundColor Green
  Write-Host 'OpenAI API：禁用；OPENAI_API_KEY：未收集。' -ForegroundColor Green
  Write-Host "安装目录：$Target"
  Write-Host "部署报告：$LastMessage"
  Write-Host "日志：$LogPath"
} catch {
  Write-Host ''
  Write-Host "部署中断：$($_.Exception.Message)" -ForegroundColor Red
  Write-Host "日志：$LogPath" -ForegroundColor Yellow
  exit 1
} finally {
  if ($TranscriptStarted) { try { Stop-Transcript | Out-Null } catch {} }
}
