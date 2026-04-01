#!/bin/bash

# ==========================================
# Helper Function / 辅助函数：提示如何设置环境变量
# ==========================================
show_env_help() {
    local env_name=$1
    local service_name=$2
    echo "\033[31m❌ Error: Environment variable $env_name not set / 错误：未设置环境变量\033[0m"
    echo "\033[36m👉 Setup steps for macOS / 请按以下步骤在 macOS 中配置 API Key：\033[0m"
    echo "   1. Open Terminal, type: nano ~/.zshrc"
    echo "   2. Add this line at the end: export $env_name=\"YOUR_REAL_TOKEN\""
    echo "   3. Save and exit (Ctrl+O, Enter, Ctrl+X)"
    echo "   4. Run: source ~/.zshrc"
    exit 1
}

# Check dependencies / 依赖检查
if ! command -v jq &> /dev/null; then
    echo "\033[31m❌ Error: 'jq' is not installed. Run 'brew install jq' first. / 错误：未安装 jq。\033[0m"
    exit 1
fi

# ==========================================
# Step 1: Get Location / 第一步：获取地理位置
# ==========================================
echo "\033[36m1. Locating... / 正在定位...\033[0m"

if [ -z "$DASHSCOPE_API_KEY" ]; then show_env_help "DASHSCOPE_API_KEY" "AliCloud DashScope"; fi

locationData=$(curl -s "https://ipinfo.io/json")
loc=$(echo "$locationData" | jq -r '.loc // empty')
city=$(echo "$locationData" | jq -r '.city // empty')

if [ -z "$loc" ]; then
    echo "\033[90mℹ️ Main API failed, using backup service... / 使用备用接口...\033[0m"
    backupGeo=$(curl -s "http://ip-api.com/json/")
    status=$(echo "$backupGeo" | jq -r '.status // empty')
    if [ "$status" = "success" ]; then
        lat=$(echo "$backupGeo" | jq -r '.lat')
        lon=$(echo "$backupGeo" | jq -r '.lon')
        loc="$lat,$lon"
        [ -z "$city" ] && city=$(echo "$backupGeo" | jq -r '.city')
    fi
fi

if [ -z "$loc" ]; then
    echo "\033[31m❌ Location failed. / 无法定位，脚本退出。\033[0m"
    exit 1
fi
echo "\033[33m📍 City / 城市：$city (Coords: $loc)\033[0m"

# ==========================================
# Step 2: Get Weather / 第二步：获取天气详情
# ==========================================
echo "\033[36m2. Fetching weather data... / 正在获取天气...\033[0m"

lat=$(echo "$loc" | cut -d',' -f1)
lon=$(echo "$loc" | cut -d',' -f2)

url="https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code&timezone=auto&temperature_unit=celsius"
weatherResponse=$(curl -s "$url")

temp=$(echo "$weatherResponse" | jq -r '.current.temperature_2m')
weatherCode=$(echo "$weatherResponse" | jq -r '.current.weather_code')

get_weather_desc() {
    case "$1" in
        0) echo "Clear sky" ;;
        1|2|3) echo "Cloudy" ;;
        45|48) echo "Fog" ;;
        51|53|55|61|63|65) echo "Rain" ;;
        71|73|75) echo "Snow" ;;
        80|81|82) echo "Showers" ;;
        95|96|99) echo "Thunderstorm" ;;
        *) echo "Cloudy" ;;
    esac
}
weatherDesc=$(get_weather_desc "$weatherCode")

echo "\033[33m🌤️ Weather / 天气：$weatherDesc\033[0m"
echo "\033[33m🌡️ Temp / 气温：${temp}°C\033[0m"

# ==========================================
# Step 3: AI Generation / 第三步：生成高颜值人物壁纸
# ==========================================
echo "\033[36m3. Requesting AI generation... / 正在请求 AI 生成...\033[0m"

imagePromptText="Current weather: $weatherDesc, temperature: ${temp}°C. A masterpiece cinematic portrait wallpaper. Center: a beautiful East Asian girl facing the camera, sweet smile. Features: delicate facial features, big eyes, fair skin, pure and cute, exquisite makeup, detailed hair. Clothing: fashionable outfit matching the current weather and temperature. Half-body shot, wearing a skirt, close-up. Background: aesthetic natural or urban scenery reflecting the current weather, depth of field effect, 8k resolution."

JSON_PAYLOAD=$(cat <<EOF
{
  "model": "z-image-turbo",
  "input": {
    "messages": [{"role": "user", "content": [{"text": "$imagePromptText"}]}]
  },
  "parameters": {
    "negative_prompt": "text, low resolution, blurry, deformed, ugly, oversaturated, watermark",
    "size": "1920*1080"
  }
}
EOF
)

imageResponse=$(curl -s -X POST "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DASHSCOPE_API_KEY" \
    -d "$JSON_PAYLOAD")

imageUrl=$(echo "$imageResponse" | jq -r '.output.choices[0].message.content[0].image // empty')

if [ -z "$imageUrl" ] || [ "$imageUrl" = "null" ]; then
    echo "\033[31m❌ Generation failed. / 图片生成失败。\033[0m"
    echo "$imageResponse" | jq '.message'
    exit 1
fi
echo "\033[32m✅ Success! / 生成成功！\033[0m"

# ==========================================
# Step 4: Set Wallpaper / 第四步：设置桌面壁纸 (macOS 专属)
# ==========================================
echo "\033[36m4. Updating wallpaper... / 正在更新桌面壁纸...\033[0m"

wallpaperDir="$HOME/Pictures/WeatherWallpapers"
mkdir -p "$wallpaperDir"
wallpaperPath="$wallpaperDir/wallpaper_$(date +%s).png"

curl -s -o "$wallpaperPath" "$imageUrl"

# Use macOS osascript to change all desktops / 使用 osascript 更改所有屏幕壁纸
osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$wallpaperPath\""

echo "\033[32m🎉 Desktop wallpaper updated! / 桌面壁纸已更新！\033[0m"

# ==========================================
# Step 5: Autostart (LaunchAgent) / 第五步：设置开机启动
# ==========================================
echo ""
plistDir="$HOME/Library/LaunchAgents"
plistPath="$plistDir/com.user.weatherwallpaper.plist"

if [ -f "$plistPath" ]; then
    echo "\033[90mℹ️ Autostart already configured. / 已配置开机启动，跳过。\033[0m"
else
    read -p "❓ Set to auto-run on startup? / 是否设置为开机自动后台运行？(Y/N) " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        scriptPath=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
        chmod +x "$scriptPath"
        
        cat > "$plistPath" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.weatherwallpaper</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$scriptPath</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
        launchctl load "$plistPath" 2>/dev/null
        echo "\033[32m✅ Added to LaunchAgent. / 已加入开机启动队列。\033[0m"
    fi
fi