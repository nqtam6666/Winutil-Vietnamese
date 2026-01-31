<#
.SYNOPSIS
    WinUtil Launcher Tiếng Việt - GUI tải, dịch, build và chạy.
    Lưu file UTF-8 BOM để hiển thị tiếng Việt có dấu âm.
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\WinUtil-Vi-Launcher.ps1
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null
} catch {
    # No console when running as GUI EXE (-NoConsole); encoding setup is skipped.
}

$FontTitle = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$FontBody = New-Object System.Drawing.Font("Segoe UI", 9.5)
$ColorBg = [System.Drawing.Color]::FromArgb(250, 250, 252)
$ColorAccent = [System.Drawing.Color]::FromArgb(0, 120, 215)

$GitHubRepo = "https://github.com/ChrisTitusTech/winutil.git"
$GitHubZip = "https://github.com/ChrisTitusTech/winutil/archive/refs/heads/main.zip"

$appData = $env:LOCALAPPDATA
if ([string]::IsNullOrEmpty($appData)) {
    $appData = [Environment]::GetFolderPath('LocalApplicationData')
}
if ([string]::IsNullOrEmpty($appData)) {
    $appData = $env:TEMP
}
$WorkRoot = Join-Path $appData "WinUtil-Vi"
$WinUtilDir = Join-Path $WorkRoot "winutil"

$LauncherDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($LauncherDir)) {
    $cmdPath = $MyInvocation.MyCommand.Path
    if (-not [string]::IsNullOrEmpty($cmdPath)) {
        $LauncherDir = Split-Path -Parent $cmdPath
    }
}
if ([string]::IsNullOrEmpty($LauncherDir)) {
    $LauncherDir = (Get-Location).Path
}
if ([string]::IsNullOrEmpty($LauncherDir)) {
    $LauncherDir = $WorkRoot
}
if ($null -ne $LauncherDir) {
    $LauncherDir = $LauncherDir.ToString().Trim()
}

# File nhung vao EXE - Build-Exe.ps1 thay the block nay bang hashtable day du
$script:EmbeddedFiles = @{}

function Export-EmbeddedLauncherFiles {
    param([string]$ExportDir)
    if ([string]::IsNullOrEmpty($ExportDir)) { return }
    if (-not $script:EmbeddedFiles -or $script:EmbeddedFiles.Count -eq 0) { return }
    if (-not (Test-Path $ExportDir)) { New-Item -ItemType Directory -Path $ExportDir -Force | Out-Null }
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    foreach ($key in $script:EmbeddedFiles.Keys) {
        $destPath = Join-Path $ExportDir $key
        $parentDir = Split-Path -Parent $destPath
        if (-not [string]::IsNullOrEmpty($parentDir) -and -not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        $bytes = [Convert]::FromBase64String($script:EmbeddedFiles[$key])
        if ($key -match '\.(ico|png|jpg|exe)$') {
            [System.IO.File]::WriteAllBytes($destPath, $bytes)
        } else {
            $text = [System.Text.Encoding]::UTF8.GetString($bytes)
            [System.IO.File]::WriteAllText($destPath, $text, $utf8Bom)
        }
    }
}

# Hien thi thong bao tu dong dong sau N giay (mac dinh 0.5s) - Modern Dark Toast
function Show-ToastMessage {
    param(
        [string]$Message,
        [string]$Title = "WinUtil-Vi",
        [double]$Seconds = 1.5,
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Type = "Info"
    )
    
    # Colors based on type
    $colors = @{
        "Info"    = @{ Bg = [System.Drawing.Color]::FromArgb(30, 35, 45); Accent = [System.Drawing.Color]::FromArgb(0, 120, 212); Icon = [char]0x2139 }
        "Success" = @{ Bg = [System.Drawing.Color]::FromArgb(30, 45, 35); Accent = [System.Drawing.Color]::FromArgb(16, 185, 129); Icon = [char]0x2714 }
        "Warning" = @{ Bg = [System.Drawing.Color]::FromArgb(45, 40, 30); Accent = [System.Drawing.Color]::FromArgb(245, 158, 11); Icon = [char]0x26A0 }
        "Error"   = @{ Bg = [System.Drawing.Color]::FromArgb(45, 30, 30); Accent = [System.Drawing.Color]::FromArgb(239, 68, 68); Icon = [char]0x2716 }
    }
    $theme = $colors[$Type]
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = ""
    $form.Size = New-Object System.Drawing.Size(380, 90)
    $form.StartPosition = "Manual"
    $form.FormBorderStyle = "None"
    $form.BackColor = $theme.Bg
    $form.Topmost = $true
    $form.ShowInTaskbar = $false
    $form.Opacity = 0
    
    # Position: bottom-right corner
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $form.Location = New-Object System.Drawing.Point(($screen.Right - $form.Width - 20), ($screen.Bottom - $form.Height - 20))
    
    # Accent bar on left
    $accentBar = New-Object System.Windows.Forms.Panel
    $accentBar.Size = New-Object System.Drawing.Size(4, 90)
    $accentBar.Location = New-Object System.Drawing.Point(0, 0)
    $accentBar.BackColor = $theme.Accent
    $form.Controls.Add($accentBar)
    
    # Icon
    $iconLabel = New-Object System.Windows.Forms.Label
    $iconLabel.Text = $theme.Icon
    $iconLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Regular)
    $iconLabel.ForeColor = $theme.Accent
    $iconLabel.Size = New-Object System.Drawing.Size(40, 40)
    $iconLabel.Location = New-Object System.Drawing.Point(16, 25)
    $iconLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $form.Controls.Add($iconLabel)
    
    # Title
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $Title
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.AutoSize = $true
    $titleLabel.Location = New-Object System.Drawing.Point(60, 15)
    $form.Controls.Add($titleLabel)
    
    # Message
    $msgLabel = New-Object System.Windows.Forms.Label
    $msgLabel.Text = $Message
    $msgLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $msgLabel.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
    $msgLabel.Size = New-Object System.Drawing.Size(290, 35)
    $msgLabel.Location = New-Object System.Drawing.Point(60, 42)
    $form.Controls.Add($msgLabel)
    
    # Close button (X)
    $closeBtn = New-Object System.Windows.Forms.Label
    $closeBtn.Text = [char]0x2715
    $closeBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $closeBtn.ForeColor = [System.Drawing.Color]::FromArgb(120, 120, 120)
    $closeBtn.Size = New-Object System.Drawing.Size(20, 20)
    $closeBtn.Location = New-Object System.Drawing.Point(352, 8)
    $closeBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $closeBtn.Add_Click({ $form.Close() })
    $closeBtn.Add_MouseEnter({ $closeBtn.ForeColor = [System.Drawing.Color]::White })
    $closeBtn.Add_MouseLeave({ $closeBtn.ForeColor = [System.Drawing.Color]::FromArgb(120, 120, 120) })
    $form.Controls.Add($closeBtn)
    
    # Fade in/out animation
    $fadeTimer = New-Object System.Windows.Forms.Timer
    $fadeTimer.Interval = 15
    $script:fadeStep = 0
    $script:totalSteps = [int]($Seconds * 1000 / 15)
    $script:fadeInSteps = 10
    $script:fadeOutSteps = 15
    
    $fadeTimer.Add_Tick({
        $script:fadeStep++
        if ($script:fadeStep -le $script:fadeInSteps) {
            # Fade in
            $form.Opacity = $script:fadeStep / $script:fadeInSteps
        } elseif ($script:fadeStep -ge ($script:totalSteps - $script:fadeOutSteps)) {
            # Fade out
            $remaining = $script:totalSteps - $script:fadeStep
            $form.Opacity = [Math]::Max(0, $remaining / $script:fadeOutSteps)
        }
        if ($script:fadeStep -ge $script:totalSteps) {
            $fadeTimer.Stop()
            $fadeTimer.Dispose()
            $form.Close()
        }
    })
    
    $form.Add_Shown({ $fadeTimer.Start() })
    $form.ShowDialog() | Out-Null
}

# ScriptBlock chua logic - de chay sau khi form dong
$script:UserChoice = $null
$script:ShouldDownload = $null

function Get-LauncherFiles {
    $files = @{ TranslateVi = $null; Translations = $null; CompileVi = $null; Icon = $null }
    if ([string]::IsNullOrEmpty($LauncherDir)) { return $files }
    $dirs = @($LauncherDir, (Join-Path $LauncherDir ".."))
    foreach ($d in $dirs) {
        if (-not $d) { continue }
        $d = $d.TrimEnd('\')
        if (Test-Path (Join-Path $d "Translate-Vi.ps1")) { $files.TranslateVi = Join-Path $d "Translate-Vi.ps1"; break }
    }
    foreach ($d in $dirs) {
        if (-not $d) { continue }
        $d = $d.TrimEnd('\')
        $p = Join-Path $d "config\vi_translations.json"
        if (Test-Path $p) { $files.Translations = $p; break }
    }
    foreach ($d in $dirs) {
        if (-not $d) { continue }
        $d = $d.TrimEnd('\')
        if (Test-Path (Join-Path $d "Compile-Vi.ps1")) { $files.CompileVi = Join-Path $d "Compile-Vi.ps1"; break }
    }
    if (-not $files.CompileVi) {
        foreach ($d in $dirs) {
            if (-not $d) { continue }
            $d = $d.TrimEnd('\')
            $cp = Join-Path $d "Compile.ps1"
            if (Test-Path $cp) { $files.CompileVi = $cp; break }
        }
    }
    # Icon
    foreach ($d in $dirs) {
        if (-not $d) { continue }
        $d = $d.TrimEnd('\')
        $ico = Join-Path $d "meo.ico"
        if (Test-Path $ico) { $files.Icon = $ico; break }
    }
    return $files
}

function Test-RequireFiles {
    $f = Get-LauncherFiles
    $ok = $true
    if (-not $f.TranslateVi -or -not (Test-Path $f.TranslateVi)) { $ok = $false }
    if (-not $f.Translations -or -not (Test-Path $f.Translations)) { $ok = $false }
    if (-not $f.CompileVi -or -not (Test-Path $f.CompileVi)) { $ok = $false }
    return $ok
}

# Neu chua co file ben ngoai, giai nen tu file nhung (khi chay EXE don le)
if (-not (Test-RequireFiles)) {
    if ($script:EmbeddedFiles -and $script:EmbeddedFiles.Count -gt 0) {
        $exportDir = Join-Path $WorkRoot "LauncherFiles"
        Export-EmbeddedLauncherFiles -ExportDir $exportDir
        $LauncherDir = $exportDir
    }
}
if (-not (Test-RequireFiles)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Thiếu file: cần Translate-Vi.ps1, config\vi_translations.json, Compile-Vi.ps1. Chạy từ thư mục nguồn hoặc dùng EXE đã nhúng file.",
        "Lỗi",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

function Show-MainGUI {
    param([bool]$FirstRun = $false)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "WinUtil Tiếng Việt"
    $form.Size = New-Object System.Drawing.Size(480, 420)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedSingle"
    $form.MaximizeBox = $false
    $form.BackColor = $ColorBg
    $form.Font = $FontBody
    # Use embedded icon
    $f = Get-LauncherFiles
    $iconPath = if ($f.Icon -and (Test-Path $f.Icon)) { $f.Icon } else { Join-Path $LauncherDir "meo.ico" }
    if ($iconPath -and (Test-Path $iconPath)) { try { $form.Icon = [System.Drawing.Icon]::new($iconPath) } catch {} }

    # Language toggle button (top-right)
    $btnLang = New-Object System.Windows.Forms.Button
    $btnLang.Location = New-Object System.Drawing.Point(380, 12)
    $btnLang.Size = New-Object System.Drawing.Size(70, 28)
    $btnLang.Text = "EN"
    $btnLang.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $btnLang.FlatStyle = "Flat"
    $btnLang.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btnLang.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnLang.Add_Click({
        # Toggle language
        if ($form.Tag -eq "vi") {
            # Switch to English
            $form.Tag = "en"
            $btnLang.Text = "VI"
            $form.Text = "WinUtil English"
            $lblTitle.Text = "Choose Action"
            $grp.Text = " Options "
            $rb1.Text = "Download from GitHub, translate, build and run"
            $rb2.Text = "Run current build (offline - requires build)"
            $rb3.Text = "Edit translations (open JSON file)"
            $rb4.Text = "Add new translation (EN -> VI string)"
            $chkDownload.Text = "Download latest from GitHub before translate/build"
            $btnOK.Text = "Execute"
            $btnCancel.Text = "Exit"
        } else {
            # Switch to Vietnamese
            $form.Tag = "vi"
            $btnLang.Text = "EN"
            $form.Text = "WinUtil Tiếng Việt"
            $lblTitle.Text = "Chọn hành động"
            $grp.Text = " T?y ch?n "
            $rb1.Text = "Tải bản mới từ GitHub, dịch, build và chạy"
            $rb2.Text = "Chạy bản hiện tại (offline - cần build)"
            $rb3.Text = "Chỉnh sửa bản dịch (mở file JSON)"
            $rb4.Text = "Thêm bản dịch mới (chuỗi EN -> VI)"
            $chkDownload.Text = "Tải bản mới từ GitHub trước khi dịch/build"
            $btnOK.Text = "Thực hiện"
            $btnCancel.Text = "Thoát"
        }
    })
    $form.Controls.Add($btnLang)
    $form.Tag = "vi"  # Default language
    
    $y = 24
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Location = New-Object System.Drawing.Point(24, $y)
    $lblTitle.Size = New-Object System.Drawing.Size(340, 28)
    $lblTitle.Text = "Ch?n h?nh ??ng"
    $lblTitle.Font = $FontTitle
    $lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(33, 33, 33)
    $form.Controls.Add($lblTitle)
    $y += 44

    $grp = New-Object System.Windows.Forms.GroupBox
    $grp.Location = New-Object System.Drawing.Point(24, $y)
    $grp.Size = New-Object System.Drawing.Size(420, 200)
    $grp.Text = " Tùy chọn "
    $grp.Font = $FontBody
    $grp.Padding = New-Object System.Windows.Forms.Padding(16, 20, 16, 16)

    $gy = 28
    $rb1 = New-Object System.Windows.Forms.RadioButton
    $rb1.Location = New-Object System.Drawing.Point(16, $gy)
    $rb1.Size = New-Object System.Drawing.Size(380, 24)
    $rb1.Text = "Tải bản mới từ GitHub, dịch, build và chạy"
    $rb1.Checked = $FirstRun
    $grp.Controls.Add($rb1)
    $gy += 32

    $rb2 = New-Object System.Windows.Forms.RadioButton
    $rb2.Location = New-Object System.Drawing.Point(16, $gy)
    $rb2.Size = New-Object System.Drawing.Size(380, 24)
    $rb2.Text = "Chạy bản hiện tại (offline - cần build)"
    $rb2.Enabled = -not $FirstRun
    $rb2.Checked = -not $FirstRun
    $grp.Controls.Add($rb2)
    $gy += 32

    $rb3 = New-Object System.Windows.Forms.RadioButton
    $rb3.Location = New-Object System.Drawing.Point(16, $gy)
    $rb3.Size = New-Object System.Drawing.Size(380, 24)
    $rb3.Text = "Chỉnh sửa bản dịch (mở file JSON)"
    $grp.Controls.Add($rb3)
    $gy += 32

    $rb4 = New-Object System.Windows.Forms.RadioButton
    $rb4.Location = New-Object System.Drawing.Point(16, $gy)
    $rb4.Size = New-Object System.Drawing.Size(380, 24)
    $rb4.Text = "Thêm bản dịch mới (chuỗi EN -> VI)"
    $grp.Controls.Add($rb4)
    $gy += 36

    $chkDownload = New-Object System.Windows.Forms.CheckBox
    $chkDownload.Location = New-Object System.Drawing.Point(16, $gy)
    $chkDownload.Size = New-Object System.Drawing.Size(380, 24)
    $chkDownload.Text = "Tải bản mới từ GitHub trước khi dịch/build"
    $chkDownload.Checked = $true
    $chkDownload.Visible = $rb1.Checked
    $grp.Controls.Add($chkDownload)

    $form.Controls.Add($grp)
    $y += 216

    $rb1.Add_CheckedChanged({ $chkDownload.Visible = $rb1.Checked })

    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Location = New-Object System.Drawing.Point(180, $y)
    $btnOK.Size = New-Object System.Drawing.Size(120, 36)
    $btnOK.Text = "Thực hiện"
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $btnOK.BackColor = $ColorAccent
    $btnOK.ForeColor = [System.Drawing.Color]::White
    $btnOK.FlatStyle = "Flat"
    $form.AcceptButton = $btnOK
    $form.Controls.Add($btnOK)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Location = New-Object System.Drawing.Point(310, $y)
    $btnCancel.Size = New-Object System.Drawing.Size(120, 36)
    $btnCancel.Text = "Thoát"
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $btnCancel
    $form.Controls.Add($btnCancel)

    $result = $form.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        if ($rb1.Checked) { $script:UserChoice = "1"; $script:ShouldDownload = $chkDownload.Checked }
        elseif ($rb2.Checked) { $script:UserChoice = "2" }
        elseif ($rb3.Checked) { $script:UserChoice = "3" }
        elseif ($rb4.Checked) { $script:UserChoice = "4" }
        else { $script:UserChoice = $null }
    } else {
        $script:UserChoice = "cancel"
    }
}

function Show-AddTranslationGUI {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Thêm bản dịch mới"
    $form.Size = New-Object System.Drawing.Size(540, 280)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedSingle"
    $form.BackColor = $ColorBg
    $form.Font = $FontBody
    # Use embedded icon
    $f = Get-LauncherFiles
    $iconPath = if ($f.Icon -and (Test-Path $f.Icon)) { $f.Icon } else { Join-Path $LauncherDir "meo.ico" }
    if ($iconPath -and (Test-Path $iconPath)) { try { $form.Icon = [System.Drawing.Icon]::new($iconPath) } catch {} }

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Location = New-Object System.Drawing.Point(24, 20)
    $lblTitle.Size = New-Object System.Drawing.Size(480, 24)
    $lblTitle.Text = "Thêm hoặc cập nhật bản dịch (ghi nếu tồn tại)"
    $lblTitle.Font = $FontTitle
    $form.Controls.Add($lblTitle)

    $lbl1 = New-Object System.Windows.Forms.Label
    $lbl1.Location = New-Object System.Drawing.Point(24, 58)
    $lbl1.Size = New-Object System.Drawing.Size(480, 20)
    $lbl1.Text = "Chuỗi tiếng Anh (trong WinUtil):"
    $form.Controls.Add($lbl1)

    $txtEN = New-Object System.Windows.Forms.TextBox
    $txtEN.Location = New-Object System.Drawing.Point(24, 80)
    $txtEN.Size = New-Object System.Drawing.Size(478, 26)
    $txtEN.Font = $FontBody
    $form.Controls.Add($txtEN)

    $lbl2 = New-Object System.Windows.Forms.Label
    $lbl2.Location = New-Object System.Drawing.Point(24, 118)
    $lbl2.Size = New-Object System.Drawing.Size(480, 20)
    $lbl2.Text = "Bản dịch tiếng Việt:"
    $form.Controls.Add($lbl2)

    $txtVI = New-Object System.Windows.Forms.TextBox
    $txtVI.Location = New-Object System.Drawing.Point(24, 140)
    $txtVI.Size = New-Object System.Drawing.Size(478, 26)
    $txtVI.Font = $FontBody
    $form.Controls.Add($txtVI)

    $lblHint = New-Object System.Windows.Forms.Label
    $lblHint.Location = New-Object System.Drawing.Point(24, 175)
    $lblHint.Size = New-Object System.Drawing.Size(478, 36)
    $lblHint.Text = "Gợi ý: Thêm chuỗi mới khi WinUtil cập nhật và có text chưa dịch. Bản dịch mới sẽ ghi nếu chuỗi đã tồn tại."
    $lblHint.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
    $lblHint.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $form.Controls.Add($lblHint)

    $btnAdd = New-Object System.Windows.Forms.Button
    $btnAdd.Location = New-Object System.Drawing.Point(290, 218)
    $btnAdd.Size = New-Object System.Drawing.Size(100, 32)
    $btnAdd.Text = "Thêm"
    $btnAdd.BackColor = $ColorAccent
    $btnAdd.ForeColor = [System.Drawing.Color]::White
    $btnAdd.FlatStyle = "Flat"
    $form.Controls.Add($btnAdd)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Location = New-Object System.Drawing.Point(402, 218)
    $btnCancel.Size = New-Object System.Drawing.Size(100, 32)
    $btnCancel.Text = "Đóng"
    $form.Controls.Add($btnCancel)

    $script:AddTranslationResult = $null
    $btnAdd.Add_Click({
        if ([string]::IsNullOrWhiteSpace($txtEN.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Nhập chuỗi tiếng Anh.", "Thiếu thông tin", "OK", "Warning")
            return
        }
        if ([string]::IsNullOrWhiteSpace($txtVI.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Nhập bản dịch tiếng Việt.", "Thiếu thông tin", "OK", "Warning")
            return
        }
        $script:AddTranslationResult = @{ EN = $txtEN.Text.Trim(); VI = $txtVI.Text.Trim() }
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
    })

    $script:AddTranslationResult = $null
    $btnCancel.Add_Click({ $form.Close() })

    $form.ShowDialog() | Out-Null
    return $script:AddTranslationResult
}

function Add-TranslationToFile {
    param([string]$en, [string]$vi)
    $f = Get-LauncherFiles
    $path = $f.Translations
    if (-not $path -or -not (Test-Path $path)) {
        [System.Windows.Forms.MessageBox]::Show("Không tìm thấy vi_translations.json", "Lỗi", "OK", "Error")
        return $false
    }
    $reader = New-Object System.IO.StreamReader($path, [System.Text.Encoding]::UTF8, $true)
    $content = $reader.ReadToEnd()
    $reader.Close()

    $enEscaped = $en -replace '\\', '\\\\' -replace '"', '\"'
    $viEscaped = $vi -replace '\\', '\\\\' -replace '"', '\"' -replace "`r`n", '\n' -replace "`n", '\n' -replace "`r", '\n'

    $keyEscaped = [regex]::Escape($en)
    $keyPattern = '"' + $keyEscaped + '":\s*"(?:[^"\\]|\\.)*"'
    $newEntry = "`"$enEscaped`": `"$viEscaped`""

    if ($content -match $keyPattern) {
        $content = $content -replace $keyPattern, $newEntry
    } else {
        $newLine = "  $newEntry,"
        $lastBrace = $content.LastIndexOf('}')
        if ($lastBrace -gt 0) {
            $before = $content.Substring(0, $lastBrace).TrimEnd()
            $after = $content.Substring($lastBrace)
            if (-not $before.EndsWith(',')) { $before = $before + ',' }
            $content = $before + "`r`n" + $newLine + "`r`n" + $after
        }
    }

    $utf8 = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($path, $content, $utf8)
    return $true
}

function Invoke-GitClone {
    Show-ToastMessage -Message "Đang clone WinUtil từ GitHub (Git)..." -Type "Info" -Seconds 1
    if (-not (Test-Path $WorkRoot)) { New-Item -ItemType Directory -Path $WorkRoot -Force | Out-Null }
    if (Test-Path $WinUtilDir) { Remove-Item $WinUtilDir -Recurse -Force }
    Push-Location $WorkRoot
    try {
        git clone --depth 1 $GitHubRepo winutil 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
        Show-ToastMessage -Message "Clone xong!" -Type "Success" -Seconds 1
    } catch { Pop-Location; throw }
    Pop-Location
}

function Invoke-DownloadAndExtract {
    Show-ToastMessage -Message "Đang tải WinUtil từ GitHub (ZIP)..." -Type "Info" -Seconds 1
    if (-not (Test-Path $WorkRoot)) { New-Item -ItemType Directory -Path $WorkRoot -Force | Out-Null }
    $zipPath = Join-Path $env:TEMP "winutil-main.zip"
    $extractPath = Join-Path $env:TEMP "winutil-extract"
    try {
        Invoke-WebRequest -Uri $GitHubZip -OutFile $zipPath -UseBasicParsing
        if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        $srcDir = Join-Path $extractPath "winutil-main"
        if (-not (Test-Path $srcDir)) {
            $folders = Get-ChildItem $extractPath -Directory
            $srcDir = $folders[0].FullName
        }
        if (Test-Path $WinUtilDir) { Remove-Item $WinUtilDir -Recurse -Force }
        Move-Item $srcDir $WinUtilDir -Force
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        Show-ToastMessage -Message "Tải xong!" -Type "Success" -Seconds 1
    } catch { Show-ToastMessage -Message "Lỗi tải: $_" -Type "Error" -Seconds 2; throw }
}

function Invoke-GitPull {
    Push-Location $WinUtilDir
    try {
        git pull origin main 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git pull failed" }
        Show-ToastMessage -Message "Đã cập nhật từ Git!" -Type "Success" -Seconds 1
    } catch { Pop-Location; Invoke-DownloadAndExtract; return }
    Pop-Location
}

function Invoke-TranslateAndBuild {
    $f = Get-LauncherFiles
    if (Test-Path $f.TranslateVi) { Copy-Item $f.TranslateVi -Destination (Join-Path $WinUtilDir "Translate-Vi.ps1") -Force }
    $configDir = Join-Path $WinUtilDir "config"
    if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
    if (Test-Path $f.Translations) { Copy-Item $f.Translations -Destination (Join-Path $configDir "vi_translations.json") -Force }
    # Copy en_translations.json for language switching
    $enTransSrc = Join-Path $LauncherDir "config\en_translations.json"
    if (Test-Path $enTransSrc) { Copy-Item $enTransSrc -Destination (Join-Path $configDir "en_translations.json") -Force }
    $compileDest = Join-Path $WinUtilDir "Compile.ps1"
    if ($f.CompileVi -and (Test-Path $f.CompileVi)) { Copy-Item $f.CompileVi -Destination $compileDest -Force }
    # Copy Language Change function vao functions\public de Compile.ps1 nhung vao winutil.ps1
    $langFuncSrc = Join-Path $LauncherDir "Invoke-WPFLanguageChange.ps1"
    $langFuncDestDir = Join-Path $WinUtilDir "functions\public"
    if (Test-Path $langFuncSrc) {
        if (-not (Test-Path $langFuncDestDir)) { New-Item -ItemType Directory -Path $langFuncDestDir -Force | Out-Null }
        Copy-Item $langFuncSrc -Destination (Join-Path $langFuncDestDir "Invoke-WPFLanguageChange.ps1") -Force
    }

    Push-Location $WinUtilDir
    try {
        # Đồn hoàn toàn PowerShell - dùng -WindowStyle Hidden cho Start-Process
        Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ".\Translate-Vi.ps1" -Restore' -Wait -WindowStyle Hidden
        Show-ToastMessage -Message "Đã khôi phục bản gốc." -Type "Success" -Seconds 1
        # Restore ghi de functions\ tu git -> phai copy lai Invoke-WPFLanguageChange.ps1 sau Restore
        if (Test-Path $langFuncSrc) {
            if (-not (Test-Path $langFuncDestDir)) { New-Item -ItemType Directory -Path $langFuncDestDir -Force | Out-Null }
            Copy-Item $langFuncSrc -Destination (Join-Path $langFuncDestDir "Invoke-WPFLanguageChange.ps1") -Force
        }
        Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ".\Translate-Vi.ps1"' -Wait -WindowStyle Hidden
        Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ".\Compile.ps1"' -Wait -WindowStyle Hidden
        if (-not (Test-Path ".\winutil.ps1")) { throw "Build thất bại - không tìm thấy winutil.ps1" }
        Show-ToastMessage -Message "Đã dịch và build xong. Đang khởi chạy WinUtil..." -Type "Success" -Seconds 1.5
        # Start WinUtil with admin rights
        $winutilPs1 = Join-Path $WinUtilDir "winutil.ps1"
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$winutilPs1`"" -Verb RunAs
    } catch { [System.Windows.Forms.MessageBox]::Show("LOI: $_", "WinUtil-Vi", "OK", "Error") }
    finally { Pop-Location }
}

function Invoke-RunCurrent {
    $winutilPath = Join-Path $WinUtilDir "winutil.ps1"
    if (-not (Test-Path $winutilPath)) {
        Show-ToastMessage -Message "Chưa có bản build. Hãy chọn 'Tải bản mới...' trước." -Type "Warning" -Seconds 2
        return
    }
    # Start WinUtil with admin rights
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$winutilPath`"" -Verb RunAs
}

function Invoke-EditTranslations {
    $f = Get-LauncherFiles
    $path = $f.Translations
    if (-not $path -or -not (Test-Path $path)) { $path = Join-Path $WinUtilDir "config\vi_translations.json" }
    if (-not (Test-Path $path)) {
        [System.Windows.Forms.MessageBox]::Show("Không tìm thấy vi_translations.json", "Lỗi", "OK", "Error")
        return
    }
    Start-Process notepad $path
}

# === MAIN ===
if (-not (Test-RequireFiles)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Thiếu file:`n- Translate-Vi.ps1`n- config\vi_translations.json`n- Compile-Vi.ps1`n`nCần đặt các file này cùng thư mục với Launcher.",
        "WinUtil - Lỗi", "OK", "Error")
    exit 1
}

$hasWinUtil = Test-Path $WinUtilDir

if (-not $hasWinUtil) {
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Chưa có bản WinUtil. Cần tải lần đầu.`n`nBạn muốn tải từ GitHub ngay",
        "WinUtil - Lần mới", "YesNo", "Question")
    if ($result -eq "Yes") {
        try {
            if (Get-Command git -ErrorAction SilentlyContinue) { Invoke-GitClone }
            else { Invoke-DownloadAndExtract }
        } catch {
            Show-ToastMessage -Message "Tải bản ZIP..." -Type "Info" -Seconds 1
            Invoke-DownloadAndExtract
        }
        Invoke-TranslateAndBuild
    }
    exit 0
}

Show-MainGUI -FirstRun $false

if ($script:UserChoice -eq "cancel" -or -not $script:UserChoice) { exit 0 }

switch ($script:UserChoice) {
    "1" {
        if ($script:ShouldDownload) {
            try {
                if (Test-Path (Join-Path $WinUtilDir ".git")) { Invoke-GitPull }
                elseif (Get-Command git -ErrorAction SilentlyContinue) { Invoke-GitClone }
                else { Invoke-DownloadAndExtract }
            } catch {
                Show-ToastMessage -Message "Tải bản ZIP..." -Type "Info" -Seconds 1
                Invoke-DownloadAndExtract
            }
        }
        Invoke-TranslateAndBuild
    }
    "2" { Invoke-RunCurrent }
    "3" { Invoke-EditTranslations }
    "4" {
        do {
            $pair = Show-AddTranslationGUI
            if ($pair) {
                if (Add-TranslationToFile -en $pair.EN -vi $pair.VI) {
                    Show-ToastMessage -Message "Thêm/cập nhật bản dịch. Chọn 'Tải bản mới...' để build lại." -Type "Success" -Seconds 2
                }
            }
        } while ($pair -ne $null)
    }
}
