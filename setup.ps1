# ============================================
# Fishstrap Auto Setup Script — Bot Optimized
# รันในฐานะ Administrator เท่านั้น
# ============================================

$ErrorActionPreference = "SilentlyContinue"

# --- สี + Header ---
function Write-Header {
    Clear-Host
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "   Fishstrap Auto Setup — Bot Optimized    " -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}

# --- ตรวจสอบ Admin ---
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

# --- หา Path ของ Fishstrap ---
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

# --- ดาวน์โหลดและติดตั้ง Fishstrap ---
function Install-Fishstrap {
    Write-Host ""
    Write-Host "[STEP 1] ติดตั้ง Fishstrap..." -ForegroundColor Yellow

    $installerUrl = "https://github.com/midaskira/Fishstrap/releases/latest/download/Fishstrap.exe"
    $installerPath = "$env:TEMP\FishstrapSetup.exe"

    try {
        Write-Host "  กำลังดาวน์โหลด Fishstrap..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
        Write-Host "  ดาวน์โหลดสำเร็จ กำลังติดตั้ง..." -ForegroundColor Cyan
        Start-Process -FilePath $installerPath -Wait
        Write-Host "  [OK] ติดตั้ง Fishstrap เสร็จสิ้น" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] ดาวน์โหลดไม่สำเร็จ: $_" -ForegroundColor Red
        Write-Host "  กรุณาดาวน์โหลดและติดตั้ง Fishstrap เองที่: https://github.com/midaskira/Fishstrap/releases" -ForegroundColor Yellow
    }
}

# --- เขียน FFlag ---
function Set-FFlags {
    param($fishstrapPath)

    Write-Host ""
    Write-Host "[STEP 2] ตั้งค่า FFlags..." -ForegroundColor Yellow

    $fflagPath = "$fishstrapPath\ClientAppSettings.json"

    $fflags = @{
        # Texture Quality
        "DFFlagTextureQualityOverrideEnabled" = "True"
        "DFIntTextureQualityOverride"         = "0"

        # MSAA ปิด
        "FIntDebugForceMSAASamples"           = "-1"

        # Grass ปิด
        "FIntFRMMinGrassDistance"             = "0"
        "FIntFRMMaxGrassDistance"             = "0"
        "FIntGrassMovementReducedMotionFactor" = "0"

        # LOD ต่ำสุด
        "DFIntCSGLevelOfDetailSwitchingDistance"    = "0"
        "DFIntCSGLevelOfDetailSwitchingDistanceL12" = "0"
        "DFIntCSGLevelOfDetailSwitchingDistanceL23" = "0"
        "DFIntCSGLevelOfDetailSwitchingDistanceL34" = "0"

        # Sky เทา (ประหยัด render)
        "FFlagDebugSkyGray"                   = "True"

        # Graphics D3D11
        "FFlagDebugGraphicsPreferD3D11"       = "True"

        # Fullscreen
        "FFlagHandleAltEnterFullscreenManually" = "False"
    }

    $fflags | ConvertTo-Json -Depth 2 | Set-Content -Path $fflagPath -Encoding UTF8
    Write-Host "  [OK] FFlags บันทึกที่: $fflagPath" -ForegroundColor Green
}

# --- ตั้งค่า Fishstrap Config ---
function Set-FishstrapConfig {
    param($fishstrapPath)

    Write-Host ""
    Write-Host "[STEP 3] ตั้งค่า Fishstrap Config..." -ForegroundColor Yellow

    $configPath = "$fishstrapPath\Config.json"

    $config = @{
        "MultiInstanceEnabled"     = $true
        "RenderingMode"            = "Direct3D11"
        "DiscordRichPresence"      = $false
        "CheckForUpdates"          = $true
        "Theme"                    = "Dark"
    }

    $config | ConvertTo-Json -Depth 2 | Set-Content -Path $configPath -Encoding UTF8
    Write-Host "  [OK] Config บันทึกที่: $configPath" -ForegroundColor Green
}

# --- ตั้งค่า Process Priority อัตโนมัติ ---
function Set-RobloxPriority {
    Write-Host ""
    Write-Host "[STEP 4] สร้าง Priority Script..." -ForegroundColor Yellow

    $priorityScript = @'
# Roblox Process Optimizer — Auto Priority & Affinity
$priority = "BelowNormal"
$coresPerInstance = 1
$totalCores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum

Write-Host "Total Cores: $totalCores" -ForegroundColor Cyan

function Set-RobloxOptimization {
    $processes = Get-Process -Name "RobloxPlayerBeta" -ErrorAction SilentlyContinue
    if ($processes.Count -eq 0) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] รอ Roblox..." -ForegroundColor Yellow
        return
    }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] พบ $($processes.Count) instance" -ForegroundColor Green
    $coreIndex = 0
    foreach ($proc in $processes) {
        try {
            $proc.PriorityClass = $priority
            $mask = 0
            for ($i = 0; $i -lt $coresPerInstance; $i++) {
                $core = ($coreIndex + $i) % $totalCores
                $mask = $mask -bor (1 -shl $core)
            }
            $proc.ProcessorAffinity = $mask
            $coreIndex = ($coreIndex + $coresPerInstance) % $totalCores
            Write-Host "  PID $($proc.Id) → Mask: $mask" -ForegroundColor Green
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
    Write-Host "  รัน script นี้ทุกครั้งที่เปิด bot" -ForegroundColor Yellow
}

# --- ปิด Services ที่ไม่จำเป็น ---
function Disable-UnnecessaryServices {
    Write-Host ""
    Write-Host "[STEP 5] ปิด Services ที่ไม่จำเป็น..." -ForegroundColor Yellow

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
    Set-FFlags -fishstrapPath $fishstrapPath
    Set-FishstrapConfig -fishstrapPath $fishstrapPath
} else {
    Write-Host "[WARN] ไม่พบ Fishstrap Path — ข้ามขั้นตอน FFlag และ Config" -ForegroundColor Red
}

Set-RobloxPriority
Disable-UnnecessaryServices

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   ✅ Setup เสร็จสิ้น!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "สิ่งที่ทำเสร็จแล้ว:" -ForegroundColor White
Write-Host "  ✅ FFlags (Allowlist) ตั้งค่าแล้ว" -ForegroundColor Green
Write-Host "  ✅ Fishstrap Config ตั้งค่าแล้ว" -ForegroundColor Green
Write-Host "  ✅ RobloxOptimizer.ps1 อยู่ที่ Desktop" -ForegroundColor Green
Write-Host "  ✅ Services ที่ไม่จำเป็นถูกปิดแล้ว" -ForegroundColor Green
Write-Host ""
Write-Host "สิ่งที่ต้องทำเพิ่ม:" -ForegroundColor Yellow
Write-Host "  → ติดตั้ง ISLC จาก wagnardsoft.com" -ForegroundColor Yellow
Write-Host "  → รัน RobloxOptimizer.ps1 ทุกครั้งที่เปิด bot" -ForegroundColor Yellow
Write-Host ""
pause
