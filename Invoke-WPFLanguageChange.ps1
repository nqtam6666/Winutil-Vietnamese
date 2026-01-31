function Invoke-WPFLanguageChange {
    <#
    .SYNOPSIS
        Handles language change from ComboBox
    .DESCRIPTION
        When user changes language:
        1. Save preference
        2. Close WinUtil
        3. Apply translation (vi) or restore original (en)
        4. Rebuild and restart
    #>
    param(
        [string]$Language = "vi"
    )

    # Helper: Modern dark toast notification
    function Show-LangToast {
        param([string]$Message, [double]$Seconds = 1.5)
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        $bgColor = [System.Drawing.Color]::FromArgb(30, 35, 45)
        $accentColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
        
        $form = New-Object System.Windows.Forms.Form
        $form.Text = ""
        $form.Size = New-Object System.Drawing.Size(360, 80)
        $form.StartPosition = "Manual"
        $form.FormBorderStyle = "None"
        $form.BackColor = $bgColor
        $form.Topmost = $true
        $form.ShowInTaskbar = $false
        $form.Opacity = 0
        
        # Position: bottom-right
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
        $form.Location = New-Object System.Drawing.Point(($screen.Right - $form.Width - 20), ($screen.Bottom - $form.Height - 20))
        
        # Accent bar
        $bar = New-Object System.Windows.Forms.Panel
        $bar.Size = New-Object System.Drawing.Size(4, 80)
        $bar.Location = New-Object System.Drawing.Point(0, 0)
        $bar.BackColor = $accentColor
        $form.Controls.Add($bar)
        
        # Icon (use simple Unicode char that fits in 16-bit)
        $icon = New-Object System.Windows.Forms.Label
        $icon.Text = [char]0x21BB  # Rotation arrow symbol
        $icon.Font = New-Object System.Drawing.Font("Segoe UI Symbol", 22)
        $icon.ForeColor = $accentColor
        $icon.Size = New-Object System.Drawing.Size(45, 45)
        $icon.Location = New-Object System.Drawing.Point(14, 18)
        $form.Controls.Add($icon)
        
        # Message
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $Message
        $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 11)
        $lbl.ForeColor = [System.Drawing.Color]::White
        $lbl.Size = New-Object System.Drawing.Size(280, 50)
        $lbl.Location = New-Object System.Drawing.Point(65, 18)
        $lbl.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
        $form.Controls.Add($lbl)
        
        # Fade animation
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 20
        $script:step = 0
        $script:total = [int]($Seconds * 1000 / 20)
        
        $timer.Add_Tick({
            $script:step++
            if ($script:step -le 8) { $form.Opacity = $script:step / 8 }
            elseif ($script:step -ge ($script:total - 10)) {
                $form.Opacity = [Math]::Max(0, ($script:total - $script:step) / 10)
            }
            if ($script:step -ge $script:total) { $timer.Stop(); $timer.Dispose(); $form.Close() }
        })
        
        $form.Add_Shown({ $timer.Start() })
        $form.ShowDialog() | Out-Null
    }

    $configPath = Join-Path $env:LOCALAPPDATA "WinUtil-Vi"
    $langFile = Join-Path $configPath "language.txt"

    # Create config directory if not exists
    if (-not (Test-Path $configPath)) {
        New-Item -ItemType Directory -Path $configPath -Force | Out-Null
    }

    # Save language preference
    $Language | Out-File -FilePath $langFile -Encoding UTF8 -Force

    # Show confirmation toast (auto-closes after 0.5s)
    $msg = if ($Language -eq "vi") {
        "Đang chuyển sang Tiếng Việt..."
    } else {
        "Switching to English..."
    }
    Show-LangToast -Message $msg -Seconds 1.5

    # Get WinUtil directory - try multiple locations
    $winUtilDir = $null

    # 1. Check if running from script file location
    if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "Translate-Vi.ps1"))) {
        $winUtilDir = $PSScriptRoot
    }
    # 2. Check current directory
    elseif (Test-Path ".\Translate-Vi.ps1") {
        $winUtilDir = (Get-Location).Path
    }
    # 3. Check standard location
    elseif (Test-Path (Join-Path $configPath "winutil\Translate-Vi.ps1")) {
        $winUtilDir = Join-Path $configPath "winutil"
    }

    if ($winUtilDir -and (Test-Path $winUtilDir)) {
        # Toast function to embed in rebuild script
        $toastFunc = @'
function Show-BuildToast {
    param([string]$Message, [string]$Type = "Info", [double]$Seconds = 1.5)
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $colors = @{
        "Info" = @{ Bg = [System.Drawing.Color]::FromArgb(30, 35, 45); Accent = [System.Drawing.Color]::FromArgb(0, 120, 212); Icon = [char]0x2139 }
        "Success" = @{ Bg = [System.Drawing.Color]::FromArgb(30, 45, 35); Accent = [System.Drawing.Color]::FromArgb(16, 185, 129); Icon = [char]0x2714 }
        "Warning" = @{ Bg = [System.Drawing.Color]::FromArgb(45, 40, 30); Accent = [System.Drawing.Color]::FromArgb(245, 158, 11); Icon = [char]0x26A0 }
    }
    $theme = $colors[$Type]
    $form = New-Object System.Windows.Forms.Form
    $form.Text = ""; $form.Size = New-Object System.Drawing.Size(380, 85)
    $form.StartPosition = "Manual"; $form.FormBorderStyle = "None"
    $form.BackColor = $theme.Bg; $form.Topmost = $true; $form.ShowInTaskbar = $false; $form.Opacity = 0
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $form.Location = New-Object System.Drawing.Point(($screen.Right - 400), ($screen.Bottom - 105))
    $bar = New-Object System.Windows.Forms.Panel
    $bar.Size = New-Object System.Drawing.Size(4, 85); $bar.BackColor = $theme.Accent
    $form.Controls.Add($bar)
    $icon = New-Object System.Windows.Forms.Label
    $icon.Text = $theme.Icon; $icon.Font = New-Object System.Drawing.Font("Segoe UI", 16)
    $icon.ForeColor = $theme.Accent; $icon.Size = New-Object System.Drawing.Size(35, 35)
    $icon.Location = New-Object System.Drawing.Point(14, 25); $form.Controls.Add($icon)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Message; $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $lbl.ForeColor = [System.Drawing.Color]::White
    $lbl.Size = New-Object System.Drawing.Size(310, 50); $lbl.Location = New-Object System.Drawing.Point(55, 18)
    $form.Controls.Add($lbl)
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 20; $script:step = 0; $script:total = [int]($Seconds * 1000 / 20)
    $timer.Add_Tick({
        $script:step++
        if ($script:step -le 6) { $form.Opacity = $script:step / 6 }
        elseif ($script:step -ge ($script:total - 8)) { $form.Opacity = [Math]::Max(0, ($script:total - $script:step) / 8) }
        if ($script:step -ge $script:total) { $timer.Stop(); $timer.Dispose(); $form.Close() }
    })
    $form.Add_Shown({ $timer.Start() })
    $form.ShowDialog() | Out-Null
}
'@
        
        # Build script based on language
        if ($Language -eq "vi") {
            $rebuildScript = @"
$toastFunc

Set-Location '$winUtilDir'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; chcp 65001 | Out-Null } catch {}

Show-BuildToast -Message "Đang build WinUtil (Tiếng Việt)..." -Type "Info" -Seconds 1.2

# Restore original files first
Show-BuildToast -Message "Khôi phục file gốc..." -Type "Info" -Seconds 1
Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ".\Translate-Vi.ps1" -Restore' -Wait -WindowStyle Hidden

# Translate to Vietnamese
Show-BuildToast -Message "Đang dịch sang Tiếng Việt..." -Type "Info" -Seconds 1
Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ".\Translate-Vi.ps1" -Language vi' -Wait -WindowStyle Hidden

# Compile
Show-BuildToast -Message "Đang compile..." -Type "Info" -Seconds 1
Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ".\Compile.ps1"' -Wait -WindowStyle Hidden

# Restart WinUtil with admin rights
Show-BuildToast -Message "Hoàn tất! Đang khởi động WinUtil..." -Type "Success" -Seconds 1.5
`$winutilFullPath = Join-Path '$winUtilDir' 'winutil.ps1'
Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ```"`$winutilFullPath```"" -Verb RunAs
"@
        } else {
            $rebuildScript = @"
$toastFunc

Set-Location '$winUtilDir'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; chcp 65001 | Out-Null } catch {}

Show-BuildToast -Message "Rebuilding WinUtil (Tiếng Anh)..." -Type "Info" -Seconds 1.2

# Restore original English files
Show-BuildToast -Message "Khôi phục file Tiếng Anh..." -Type "Info" -Seconds 1
Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ".\Translate-Vi.ps1" -Language en -Restore' -Wait -WindowStyle Hidden

# Compile
Show-BuildToast -Message "Đang compile..." -Type "Info" -Seconds 1
Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ".\Compile.ps1"' -Wait -WindowStyle Hidden

# Restart WinUtil with admin rights
Show-BuildToast -Message "Done! Starting WinUtil..." -Type "Success" -Seconds 1.5
`$winutilFullPath = Join-Path '$winUtilDir' 'winutil.ps1'
Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ```"`$winutilFullPath```"" -Verb RunAs
"@
        }

        $tempScript = Join-Path $env:TEMP "winutil-rebuild.ps1"
        $rebuildScript | Out-File -FilePath $tempScript -Encoding UTF8 -Force

        # Start rebuild in new HIDDEN process and close current
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$tempScript`"" -Verb RunAs

        # Close current WinUtil
        $sync.Form.Close()
    } else {
        [System.Windows.MessageBox]::Show(
            "Không tìm thấy Translate-Vi.ps1.`nHãy đảm bảo file này nằm cùng thư mục với winutil.ps1",
            "Lỗi", "OK", "Error")
    }
    $sync.Form.Close()
}
