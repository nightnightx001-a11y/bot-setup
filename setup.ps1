# ============================================
# Fishstrap Auto Setup Script — Bot Optimized
# รันในฐานะ Administrator เท่านั้น
# ============================================

$ErrorActionPreference = "SilentlyContinue"

$GITHUB_USERNAME = "nightnightx001-a11y"
$GITHUB_REPO     = "bot-setup"
$RAW_BASE        = "https://raw.githubusercontent.com/$GITHUB_USERNAME/$GITHUB_REPO/main"

function Write-Header {
    Clear-Host
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "   Fishstrap Auto Setup — Bot Optimized    " -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Check-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "[ERROR] กรุณารัน script นี้ในฐานะ Administrator" -ForegroundColor Red
        Write-Host "คลิกขวาที่ PowerShell → Run as Administrator" -ForegroundColor Yellow
        pause
        exit
    }
    Write-Host "[OK] กำลังรันในฐานะ Administrator" -ForegroundColor Green
}

function Get-FishstrapPath {
    $commonPaths = @(
        "$env:LOCALAPPDATA\Fishstrap",
        "$env:APPDATA\Fishstrap",
        "C:\Fishstrap"
    )
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    return $null
}

# ============ STEP 1 — ติดตั้ง Fishstrap ============
function Install-Fishstrap {
    Write-Host ""
    Write-Host "[STEP 1] ติดตั้ง Fishstrap..." -ForegroundColor Yellow

    $installerUrl  = "https://github.com/midaskira/Fishstrap/releases/latest/download/Fishstrap.exe"
    $installerPath = "$env:TEMP\FishstrapSetup.exe"

    try {
        Write-Host "  กำลังดาวน์โหลด Fishstrap..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
        Write-Host "  ดาวน์โหลดสำเร็จ กำลังติดตั้ง..." -ForegroundColor Cyan
        Start-Process -FilePath $installerPath -Wait
        Write-Host "  [OK] ติดตั้ง Fishstrap เสร็จสิ้น" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] ดาวน์โหลดไม่สำเร็จ: $_" -ForegroundColor Red
        Write-Host "  กรุณาดาวน์โหลดเองที่: https://github.com/midaskira/Fishstrap/releases" -ForegroundColor Yellow
    }
}

# ============ STEP 2 — FFlags ============
function Set-FFlags {
    param($fishstrapPath)

    Write-Host ""
    Write-Host "[STEP 2] ตั้งค่า FFlags..." -ForegroundColor Yellow

    $fflagPath = "$fishstrapPath\ClientAppSettings.json"

    $fflags = [ordered]@{
        "DFFlagTextureQualityOverrideEnabled"       = "True"
        "DFIntTextureQualityOverride"               = "0"
        "FIntDebugForceMSAASamples"                 = "-1"
        "FIntFRMMinGrassDistance"                   = "0"
        "FIntFRMMaxGrassDistance"                   = "0"
        "FIntGrassMovementReducedMotionFactor"      = "0"
        "DFIntCSGLevelOfDetailSwitchingDistance"    = "0"
        "DFIntCSGLevelOfDetailSwitchingDistanceL12" = "0"
        "DFIntCSGLevelOfDetailSwitchingDistanceL23" = "0"
        "DFIntCSGLevelOfDetailSwitchingDistanceL34" = "0"
        "FFlagDebugSkyGray"                         = "True"
        "FFlagDebugGraphicsPreferD3D11"             = "True"
        "FFlagHandleAltEnterFullscreenManually"     = "False"
    }

    $fflags | ConvertTo-Json -Depth 2 | Set-Content -Path $fflagPath -Encoding UTF8
    Write-Host "  [OK] FFlags บันทึกที่: $fflagPath" -ForegroundColor Green
}

# ============ STEP 3 — Settings.json ============
function Set-FishstrapConfig {
    param($fishstrapPath)

    Write-Host ""
    Write-Host "[STEP 3] ตั้งค่า Fishstrap Settings..." -ForegroundColor Yellow

    $configPath = "$fishstrapPath\Settings.json"

    $config = [ordered]@{
        "AllowCookieAccess"                    = $false
        "BootstrapperStyle"                    = 8
        "BootstrapperIcon"                     = 1
        "BootstrapperTitle"                    = "Fishstrap"
        "BootstrapperIconCustomLocation"       = ""
        "Theme"                                = 2
        "ForceLocalData"                       = $false
        "CheckForUpdates"                      = $true
        "MultiInstanceLaunching"               = $true
        "ConfirmLaunches"                      = $false
        "Locale"                               = "nil"
        "ForceRobloxLanguage"                  = $false
        "UseFastFlagManager"                   = $true
        "WPFSoftwareRender"                    = $false
        "EnableAnalytics"                      = $false
        "UpdateRoblox"                         = $true
        "StaticDirectory"                      = $false
        "Channel"                              = "production"
        "ChannelChangeMode"                    = 2
        "ChannelHash"                          = ""
        "DownloadingStringFormat"              = "Downloading {0} - {1}MB / {2}MB"
        "SelectedCustomTheme"                  = $null
        "BackgroundUpdatesEnabled"             = $false
        "DebugDisableVersionPackageCleanup"    = $false
        "EnableBetterMatchmaking"              = $true
        "EnableBetterMatchmakingRandomization" = $false
        "WebEnvironment"                       = "Production"
        "CleanerOptions"                       = 1
        "CleanerDirectories"                   = @("RobloxCache", "RobloxLogs", "FishstrapLogs")
        "EnableActivityTracking"               = $false
        "UseDiscordRichPresence"               = $false
        "HideRPCButtons"                       = $true
        "ShowAccountOnRichPresence"            = $false
        "ShowServerDetails"                    = $false
        "CustomIntegrations"                   = @()
        "UseDisableAppPatch"                   = $false
    }

    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
    Write-Host "  [OK] Settings บันทึกที่: $configPath" -ForegroundColor Green
}

# ============ STEP 4 — GlobalBasicSettings ============
function Set-RobloxGameSettings {
    Write-Host ""
    Write-Host "[STEP 4] ตั้งค่า Roblox Game Settings..." -ForegroundColor Yellow

    $targetPath = "$env:LOCALAPPDATA\Roblox\GlobalBasicSettings_13.xml"
    $targetDir  = "$env:LOCALAPPDATA\Roblox"
    $xmlUrl     = "$RAW_BASE/GlobalBasicSettings_13.xml"

    try {
        # สร้างโฟลเดอร์ถ้าไม่มี
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        # Force ownership และ permission ด้วย takeown + icacls
        Write-Host "  กำลัง unlock permission..." -ForegroundColor Cyan
        & takeown /f $targetDir /r /d y 2>&1 | Out-Null
        & icacls $targetDir /grant "Administrator:(OI)(CI)F" /t /c 2>&1 | Out-Null

        # ดาวน์โหลดและวางไฟล์
        Invoke-WebRequest -Uri $xmlUrl -OutFile $targetPath -UseBasicParsing
        Write-Host "  [OK] Game Settings บันทึกที่: $targetPath" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] ไม่สำเร็จ: $_" -ForegroundColor Red
    }
}

# ============ STEP 5 — Priority Script ============
function Set-RobloxPriority {
    Write-Host ""
    Write-Host "[STEP 5] สร้าง Priority Script..." -ForegroundColor Yellow

    $priorityScript = @'
# ============================================
# Roblox Optimizer — Priority BelowNormal
# ไม่ Lock Affinity — ให้ Windows กระจาย Core เอง
# ============================================

$priority = "BelowNormal"

$totalCores = (Get-CimInstance Win32_Processor |
    Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
$cpuCount = (Get-CimInstance Win32_Processor).Count

Write-Host "=== Roblox Optimizer ===" -ForegroundColor Cyan
Write-Host "CPU: $cpuCount หัว | Total Cores: $totalCores" -ForegroundColor Cyan
Write-Host "Mode: Priority BelowNormal (ไม่ Lock Affinity)" -ForegroundColor Cyan
Write-Host ""

function Set-RobloxOptimization {
    $processes = Get-Process -Name "RobloxPlayerBeta" -ErrorAction SilentlyContinue

    if ($processes.Count -eq 0) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] รอ Roblox..." -ForegroundColor Yellow
        return
    }

    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] พบ $($processes.Count) instance" -ForegroundColor Green

    foreach ($proc in $processes) {
        try {
            $proc.PriorityClass = $priority
            Write-Host "  PID $($proc.Id) → BelowNormal" -ForegroundColor Green
        } catch {
            Write-Host "  Error PID $($proc.Id)" -ForegroundColor Red
        }
    }
}

while ($true) {
    Set-RobloxOptimization
    Start-Sleep -Seconds 30
}
'@

    $scriptPath = "$env:USERPROFILE\Desktop\RobloxOptimizer.ps1"
    $priorityScript | Set-Content -Path $scriptPath -Encoding UTF8
    Write-Host "  [OK] บันทึก RobloxOptimizer.ps1 ไว้ที่ Desktop" -ForegroundColor Green
}

# ============ STEP 6 — Auto Start ============
function Register-AutoStart {
    Write-Host ""
    Write-Host "[STEP 6] ตั้งค่า Auto Start เมื่อ Login..." -ForegroundColor Yellow

    $taskName   = "RobloxOptimizer"
    $scriptPath = "$env:USERPROFILE\Desktop\RobloxOptimizer.ps1"

    $action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

    $trigger = New-ScheduledTaskTrigger -AtLogOn

    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -RunOnlyIfNetworkAvailable:$false

    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -RunLevel Highest `
        -Force | Out-Null

    Write-Host "  [OK] RobloxOptimizer รันอัตโนมัติทุกครั้งที่ Login" -ForegroundColor Green
}

# ============ STEP 7 — ปิด Services ============
function Disable-UnnecessaryServices {
    Write-Host ""
    Write-Host "[STEP 7] ปิด Services ที่ไม่จำเป็น..." -ForegroundColor Yellow

    $services = @("WSearch", "Spooler", "SysMain")
    foreach ($svc in $services) {
        try {
            Stop-Service -Name $svc -Force
            Set-Service -Name $svc -StartupType Disabled
            Write-Host "  [OK] ปิด $svc" -ForegroundColor Green
        } catch {
            Write-Host "  [SKIP] $svc ไม่พบหรือปิดอยู่แล้ว" -ForegroundColor Gray
        }
    }
}

# ============ MAIN ============
Write-Header
Check-Admin

$fishstrapPath = Get-FishstrapPath

if ($null -eq $fishstrapPath) {
    Write-Host "[INFO] ไม่พบ Fishstrap — จะติดตั้งใหม่" -ForegroundColor Yellow
    Install-Fishstrap
    Start-Sleep -Seconds 3
    $fishstrapPath = Get-FishstrapPath
} else {
    Write-Host "[INFO] พบ Fishstrap ที่: $fishstrapPath" -ForegroundColor Green
    Write-Host "[INFO] จะ override ค่าทั้งหมด" -ForegroundColor Yellow
}

if ($null -ne $fishstrapPath) {
    Set-FFlags          -fishstrapPath $fishstrapPath
    Set-FishstrapConfig -fishstrapPath $fishstrapPath
} else {
    Write-Host "[WARN] ไม่พบ Fishstrap Path — ข้ามขั้นตอน FFlag และ Config" -ForegroundColor Red
}

Set-RobloxGameSettings
Set-RobloxPriority
Register-AutoStart
Disable-UnnecessaryServices

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "         ✅ Setup เสร็จสิ้น!               " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "สิ่งที่ทำเสร็จแล้ว:" -ForegroundColor White
Write-Host "  ✅ FFlags (Allowlist) ตั้งค่าแล้ว"                   -ForegroundColor Green
Write-Host "  ✅ Settings.json เขียนทับด้วย config ที่ตั้งมาแล้ว"  -ForegroundColor Green
Write-Host "  ✅ GlobalBasicSettings_13.xml วางถูก path แล้ว"      -ForegroundColor Green
Write-Host "  ✅ Priority BelowNormal (ไม่ Lock Affinity)"          -ForegroundColor Green
Write-Host "  ✅ RobloxOptimizer รันอัตโนมัติตอน Login"            -ForegroundColor Green
Write-Host "  ✅ Services ที่ไม่จำเป็นถูกปิดแล้ว"                 -ForegroundColor Green
Write-Host ""
Write-Host "สิ่งที่ต้องทำเพิ่ม:" -ForegroundColor Yellow
Write-Host "  → ติดตั้ง ISLC จาก wagnardsoft.com"                  -ForegroundColor Yellow
Write-Host ""
pause
