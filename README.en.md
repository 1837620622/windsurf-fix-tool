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

## 🖥️ Supported Platforms

| Platform | Script | Usage |
|----------|--------|-------|
| macOS | `fix-windsurf-mac.sh` | `./fix-windsurf-mac.sh` |
| Linux | `fix-windsurf-linux.sh` | `./fix-windsurf-linux.sh` |
| Windows | `fix-windsurf-win.ps1` | Run in PowerShell (Admin) |

## 🚀 Quick Start

### macOS

```bash
git clone https://github.com/YOUR_USERNAME/windsurf-fix-tool.git
cd windsurf-fix-tool
chmod +x fix-windsurf-mac.sh
./fix-windsurf-mac.sh
```

### Linux

```bash
git clone https://github.com/YOUR_USERNAME/windsurf-fix-tool.git
cd windsurf-fix-tool
chmod +x fix-windsurf-linux.sh
./fix-windsurf-linux.sh
```

### Windows

```powershell
git clone https://github.com/YOUR_USERNAME/windsurf-fix-tool.git
cd windsurf-fix-tool
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\fix-windsurf-win.ps1
```

## 📋 Common Issues & Solutions

### 1. Slow Startup / Lag

**Recommended:** Run "Clean Startup Cache" (Option 2)

This clears GPU cache, code cache, and extension cache **without** affecting your conversation history.

```bash
# Manual cleanup (macOS)
rm -rf ~/Library/Application\ Support/Windsurf/GPUCache
rm -rf ~/Library/Application\ Support/Windsurf/Code\ Cache
rm -rf ~/.codeium/windsurf/CachedData
```

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
