# 🌤️ 智能天气壁纸自动生成器 (Weather AI Wallpaper)

这是一个基于 PowerShell 的自动化脚本工具。它能够根据你当前的地理位置和实时天气情况，利用 AI 自动生成契合当前天气氛围的高颜值二次元写真壁纸，并自动将其设置为你的 Windows 桌面背景。

## ✨ 功能特点

- **🌍 智能定位**：使用 `ipinfo.io` 接口精准获取当前所在城市与经纬度（并内置 `ip-api.com` 作为兜底备选方案）。
- **🌦️ 实时天气**：调用 Open-Meteo 接口，获取精准的实时天气状况（WMO 天气代码）与气温。
- **🎨 AI 绘图**：对接阿里云 DashScope (灵积) 大模型接口 (`z-image-turbo`)，根据“晴、雨、雪、雾”等天气特征及气温，动态生成包含特定着装和背景的 8K 大师级画质人物壁纸。
- **💻 自动换肤**：下载生成的图片，并调用 Windows 底层 API (user32.dll) 无缝替换当前桌面壁纸。
- **🚀 开机自启**：内置交互式引导，支持一键将脚本配置为开机静默后台运行，实现每天打开电脑自动拥有匹配天气的全新壁纸。

## 🛠️ 准备工作 (Prerequisites)

在运行此脚本之前，你需要准备以下两个免费的 API 密钥：

1. **IPInfo Token**: 用于精准获取 IP 地理位置。
   - 注册并登录 [ipinfo.io](https://ipinfo.io/) 获取你的 Access Token。
2. **DashScope API Key**: 用于调用阿里云 AI 绘画大模型。
   - 注册并登录 [阿里云百炼控制台](https://bailian.console.aliyun.com/) 开通 DashScope 服务并获取 API Key。

## ⚙️ 环境变量配置

脚本依赖系统环境变量来安全地读取 API 密钥，避免明文硬编码在脚本中。请在系统中配置以下两个环境变量：

- `IPINFO_AUTH`: 填写你的 ipinfo.io 鉴权 Token (例如：`Bearer 你的Token`，具体格式视你在代码中的配置而定)。
- `DASHSCOPE_API_KEY`: 填写你的阿里云 DashScope API Key。

**配置方法 (Windows):**
1. 按下 `Win + R` 键，输入 `sysdm.cpl` 并按回车打开“系统属性”。
2. 切换到“高级”选项卡，点击底部的“环境变量”按钮。
3. 在上半部分的“用户变量”中点击“新建”。
4. 依次创建上述两个变量并填入对应的值。
5. 点击“确定”保存。**注意：配置完成后，必须关闭并重新打开 PowerShell 窗口才能使环境变量生效。**

## 🚀 快速开始

1. 将项目中的 PowerShell 脚本保存到你的本地电脑，例如命名为 `WeatherWallpaper.ps1`。
2. 右键点击该 `.ps1` 文件，选择 **“使用 PowerShell 运行” (Run with PowerShell)**。
3. 观察控制台输出，脚本会依次执行定位、天气获取、AI 生成和壁纸替换。
4. 在脚本执行完毕前，系统会提示：`❓ 是否设置为开机自动后台运行？(Y/N)`。
   - 输入 `Y` 即可自动在 Windows“启动”文件夹中创建快捷方式，以后每次开机都会在后台默默为你更换天气壁纸。

## ❓ 常见问题 (FAQ)

**1. 运行脚本时提示“在此系统上禁止运行脚本”怎么办？**
这是 Windows PowerShell 的默认安全执行策略导致的。你可以以管理员身份运行 PowerShell，然后执行以下命令解除限制：
```powershell
Set-ExecutionPolicy RemoteSigned