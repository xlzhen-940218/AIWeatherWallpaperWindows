# 🌤️ Weather AI Wallpaper Generator | 智能天气壁纸自动生成器

[English](#english) | [中文](#chinese)

---

<a id="english"></a>
## 🇬🇧 English

This is a cross-platform automation script natively supporting **Windows, macOS, and Linux**. It automatically detects your current location and real-time weather, uses AI to generate an aesthetic, high-quality portrait/scenic wallpaper that matches the current weather vibe, and sets it as your desktop background.

### ✨ Features
- **🌍 Smart Location:** Accurately detects your current city and coordinates using the `ipinfo.io` API (with `ip-api.com` as a built-in fallback).
- **🌦️ Real-time Weather:** Calls the Open-Meteo API to get precise real-time weather conditions (WMO weather codes) and temperature.
- **🎨 AI Image Generation:** Integrates with the AliCloud DashScope AI model (`z-image-turbo`) to dynamically generate 8K cinematic wallpapers featuring specific outfits and backgrounds based on weather attributes (e.g., sunny, rainy, snowy) and temperature.
- **💻 Cross-Platform Native Theming:**
  - **Windows:** Seamlessly applies the wallpaper using low-level API (`user32.dll`).
  - **macOS:** Replaces the wallpaper across all screens using native AppleScript (`osascript`).
  - **Linux:** Perfectly adapted for GNOME desktop environments using `gsettings`.
- **🚀 Auto-Start on Boot:** Built-in interactive wizard to easily set up the script for silent background execution on startup (Supports Windows Startup folder, macOS LaunchAgents, Linux Autostart).

### 🛠️ Prerequisites
#### 1. Get a Free API Key (Required for all platforms)
- **DashScope API Key:** Used to call the AliCloud AI drawing model. Register and log in to the [AliCloud Bailian Console](https://bailian.console.aliyun.com/) to activate the DashScope service and get your API Key.

#### 2. Install JSON Parser (Linux/macOS only)
Linux and macOS scripts require `jq` to parse API responses. Install it via terminal:
- **macOS (Homebrew):** `brew install jq`
- **Ubuntu/Debian:** `sudo apt install jq`
- **CentOS/RHEL:** `sudo yum install jq`

### ⚙️ Environment Variables Setup
For security, the script reads your API key from environment variables to avoid hardcoding.
- Variable Name: `DASHSCOPE_API_KEY`

**Windows Setup:**
1. Press `Win + R`, type `sysdm.cpl`, and hit Enter.
2. Go to the "Advanced" tab -> "Environment Variables".
3. Click "New" under "User variables" and add `DASHSCOPE_API_KEY` with your token.
4. **Note:** Restart your PowerShell window for changes to take effect.

**macOS / Linux Setup:**
1. Open Terminal.
2. Edit your shell config (`nano ~/.zshrc` or `nano ~/.bashrc`).
3. Add: `export DASHSCOPE_API_KEY="your_api_key_here"`
4. Apply changes: `source ~/.zshrc` or `source ~/.bashrc`.

### 🚀 Quick Start
**Windows (`generator_ai_wallpaper.ps1`)**
1. Right-click the `.ps1` file.
2. Select **"Run with PowerShell"**.
3. Follow the console prompts to optionally set up auto-start.

**macOS & Linux (`.sh` files)**
1. Open Terminal and navigate to the script directory.
2. Grant execution permissions: `chmod +x generator_ai_wallpaper_macos.sh` (or the linux version).
3. Run it: `./generator_ai_wallpaper_macos.sh`

---

<a id="chinese"></a>
## 🇨🇳 中文

这是一个跨平台的自动化脚本工具，原生支持 **Windows、macOS 和 Linux**。它能够根据你当前的地理位置和实时天气情况，利用 AI 自动生成契合当前天气氛围的高颜值二次元/写真壁纸，并自动将其设置为你的桌面背景。

### ✨ 功能特点
- **🌍 智能定位**：使用 `ipinfo.io` 接口精准获取当前所在城市与经纬度（并内置 `ip-api.com` 作为兜底方案）。
- **🌦️ 实时天气**：调用 Open-Meteo 接口，获取精准的实时天气状况（WMO 天气代码）与气温。
- **🎨 AI 绘图**：对接阿里云 DashScope (灵积) 大模型接口 (`z-image-turbo`)，根据“晴、雨、雪、雾”等天气特征及气温，动态生成包含特定着装和背景的 8K 大师级画质人物壁纸。
- **💻 全平台自动换肤**：
  - **Windows**: 调用底层 API (`user32.dll`) 无缝替换。
  - **macOS**: 使用原生 AppleScript (`osascript`) 全屏幕替换。
  - **Linux**: 使用 `gsettings` 完美适配 GNOME 桌面环境。
- **🚀 开机自启**：内置交互式引导，支持一键将脚本配置为开机静默后台运行。

### 🛠️ 准备工作
#### 1. 获取免费 API 密钥 (全平台必须)
- **DashScope API Key**: 注册并登录 [阿里云百炼控制台](https://bailian.console.aliyun.com/) 开通 DashScope 服务并获取 API Key。

#### 2. 安装命令行 JSON 解析工具 (仅 Linux/macOS 需要)
- **macOS (Homebrew)**: `brew install jq`
- **Ubuntu/Debian**: `sudo apt install jq`

### ⚙️ 环境变量配置
请将你的密钥配置为环境变量 `DASHSCOPE_API_KEY`。

**Windows 配置方法：**
1. 按下 `Win + R` 键，输入 `sysdm.cpl` 打开“系统属性”。
2. 切换到“高级”选项卡，点击“环境变量”。
3. 在“用户变量”中点击“新建”，创建 `DASHSCOPE_API_KEY` 并填入密钥。
4. **注意**：必须重启 PowerShell 窗口才能生效。

**macOS / Linux 配置方法：**
在终端编辑配置文件（`~/.zshrc` 或 `~/.bashrc`），添加 `export DASHSCOPE_API_KEY="你的密钥"`，然后执行 `source ~/.zshrc` 使其生效。

### 🚀 快速开始
**Windows**：右键点击 `generator_ai_wallpaper.ps1`，选择 **“使用 PowerShell 运行”**。
**macOS/Linux**：在终端执行 `chmod +x` 赋予权限后，运行对应的 `.sh` 脚本即可。

---
**💡 FAQ**
- **[Windows] 提示“在此系统上禁止运行脚本”？**
  以管理员身份运行 PowerShell 并执行：`Set-ExecutionPolicy RemoteSigned`。
- **[Linux] 壁纸没有成功替换？**
  目前的 Linux 脚本默认针对 GNOME 桌面环境编写。如果你使用的是 KDE 等其他桌面，需修改脚本中的换壁纸命令以适配。