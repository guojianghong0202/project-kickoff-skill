# AI实战飞书 Codex 工作站：零 API 额外计费版引导器
# 不收集、不使用 OPENAI_API_KEY。模型任务只通过 Codex 的 ChatGPT 登录执行。
#requires -Version 5.1

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$SpecUrl = 'https://raw.githubusercontent.com/guojianghong0202/project-kickoff-skill/cada39e69c3dacabb6fa8c5f0661858c9d8118bb/ai-workstation/CODEX_SPEC.md'
$Target = if (Test-Path 'D:\') { 'D:\AI_ShiZhan_Workstation' } else { Join-Path $env:USERPROFILE 'AI_ShiZhan_Workstation' }
$Desktop = [Environment]::GetFolderPath('Desktop')
$LogPath = Join-Path $Desktop ('AI实战_Codex零API部署日志_' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.txt')
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
  Write-Host ('=' * 70) -ForegroundColor DarkCyan
  Write-Host $Text -ForegroundColor Cyan
  Write-Host ('=' * 70) -ForegroundColor DarkCyan
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

  Stage '1/6 检查 Node.js 22+'
  $node = Get-Command node -ErrorAction SilentlyContinue
  $needsNode = $true
  if ($node) {
    try { $needsNode = [int]((& node -p "process.versions.node.split('.')[0]").Trim()) -lt 22 } catch {}
  }
  if ($needsNode) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
      throw '未找到 Node.js 22+，也未找到 winget。请先安装 Node.js LTS。'
    }
    if ($node) {
      & winget upgrade --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements --silent
    } else {
      & winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements --silent
    }
    if ($LASTEXITCODE -ne 0) { throw "Node.js 安装或升级失败，winget 退出码：$LASTEXITCODE" }
    Refresh-Path
  }
  if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw 'Node.js 安装后仍不可用。请重启 Windows 后重新运行本脚本。'
  }
  $major = [int]((& node -p "process.versions.node.split('.')[0]").Trim())
  if ($major -lt 22) { throw "当前 Node.js 主版本为 $major，需要 22 或更高版本。" }
  Write-Host "Node.js: $(& node --version)"

  Stage '2/6 安装或更新官方 Codex CLI'
  if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { throw '找不到 npm。Node.js 安装不完整。' }
  & npm install -g @openai/codex@latest --no-audit --no-fund
  if ($LASTEXITCODE -ne 0) { throw "Codex 安装失败，npm 退出码：$LASTEXITCODE" }
  Refresh-Path
  if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
    throw 'Codex 安装后仍不在 PATH。请重启 Windows 后重新运行。'
  }
  Write-Host "Codex: $(& codex --version)"

  Stage '3/6 使用你的 ChatGPT 账号登录 Codex（仅用于生成工作站）'
  & codex login status 2>$null
  if ($LASTEXITCODE -ne 0) {
    Write-Host '浏览器将打开。请用你自己的 ChatGPT 账号完成登录；不要输入 API Key。' -ForegroundColor Yellow
    & codex login
    if ($LASTEXITCODE -ne 0) { throw 'Codex 的 ChatGPT 登录未完成。' }
  }

  Stage '4/6 下载固定任务书并让 Codex 创建零 API 工作站'
  New-Item -ItemType Directory -Path $Target -Force | Out-Null
  $specPath = Join-Path $Target 'CODEX_DEPLOYMENT_SPEC.md'
  Invoke-WebRequest -UseBasicParsing -Uri $SpecUrl -OutFile $specPath
  if (-not (Test-Path $specPath)) { throw '任务书下载失败。' }

  $prompt = @"
严格执行当前目录中的 CODEX_DEPLOYMENT_SPEC.md。不要只解释，请实际创建或升级全部文件、安装本地依赖、运行静态检查和 smoke tests 并修复失败。当前版本必须完全移除 OpenAI API 调用和 OPENAI_API_KEY，所有群成员通过各自独立的 CODEX_HOME 与 ChatGPT 登录使用自己的 Codex套餐额度。不得把管理员个人登录态共享给其他成员，不得读取工作目录之外的个人文件，不得使用无沙箱危险模式。完成后给出简洁部署报告。
"@

  $env:npm_config_cache = Join-Path $Target '.npm-cache'
  $prompt | & codex --ask-for-approval never --sandbox workspace-write exec --cd $Target --color never --ephemeral --skip-git-repo-check --config 'sandbox_workspace_write.network_access=true' -
  if ($LASTEXITCODE -ne 0) { throw "Codex 生成工作站失败，退出码：$LASTEXITCODE" }

  Stage '5/6 验证零 API 架构与测试结果'
  $required = @(
    'package.json', 'INSTALL_AND_CONFIGURE.cmd', 'CREATE_FEISHU_APP.cmd',
    'ADD_CODEX_USER.cmd', 'LIST_CODEX_USERS.cmd', 'REVOKE_CODEX_USER.cmd',
    'START_HIDDEN.cmd', 'CHECK_STATUS.cmd', 'scripts\install.ps1',
    'scripts\add-codex-user.ps1', 'src\index.mjs', 'src\codex-profiles.mjs',
    'tests\smoke.mjs'
  )
  foreach ($relative in $required) {
    if (-not (Test-Path (Join-Path $Target $relative))) {
      throw "Codex 未生成必要文件：$relative"
    }
  }

  $envExample = Join-Path $Target '.env.example'
  if ((Test-Path $envExample) -and (Select-String -Path $envExample -Pattern '^\s*OPENAI_API_KEY\s*=' -Quiet)) {
    throw '检测到 .env.example 仍要求 OPENAI_API_KEY，已停止。'
  }

  $pkgPath = Join-Path $Target 'package.json'
  $pkg = Get-Content -Raw -LiteralPath $pkgPath | ConvertFrom-Json
  $dependencyNames = @()
  if ($pkg.dependencies) { $dependencyNames += $pkg.dependencies.PSObject.Properties.Name }
  if ($pkg.devDependencies) { $dependencyNames += $pkg.devDependencies.PSObject.Properties.Name }
  if ($dependencyNames -contains 'openai') {
    throw '检测到项目仍依赖 openai API SDK，已停止。'
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

  Stage '6/6 打开飞书配置与成员授权入口'
  $installer = Join-Path $Target 'INSTALL_AND_CONFIGURE.cmd'
  Start-Process -FilePath $installer -WorkingDirectory $Target
  Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $Target + '"')

  Write-Host ''
  Write-Host '零 API 额外计费版已经生成并通过本地检查。' -ForegroundColor Green
  Write-Host '安装器不会要求 OpenAI API Key。完成飞书配置后，请为每位成员分别运行 ADD_CODEX_USER.cmd，并由本人登录自己的 ChatGPT 账号。' -ForegroundColor Yellow
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
