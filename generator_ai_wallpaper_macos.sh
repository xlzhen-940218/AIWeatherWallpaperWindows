#!/bin/bash

# ==========================================
# 辅助函数：提示如何设置环境变量
# ==========================================
show_env_help() {
    local env_name=$1
    local service_name=$2
    echo "\033[31m❌ 错误：未设置环境变量 $env_name\033[0m"
    echo "\033[36m👉 请按以下步骤在 macOS 中配置 $service_name 的 Token/API Key：\033[0m"
    echo "   1. 打开终端 (Terminal)，输入: nano ~/.zshrc"
    echo "   2. 在文件末尾添加一行: export $env_name=\"你的真实Token\""
    echo "   3. 保存并退出 (按 Ctrl+O, Enter, Ctrl+X)"
    echo "   4. 执行: source ~/.zshrc 使其立即生效"
    exit 1
}

# 依赖检查
if ! command -v jq &> /dev/null; then
    echo "\033[31m❌ 错误：未安装 jq。请在终端执行 brew install jq 进行安装。\033[0m"
    exit 1
fi

# ==========================================
# 1. 第一步：获取地理位置
# ==========================================
echo "\033[36m1. 正在定位...\033[0m"

if [ -z "$IPINFO_AUTH" ]; then show_env_help "IPINFO_AUTH" "ipinfo.io"; fi
if [ -z "$DASHSCOPE_API_KEY" ]; then show_env_help "DASHSCOPE_API_KEY" "阿里云 DashScope"; fi

locationData=$(curl -s -H "Authorization: $IPINFO_AUTH" "https://ipinfo.io/json")
loc=$(echo "$locationData" | jq -r '.loc // empty')
city=$(echo "$locationData" | jq -r '.city // empty')

if [ -z "$loc" ]; then
    echo "\033[90mℹ️ 主接口未返回坐标，正在调用备用接口...\033[0m"
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
    echo "\033[31m❌ 无法定位，脚本退出。\033[0m"
    exit 1
fi
echo "\033[33m📍 定位城市：$city (坐标：$loc)\033[0m"

# ==========================================
# 2. 第二步：获取天气详情
# ==========================================
echo "\033[36m2. 正在获取详细天气数据...\033[0m"

lat=$(echo "$loc" | cut -d',' -f1)
lon=$(echo "$loc" | cut -d',' -f2)

url="https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code&timezone=auto&temperature_unit=celsius"
weatherResponse=$(curl -s "$url")

temp=$(echo "$weatherResponse" | jq -r '.current.temperature_2m')
weatherCode=$(echo "$weatherResponse" | jq -r '.current.weather_code')

get_weather_desc() {
    case "$1" in
        0) echo "晴朗无云" ;;
        1) echo "主要晴朗" ;;
        2) echo "部分多云" ;;
        3) echo "阴天" ;;
        45|48) echo "有雾" ;;
        51|53|61) echo "小雨" ;;
        55|65) echo "大雨" ;;
        63) echo "中雨" ;;
        71) echo "小雪" ;;
        73) echo "中雪" ;;
        75) echo "大雪" ;;
        80) echo "阵雨" ;;
        81) echo "中阵雨" ;;
        82) echo "大暴雨" ;;
        95|96|99) echo "雷雨" ;;
        *) echo "多云" ;;
    esac
}
weatherDesc=$(get_weather_desc "$weatherCode")

echo "\033[33m🌤️ 天气状况：$weatherDesc\033[0m"
echo "\033[33m🌡️ 实时气温：${temp}°C\033[0m"

# ==========================================
# 3. 第三步：生成高颜值人物壁纸
# ==========================================
echo "\033[36m3. 正在请求 AI 生成壁纸...\033[0m"

imagePromptText="当前天气：$weatherDesc，气温${temp}摄氏度。画面描述：一张大师级画质的写真壁纸。画面正中央是一位绝美的东亚少女，面向镜头，甜美微笑。容貌特征：精致五官，大眼睛，双眼皮，高鼻梁，皮肤白皙细腻，清纯可爱，妆容精致，发丝细节清晰。衣着：穿着符合当前天气和温度的时尚服装。半身像，裙子，近景。背景是展现该天气的自然或城市风光，景深效果，8k分辨率。"

JSON_PAYLOAD=$(cat <<EOF
{
  "model": "z-image-turbo",
  "input": {
    "messages": [{"role": "user", "content": [{"text": "$imagePromptText"}]}]
  },
  "parameters": {
    "negative_prompt": "文字，低分辨率，模糊，畸形，丑陋，画面过饱和，水印",
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
    echo "\033[31m❌ 图片生成失败。\033[0m"
    echo "$imageResponse" | jq '.message'
    exit 1
fi
echo "\033[32m✅ 生成成功！\033[0m"

# ==========================================
# 4. 第四步：下载并设置桌面壁纸 (macOS 专属)
# ==========================================
echo "\033[36m4. 正在更新桌面壁纸...\033[0m"

wallpaperDir="$HOME/Pictures/WeatherWallpapers"
mkdir -p "$wallpaperDir"
wallpaperPath="$wallpaperDir/wallpaper_$(date +%s).png"

curl -s -o "$wallpaperPath" "$imageUrl"

# 使用 macOS 自带的 osascript 更改所有屏幕的壁纸
osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$wallpaperPath\""

echo "\033[32m🎉 桌面壁纸已更新！\033[0m"

# ==========================================
# 5. 第五步：设置开机启动 (LaunchAgent)
# ==========================================
echo ""
plistDir="$HOME/Library/LaunchAgents"
plistPath="$plistDir/com.user.weatherwallpaper.plist"

if [ -f "$plistPath" ]; then
    echo "\033[90mℹ️ 检测到已配置开机启动，跳过设置。\033[0m"
else
    read -p "❓ 是否设置为开机自动后台运行？(Y/N) " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        # 绝对路径
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
        # 加载任务
        launchctl load "$plistPath" 2>/dev/null
        echo "\033[32m✅ 已加入开机启动队列 (LaunchAgent)。\033[0m"
    fi
fi