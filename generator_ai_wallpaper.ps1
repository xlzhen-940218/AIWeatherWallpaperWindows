# ==========================================
# 辅助函数：提示如何设置环境变量
# ==========================================
function Show-EnvHelp {
    param(
        [string]$EnvName,
        [string]$ServiceName
    )
    Write-Host "❌ 错误：未设置环境变量 $EnvName" -ForegroundColor Red
    Write-Host "👉 请按以下步骤配置 $ServiceName 的 Token/API Key：" -ForegroundColor Cyan
    Write-Host "   1. 按下 [Win + R] 键，输入 sysdm.cpl 并按回车打开系统属性。"
    Write-Host "   2. 切换到“高级”选项卡，点击底部的“环境变量”按钮。"
    Write-Host "   3. 在上半部分的“用户变量”中点击“新建”。"
    Write-Host "   4. 变量名填写：$EnvName"
    Write-Host "   5. 变量值填写：你的真实 Token / API Key"
    Write-Host "   6. 点击三次“确定”保存所有窗口。"
    Write-Host "   7. ⚠️ 重要：关闭当前所有的 PowerShell 窗口并重新打开，以使环境变量生效。" -ForegroundColor Yellow
}

# ==========================================
# 1. 第一步：获取地理位置
# ==========================================
Write-Host "1. 正在定位..." -ForegroundColor Cyan

if (-not $env:DASHSCOPE_API_KEY) {
    Show-EnvHelp -EnvName "DASHSCOPE_API_KEY" -ServiceName "阿里云 DashScope"
    exit
}

# 使用 ipinfo.io 接口获取详细位置
try {
    $url = "https://ipinfo.io/json"
    $locationData = Invoke-RestMethod -Uri $url -ErrorAction Stop
    
    $loc = $locationData.loc
    $city = $locationData.city

    # 逻辑优化：如果主接口未返回经纬度（Open-Meteo 天气接口必需），则调用兜底服务获取坐标
    if (-not $loc) {
        Write-Host "ℹ️ 主接口未返回坐标，正在通过备用接口获取天气定位..." -ForegroundColor Gray
        $backupGeo = Invoke-RestMethod -Uri "http://ip-api.com/json/" -ErrorAction SilentlyContinue
        if ($backupGeo -and $backupGeo.status -eq "success") {
            $loc = "$($backupGeo.lat),$($backupGeo.lon)"
            if (-not $city) { $city = $backupGeo.city }
        }
    }

    Write-Host "📍 定位城市：$city (坐标：$loc)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ 定位失败：$($_.Exception.Message)" -ForegroundColor Red
    exit
}

# ==========================================
# 2. 第二步：调用 Open-Meteo 获取天气详情
# ==========================================
Write-Host "2. 正在获取详细天气数据..." -ForegroundColor Cyan

if (-not $loc -or $loc -eq ",") {
    Write-Host "❌ 无法获取有效的经纬度坐标，天气获取失败，脚本退出。" -ForegroundColor Red
    exit
}

$lat, $lon = $loc -split ','

try {
    $url = "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code&timezone=auto&temperature_unit=celsius"
    $weatherResponse = Invoke-RestMethod -Uri $url -ErrorAction Stop

    $current = $weatherResponse.current
    $temp = $current.temperature_2m
    # 强制转换为 [int] 类型，解决强类型匹配失败的问题
    $weatherCode = [int]$current.weather_code

    $weatherMap = @{
        0 = "晴朗无云"; 1 = "主要晴朗"; 2 = "部分多云"; 3 = "阴天"
        45 = "有雾"; 48 = "有雾"
        51 = "毛毛雨"; 53 = "小雨"; 55 = "大雨"
        61 = "小雨"; 63 = "中雨"; 65 = "大雨"
        71 = "小雪"; 73 = "中雪"; 75 = "大雪"
        80 = "阵雨"; 81 = "中阵雨"; 82 = "大暴雨"
        95 = "雷雨"; 96 = "雷雨伴冰雹"; 99 = "强雷雨"
    }

    $weatherDesc = if ($weatherMap.ContainsKey($weatherCode)) { $weatherMap[$weatherCode] } else { "多云" }

    Write-Host "🌤️ 天气状况：$weatherDesc" -ForegroundColor Yellow
    Write-Host "🌡️ 实时气温：${temp}°C" -ForegroundColor Yellow
} catch {
    Write-Host "❌ 获取天气失败：$($_.Exception.Message)" -ForegroundColor Red
    exit
}

# ==========================================
# 3. 第三步：生成高颜值人物壁纸
# ==========================================
Write-Host "3. 正在请求 AI 生成壁纸..." -ForegroundColor Cyan

$imagePromptText = "当前天气：$weatherDesc，气温${temp}摄氏度。画面描述：一张大师级画质的写真壁纸。画面正中央是一位绝美的东亚少女，面向镜头，甜美微笑。容貌特征：精致五官，大眼睛，双眼皮，高鼻梁，皮肤白皙细腻，清纯可爱，妆容精致，发丝细节清晰。衣着：穿着符合当前天气和温度的时尚服装。半身像，裙子，近景。背景是展现该天气的自然或城市风光，景深效果，8k分辨率。"

$imageDataJson = @{
    model = "z-image-turbo"
    input = @{
        messages = @(@{
            role = "user"
            content = @(@{ text = $imagePromptText })
        })
    }
    parameters = @{
        negative_prompt = "文字，低分辨率，模糊，畸形，丑陋，画面过饱和，水印"
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
    Write-Host "✅ 生成成功！" -ForegroundColor Green
} catch {
    Write-Host "❌ 图片生成失败：$($_.Exception.Message)" -ForegroundColor Red
    exit
}

# ==========================================
# 4. 第四步：下载并设置桌面壁纸
# ==========================================
Write-Host "4. 正在更新桌面壁纸..." -ForegroundColor Cyan

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
    Write-Host "🎉 桌面壁纸已更新！" -ForegroundColor Green
} catch {
    Write-Host "❌ 设置壁纸失败：$($_.Exception.Message)" -ForegroundColor Red
}

# ==========================================
# 5. 第五步：设置开机启动提示
# ==========================================
Write-Host ""
$startupFolder = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startupFolder "WeatherWallpaper.lnk"

# 检查是否已经存在快捷方式
if (Test-Path $shortcutPath) {
    Write-Host "ℹ️ 检测到已配置开机启动，跳过设置。" -ForegroundColor Gray
} else {
    $answer = Read-Host "❓ 是否设置为开机自动后台运行？(Y/N)"
    if ($answer -match '^[Yy]') {
        $scriptPath = $MyInvocation.MyCommand.Path
        if (-not $scriptPath) {
            Write-Host "⚠️ 请先保存脚本为 .ps1 文件再设置开机启动。" -ForegroundColor Yellow
        } else {
            try {
                $WshShell = New-Object -ComObject WScript.Shell
                $Shortcut = $WshShell.CreateShortcut($shortcutPath)
                $Shortcut.TargetPath = "powershell.exe"
                $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
                $Shortcut.Save()
                Write-Host "✅ 已加入开机启动队列。" -ForegroundColor Green
            } catch {
                Write-Host "❌ 设置失败：$($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}