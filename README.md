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

## 🖥️ 支持平台

| 平台 | 脚本文件 | 执行方式 |
|------|----------|----------|
| macOS | `fix-windsurf-mac.sh` | `./fix-windsurf-mac.sh` |
| Linux | `fix-windsurf-linux.sh` | `./fix-windsurf-linux.sh` |
| Windows | `fix-windsurf-win.ps1` | PowerShell 管理员模式运行 |

## 🚀 快速开始

### macOS

```bash
git clone https://github.com/chuankangkk/windsurf-fix-tool.git
cd windsurf-fix-tool
chmod +x fix-windsurf-mac.sh
./fix-windsurf-mac.sh
```

### Linux

```bash
git clone https://github.com/chuankangkk/windsurf-fix-tool.git
cd windsurf-fix-tool
chmod +x fix-windsurf-linux.sh
./fix-windsurf-linux.sh
```

### Windows

```powershell
git clone https://github.com/chuankangkk/windsurf-fix-tool.git
cd windsurf-fix-tool
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\fix-windsurf-win.ps1
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
# macOS - 以下操作不会影响对话历史
rm -rf ~/Library/Application\ Support/Windsurf/GPUCache
rm -rf ~/Library/Application\ Support/Windsurf/Code\ Cache
rm -rf ~/.codeium/windsurf/CachedData
rm -rf ~/.codeium/windsurf/CachedExtensions
```

**注意:** 对话历史保存在 `~/.codeium/windsurf/cascade` 目录，上述清理操作不会影响它。

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
