# unity-safe install script — Windows PowerShell
# Usage:
#   Global install:      .\install.ps1
#   Per-project install: .\install.ps1 -Project "C:\path\to\your\unity\project"

param(
    [string]$Project = ""
)

$SkillFile = "commands\unity-safe.md"
$SkillName = "unity-safe.md"

# ── helpers ───────────────────────────────────────────────────────────────────

function Write-Green  { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Yellow { param($msg) Write-Host $msg -ForegroundColor Yellow }
function Write-Red    { param($msg) Write-Host $msg -ForegroundColor Red }
function Write-Bold   { param($msg) Write-Host $msg -ForegroundColor White }

# ── resolve source file ───────────────────────────────────────────────────────

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Source = Join-Path $ScriptDir $SkillFile

if (-not (Test-Path $Source)) {
    Write-Red "Error: $SkillFile not found in $ScriptDir"
    exit 1
}

# ── determine install target ──────────────────────────────────────────────────

if ($Project -ne "") {
    if (-not (Test-Path $Project)) {
        Write-Red "Error: directory '$Project' does not exist"
        exit 1
    }
    $DestDir = Join-Path $Project ".claude\commands"
    $Mode = "project"
} else {
    $DestDir = Join-Path $env:USERPROFILE ".claude\commands"
    $Mode = "global"
}

$Dest = Join-Path $DestDir $SkillName

# ── install ───────────────────────────────────────────────────────────────────

Write-Bold "unity-safe skill installer"
Write-Host ""

if ($Mode -eq "global") {
    Write-Yellow "Installing globally → $Dest"
    Write-Yellow "This skill will be available in every Claude Code session on this machine."
} else {
    Write-Yellow "Installing into project → $Dest"
    Write-Yellow "This skill will only be available inside: $Project"
}

Write-Host ""

New-Item -ItemType Directory -Force -Path $DestDir | Out-Null

if (Test-Path $Dest) {
    Write-Yellow "Existing file found. Backing up to $Dest.bak"
    Copy-Item $Dest "$Dest.bak" -Force
}

Copy-Item $Source $Dest -Force

Write-Host ""
Write-Green "✓ Installed: $Dest"
Write-Host ""
Write-Bold "Usage in Claude Code:"
Write-Host "  /unity-safe fix the dropdown crash"
Write-Host "  /unity-safe add a new save condition"
Write-Host "  /unity-safe audit performance in AudioManager.cs"
Write-Host ""

# ── optional: also install overlay template ───────────────────────────────────

$OverlaySource = Join-Path $ScriptDir "examples\project-overlay.md"

if ($Mode -eq "project" -and (Test-Path $OverlaySource)) {
    $OverlayDest = Join-Path $Project ".claude\commands\unity.md"
    if (-not (Test-Path $OverlayDest)) {
        $answer = Read-Host "Also install the project overlay template as /unity? [y/N]"
        if ($answer -match "^[Yy]$") {
            Copy-Item $OverlaySource $OverlayDest -Force
            Write-Green "✓ Overlay installed: $OverlayDest"
            Write-Yellow "  Edit it to describe your project's folders and tech stack."
            Write-Host ""
        }
    } else {
        Write-Yellow "Project overlay already exists at $OverlayDest — skipping."
        Write-Host ""
    }
}
