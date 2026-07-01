param(
    [ValidateSet("doctor", "ensure-godot", "verify", "run", "editor", "paths")]
    [string]$Command = "doctor",
    [int]$QuitAfter = 0
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ParentRoot = Split-Path -Parent $RepoRoot
$ToolsRoot = if ($env:MINIGAME_TOOLS_DIR) { $env:MINIGAME_TOOLS_DIR } else { Join-Path $ParentRoot "tmp\godot" }
$GodotVersion = "4.6-stable"
$GodotZip = Join-Path $ToolsRoot "Godot_v4.6-stable_win64.exe.zip"
$GodotDir = Join-Path $ToolsRoot $GodotVersion
$GodotExe = Join-Path $GodotDir "Godot_v4.6-stable_win64_console.exe"
$GodotUrl = "https://github.com/godotengine/godot-builds/releases/download/4.6-stable/Godot_v4.6-stable_win64.exe.zip"

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Ensure-Godot {
    if (Test-Path -LiteralPath $GodotExe) {
        return
    }

    New-Item -ItemType Directory -Force -Path $ToolsRoot | Out-Null

    if (-not (Test-Path -LiteralPath $GodotZip)) {
        Write-Step "Downloading Godot $GodotVersion"
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $GodotUrl -OutFile $GodotZip -Headers @{ "User-Agent" = "Mozilla/5.0" }
    }

    Write-Step "Extracting Godot $GodotVersion"
    New-Item -ItemType Directory -Force -Path $GodotDir | Out-Null
    Expand-Archive -LiteralPath $GodotZip -DestinationPath $GodotDir -Force

    if (-not (Test-Path -LiteralPath $GodotExe)) {
        throw "Godot executable was not found after extraction: $GodotExe"
    }
}

function Get-LocalEnv {
    param([string]$Name)
    $value = [Environment]::GetEnvironmentVariable($Name, "Process")
    if (-not $value) {
        $value = [Environment]::GetEnvironmentVariable($Name, "User")
    }
    if (-not $value) {
        $value = [Environment]::GetEnvironmentVariable($Name, "Machine")
    }
    return $value
}

function Invoke-Godot {
    param([string[]]$GodotArgs)
    Ensure-Godot
    & $GodotExe @GodotArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Godot exited with code $LASTEXITCODE"
    }
}

function Show-Paths {
    [PSCustomObject]@{
        RepoRoot = $RepoRoot
        ToolsRoot = $ToolsRoot
        GodotExe = $GodotExe
        WeChatBackup = Get-LocalEnv "MINIGAME_WECHAT_BACKUP"
        PrototypePdf = Get-LocalEnv "MINIGAME_PROTOTYPE_PDF"
    } | Format-List
}

switch ($Command) {
    "paths" {
        Show-Paths
    }
    "ensure-godot" {
        Ensure-Godot
        Write-Host $GodotExe
    }
    "doctor" {
        Show-Paths
        Ensure-Godot
        Write-Step "Godot version"
        & $GodotExe --version
        Write-Step "Git status"
        if (Get-Command git -ErrorAction SilentlyContinue) {
            git -C $RepoRoot status --short
        } else {
            Write-Host "git is not on PATH; Codex bundled git can still be used by agents."
        }
    }
    "verify" {
        Write-Step "Refreshing Godot project metadata"
        Invoke-Godot -GodotArgs @("--headless", "--editor", "--path", $RepoRoot, "--quit")
        Write-Step "Running main scene smoke test"
        Invoke-Godot -GodotArgs @("--headless", "--path", $RepoRoot, "--quit-after", "2")
    }
    "run" {
        Ensure-Godot
        if ($QuitAfter -gt 0) {
            & $GodotExe --path $RepoRoot --quit-after $QuitAfter
        } else {
            & $GodotExe --path $RepoRoot
        }
    }
    "editor" {
        Ensure-Godot
        & $GodotExe --editor --path $RepoRoot
    }
}
