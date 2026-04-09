# ==========================================
# Helper Function: Env Var Setup / 辅助函数：提示如何设置环境变量
# ==========================================
function Show-EnvHelp {
    param(
        [string]$EnvName,
        [string]$ServiceName
    )
    Write-Host "❌ Error / 错误：Environment variable not set / 未设置环境变量 $EnvName" -ForegroundColor Red
    Write-Host "👉 Please follow these steps to configure the Token/API Key for $ServiceName / 请按以下步骤配置 $ServiceName 的 Token/API Key：" -ForegroundColor Cyan
    Write-Host "   1. Press [Win + R], type 'sysdm.cpl' and press Enter. / 按下 [Win + R] 键，输入 sysdm.cpl 并按回车打开系统属性。"
    Write-Host "   2. Go to 'Advanced' tab, click 'Environment Variables'. / 切换到“高级”选项卡，点击底部的“环境变量”按钮。"
    Write-Host "   3. Click 'New' under 'User variables'. / 在上半部分的“用户变量”中点击“新建”。"
    Write-Host "   4. Variable name / 变量名填写：$EnvName"
    Write-Host "   5. Variable value / 变量值填写：Your real Token/API Key / 你的真实 Token / API Key"
    Write-Host "   6. Click 'OK' to save. / 点击三次“确定”保存所有窗口。"
    Write-Host "   7. ⚠️ IMPORTANT: Restart all PowerShell windows to apply changes. / 重要：关闭当前所有的 PowerShell 窗口并重新打开，以使环境变量生效。" -ForegroundColor Yellow
}

# ==========================================
# Step 1: Get Location / 第一步：获取地理位置
# ==========================================
Write-Host "1. Locating... / 正在定位..." -ForegroundColor Cyan

if (-not $env:DASHSCOPE_API_KEY) {
    Show-EnvHelp -EnvName "DASHSCOPE_API_KEY" -ServiceName "AliCloud DashScope (阿里云灵积)"
    exit
}

# Fetch location via ipinfo.io / 使用 ipinfo.io 接口获取详细位置
try {
    $url = "https://ipinfo.io/json"
    $locationData = Invoke-RestMethod -Uri $url -ErrorAction Stop
    
    $loc = $locationData.loc
    $city = $locationData.city

    # Fallback to ip-api if main API fails / 如果主接口未返回经纬度，调用兜底服务
    if (-not $loc) {
        Write-Host "ℹ️ Main API failed, using backup location service... / 主接口未返回坐标，正在通过备用接口获取天气定位..." -ForegroundColor Gray
        $backupGeo = Invoke-RestMethod -Uri "http://ip-api.com/json/" -ErrorAction SilentlyContinue
        if ($backupGeo -and $backupGeo.status -eq "success") {
            $loc = "$($backupGeo.lat),$($backupGeo.lon)"
            if (-not $city) { $city = $backupGeo.city }
        }
    }

    Write-Host "📍 City / 定位城市：$city (Coords / 坐标：$loc)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ Location failed / 定位失败：$($_.Exception.Message)" -ForegroundColor Red
    exit
}

# ==========================================
# Step 2: Get Weather / 第二步：调用 Open-Meteo 获取天气详情
# ==========================================
Write-Host "2. Fetching weather data... / 正在获取详细天气数据..." -ForegroundColor Cyan

if (-not $loc -or $loc -eq ",") {
    Write-Host "❌ Invalid coordinates, exiting. / 无法获取有效的经纬度坐标，天气获取失败，脚本退出。" -ForegroundColor Red
    exit
}

$lat, $lon = $loc -split ','

try {
    $url = "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code&timezone=auto&temperature_unit=celsius"
    $weatherResponse = Invoke-RestMethod -Uri $url -ErrorAction Stop

    $current = $weatherResponse.current
    $temp = $current.temperature_2m
    $weatherCode = [int]$current.weather_code

    $weatherMap = @{
        0 = "Clear sky"; 1 = "Mainly clear"; 2 = "Partly cloudy"; 3 = "Overcast"
        45 = "Fog"; 48 = "Depositing rime fog"
        51 = "Light drizzle"; 53 = "Moderate drizzle"; 55 = "Dense drizzle"
        61 = "Light rain"; 63 = "Moderate rain"; 65 = "Heavy rain"
        71 = "Light snow"; 73 = "Moderate snow"; 75 = "Heavy snow"
        80 = "Rain showers"; 81 = "Moderate rain showers"; 82 = "Violent rain showers"
        95 = "Thunderstorm"; 96 = "Thunderstorm with light hail"; 99 = "Thunderstorm with heavy hail"
    }

    $weatherDesc = if ($weatherMap.ContainsKey($weatherCode)) { $weatherMap[$weatherCode] } else { "Cloudy" }

    Write-Host "🌤️ Weather / 天气状况：$weatherDesc" -ForegroundColor Yellow
    Write-Host "🌡️ Temp / 实时气温：${temp}°C" -ForegroundColor Yellow
} catch {
    Write-Host "❌ Weather fetch failed / 获取天气失败：$($_.Exception.Message)" -ForegroundColor Red
    exit
}

# ==========================================
# Step 3: AI Wallpaper Generation / 第三步：生成高颜值人物壁纸
# ==========================================
Write-Host "3. Requesting AI generation... / 正在请求 AI 生成壁纸..." -ForegroundColor Cyan

# English prompt for better international compatibility / 改用英文提示词以利于海外用户理解和修改
$imagePromptText = "Create an 8k cinematic portrait wallpaper inspired by $weatherDesc weather. A beautiful East Asian teenage girl faces the camera with a sweet smile, delicate facial features, big eyes, fair skin, elegant natural makeup, and neatly tied-up hair in a youthful ponytail or twin tails, with no loose long hair covering the shoulders. Half-body close-up, wearing a stylish outfit that naturally matches the atmosphere. The background should be aesthetic natural or urban scenery with lighting, colors, and mood consistent with $weatherDesc conditions, with depth of field and a clean premium composition. Absolutely no words, letters, numbers, subtitles, captions, logos, signs, watermarks, UI elements, or any readable text anywhere in the image."

$imageDataJson = @{
    model = "z-image-turbo"
    input = @{
        messages = @(@{
            role = "user"
            content = @(@{ text = $imagePromptText })
        })
    }
    parameters = @{
        negative_prompt = "text, letters, words, numbers, digits, subtitles, captions, signatures, signage, logos, watermark, UI, interface, overlays, labels, temperature readout, date stamp, Chinese characters, English letters, low resolution, blurry, deformed, ugly, oversaturated"
        size = "1920*1080"
    }
} | ConvertTo-Json -Depth 10

try {
    $imageResponse = Invoke-RestMethod -Uri 'https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation' `
                          -Method Post `
                          -Headers @{
                              'Content-Type' = 'application/json'
                              'Authorization' = "Bearer $($env:DASHSCOPE_API_KEY)"
                          } `
                          -Body $imageDataJson -ErrorAction Stop

    $imageUrl = $imageResponse.output.choices[0].message.content[0].image
    Write-Host "✅ Generation successful! / 生成成功！" -ForegroundColor Green
} catch {
    Write-Host "❌ Image generation failed / 图片生成失败：$($_.Exception.Message)" -ForegroundColor Red
    exit
}

# ==========================================
# Step 4: Set Wallpaper / 第四步：下载并设置桌面壁纸
# ==========================================
Write-Host "4. Updating desktop wallpaper... / 正在更新桌面壁纸..." -ForegroundColor Cyan

try {
    $wallpaperPath = Join-Path $env:TEMP "WeatherWallpaper.png"
    Invoke-WebRequest -Uri $imageUrl -OutFile $wallpaperPath -ErrorAction Stop

    $csharpCode = @"
    using System;
    using System.Runtime.InteropServices;
    public class WallpaperSetter {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
        public static void SetWallpaper(string path) {
            SystemParametersInfo(20, 0, path, 0x01 | 0x02);
        }
    }
"@
    if (-not ([System.Management.Automation.PSTypeName]'WallpaperSetter').Type) {
        Add-Type -TypeDefinition $csharpCode
    }
    [WallpaperSetter]::SetWallpaper($wallpaperPath)
    Write-Host "🎉 Desktop wallpaper updated! / 桌面壁纸已更新！" -ForegroundColor Green
} catch {
    Write-Host "❌ Set wallpaper failed / 设置壁纸失败：$($_.Exception.Message)" -ForegroundColor Red
}

# ==========================================
# Step 5: Autostart Setup / 第五步：设置开机启动提示
# ==========================================
Write-Host ""
$taskName = "WeatherAIWallpaperOnLogon"
$startupFolder = [Environment]::GetFolderPath('Startup')
$legacyLauncherPath = Join-Path $startupFolder "WeatherWallpaperStartup.cmd"
$legacyShortcutPath = Join-Path $startupFolder "WeatherWallpaper.lnk"
$scriptPath = $MyInvocation.MyCommand.Path

function Remove-LegacyWindowsAutostartArtifacts {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    foreach ($path in $Paths) {
        if ($path -and (Test-Path $path)) {
            Remove-Item -LiteralPath $path -Force
        }
    }
}

function Test-WindowsStartupTask {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName
    )

    if (Get-Command -Name Get-ScheduledTask -ErrorAction SilentlyContinue) {
        return ($null -ne (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue))
    }

    $null = & schtasks.exe /Query /TN $TaskName 2>&1
    return ($LASTEXITCODE -eq 0)
}

function Set-WindowsStartupTask {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        [Parameter(Mandatory = $true)]
        [string[]]$LegacyPaths
    )

    if (Get-Command -Name Register-ScheduledTask -ErrorAction SilentlyContinue) {
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $currentUser
        $principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Limited
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

        Register-ScheduledTask -TaskName $TaskName `
                               -Description "Open PowerShell and run Weather AI Wallpaper at sign-in." `
                               -Action $action `
                               -Trigger $trigger `
                               -Principal $principal `
                               -Settings $settings `
                               -Force | Out-Null
    } else {
        $taskCommand = "powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
        $null = & schtasks.exe /Create /TN $TaskName /SC ONLOGON /TR $taskCommand /IT /RL LIMITED /F 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "schtasks.exe returned exit code $LASTEXITCODE"
        }
    }

    Remove-LegacyWindowsAutostartArtifacts -Paths $LegacyPaths
}

$legacyAutostartExists = (Test-Path $legacyLauncherPath) -or (Test-Path $legacyShortcutPath)

if (Test-WindowsStartupTask -TaskName $taskName) {
    Remove-LegacyWindowsAutostartArtifacts -Paths @($legacyLauncherPath, $legacyShortcutPath)
    Write-Host "ℹ️ Autostart already configured via Task Scheduler, skipping. / 已通过计划任务配置开机启动，跳过设置。" -ForegroundColor Gray
} elseif ($legacyAutostartExists) {
    if (-not $scriptPath) {
        Write-Host "⚠️ Legacy autostart detected, but the script path is unavailable. Please save the script as a .ps1 file and run it once manually to upgrade startup. / 检测到旧版开机启动配置，但当前脚本路径不可用。请先将脚本保存为 .ps1 文件后手动运行一次，以升级开机启动方式。" -ForegroundColor Yellow
    } else {
        try {
            Set-WindowsStartupTask -ScriptPath $scriptPath -TaskName $taskName -LegacyPaths @($legacyLauncherPath, $legacyShortcutPath)
            Write-Host "✅ Upgraded startup entry. Windows will now launch the script through Task Scheduler at sign-in and open a PowerShell window. / 已升级开机启动配置，Windows 登录后会通过计划任务启动并弹出 PowerShell 窗口执行脚本。" -ForegroundColor Green
        } catch {
            Write-Host "❌ Upgrade failed / 升级失败：$($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    $answer = Read-Host "❓ Create a Task Scheduler auto-start item that opens PowerShell and runs this script when Windows starts? / 是否创建计划任务，在 Windows 登录后弹出 PowerShell 并执行此脚本？(Y/N)"
    if ($answer -match '^[Yy]') {
        if (-not $scriptPath) {
            Write-Host "⚠️ Please save the script as a .ps1 file first. / 请先保存脚本为 .ps1 文件再设置开机启动。" -ForegroundColor Yellow
        } else {
            try {
                Set-WindowsStartupTask -ScriptPath $scriptPath -TaskName $taskName -LegacyPaths @($legacyLauncherPath, $legacyShortcutPath)
                Write-Host "✅ Added to Task Scheduler. Windows will open a PowerShell window and run the script at sign-in. / 已加入计划任务，Windows 登录后会弹出 PowerShell 窗口并执行脚本。" -ForegroundColor Green
            } catch {
                Write-Host "❌ Setup failed / 设置失败：$($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}
