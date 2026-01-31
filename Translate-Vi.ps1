<#
.SYNOPSIS
    Dich WinUtil sang tieng Viet hoac Anh.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Translate-Vi.ps1
    powershell -ExecutionPolicy Bypass -File .\Translate-Vi.ps1 -Language vi
    powershell -ExecutionPolicy Bypass -File .\Translate-Vi.ps1 -Language en
    powershell -ExecutionPolicy Bypass -File .\Translate-Vi.ps1 -Restore
#>

param(
    [ValidateSet("vi", "en")]
    [string]$Language = "vi",
    [switch]$Restore
)

$ErrorActionPreference = "Continue"
$scriptDir = $PSScriptRoot

# CRITICAL: Set UTF-8 encoding for PowerShell operations
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'
chcp 65001 | Out-Null

Write-Host ""
if ($Restore -and $Language -eq "en") {
    Write-Host "=== RESTORE WINUTIL TO ENGLISH ===" -ForegroundColor Cyan
} elseif ($Restore) {
    Write-Host "=== KHOI PHUC VA DICH SANG TIENG VIET ===" -ForegroundColor Cyan
} elseif ($Language -eq "vi") {
    Write-Host "=== DICH WINUTIL SANG TIENG VIET ===" -ForegroundColor Cyan
} else {
    Write-Host "=== TRANSLATE WINUTIL TO ENGLISH ===" -ForegroundColor Cyan
}
Write-Host ""

# 1. Khoi phuc ban goc neu can
if ($Restore) {
    $gitDir = Join-Path $scriptDir ".git"
    $useGit = (Test-Path $gitDir) -and (Get-Command git -ErrorAction SilentlyContinue)
    
    if ($useGit) {
        Write-Host "Dang khoi phuc ban goc tu git..." -ForegroundColor Yellow
    } else {
        Write-Host "Dang khoi phuc ban goc tu GitHub (download)..." -ForegroundColor Yellow
    }
    
    $GitHubRaw = "https://raw.githubusercontent.com/ChrisTitusTech/winutil/main"
    
    # Function to restore a file
    function Restore-File {
        param([string]$RelativePath)
        $localPath = Join-Path $scriptDir $RelativePath
        $localDir = Split-Path $localPath -Parent
        if (-not (Test-Path $localDir)) { New-Item -ItemType Directory -Path $localDir -Force | Out-Null }
        
        if ($useGit) {
            Push-Location $scriptDir
            git checkout origin/main -- $RelativePath 2>$null
            $success = ($LASTEXITCODE -eq 0)
            Pop-Location
            if ($success) { return $true }
        }
        
        # Fallback: download from GitHub
        try {
            $url = "$GitHubRaw/$RelativePath"
            Invoke-WebRequest -Uri $url -OutFile $localPath -UseBasicParsing -ErrorAction Stop
            return $true
        } catch {
            return $false
        }
    }
    
    # Restore config files
    $configFiles = @("appnavigation.json", "applications.json", "tweaks.json", "feature.json", "preset.json")
    foreach ($file in $configFiles) {
        if (Restore-File "config/$file") {
            Write-Host "  Da khoi phuc: config\$file" -ForegroundColor Green
        } else {
            Write-Host "  Bo qua: $file" -ForegroundColor Gray
        }
    }
    
    # Restore XAML
    if (Restore-File "xaml/inputXML.xaml") {
        Write-Host "  Da khoi phuc: xaml\inputXML.xaml" -ForegroundColor Green
    }
    
    # Restore main.ps1
    if (Restore-File "scripts/main.ps1") {
        Write-Host "  Da khoi phuc: scripts\main.ps1" -ForegroundColor Green
    }
    
    Write-Host ""
    
    # IMPORTANT: Copy Invoke-WPFLanguageChange.ps1 AFTER restore (git checkout xóa functions/)
    $langFuncSrc = Join-Path $scriptDir "Invoke-WPFLanguageChange.ps1"
    $langFuncDst = Join-Path $scriptDir "functions\public\Invoke-WPFLanguageChange.ps1"
    if (Test-Path $langFuncSrc) {
        $langFuncDir = Split-Path $langFuncDst -Parent
        if (-not (Test-Path $langFuncDir)) { New-Item -ItemType Directory -Path $langFuncDir -Force | Out-Null }
        Copy-Item $langFuncSrc $langFuncDst -Force
        Write-Host "  Da copy: Invoke-WPFLanguageChange.ps1 (sau restore)" -ForegroundColor Magenta
    }
    
    # For English: Don't exit yet - continue to update XAML with English selected
    # The XAML processing below will set English as the selected language
}

# For English restore: Skip translation, only update XAML ComboBox
$skipTranslation = ($Restore -and $Language -eq "en")

$translations = @{}
$sortedKeys = @()
$translatedCount = 0

if (-not $skipTranslation) {
    # 2. Load tu dien dich - chon file phu hop
    $translationsPath = if ($Language -eq "vi") {
        Join-Path $scriptDir "config\vi_translations.json"
    } else {
        Join-Path $scriptDir "config\en_translations.json"
    }

    if (-not (Test-Path $translationsPath)) {
        Write-Host "KHONG TIM THAY: $translationsPath" -ForegroundColor Red
        exit 1
    }

    # Doc file bang StreamReader voi UTF8
    $reader = New-Object System.IO.StreamReader($translationsPath, [System.Text.Encoding]::UTF8, $true)
    $dictContent = $reader.ReadToEnd()
    $reader.Close()

    $dict = $dictContent | ConvertFrom-Json
    $dict.PSObject.Properties | Where-Object { $_.Name -notlike "_*" } | ForEach-Object {
        $translations[$_.Name] = $_.Value
    }

    $sortedKeys = $translations.Keys | Sort-Object { $_.Length } -Descending

    Write-Host "Dang dich $($translations.Count) chuoi..." -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "Bo qua dich (English restore) - chi cap nhat XAML..." -ForegroundColor Yellow
    Write-Host ""
}

# 3. Ham thay the
function Apply-Translations {
    param([string]$content)
    $changed = $false
    foreach ($key in $sortedKeys) {
        if ($content.Contains($key)) {
            $content = $content.Replace($key, $translations[$key])
            $changed = $true
        }
    }
    return @{ Content = $content; Changed = $changed }
}

# 4. Ham doc file UTF8
function Read-FileUtf8 {
    param([string]$path)
    $reader = New-Object System.IO.StreamReader($path, [System.Text.Encoding]::UTF8, $true)
    $content = $reader.ReadToEnd()
    $reader.Close()
    return $content
}

# 5. Ham ghi file UTF8 (khong BOM)
function Write-FileUtf8 {
    param([string]$path, [string]$content)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $writer = New-Object System.IO.StreamWriter($path, $false, $utf8NoBom)
    $writer.Write($content)
    $writer.Close()
}

# 6. Xu ly config JSON (skip for English restore)
if (-not $skipTranslation) {
    $configPath = Join-Path $scriptDir "config"
    Get-ChildItem $configPath -Filter "*.json" | Where-Object { $_.Name -notmatch "(vi|en)_translations\.json" -and $_.Name -notlike "*(*" } | ForEach-Object {
        $content = Read-FileUtf8 $_.FullName
        $result = Apply-Translations $content
        if ($result.Changed) {
            Write-FileUtf8 $_.FullName $result.Content
            Write-Host "  Da dich: config\$($_.Name)" -ForegroundColor Green
            $script:translatedCount++
        }
    }
}

# 7. Xu ly XAML
$xamlPath = Join-Path $scriptDir "xaml\inputXML.xaml"
if (Test-Path $xamlPath) {
    $content = Read-FileUtf8 $xamlPath
    
    # Protect Language ComboBox from translation (keep "English" and "Vietnamese" as-is)
    $langComboPattern = '(<ComboBox\s+Name="LanguageComboBox"[^>]*>.*?</ComboBox>)'
    $langComboMatch = [regex]::Match($content, $langComboPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $langComboOriginal = if ($langComboMatch.Success) { $langComboMatch.Value } else { $null }
    
    # Replace with placeholder
    if ($langComboOriginal) {
        $content = $content -replace [regex]::Escape($langComboOriginal), '<!--LANGCOMBO_PLACEHOLDER-->'
    }
    
    # Apply translations to rest of XAML
    $result = Apply-Translations $content
    $content = $result.Content
    
    # Restore Language ComboBox (untranslated)
    if ($langComboOriginal) {
        $content = $content -replace '<!--LANGCOMBO_PLACEHOLDER-->', $langComboOriginal
    }

    # Inject Language ComboBox if not present (for BOTH vi and en builds)
    if ($content -notmatch 'LanguageComboBox') {
        $selectedVi = if ($Language -eq "vi") { 'IsSelected="True"' } else { '' }
        $selectedEn = if ($Language -eq "en") { 'IsSelected="True"' } else { '' }
        $comboBoxXaml = @"
                    <!-- Language Selector -->
                    <ComboBox Name="LanguageComboBox"
                        Width="105" Height="28"
                        Margin="0,0,8,0"
                        VerticalAlignment="Center"
                        Background="{DynamicResource MainBackgroundColor}"
                        Foreground="{DynamicResource MainForegroundColor}"
                        BorderBrush="{DynamicResource MainForegroundColor}"
                        ToolTip="Select Language">
                        <ComboBoxItem Content="Vietnamese" $selectedVi Tag="vi"/>
                        <ComboBoxItem Content="English" $selectedEn Tag="en"/>
                    </ComboBox>
                    <Button Name="ThemeButton"
"@
        $content = $content -replace '(<StackPanel[^>]*Orientation="Horizontal"[^>]*>\s*)<Button Name="ThemeButton"', "`$1$comboBoxXaml"
        Write-Host "  Da them: Language ComboBox vao XAML" -ForegroundColor Magenta
        $result.Changed = $true
    } else {
        # Update IsSelected state for existing ComboBox based on language
        if ($Language -eq "en") {
            # English: Remove IsSelected from Vietnamese, add to English
            $content = $content -replace '(<ComboBoxItem\s+Content="Vietnamese"\s*)IsSelected="True"\s*', '$1'
            if ($content -notmatch '<ComboBoxItem\s+Content="English"[^>]*IsSelected="True"') {
                $content = $content -replace '(<ComboBoxItem\s+Content="English")', '$1 IsSelected="True"'
            }
            Write-Host "  Da cap nhat: Language ComboBox -> English selected" -ForegroundColor Magenta
            $result.Changed = $true
        } else {
            # Vietnamese: Remove IsSelected from English, add to Vietnamese  
            $content = $content -replace '(<ComboBoxItem\s+Content="English"\s*)IsSelected="True"\s*', '$1'
            if ($content -notmatch '<ComboBoxItem\s+Content="Vietnamese"[^>]*IsSelected="True"') {
                $content = $content -replace '(<ComboBoxItem\s+Content="Vietnamese")', '$1 IsSelected="True"'
            }
            Write-Host "  Da cap nhat: Language ComboBox -> Vietnamese selected" -ForegroundColor Magenta
            $result.Changed = $true
        }
    }

    if ($result.Changed) {
        Write-FileUtf8 $xamlPath $content
        Write-Host "  Da dich: xaml\inputXML.xaml" -ForegroundColor Green
        $script:translatedCount++
    }
}

# 7b. Patch main.ps1 with Language Handler (for BOTH vi and en builds)
$mainPath = Join-Path $scriptDir "scripts\main.ps1"
if (Test-Path $mainPath) {
    $mainContent = Read-FileUtf8 $mainPath

    # Inject Language ComboBox handler if not present
    if ($mainContent -notmatch 'LanguageComboBox') {
        $handlerCode = @'
# Language Selector Handler
$sync["LanguageComboBox"].Add_SelectionChanged({
    $selectedItem = $sync.LanguageComboBox.SelectedItem
    if ($selectedItem) {
        # Determine language from Content (more reliable than Tag in WPF)
        $content = "$($selectedItem.Content)"
        $lang = if ($content -eq "English") { "en" } else { "vi" }
        Write-Debug "Language changed to: $lang (content: $content)"
        if ($sync.LanguageInitialized) {
            Invoke-WPFLanguageChange -Language $lang
        }
    }
})

$sync["SettingsButton"].Add_Click({
'@
        $mainContent = $mainContent -replace '\$sync\["SettingsButton"\]\.Add_Click\(\{', $handlerCode

        # Add initialization flag before ShowDialog
        $initFlag = @'
# Mark language selector as initialized (prevent trigger on first load)
$sync.LanguageInitialized = $true

$sync["Form"].ShowDialog() | out-null
'@
        $mainContent = $mainContent -replace '\$sync\["Form"\]\.ShowDialog\(\)\s*\|\s*out-null', $initFlag

        Write-FileUtf8 $mainPath $mainContent
        Write-Host "  Da them: Language Handler vao main.ps1" -ForegroundColor Magenta
    }
}

# 7c. Ensure Language Change function exists (already copied after restore, just verify)
$langFuncDst = Join-Path $scriptDir "functions\public\Invoke-WPFLanguageChange.ps1"
if (-not (Test-Path $langFuncDst)) {
    $langFuncSrc = Join-Path $scriptDir "Invoke-WPFLanguageChange.ps1"
    if (Test-Path $langFuncSrc) {
        $langFuncDir = Split-Path $langFuncDst -Parent
        if (-not (Test-Path $langFuncDir)) { New-Item -ItemType Directory -Path $langFuncDir -Force | Out-Null }
        Copy-Item $langFuncSrc $langFuncDst -Force
        Write-Host "  Da copy: Invoke-WPFLanguageChange.ps1 (backup)" -ForegroundColor Yellow
    }
}

# 7d. Fix Search - Use tab index instead of tab name (works with translated tabs)
# Patch start.ps1 - add currentTabIndex initialization
$startPath = Join-Path $scriptDir "scripts\start.ps1"
if (Test-Path $startPath) {
    $startContent = Read-FileUtf8 $startPath
    if ($startContent -notmatch 'currentTabIndex') {
        $startContent = $startContent -replace '(\$sync\.currentTab\s*=\s*"Install")', "`$1`n`$sync.currentTabIndex = 0"
        Write-FileUtf8 $startPath $startContent
        Write-Host "  Da them: currentTabIndex vao start.ps1" -ForegroundColor Magenta
    }
}

# Patch main.ps1 - use currentTabIndex in search timer
if (Test-Path $mainPath) {
    $mainContent = Read-FileUtf8 $mainPath
    if ($mainContent -notmatch 'currentTabIndex') {
        # Replace the search switch to use tab index
        $mainContent = $mainContent -replace 'switch \(\$sync\.currentTab\) \{\s*"Install"', 'switch ($sync.currentTabIndex) { 0'
        $mainContent = $mainContent -replace '"Tweaks" \{', '1 {'
        Write-FileUtf8 $mainPath $mainContent
        Write-Host "  Da sua: Search dung tab index trong main.ps1" -ForegroundColor Magenta
    }
}

# Patch Invoke-WPFTab.ps1 - set currentTabIndex when switching tabs
$tabPath = Join-Path $scriptDir "functions\public\Invoke-WPFTab.ps1"
if (Test-Path $tabPath) {
    $tabContent = Read-FileUtf8 $tabPath
    if ($tabContent -notmatch 'currentTabIndex') {
        # Add currentTabIndex assignment before currentTab assignment
        $tabContent = $tabContent -replace '(\$sync\.currentTab\s*=\s*\$sync\.\$tabNav\.Items\[\$tabNumber\]\.Header)', "`$sync.currentTabIndex = `$tabNumber`n    `$1"
        # Fix the filter reset to use tab index
        $tabContent = $tabContent -replace 'if \(\$sync\.currentTab -eq "Install"\)', 'if ($tabNumber -eq 0)'
        $tabContent = $tabContent -replace 'elseif \(\$sync\.currentTab -eq "Tweaks"\)', 'elseif ($tabNumber -eq 1)'
        Write-FileUtf8 $tabPath $tabContent
        Write-Host "  Da sua: Tab index trong Invoke-WPFTab.ps1" -ForegroundColor Magenta
    }
}

# 8. Xu ly functions PowerShell (skip for English restore)
if (-not $skipTranslation) {
    $functionsPath = Join-Path $scriptDir "functions"
    # Exclude files that contain code logic (not just UI text)
    $excludeFiles = @("Invoke-WPFTab.ps1")
    Get-ChildItem $functionsPath -Filter "*.ps1" -Recurse | ForEach-Object {
        if ($excludeFiles -contains $_.Name) {
            Write-Host "  Bo qua: $($_.Name) (file logic)" -ForegroundColor Gray
            return
        }
        $content = Read-FileUtf8 $_.FullName
        $result = Apply-Translations $content
        if ($result.Changed) {
            Write-FileUtf8 $_.FullName $result.Content
            $relativePath = $_.FullName.Replace($scriptDir, '').TrimStart('\')
            Write-Host "  Da dich: $relativePath" -ForegroundColor Green
            $script:translatedCount++
        }
    }
}

Write-Host ""
if ($skipTranslation) {
    Write-Host "HOAN TAT! Da khoi phuc ban goc tieng Anh va cap nhat XAML." -ForegroundColor Green
} elseif ($translatedCount -gt 0) {
    Write-Host "HOAN TAT! Da dich $translatedCount file." -ForegroundColor Green
} else {
    Write-Host "Khong co file nao can dich (co the da dich roi)." -ForegroundColor Yellow
}
Write-Host "Chay: powershell -ExecutionPolicy Bypass -File .\Compile.ps1" -ForegroundColor White
Write-Host ""
