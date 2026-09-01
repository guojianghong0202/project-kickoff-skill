#requires -Version 5.1

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

$SpecUrl = "https://raw.githubusercontent.com/guojianghong0202/project-kickoff-skill/6a4c4807303554cb852e4ebbb96359ef37caea3b/ai-shizhan-shared-work-center/CODEX_SPEC.md"
$Target = if (Test-Path "D:\") { "D:\AI_ShiZhan_Shared_Work_Center" } else { Join-Path $env:USERPROFILE "AI_ShiZhan_Shared_Work_Center" }
$Desktop = [Environment]::GetFolderPath("Desktop")
$LogPath = Join-Path $Desktop ("AI_ShiZhan_Resume_" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
$TranscriptStarted = $false

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

function Get-CodexLoginStatus {
    $previous = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $lines = & codex login status 2>&1
        $code = $LASTEXITCODE
        $text = ($lines | Out-String).Trim()
        return [pscustomobject]@{
            ExitCode = $code
            Text = $text
        }
    }
    finally {
        $ErrorActionPreference = $previous
    }
}

function Invoke-CodexBuild([string]$Prompt, [string]$TargetPath, [string]$LastMessagePath, [string]$RunLogPath) {
    $previous = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $Prompt | & codex exec `
            --cd $TargetPath `
            --sandbox workspace-write `
            --color never `
            --ephemeral `
            --skip-git-repo-check `
            --ignore-user-config `
            --ignore-rules `
            --config 'approval_policy="never"' `
            --config 'sandbox_workspace_write.network_access=true' `
            --output-last-message $LastMessagePath `
            - 2>&1 | Tee-Object -FilePath $RunLogPath
        return $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previous
    }
}

function Invoke-Npm([string[]]$Arguments, [string]$RunLogPath) {
    $previous = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        & npm.cmd @Arguments 2>&1 | Tee-Object -FilePath $RunLogPath -Append
        return $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previous
    }
}

try {
    Start-Transcript -Path $LogPath -Force | Out-Null
    $TranscriptStarted = $true

    Show-Stage "Resume 1/4 Verifying the existing ChatGPT Codex login"

    if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
        throw "Codex is not available in PATH."
    }

    $CodexHome = Join-Path $env:LOCALAPPDATA "AI_ShiZhan\codex-owner"
    $env:CODEX_HOME = $CodexHome
    Remove-OpenAIApiEnvironment

    $status = Get-CodexLoginStatus
    if ($status.Text) {
        Write-Host $status.Text
    }
    if ($status.ExitCode -ne 0) {
        throw "Codex is not logged in. Run codex login first."
    }
    if ($status.Text -notmatch "Logged in using ChatGPT") {
        throw "Codex is not using ChatGPT login. API-key fallback is not allowed."
    }

    Write-Host "ChatGPT login verified." -ForegroundColor Green

    Show-Stage "Resume 2/4 Downloading the pinned deployment specification"

    New-Item -ItemType Directory -Path $Target -Force | Out-Null
    $specPath = Join-Path $Target "CODEX_DEPLOYMENT_SPEC.md"
    Invoke-WebRequest -UseBasicParsing -Uri $SpecUrl -OutFile $specPath
    if (-not (Test-Path $specPath)) {
        throw "The deployment specification was not downloaded."
    }
    Write-Host ("Specification: " + $specPath)

    Show-Stage "Resume 3/4 Asking local Codex to build and test the workstation"

    $lastMessage = Join-Path $Target "CODEX_DEPLOYMENT_REPORT.txt"
    $codexRunLog = Join-Path $Target "CODEX_BUILD_CONSOLE.log"
    $prompt = "Read CODEX_DEPLOYMENT_SPEC.md and execute it fully. Create all required files, install local dependencies, run static checks and smoke tests, fix failures, and finish only after tests pass. Do not call the OpenAI API, do not collect OPENAI_API_KEY, and do not use danger-full-access or disable the sandbox. Work only in the current deployment directory and directories explicitly created by the installer."

    $env:npm_config_cache = Join-Path $Target ".npm-cache"
    Remove-OpenAIApiEnvironment

    $codexExit = Invoke-CodexBuild -Prompt $prompt -TargetPath $Target -LastMessagePath $lastMessage -RunLogPath $codexRunLog
    if ($codexExit -ne 0) {
        throw ("Codex workstation generation failed. Exit code: " + $codexExit)
    }

    Show-Stage "Resume 4/4 Validating files, tests, and the no-API constraint"

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

    $npmLog = Join-Path $Target "NPM_VALIDATION.log"
    Push-Location $Target
    try {
        $installExit = Invoke-Npm -Arguments @("install", "--omit=dev", "--ignore-scripts", "--no-audit", "--no-fund") -RunLogPath $npmLog
        if ($installExit -ne 0) {
            throw ("npm install failed. Exit code: " + $installExit)
        }

        $testExit = Invoke-Npm -Arguments @("test") -RunLogPath $npmLog
        if ($testExit -ne 0) {
            throw ("Workstation smoke tests failed. Exit code: " + $testExit)
        }

        $treeExit = Invoke-Npm -Arguments @("ls", "--depth=0") -RunLogPath $npmLog
        if ($treeExit -ne 0) {
            throw ("The npm dependency tree is incomplete. Exit code: " + $treeExit)
        }
    }
    finally {
        Pop-Location
    }

    $installer = Join-Path $Target "INSTALL_AND_CONFIGURE.cmd"
    Start-Process -FilePath $installer -WorkingDirectory $Target
    Start-Process -FilePath "explorer.exe" -ArgumentList ('"' + $Target + '"')

    Write-Host ""
    Write-Host "Codex generated and validated the shared work center." -ForegroundColor Green
    Write-Host "OpenAI API: disabled. OPENAI_API_KEY: not collected." -ForegroundColor Green
    Write-Host ("Install directory: " + $Target)
    Write-Host ("Deployment report: " + $lastMessage)
    Write-Host ("Resume log: " + $LogPath)
}
catch {
    Write-Host ""
    Write-Host ("Resume stopped: " + $_.Exception.Message) -ForegroundColor Red
    Write-Host ("Resume log: " + $LogPath) -ForegroundColor Yellow
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
