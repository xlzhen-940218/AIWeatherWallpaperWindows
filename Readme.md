# 🌤️ 智能天气壁纸自动生成器 (Weather AI Wallpaper)

这是一个跨平台的自动化脚本工具，原生支持 **Windows、macOS 和 Linux**。它能够根据你当前的地理位置和实时天气情况，利用 AI 自动生成契合当前天气氛围的高颜值二次元写真壁纸，并自动将其设置为你的桌面背景。

## ✨ 功能特点

- **🌍 智能定位**：使用 `ipinfo.io` 接口精准获取当前所在城市与经纬度（并内置 `ip-api.com` 作为兜底备选方案）。
- **🌦️ 实时天气**：调用 Open-Meteo 接口，获取精准的实时天气状况（WMO 天气代码）与气温。
- **🎨 AI 绘图**：对接阿里云 DashScope (灵积) 大模型接口 (`z-image-turbo`)，根据“晴、雨、雪、雾”等天气特征及气温，动态生成包含特定着装和背景的 8K 大师级画质人物壁纸。
- **💻 全平台自动换肤**：
  - **Windows**: 调用底层 API (`user32.dll`) 无缝替换。
  - **macOS**: 使用原生 AppleScript (`osascript`) 全屏幕替换。
  - **Linux**: 使用 `gsettings` 完美适配 GNOME 桌面环境。
- **🚀 开机自启**：内置交互式引导，支持一键将脚本配置为开机静默后台运行（支持 Windows 启动文件夹、macOS LaunchAgents、Linux Autostart）。

## 🛠️ 准备工作 (Prerequisites)

### 1. 获取免费 API 密钥 (全平台必须)
在运行此脚本之前，你需要准备以下两个免费的 API 密钥：
- **IPInfo Token**: 用于精准获取 IP 地理位置。注册并登录 [ipinfo.io](https://ipinfo.io/) 获取 Access Token。
- **DashScope API Key**: 用于调用阿里云 AI 绘画大模型。注册并登录 [阿里云百炼控制台](https://bailian.console.aliyun.com/) 开通 DashScope 服务并获取 API Key。

### 2. 安装命令行 JSON 解析工具 (仅 Linux/macOS 需要)
Linux 和 macOS 脚本依赖 `jq` 工具来解析 API 返回的数据。请在终端中执行以下命令安装：
- **macOS (Homebrew)**: `brew install jq`
- **Ubuntu/Debian**: `sudo apt install jq`
- **CentOS/RHEL**: `sudo yum install jq`

## ⚙️ 环境变量配置

为了安全起见，脚本通过读取系统环境变量来获取 API 密钥，避免明文硬编码。请将你的密钥配置为以下两个环境变量：
- `DASHSCOPE_API_KEY`: 你的阿里云 DashScope API Key。

### Windows 配置方法：
1. 按下 `Win + R` 键，输入 `sysdm.cpl` 打开“系统属性”。
2. 切换到“高级”选项卡，点击“环境变量”。
3. 在“用户变量”中点击“新建”，创建 `DASHSCOPE_API_KEY`。
4. **注意**：配置完成后，必须关闭并重新打开 PowerShell 窗口才能生效。

### macOS / Linux 配置方法：
1. 打开终端 (Terminal)。
2. 编辑你的 shell 配置文件（macOS 通常是 `~/.zshrc`，Linux 通常是 `~/.bashrc` 或 `~/.zshrc`）：
   ```bash
   nano ~/.zshrc  # 或 nano ~/.bashrc
   ```
3. 在文件末尾添加以下两行（替换为你真实的 Key）：
   ```bash
   export DASHSCOPE_API_KEY="你的dashscope_key"
   ```
4. 保存退出后，执行以下命令使其立即生效：
   ```bash
   source ~/.zshrc  # 或 source ~/.bashrc
   ```

## 🚀 快速开始

根据你的操作系统，选择对应的脚本运行：

### 🪟 Windows (`generator_ai_wallpaper.ps1`)
1. 右键点击 `generator_ai_wallpaper.ps1` 文件。
2. 选择 **“使用 PowerShell 运行” (Run with PowerShell)**。
3. 按照控制台提示，选择是否设置开机启动。

### 🍏 macOS (`generator_ai_wallpaper_macos.sh`)
1. 打开终端，进入脚本所在目录。
2. 赋予脚本执行权限：
   ```bash
   chmod +x generator_ai_wallpaper_macos.sh
   ```
3. 运行脚本：
   ```bash
   ./generator_ai_wallpaper_macos.sh
   ```

### 🐧 Linux (`generator_ai_wallpaper_linux.sh`)
1. 打开终端，进入脚本所在目录。
2. 赋予脚本执行权限：
   ```bash
   chmod +x generator_ai_wallpaper_linux.sh
   ```
3. 运行脚本：
   ```bash
   ./generator_ai_wallpaper_linux.sh
   ```

## ❓ 常见问题 (FAQ)

**1. [Windows] 运行脚本时提示“在此系统上禁止运行脚本”怎么办？**
这是 Windows PowerShell 的默认安全执行策略导致的。你可以以管理员身份运行 PowerShell，然后执行以下命令解除限制：
```powershell
Set-ExecutionPolicy RemoteSigned
```

**2. [Linux] 壁纸没有成功替换怎么办？**
目前的 Linux 脚本默认针对 **GNOME** 桌面环境（Ubuntu 默认桌面）编写。如果你使用的是 KDE Plasma、XFCE 等其他桌面环境，需要修改脚本“第四步”中的换壁纸命令以适配你的桌面环境。

**3. 为什么开机启动没有生效？**
开机启动机制依赖于你初次运行脚本时的绝对路径。如果你移动了脚本文件，旧的开机自启快捷方式将失效。你需要先清理旧的自启项（Windows 位于启动文件夹，macOS 位于 `~/Library/LaunchAgents/`，Linux 位于 `~/.config/autostart/`），然后在脚本的新位置重新运行并再次配置开机启动。