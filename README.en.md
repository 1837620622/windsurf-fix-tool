<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-blue?style=for-the-badge" alt="Platform"/>
  <img src="https://img.shields.io/badge/Shell-Bash%20%7C%20PowerShell-green?style=for-the-badge" alt="Shell"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License"/>
</p>

<h1 align="center">🌊 Windsurf Fix Tool</h1>

<p align="center">
  <strong>A cross-platform troubleshooting toolkit for Windsurf IDE</strong>
  <br/>
  Fix startup lag, shell connection issues, MCP loading problems and more
</p>

<p align="center">
  <a href="./README.md">🇨🇳 中文</a> | <a href="./README.en.md">🇺🇸 English</a>
</p>

## ✨ Features

| Feature | Description | Clears History |
|---------|-------------|----------------|
| 🚀 **Startup Cache Cleanup** | Fix slow startup by clearing GPU/Code cache | ❌ No |
| 🔧 **Extension Cache Cleanup** | Resolve extension loading issues | ❌ No |
| 🔌 **MCP Diagnostics** | Diagnose and fix MCP auto-loading problems | ❌ No |
| 💬 **Cascade Cache Cleanup** | Fix startup failures (last resort) | ⚠️ Yes |
| 🖥️ **Terminal Fixes** | Resolve shell connection and stuck sessions | ❌ No |
| 📊 **Diagnostic Reports** | Generate system info for troubleshooting | ❌ No |
| 🧹 **Dev Tool Cache Cleanup** | Clean npm/pip/Homebrew/Maven/Gradle caches | ❌ No |
| 🗑️ **System Cache Cleanup** | Clean logs/trash/old backups/DNS cache | ❌ No |
| 📈 **Disk Usage Analysis** | Analyze disk usage, locate large files and caches | ❌ No |

## 🖥️ Supported Platforms

| Platform | Script | Usage |
|----------|--------|-------|
| macOS | `fix-windsurf-mac.sh` | `./fix-windsurf-mac.sh` |
| Linux | `fix-windsurf-linux.sh` | `./fix-windsurf-linux.sh` |
| Windows | `fix-windsurf-win.ps1` | Run in PowerShell (Admin) |
| macOS System Cleanup | `macos-safe-cleanup.sh` | `./macos-safe-cleanup.sh` |

## 🚀 Quick Start

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

### macOS System Cleanup

```bash
git clone https://github.com/1837620622/windsurf-fix-tool.git
cd windsurf-fix-tool
chmod +x macos-safe-cleanup.sh
./macos-safe-cleanup.sh
```

## 📋 Common Issues & Solutions

### 1. Slow Startup / Lag

**Recommended:** Run "Clean Startup Cache" (Option 2)

This clears GPU cache, code cache, and extension cache **without** affecting your conversation history.

```bash
# Manual cleanup (macOS)
rm -rf ~/Library/Application\ Support/Windsurf/CachedData
rm -rf ~/Library/Application\ Support/Windsurf/Cache
rm -rf ~/Library/Application\ Support/Windsurf/GPUCache
rm -rf ~/Library/Application\ Support/Windsurf/Code\ Cache
rm -rf ~/Library/Application\ Support/Windsurf/DawnWebGPUCache
rm -rf ~/Library/Application\ Support/Windsurf/DawnGraphiteCache
rm -rf ~/Library/Application\ Support/Windsurf/CachedExtensionVSIXs

# Manual cleanup (Linux)
rm -rf ~/.config/Windsurf/CachedData
rm -rf ~/.config/Windsurf/Cache
rm -rf ~/.config/Windsurf/GPUCache
rm -rf ~/.config/Windsurf/Code\ Cache
rm -rf ~/.config/Windsurf/DawnWebGPUCache
rm -rf ~/.config/Windsurf/DawnGraphiteCache
rm -rf ~/.config/Windsurf/CachedExtensionVSIXs
```

```powershell
# Manual cleanup (Windows PowerShell)
Remove-Item -Recurse -Force "$env:APPDATA\Windsurf\CachedData"
Remove-Item -Recurse -Force "$env:APPDATA\Windsurf\Cache"
Remove-Item -Recurse -Force "$env:APPDATA\Windsurf\GPUCache"
Remove-Item -Recurse -Force "$env:APPDATA\Windsurf\Code Cache"
Remove-Item -Recurse -Force "$env:APPDATA\Windsurf\DawnWebGPUCache"
Remove-Item -Recurse -Force "$env:APPDATA\Windsurf\DawnGraphiteCache"
Remove-Item -Recurse -Force "$env:APPDATA\Windsurf\CachedExtensionVSIXs"
```

Avoid cleaning these folders by default:
- `IndexedDB`
- `WebStorage`
- `Local Storage`
- `Session Storage`
- `Service Worker`

These locations are closer to Electron persistent site and session data, so clearing them may require logging in again for some embedded services.

### 2. MCP Not Auto-Loading

**Diagnosis Steps:**
1. Click MCPs icon in Windsurf and refresh manually
2. Check `~/.codeium/windsurf/mcp_config.json` for JSON errors
3. Ensure Node.js/npx is installed
4. Verify environment variables (API keys)

### 3. Terminal Session Stuck

**Causes:** Complex zsh themes (Oh My Zsh, Powerlevel10k) can interfere with Cascade

**Solutions:**
- Temporarily disable theme in `~/.zshrc`
- Create a minimal shell config for Windsurf
- Enable Legacy Terminal in settings

### 4. Shell Connection Failed

Add to your `settings.json`:

```json
"terminal.integrated.defaultProfile.osx": "zsh"
```

### 5. "Windsurf is Damaged" (macOS)

```bash
xattr -c "/Applications/Windsurf.app/"
```

### 6. Silent Crash on Launch (Linux)

```bash
sudo chown root:root /path/to/windsurf/chrome-sandbox
sudo chmod 4755 /path/to/windsurf/chrome-sandbox
```

### 7. Dev Tool Cache Cleanup

Supports cleaning caches for: npm, pip, Homebrew, apt/yum/dnf, uv, Maven, Gradle, Yarn, pnpm, NuGet, Selenium/WebDriver, Go modules, Cargo/Rust, conda, CocoaPods, Xcode DerivedData, Docker.

Run the tool and select "Clean Dev Tool Caches" - supports batch cleanup or item-by-item selection.

### 8. System Cache & Junk Cleanup

**macOS:** User caches (`~/Library/Caches`), old logs (30+ days), Trash, old Windsurf backups, old diagnostic reports, DNS cache flush.

**Linux:** User caches (`~/.cache`), system logs (`/var/log` 30+ days), temp files (`/tmp` 7+ days), systemd journal logs, old Windsurf backups, DNS cache flush.

**Windows:** User temp files (`%TEMP%`), Windows temp files (`%SystemRoot%\Temp`, admin required), Recycle Bin, Windows Update cache, old Windsurf backups, old diagnostic reports, DNS cache flush.

### 9. Disk Usage Analysis

Analyze disk space usage including directory sizes, hidden folder rankings, Library subdirectory rankings (macOS), AppData directory usage (Windows), and app container usage (macOS).

### 10. macOS System Data Cleanup

**Dedicated Script:** `macos-safe-cleanup.sh`

**Features:**
- **19 cleanup functions** across 4 safety levels (Low/Medium/Dev/System)
- **Step-by-step confirmation** prompts, skip anytime for safety
- **Estimated 10-15GB space recovery** optimized for macOS system data
- **Won't delete:** Applications, chat history, documents, emails, config files

**Major Cleanup Items:**
- WeChat cache (6.9GB) → Clean in WeChat Settings recommended
- System diagnostic logs (2.7GB) → Pure logs, safe to delete
- Photo analysis cache (3.1GB) → System auto-rebuilds after deletion
- Windsurf WebStorage (1GB) → May affect login state, keep by default
- Telegram cache (1.3GB) → Clean in Telegram Settings recommended
- Homebrew, npm, Maven dev tool caches
- User cache directories, temp files, DNS cache

**Usage:**
```bash
chmod +x macos-safe-cleanup.sh
./macos-safe-cleanup.sh
```

**Safety Levels:**
- **Low Risk:** Pure caches, system auto-rebuilds
- **Medium Risk:** App caches, close apps first recommended
- **Dev Tools:** node_modules, __pycache__, reinstall when needed
- **System Level:** Requires sudo, cleans system logs and temp files

## 🌐 Network Whitelist

If using firewall/VPN/proxy, whitelist these domains:

- `*.codeium.com`
- `*.windsurf.com`
- `*.codeiumdata.com`

## 📁 Important Paths

| Platform | Conversation History | MCP Config |
|----------|---------------------|------------|
| macOS/Linux | `~/.codeium/windsurf/cascade` | `~/.codeium/windsurf/mcp_config.json` |
| Windows | `%USERPROFILE%\.codeium\windsurf\cascade` | `%USERPROFILE%\.codeium\windsurf\mcp_config.json` |

## 📚 References

- [Official Windsurf Troubleshooting](https://docs.windsurf.com/troubleshooting/windsurf-common-issues)
- [Windsurf Terminal Documentation](https://docs.windsurf.com/windsurf/terminal)
- [Windsurf MCP Documentation](https://docs.windsurf.com/windsurf/cascade/mcp)

## ⚠️ Disclaimer

This tool is based on official Windsurf documentation. Please backup important data before use. Clearing Cascade cache will delete conversation history.

## 📄 License

MIT License - Feel free to use, modify, and distribute.

## 🤝 Contributing

Issues and Pull Requests are welcome!

## ⭐ Star History

If this tool helped you, please give it a star! ⭐
