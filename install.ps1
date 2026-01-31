<#
.SYNOPSIS
    Bootstrap - tai va chay WinUtil-Vi-Launcher.ps1.
.DESCRIPTION
    Chay: irm "https://raw.githubusercontent.com/nqtam6666/Winutil-Vietnamese/main/install.ps1" | iex
    Tai repo ZIP, giai nen, chay WinUtil-Vi-Launcher.ps1 (Launcher co GUI tai/dich/build/chay).
#>
$ErrorActionPreference = "Stop"

# Bat buoc TLS 1.2 - tranh loi "connection was closed unexpectedly"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repo = "nqtam6666/Winutil-Vietnamese"
$releasesUrl = "https://github.com/$repo/releases/latest"
$repoZip = "https://github.com/$repo/archive/refs/heads/main.zip"
$launcherName = "WinUtil-Vi-Launcher.ps1"

# Kiem tra quyen Admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WinUtil can chay voi quyen Administrator. Dang khoi dong lai..."
    $installUrl = "https://raw.githubusercontent.com/$repo/main/install.ps1"
    $script = "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm '$installUrl' | iex }"
    $ps = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    Start-Process $ps -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"$script`"" -Verb RunAs
    return
}

$workDir = Join-Path $env:LOCALAPPDATA "WinUtil-Vi"
$extractDir = Join-Path $workDir "LauncherSource"
$zipPath = Join-Path $env:TEMP "Winutil-Vietnamese-main.zip"

try {
    Write-Host "Dang tai WinUtil Tieng Viet (Launcher) tu GitHub..."
    Invoke-RestMethod -Uri $repoZip -OutFile $zipPath -UseBasicParsing

    if (-not (Test-Path $workDir)) { New-Item -ItemType Directory -Path $workDir -Force | Out-Null }
    if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
    Expand-Archive -Path $zipPath -DestinationPath $workDir -Force
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

    $innerFolder = Join-Path $workDir "Winutil-Vietnamese-main"
    if (-not (Test-Path $innerFolder)) {
        $folders = Get-ChildItem $workDir -Directory | Where-Object { $_.Name -like "*main*" -or $_.Name -like "*Winutil*" }
        $innerFolder = $folders[0].FullName
    }

    $launcherPath = Join-Path $innerFolder $launcherName
    if (-not (Test-Path $launcherPath)) {
        throw "Khong tim thay $launcherName trong goi tai xuong."
    }

    Write-Host "Dang khoi chay Launcher..."
    & powershell -NoProfile -ExecutionPolicy Bypass -File $launcherPath
} catch {
    Write-Host "Loi: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Thu:" -ForegroundColor Yellow
    Write-Host "  1. Kiem tra ket noi internet"
    Write-Host "  2. Chay lai voi quyen Administrator"
    Write-Host "  Repo: https://github.com/$repo"
}
