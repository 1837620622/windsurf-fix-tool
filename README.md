<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-blue?style=for-the-badge" alt="Platform"/>
  <img src="https://img.shields.io/badge/Shell-Bash%20%7C%20PowerShell-green?style=for-the-badge" alt="Shell"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License"/>
</p>

<h1 align="center">🌊 Windsurf 修复工具</h1>

<p align="center">
  <strong>跨平台 Windsurf IDE 故障排除工具包</strong>
  <br/>
  修复启动卡顿、Shell连接问题、MCP加载失败等常见问题
</p>

<p align="center">
  <a href="./README.md">🇨🇳 中文</a> | <a href="./README.en.md">🇺🇸 English</a>
</p>

## ✨ 功能特性

| 功能 | 描述 | 清理对话历史 |
|------|------|-------------|
| 🚀 **清理启动缓存** | 清理GPU/代码缓存，解决启动卡顿 | ❌ 否 |
| 🔧 **清理扩展缓存** | 解决扩展加载问题 | ❌ 否 |
| 🔌 **MCP 诊断** | 诊断并修复MCP自动加载问题 | ❌ 否 |
| 💬 **清理Cascade缓存** | 解决启动失败（最后手段） | ⚠️ 是 |
| 🖥️ **终端修复** | 解决Shell连接和会话卡住问题 | ❌ 否 |
| 📊 **生成诊断报告** | 收集系统信息用于故障排除 | ❌ 否 |
| 🧹 **开发工具缓存清理** | 清理npm/pip/Homebrew/Maven/Gradle等缓存 | ❌ 否 |
| 🗑️ **系统缓存清理** | 清理日志/废纸篓/旧备份/DNS缓存等 | ❌ 否 |
| 📈 **磁盘空间分析** | 分析磁盘占用，定位大文件和缓存 | ❌ 否 |

## 🖥️ 支持平台

| 平台 | 脚本文件 | 执行方式 |
|------|----------|----------|
| macOS | `fix-windsurf-mac.sh` | `./fix-windsurf-mac.sh` |
| Linux | `fix-windsurf-linux.sh` | `./fix-windsurf-linux.sh` |
| Windows | `fix-windsurf-win.ps1` | PowerShell 管理员模式运行 |
| macOS 系统清理 | `macos-safe-cleanup.sh` | `./macos-safe-cleanup.sh` |

## 🚀 快速开始

### macOS

```bash
git clone https://github.com/1837620622/windsurf-fix-tool.git
cd windsurf-fix-tool
chmod +x fix-windsurf-mac.sh
./fix-windsurf-mac.sh
```

### Linux

```bash
git clone https://github.com/1837620622/windsurf-fix-tool.git
cd windsurf-fix-tool
chmod +x fix-windsurf-linux.sh
./fix-windsurf-linux.sh
```

### Windows

```powershell
git clone https://github.com/1837620622/windsurf-fix-tool.git
cd windsurf-fix-tool
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\fix-windsurf-win.ps1
```

### macOS 系统清理

```bash
git clone https://github.com/1837620622/windsurf-fix-tool.git
cd windsurf-fix-tool
chmod +x macos-safe-cleanup.sh
./macos-safe-cleanup.sh
```

## ⚠️ 重要说明

**本工具不会自动修改你的终端配置文件**（如 `.zshrc`、`.bashrc` 等）。所有涉及终端配置的操作都只是提供建议和检测信息，需要用户手动确认后才会执行。

## 常见问题及解决方案（官方最新）

### 1. Windsurf启动失败 / 卡顿严重

**原因:** 缓存文件损坏

**解决方案:** 运行工具选择"清理Cascade缓存"

**手动操作:**
```bash
# macOS/Linux
rm -rf ~/.codeium/windsurf/cascade

# Windows (PowerShell)
Remove-Item -Recurse -Force "$env:USERPROFILE\.codeium\windsurf\cascade"
```

### 2. 终端/Shell无法连接

**原因:** 
- 默认终端配置文件未设置
- zsh主题冲突（Oh My Zsh、Powerlevel10k等）
- Linux上的systemd终端上下文跟踪干扰

**解决方案（手动配置）:** 

打开 Windsurf 设置 (Cmd/Ctrl + ,)，搜索 "terminal default profile"，设置对应系统的值。

或在 `settings.json` 中添加：
```json
// macOS
"terminal.integrated.defaultProfile.osx": "zsh"

// Windows
"terminal.integrated.defaultProfile.windows": "PowerShell"

// Linux
"terminal.integrated.defaultProfile.linux": "bash"
```

### 3. 终端会话卡住（官方最新方案）

**原因:** 复杂的zsh主题导致Cascade误判命令状态

**官方诊断步骤:**
1. 打开 `~/.zshrc` 文件
2. 临时注释主题相关配置
3. 保存后重启 Windsurf 或打开新终端
4. 测试命令是否正常

**可能需要注释的配置行:**
```bash
# ZSH_THEME="powerlevel10k/powerlevel10k"
# source ~/.p10k.zsh
# eval "$(oh-my-posh init zsh)"
```

**两种解决方案:**
- 方案A: 使用更简单的主题
- 方案B: 创建 Windsurf 专用的简化 shell 配置，保留其他终端使用复杂主题

### 4. Linux systemd 终端上下文跟踪问题（Fedora 43+）

**原因:** 系统的 `~/.bashrc → /etc/bashrc → /etc/profile.d/80-systemd-osc-context.sh` 启动链会启用 systemd 终端上下文跟踪，发送 OSC 3008 转义序列干扰 Cascade

**官方解决方案:**
- 方案A: 修改 `~/.bashrc` 避免 source `/etc/bashrc`
- 方案B: 创建专用于 Windsurf/Cascade 的最小化 shell 配置

### 5. macOS提示"Windsurf已损坏"

**官方完整解决步骤:**
1. 确保 Windsurf 放在 `/Applications` 目录
2. 检查处理器类型（Intel/Apple Silicon），下载对应版本
3. 重新下载 DMG 并安装
4. 执行命令清除隔离属性：
```bash
xattr -c "/Applications/Windsurf.app/"
```

### 6. Linux启动时静默崩溃

**原因:** Electron chrome-sandbox权限问题（tarball安装常见）

**官方解决方案:**
```bash
sudo chown root:root /path/to/windsurf/chrome-sandbox
sudo chmod 4755 /path/to/windsurf/chrome-sandbox
```

**备选方案（不推荐）:**
```bash
windsurf --no-sandbox
```

### 7. 专用终端问题（Wave 13+）

从 Wave 13 开始，Windsurf 在 macOS 上引入了专用终端（始终使用 zsh）。

**如果专用终端有问题:**
- 在 Windsurf 设置中启用 "Legacy Terminal Profile" 回退到传统终端

### 8. WSL 中 Docker 容器不可见

**问题:** 在 WSL 中连接 Docker 容器时，Remote Explorer 可能不显示可用容器

**官方解决方案:**
使用命令面板：`Cmd+P` (macOS) / `Ctrl+P` (Windows) → "Dev Containers: Attach to Running Container"

### 9. Windows 更新问题

**问题:** 提示"Updates are disabled because you are running the user-scope installation of Windsurf as Administrator"

**原因:** 以管理员身份运行时无法自动更新

**解决方案:** 以普通用户权限运行 Windsurf

### 10. MCP 无法自动加载

**可能原因:**
- mcp_config.json 格式错误
- 所需运行时（Node.js/Python）未安装
- 环境变量（如 API keys）未正确配置
- MCP 服务器进程启动失败

**排查步骤:**
1. 在 Windsurf 中点击 MCPs 图标，手动刷新
2. 检查 `~/.codeium/windsurf/mcp_config.json` 格式是否正确
3. 确保 Node.js/npx 已安装（大部分 MCP 需要）
4. 检查 Windsurf 输出日志中的 MCP 相关错误

**MCP 配置文件位置:**
```
~/.codeium/windsurf/mcp_config.json
```

### 11. 启动项目卡顿

**可能原因:**
- 缓存文件过大或损坏
- 扩展加载慢
- GPU 缓存问题

**解决方案（不会清理对话历史）:**
运行工具选择"清理启动缓存"，或手动清理：
```bash
# macOS - 优先清理关键卡顿项 CachedData，不会影响对话历史、登录态和已安装扩展
rm -rf ~/Library/Application\ Support/Windsurf/CachedData

# 如果仍然卡顿，再继续清理以下运行时缓存
rm -rf ~/Library/Application\ Support/Windsurf/Cache
rm -rf ~/Library/Application\ Support/Windsurf/GPUCache
rm -rf ~/Library/Application\ Support/Windsurf/Code\ Cache
rm -rf ~/Library/Application\ Support/Windsurf/DawnWebGPUCache
rm -rf ~/Library/Application\ Support/Windsurf/DawnGraphiteCache
rm -rf ~/Library/Application\ Support/Windsurf/CachedExtensionVSIXs

# Linux
rm -rf ~/.config/Windsurf/CachedData
rm -rf ~/.config/Windsurf/Cache
rm -rf ~/.config/Windsurf/GPUCache
rm -rf ~/.config/Windsurf/Code\ Cache
rm -rf ~/.config/Windsurf/DawnWebGPUCache
rm -rf ~/.config/Windsurf/DawnGraphiteCache
rm -rf ~/.config/Windsurf/CachedExtensionVSIXs
```

```powershell
# Windows (PowerShell)
Remove-Item -Recurse -Force "$env:APPDATA\Windsurf\CachedData"
Remove-Item -Recurse -Force "$env:APPDATA\Windsurf\Cache"
Remove-Item -Recurse -Force "$env:APPDATA\Windsurf\GPUCache"
Remove-Item -Recurse -Force "$env:APPDATA\Windsurf\Code Cache"
Remove-Item -Recurse -Force "$env:APPDATA\Windsurf\DawnWebGPUCache"
Remove-Item -Recurse -Force "$env:APPDATA\Windsurf\DawnGraphiteCache"
Remove-Item -Recurse -Force "$env:APPDATA\Windsurf\CachedExtensionVSIXs"
```

**注意:** 对话历史保存在 `~/.codeium/windsurf/cascade` 目录，上述运行时缓存清理不会影响它。

**默认不建议清理的目录:**
- `IndexedDB`
- `WebStorage`
- `Local Storage`
- `Session Storage`
- `Service Worker`

这些目录更接近 Electron 持久化站点/会话数据，可能导致部分登录态或内嵌网页状态失效。只有在明确接受重新登录风险时，才建议手动处理。

### 12. 开发工具缓存占用过多磁盘空间

**支持清理的缓存类型:**

| 缓存类型 | macOS 路径 | Linux 路径 | Windows 路径 |
|----------|-----------|-----------|-------------|
| npm | `~/.npm` | `~/.npm` | `%APPDATA%\npm-cache` |
| pip | `~/Library/Caches/pip` | `~/.cache/pip` | `%LOCALAPPDATA%\pip\cache` |
| Homebrew | `~/Library/Caches/Homebrew` | - | - |
| apt/yum/dnf | - | `/var/cache/apt/archives` 等 | - |
| uv | `~/.cache/uv` | `~/.cache/uv` | `%LOCALAPPDATA%\uv\cache` |
| Maven | `~/.m2/repository` | `~/.m2/repository` | `%USERPROFILE%\.m2\repository` |
| Gradle | `~/.gradle/caches` | `~/.gradle/caches` | `%USERPROFILE%\.gradle\caches` |
| Yarn | `~/Library/Caches/Yarn` | `~/.cache/yarn` | `%LOCALAPPDATA%\Yarn\Cache` |
| pnpm | `~/Library/pnpm` | `~/.pnpm-store` | `%LOCALAPPDATA%\pnpm-store` |
| NuGet | - | - | `%USERPROFILE%\.nuget\packages` |
| Selenium/WebDriver | `~/.cache/selenium` + `~/.wdm` | `~/.cache/selenium` + `~/.wdm` | `%USERPROFILE%\.cache\selenium` |
| Go | `~/go/pkg/mod/cache` | `~/go/pkg/mod/cache` | `%USERPROFILE%\go\pkg\mod\cache` |
| Cargo | `~/.cargo/registry` | `~/.cargo/registry` | `%USERPROFILE%\.cargo\registry` |
| conda | `~/miniconda3/pkgs` | `~/miniconda3/pkgs` | `%USERPROFILE%\miniconda3\pkgs` |
| CocoaPods | `~/Library/Caches/CocoaPods` | - | - |
| Xcode DerivedData | `~/Library/Developer/Xcode/DerivedData` | - | - |
| Docker | Docker Desktop 数据 | Docker 数据 | Docker Desktop 数据 |

**使用方法:** 运行工具选择"清理开发工具缓存"，支持全部清理或逐项选择

### 13. 系统缓存和垃圾文件清理

**macOS 支持清理:**
- 用户缓存 (`~/Library/Caches`)
- 旧日志文件（超过30天）
- 废纸篓
- Windsurf 旧备份目录
- 旧诊断报告文件
- DNS 缓存刷新

**Linux 支持清理:**
- 用户缓存 (`~/.cache`)
- 系统日志 (`/var/log` 超过30天)
- 临时文件 (`/tmp` 超过7天)
- systemd journal 日志
- Windsurf 旧备份目录
- DNS 缓存刷新

**Windows 支持清理:**
- 用户临时文件 (`%TEMP%`)
- Windows 临时文件 (`%SystemRoot%\Temp`，需管理员）
- 回收站
- Windows Update 缓存
- Windsurf 旧备份目录
- 旧诊断报告文件
- DNS 缓存刷新

### 14. 磁盘空间分析

运行工具选择"磁盘空间分析"，可查看:
- 磁盘总体使用情况
- 用户主目录各子目录占用
- 隐藏目录 Top 10（macOS/Linux）
- ~/Library 子目录排名（macOS）
- 应用容器占用排名（macOS）
- AppData 目录占用（Windows）

### 15. macOS 系统数据清理

**专用脚本:** `macos-safe-cleanup.sh`

**功能特点:**
- **26项清理功能**，分5个安全等级（低/中/开发/系统级/AI工具）
- **每步确认提示**，可随时跳过，确保安全
- **自动识别垃圾文件**，不硬编码任何路径，扫描到什么清理什么
- **不会删除**：应用程序、聊天记录、文档、邮件、配置文件

**主要清理项目:**
- 微信缓存 → 自动识别缓存目录、临时文件、文件存储缓存（图片/视频/文件缓存）
- QQ缓存 → 自动识别缓存目录、临时文件、图片/文件接收/日志缓存
- Safari浏览器缓存 → 自动识别Safari缓存、WebKit缓存、LocalStorage
- Xcode派生数据 → 自动识别DerivedData、Archives、模拟器数据
- iOS/iPadOS备份 → 自动识别MobileSync备份文件
- 系统诊断日志 → 纯日志，安全删除
- 照片分析缓存 → 删除后系统自动重建
- Windsurf CachedData / Cache / GPUCache / Dawn*Cache → 默认安全清理
- Windsurf WebStorage → 可能关联登录态，脚本默认保留
- Telegram 缓存
- Homebrew、npm、Maven 等开发工具缓存
- 用户缓存目录、临时文件、DNS缓存
- **AI工具深度清理** → Claude Code / OpenAI Codex / Gemini CLI / OpenCode 缓存清理

**使用方法:**
```bash
chmod +x macos-safe-cleanup.sh
./macos-safe-cleanup.sh
```

**安全等级说明:**
- **低风险**: 纯缓存，删除后系统自动重建
- **中等风险**: 应用缓存，建议先关闭对应应用
- **开发工具**: node_modules、__pycache__等，需要时重新安装
- **系统级**: 需要sudo权限，清理系统日志和临时文件

## 🆕 新增功能

### 16. 配置备份与还原（Linux / Windows）

**功能说明:**
- 备份 MCP 配置、Skills 目录、全局 Rules 和 Memories
- 支持选择性还原（MCP / Skills / Rules / Memories 单独或全部）
- 自动扫描所有历史备份，方便管理多个备份版本

**使用方法:** 运行对应平台脚本，选择"备份 MCP 配置 / Skills / 全局 Rules"或"还原 MCP 配置 / Skills / 全局 Rules"

### 17. 重置 Windsurf ID（Linux / Windows）

**功能说明:**
- 重新生成所有 Windsurf 标识 ID（installation_id、machineid、telemetry ID）
- 重置后 Windsurf 将被视为全新安装
- 适用于解决授权问题或 ID 冲突

**使用方法:** 运行对应平台脚本，选择"重置 Windsurf ID (重新生成所有标识)"

### 18. AI 工具深度清理（macOS）

**功能说明:**
- **Claude Code**: 清理 cache、debug、downloads、paste-cache、plugins/cache、session-data
- **OpenAI Codex**: 清理 .tmp、tmp、cache、log、plugins/cache、数据库临时文件、模型缓存
- **Gemini CLI**: 清理 cache、tmp、telemetry.log
- **OpenCode**: 清理 cache、tool-output、数据库临时文件（shm/wal）

**使用方法:** 运行 `macos-safe-cleanup.sh`，进入第五部分 AI 工具深度清理

## 网络白名单

如果你使用防火墙、VPN或代理，请将以下域名加入白名单：

- `*.codeium.com`
- `*.windsurf.com`
- `*.codeiumdata.com`

## 重要路径

| 平台 | Cascade缓存路径 |
|------|----------------|
| macOS/Linux | `~/.codeium/windsurf/cascade` |
| Windows | `C:\Users\<用户名>\.codeium\windsurf\cascade` |

| 平台 | 配置文件路径 |
|------|-------------|
| macOS/Linux | `~/.codeium/windsurf/` |
| Windows | `C:\Users\<用户名>\.codeium\windsurf\` |

## 使用方法

### macOS

```bash
cd windsurf-fix-tool
chmod +x fix-windsurf-mac.sh
./fix-windsurf-mac.sh
```

### macOS 系统清理

```bash
cd windsurf-fix-tool
chmod +x macos-safe-cleanup.sh
./macos-safe-cleanup.sh
```

### Linux

```bash
cd windsurf-fix-tool
chmod +x fix-windsurf-linux.sh
./fix-windsurf-linux.sh
```

### Windows

以管理员身份打开 PowerShell：
```powershell
cd windsurf-fix-tool
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\fix-windsurf-win.ps1
```

## 📚 参考文档

- [Windsurf官方故障排除文档](https://docs.windsurf.com/troubleshooting/windsurf-common-issues)
- [Windsurf终端文档](https://docs.windsurf.com/windsurf/terminal)
- [Windsurf MCP文档](https://docs.windsurf.com/windsurf/cascade/mcp)
- [Windsurf高级配置](https://docs.windsurf.com/windsurf/advanced)

## ⚠️ 免责声明

本工具基于Windsurf官方文档编写，仅供故障排除使用。使用前请确保已备份重要数据。清理Cascade缓存会删除对话历史。

## 📄 许可证

MIT License - 欢迎自由使用、修改和分发。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## ⭐ Star

如果这个工具帮助了你，请给个 Star ⭐
