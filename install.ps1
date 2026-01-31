<#
.SYNOPSIS
    Bootstrap script - tai va chay WinUtil Tieng Viet.
.DESCRIPTION
    Chay: irm "https://raw.githubusercontent.com/nqtam6666/Winutil-Vietnamese/main/install.ps1" | iex
    Hoac: irm "https://github.com/nqtam6666/Winutil-Vietnamese/releases/latest/download/winutil.ps1" | iex
#>
$ErrorActionPreference = "Stop"
$repo = "nqtam6666/Winutil-Vietnamese"
$releasesUrl = "https://github.com/$repo/releases/latest"
$downloadUrl = "https://github.com/$repo/releases/latest/download/winutil.ps1"

# Kiem tra quyen Admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WinUtil can chay voi quyen Administrator. Dang khoi dong lai..."
    $script = "& { irm '$downloadUrl' | iex }"
    $ps = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    Start-Process $ps -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"$script`"" -Verb RunAs
    return
}

# Tai va chay winutil.ps1
try {
    $tempFile = Join-Path $env:TEMP "winutil-vi.ps1"
    Write-Host "Dang tai WinUtil Tieng Viet tu GitHub..."
    Invoke-RestMethod -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing
    & $tempFile @args
} catch {
    Write-Host "Loi: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Kiem tra:" -ForegroundColor Yellow
    Write-Host "  1. Da tao Release va dinh kem winutil.ps1 chua?"
    Write-Host "  2. Ten file phai la: winutil.ps1"
    Write-Host "  Xem: $releasesUrl"
}
