#requires -Version 5.1

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

$SpecUrl = "https://raw.githubusercontent.com/guojianghong0202/project-kickoff-skill/6a4c4807303554cb852e4ebbb96359ef37caea3b/ai-shizhan-shared-work-center/CODEX_SPEC.md"
$Target = if (Test-Path "D:\") { "D:\AI_ShiZhan_Shared_Work_Center" } else { Join-Path $env:USERPROFILE "AI_ShiZhan_Shared_Work_Center" }
$Desktop = [Environment]::GetFolderPath("Desktop")
$LogPath = Join-Path $Desktop ("AI_ShiZhan_Codex_Deploy_" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
$TranscriptStarted = $false

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Refresh-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = $machinePath + ";" + $userPath
}

function Show-Stage([string]$Text) {
    Write-Host ""
    Write-Host ("=" * 72) -ForegroundColor DarkCyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ("=" * 72) -ForegroundColor DarkCyan
}

function Remove-OpenAIApiEnvironment {
    foreach ($name in @(
        "OPENAI_API_KEY",
        "AZURE_OPENAI_API_KEY",
        "OPENAI_BASE_URL",
        "OPENAI_ORG_ID",
        "OPENAI_PROJECT_ID"
    )) {
        Remove-Item ("Env:" + $name) -ErrorAction SilentlyContinue
    }
}

if (-not (Test-IsAdministrator)) {
    if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
        throw "The bootstrap script must be saved to disk before elevation."
    }

    $quotedScript = '"' + $PSCommandPath + '"'
    Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList @(
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $quotedScript
    )
    exit 0
}

try {
    Start-Transcript -Path $LogPath -Force | Out-Null
    $TranscriptStarted = $true

    Show-Stage "1/7 Checking Node.js 22 or later"

    $nodeCommand = Get-Command node -ErrorAction SilentlyContinue
    $needsNode = $true

    if ($nodeCommand) {
        try {
            $nodeMajor = [int]((& node -p "process.versions.node.split('.')[0]").Trim())
            $needsNode = $nodeMajor -lt 22
        }
        catch {
            $needsNode = $true
        }
    }

    if ($needsNode) {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            throw "Node.js 22+ is missing and winget is unavailable. Install the current Node.js LTS and run this script again."
        }

        if ($nodeCommand) {
            & winget upgrade --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements --silent
        }
        else {
            & winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements --silent
        }

        if ($LASTEXITCODE -ne 0) {
            throw ("Node.js install or upgrade failed. winget exit code: " + $LASTEXITCODE)
        }

        Refresh-ProcessPath
    }

    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        throw "Node.js is still unavailable. Restart Windows and run this script again."
    }

    $nodeMajor = [int]((& node -p "process.versions.node.split('.')[0]").Trim())
    if ($nodeMajor -lt 22) {
        throw ("Node.js major version is " + $nodeMajor + "; version 22 or later is required.")
    }

    Write-Host ("Node.js: " + (& node --version))

    Show-Stage "2/7 Installing or updating the official OpenAI Codex CLI"

    if (-not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) {
        throw "npm.cmd is unavailable. The Node.js installation is incomplete."
    }

    & npm.cmd install -g @openai/codex@latest --no-audit --no-fund
    if ($LASTEXITCODE -ne 0) {
        throw ("Codex installation failed. npm exit code: " + $LASTEXITCODE)
    }

    Refresh-ProcessPath

    if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
        throw "Codex was installed but is not available in PATH. Restart Windows and run this script again."
    }

    Write-Host ("Codex: " + (& codex --version))

    Show-Stage "3/7 Configuring Codex for ChatGPT login only"

    $CodexHome = Join-Path $env:LOCALAPPDATA "AI_ShiZhan\codex-owner"
    New-Item -ItemType Directory -Path $CodexHome -Force | Out-Null
    $env:CODEX_HOME = $CodexHome

    $configPath = Join-Path $CodexHome "config.toml"
    $configLines = @(
        'forced_login_method = "chatgpt"',
        'cli_auth_credentials_store = "file"'
    )
    [System.IO.File]::WriteAllLines(
        $configPath,
        $configLines,
        (New-Object System.Text.UTF8Encoding($false))
    )

    Remove-OpenAIApiEnvironment

    & codex login status *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "A browser login will open. Sign in with the ChatGPT subscription owner's account." -ForegroundColor Yellow
        & codex login
        if ($LASTEXITCODE -ne 0) {
            throw "Codex ChatGPT login was not completed."
        }
    }

    Remove-OpenAIApiEnvironment
    & codex login status
    if ($LASTEXITCODE -ne 0) {
        throw "Codex login status validation failed."
    }

    Show-Stage "4/7 Downloading the pinned deployment specification"

    New-Item -ItemType Directory -Path $Target -Force | Out-Null
    $specPath = Join-Path $Target "CODEX_DEPLOYMENT_SPEC.md"
    Invoke-WebRequest -UseBasicParsing -Uri $SpecUrl -OutFile $specPath

    if (-not (Test-Path $specPath)) {
        throw "The deployment specification was not downloaded."
    }

    Write-Host ("Specification: " + $specPath)

    Show-Stage "5/7 Asking local Codex to build and test the workstation"

    $lastMessage = Join-Path $Target "CODEX_DEPLOYMENT_REPORT.txt"
    $prompt = "Read CODEX_DEPLOYMENT_SPEC.md and execute it fully. Create all required files, install local dependencies, run static checks and smoke tests, fix failures, and finish only after tests pass. Do not call the OpenAI API, do not collect OPENAI_API_KEY, and do not use danger-full-access or any approval bypass that disables the sandbox. Work only in the current deployment directory and directories explicitly created by the installer."

    $env:npm_config_cache = Join-Path $Target ".npm-cache"
    Remove-OpenAIApiEnvironment

    $prompt | & codex exec `
        --cd $Target `
        --sandbox workspace-write `
        --color never `
        --ephemeral `
        --skip-git-repo-check `
        --ignore-user-config `
        --ignore-rules `
        --config 'approval_policy="never"' `
        --config 'sandbox_workspace_write.network_access=true' `
        --output-last-message $lastMessage `
        -

    if ($LASTEXITCODE -ne 0) {
        throw ("Codex workstation generation failed. Exit code: " + $LASTEXITCODE)
    }

    Show-Stage "6/7 Validating generated files and the no-API constraint"

    $requiredFiles = @(
        "package.json",
        "INSTALL_AND_CONFIGURE.cmd",
        "CREATE_FEISHU_APP.cmd",
        "OPEN_SLACK_SETUP.cmd",
        "OPEN_CHATGPT_WORK_SETUP.cmd",
        "START_HIDDEN.cmd",
        "CHECK_STATUS.cmd",
        "CHECK_CLOSED_LOOP.cmd",
        "scripts\install.ps1",
        "src\index.mjs",
        "src\codex-runner.mjs",
        "tests\smoke.mjs"
    )

    foreach ($relativePath in $requiredFiles) {
        $fullPath = Join-Path $Target $relativePath
        if (-not (Test-Path $fullPath)) {
            throw ("Codex did not generate required file: " + $relativePath)
        }
    }

    $packageText = Get-Content (Join-Path $Target "package.json") -Raw
    if ($packageText -match '"openai"\s*:') {
        throw "Security validation failed: package.json contains the OpenAI API SDK."
    }

    $sourceFiles = Get-ChildItem (Join-Path $Target "src") -Filter "*.mjs" -Recurse -File
    foreach ($file in $sourceFiles) {
        $sourceText = Get-Content $file.FullName -Raw
        if ($sourceText -match 'api\.openai\.com') {
            throw ("Security validation failed: direct OpenAI API endpoint found in " + $file.FullName)
        }
    }

    Push-Location $Target
    try {
        & npm.cmd install --omit=dev --ignore-scripts --no-audit --no-fund
        if ($LASTEXITCODE -ne 0) {
            throw "npm install failed."
        }

        & npm.cmd test
        if ($LASTEXITCODE -ne 0) {
            throw "Workstation smoke tests failed."
        }

        & npm.cmd ls --depth=0
        if ($LASTEXITCODE -ne 0) {
            throw "The npm dependency tree is incomplete."
        }
    }
    finally {
        Pop-Location
    }

    Show-Stage "7/7 Opening the interactive configuration installer"

    $installer = Join-Path $Target "INSTALL_AND_CONFIGURE.cmd"
    Start-Process -FilePath $installer -WorkingDirectory $Target
    Start-Process -FilePath "explorer.exe" -ArgumentList ('"' + $Target + '"')

    Write-Host ""
    Write-Host "Codex generated and validated the shared work center." -ForegroundColor Green
    Write-Host "OpenAI API: disabled. OPENAI_API_KEY: not collected." -ForegroundColor Green
    Write-Host ("Install directory: " + $Target)
    Write-Host ("Deployment report: " + $lastMessage)
    Write-Host ("Bootstrap log: " + $LogPath)
}
catch {
    Write-Host ""
    Write-Host ("Deployment stopped: " + $_.Exception.Message) -ForegroundColor Red
    Write-Host ("Bootstrap log: " + $LogPath) -ForegroundColor Yellow
    exit 1
}
finally {
    if ($TranscriptStarted) {
        try {
            Stop-Transcript | Out-Null
        }
        catch {
        }
    }
}
