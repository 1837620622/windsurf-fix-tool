#!/bin/bash

# ============================================================================
# Windsurf 修复工具 - macOS 版本
# 用于修复 Windsurf IDE 卡顿、Shell无法连接等常见问题
# 基于官方文档: https://docs.windsurf.com/troubleshooting/windsurf-common-issues
# 作者: 传康KK
# GitHub: https://github.com/1837620622/windsurf-fix-tool
# ============================================================================

# ----------------------------------------------------------------------------
# 颜色定义
# ----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ----------------------------------------------------------------------------
# 路径定义
# ----------------------------------------------------------------------------
CODEIUM_DIR="$HOME/.codeium"
WINDSURF_DIR="$CODEIUM_DIR/windsurf"
CASCADE_DIR="$WINDSURF_DIR/cascade"
WINDSURF_APP="/Applications/Windsurf.app"
BACKUP_DIR="$HOME/.windsurf-backup-$(date +%Y%m%d_%H%M%S)"

# ----------------------------------------------------------------------------
# 工具函数
# ----------------------------------------------------------------------------
print_header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Windsurf 修复工具 - macOS${NC}"
    echo -e "${CYAN}  by 传康KK${NC}"
    echo -e "${CYAN}  github.com/1837620622/windsurf-fix-tool${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

confirm_action() {
    read -p "$(echo -e ${YELLOW}确认执行此操作？[y/N]: ${NC})" choice
    case "$choice" in
        y|Y ) return 0;;
        * ) return 1;;
    esac
}

# ----------------------------------------------------------------------------
# 检测系统信息
# ----------------------------------------------------------------------------
detect_system_info() {
    print_info "正在检测系统信息..."
    
    # 检测处理器类型
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ]; then
        PROCESSOR_TYPE="Apple Silicon (M系列芯片)"
    else
        PROCESSOR_TYPE="Intel"
    fi
    
    # 检测macOS版本
    MACOS_VERSION=$(sw_vers -productVersion)
    
    echo ""
    echo -e "  处理器类型: ${GREEN}$PROCESSOR_TYPE${NC}"
    echo -e "  macOS版本: ${GREEN}$MACOS_VERSION${NC}"
    echo -e "  Windsurf路径: ${GREEN}$WINDSURF_APP${NC}"
    echo ""
}

# ----------------------------------------------------------------------------
# 检查Windsurf是否正在运行
# ----------------------------------------------------------------------------
check_windsurf_running() {
    if pgrep -x "Windsurf" > /dev/null 2>&1; then
        print_warning "检测到 Windsurf 正在运行"
        echo -e "  请先关闭 Windsurf 再执行修复操作"
        read -p "$(echo -e ${YELLOW}是否自动关闭Windsurf？[y/N]: ${NC})" choice
        case "$choice" in
            y|Y )
                pkill -x "Windsurf" 2>/dev/null || true
                sleep 2
                print_success "Windsurf 已关闭"
                ;;
            * )
                print_error "请手动关闭 Windsurf 后重试"
                exit 1
                ;;
        esac
    fi
}

# ----------------------------------------------------------------------------
# 功能1: 清理Cascade缓存
# ----------------------------------------------------------------------------
clean_cascade_cache() {
    print_info "清理 Cascade 缓存..."
    print_warning "此操作将删除对话历史和本地设置！"
    
    if [ ! -d "$CASCADE_DIR" ]; then
        print_info "Cascade 缓存目录不存在，无需清理"
        return 0
    fi
    
    if confirm_action; then
        # 备份
        mkdir -p "$BACKUP_DIR"
        cp -r "$CASCADE_DIR" "$BACKUP_DIR/" 2>/dev/null || true
        print_info "已备份到: $BACKUP_DIR"
        
        # 删除
        rm -rf "$CASCADE_DIR"
        print_success "Cascade 缓存已清理"
    else
        print_info "已取消操作"
    fi
}

# ----------------------------------------------------------------------------
# 功能3: 清理扩展缓存
# ----------------------------------------------------------------------------
clean_extension_cache() {
    print_info "清理扩展缓存..."
    
    CACHE_DIR="$WINDSURF_DIR/CachedData"
    
    if confirm_action; then
        # 清理缓存数据
        if [ -d "$CACHE_DIR" ]; then
            rm -rf "$CACHE_DIR"
            print_success "已清理 CachedData"
        fi
        
        print_success "扩展缓存清理完成"
    else
        print_info "已取消操作"
    fi
}

# ----------------------------------------------------------------------------
# 功能12: 修复"Windsurf已损坏"问题
# ----------------------------------------------------------------------------
fix_damaged_app() {
    print_info "修复 'Windsurf已损坏' 问题..."
    
    if [ ! -d "$WINDSURF_APP" ]; then
        print_error "未找到 Windsurf 应用: $WINDSURF_APP"
        print_info "请确保 Windsurf 已安装在 /Applications 目录"
        return 0
    fi
    
    echo ""
    echo "此操作将执行: xattr -c \"$WINDSURF_APP\""
    echo "用于清除隔离属性，解决macOS安全提示问题"
    echo ""
    
    if confirm_action; then
        xattr -c "$WINDSURF_APP"
        print_success "已清除隔离属性"
        
        # 同时清除可能的代码签名问题
        xattr -cr "$WINDSURF_APP" 2>/dev/null || true
        print_info "提示: 如果问题仍然存在，请尝试重新下载 Windsurf"
    else
        print_info "已取消操作"
    fi
}

# ----------------------------------------------------------------------------
# 功能10: 配置终端设置
# ----------------------------------------------------------------------------
configure_terminal_settings() {
    print_info "配置终端设置..."
    
    SETTINGS_JSON="$HOME/Library/Application Support/Windsurf/User/settings.json"
    
    echo ""
    echo "推荐的终端配置:"
    echo -e "  ${GREEN}\"terminal.integrated.defaultProfile.osx\": \"zsh\"${NC}"
    echo ""
    
    if [ -f "$SETTINGS_JSON" ]; then
        print_info "settings.json 位置: $SETTINGS_JSON"
        
        # 检查是否已配置
        if grep -q "terminal.integrated.defaultProfile.osx" "$SETTINGS_JSON" 2>/dev/null; then
            print_info "终端配置已存在"
            grep "terminal.integrated.defaultProfile" "$SETTINGS_JSON" | head -1
        else
            print_warning "未找到终端配置，建议手动添加"
        fi
    else
        print_warning "未找到 settings.json 文件"
        print_info "Windsurf 可能尚未创建配置文件，请先启动一次 Windsurf"
    fi
}

# ----------------------------------------------------------------------------
# 功能9: 检测zsh主题冲突
# ----------------------------------------------------------------------------
detect_zsh_theme_conflicts() {
    print_info "检测 zsh 主题冲突..."
    
    ZSHRC="$HOME/.zshrc"
    
    if [ ! -f "$ZSHRC" ]; then
        print_info "未找到 .zshrc 文件，跳过检测"
        return 0
    fi
    
    echo ""
    echo "正在检测可能导致终端卡住的配置..."
    echo ""
    
    CONFLICTS_FOUND=0
    
    # 检测Oh My Zsh主题
    if grep -q "ZSH_THEME=" "$ZSHRC" 2>/dev/null; then
        THEME=$(grep "ZSH_THEME=" "$ZSHRC" | grep -v "^#" | head -1)
        if [ -n "$THEME" ]; then
            print_warning "检测到 Oh My Zsh 主题: $THEME"
            CONFLICTS_FOUND=1
        fi
    fi
    
    # 检测Powerlevel10k
    if grep -q "p10k" "$ZSHRC" 2>/dev/null; then
        print_warning "检测到 Powerlevel10k 配置"
        CONFLICTS_FOUND=1
    fi
    
    # 检测oh-my-posh
    if grep -q "oh-my-posh" "$ZSHRC" 2>/dev/null; then
        print_warning "检测到 oh-my-posh 配置"
        CONFLICTS_FOUND=1
    fi
    
    if [ $CONFLICTS_FOUND -eq 1 ]; then
        echo ""
        echo -e "${YELLOW}建议:${NC} 如果终端会话卡住，请尝试在 ~/.zshrc 中注释以下行:"
        echo ""
        echo "  # ZSH_THEME=\"powerlevel10k/powerlevel10k\""
        echo "  # source ~/.p10k.zsh"
        echo "  # eval \"\$(oh-my-posh init zsh)\""
        echo ""
        
        read -p "$(echo -e ${YELLOW}是否创建Windsurf专用的简化zshrc？[y/N]: ${NC})" choice
        case "$choice" in
            y|Y )
                create_windsurf_zshrc
                ;;
        esac
    else
        print_success "未检测到已知的主题冲突"
    fi
}

# ----------------------------------------------------------------------------
# 创建Windsurf专用zshrc
# ----------------------------------------------------------------------------
create_windsurf_zshrc() {
    WINDSURF_ZSHRC="$HOME/.zshrc.windsurf"
    
    cat > "$WINDSURF_ZSHRC" << 'EOF'
# ============================================================================
# Windsurf 专用 zsh 配置
# 此配置文件用于解决复杂主题导致的终端卡住问题
# 使用方法: 在 Windsurf 设置中配置 shell 参数为:
#   "terminal.integrated.shellArgs.osx": ["--rcfile", "~/.zshrc.windsurf"]
# ============================================================================

# 基础环境变量
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export EDITOR="code"
export LANG="en_US.UTF-8"

# 简单提示符
PROMPT='%n@%m %1~ %# '

# 加载用户别名（如果存在）
[ -f ~/.aliases ] && source ~/.aliases

# 历史记录配置
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

# 自动补全
autoload -Uz compinit && compinit
EOF
    
    print_success "已创建 Windsurf 专用 zshrc: $WINDSURF_ZSHRC"
    echo ""
    print_info "使用方法: 在 Windsurf 设置中添加:"
    echo '  "terminal.integrated.shellArgs.osx": ["--rcfile", "~/.zshrc.windsurf"]'
}

# ----------------------------------------------------------------------------
# 功能13: 生成诊断报告
# ----------------------------------------------------------------------------
generate_diagnostic_report() {
    print_info "生成诊断报告..."
    
    REPORT_FILE="$HOME/windsurf-diagnostic-$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=========================================="
        echo "Windsurf 诊断报告"
        echo "生成时间: $(date)"
        echo "=========================================="
        echo ""
        
        echo "## 系统信息"
        echo "处理器架构: $(uname -m)"
        echo "macOS版本: $(sw_vers -productVersion)"
        echo "macOS构建: $(sw_vers -buildVersion)"
        echo ""
        
        echo "## Windsurf 安装状态"
        if [ -d "$WINDSURF_APP" ]; then
            echo "Windsurf.app: 已安装"
            ls -la "$WINDSURF_APP" 2>/dev/null | head -5
        else
            echo "Windsurf.app: 未找到"
        fi
        echo ""
        
        echo "## Codeium 目录状态"
        if [ -d "$CODEIUM_DIR" ]; then
            echo "目录存在: $CODEIUM_DIR"
            du -sh "$CODEIUM_DIR" 2>/dev/null || echo "无法计算大小"
            echo ""
            echo "子目录:"
            ls -la "$CODEIUM_DIR" 2>/dev/null
        else
            echo "目录不存在: $CODEIUM_DIR"
        fi
        echo ""
        
        echo "## Cascade 缓存状态"
        if [ -d "$CASCADE_DIR" ]; then
            echo "目录存在: $CASCADE_DIR"
            du -sh "$CASCADE_DIR" 2>/dev/null || echo "无法计算大小"
        else
            echo "目录不存在: $CASCADE_DIR"
        fi
        echo ""
        
        echo "## Shell 配置"
        echo "默认Shell: $SHELL"
        echo ""
        echo ".zshrc 主题相关配置:"
        grep -E "(ZSH_THEME|p10k|oh-my-posh|PROMPT)" "$HOME/.zshrc" 2>/dev/null || echo "未找到主题配置"
        echo ""
        
        echo "## 网络状态"
        echo "ping codeium.com:"
        ping -c 2 codeium.com 2>/dev/null || echo "无法ping"
        echo ""
        
        echo "## 磁盘空间"
        df -h / 2>/dev/null | head -2
        echo ""
        
    } > "$REPORT_FILE"
    
    print_success "诊断报告已保存: $REPORT_FILE"
}

# ----------------------------------------------------------------------------
# 功能14: 完整修复（执行所有修复步骤）
# ----------------------------------------------------------------------------
full_repair() {
    print_info "执行完整修复..."
    print_warning "此操作将执行所有修复步骤"
    
    if confirm_action; then
        check_windsurf_running
        clean_cascade_cache
        clean_extension_cache
        clean_startup_cache
        fix_damaged_app
        configure_terminal_settings
        detect_zsh_theme_conflicts
        generate_diagnostic_report
        
        echo ""
        print_success "完整修复已完成！"
        print_info "请重新启动 Windsurf"
    else
        print_info "已取消操作"
    fi
}

# ----------------------------------------------------------------------------
# 功能11: 启用Legacy终端
# ----------------------------------------------------------------------------
enable_legacy_terminal() {
    print_info "启用 Legacy 终端配置..."
    
    SETTINGS_JSON="$HOME/Library/Application Support/Windsurf/User/settings.json"
    
    echo ""
    echo "如果专用终端有问题，可以启用 Legacy Terminal Profile"
    echo ""
    echo "请在 Windsurf 设置中搜索 'Legacy Terminal Profile' 并启用"
    echo "或手动编辑 settings.json 添加相关配置"
    echo ""
    print_info "settings.json 位置: $SETTINGS_JSON"
}

# ----------------------------------------------------------------------------
# 功能7: MCP诊断与修复
# ----------------------------------------------------------------------------
diagnose_mcp() {
    print_info "MCP (Model Context Protocol) 诊断..."
    
    MCP_CONFIG="$WINDSURF_DIR/mcp_config.json"
    MCP_CONFIG_OLD="$CODEIUM_DIR/mcp_config.json"
    
    echo ""
    echo -e "${CYAN}MCP 配置文件状态:${NC}"
    echo ""
    
    # 检查新路径的配置文件
    if [ -f "$MCP_CONFIG" ]; then
        print_success "找到 MCP 配置: $MCP_CONFIG"
        echo ""
        echo "配置内容预览:"
        head -30 "$MCP_CONFIG" 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done
        echo ""
        
        # 检查JSON格式是否有效
        if command -v python3 &> /dev/null; then
            if python3 -c "import json; json.load(open('$MCP_CONFIG'))" 2>/dev/null; then
                print_success "MCP 配置 JSON 格式有效"
            else
                print_error "MCP 配置 JSON 格式无效！"
                echo "  这可能导致 MCP 无法加载"
            fi
        fi
    else
        print_warning "未找到 MCP 配置文件: $MCP_CONFIG"
    fi
    
    # 检查旧路径
    if [ -f "$MCP_CONFIG_OLD" ]; then
        print_info "发现旧版 MCP 配置: $MCP_CONFIG_OLD"
    fi
    
    echo ""
    echo -e "${CYAN}MCP 常见问题排查:${NC}"
    echo ""
    echo "  1. 检查 Node.js 是否安装"
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version 2>/dev/null)
        print_success "Node.js 已安装: $NODE_VERSION"
    else
        print_warning "未找到 Node.js，部分 MCP 服务器需要 Node.js"
    fi
    
    echo ""
    echo "  2. 检查 npx 是否可用"
    if command -v npx &> /dev/null; then
        print_success "npx 可用"
    else
        print_warning "未找到 npx，无法运行基于 npm 的 MCP 服务器"
    fi
    
    echo ""
    echo "  3. 检查 Python/uvx 是否可用（部分MCP需要）"
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>/dev/null)
        print_success "Python3 已安装: $PYTHON_VERSION"
    else
        print_warning "未找到 Python3"
    fi
    
    if command -v uvx &> /dev/null; then
        print_success "uvx 可用"
    else
        print_info "uvx 未安装（某些MCP可能需要）"
    fi
    
    echo ""
    echo -e "${CYAN}MCP 无法自动加载的常见解决方案:${NC}"
    echo ""
    echo "  1. 在 Windsurf 中点击 MCPs 图标，手动刷新"
    echo "  2. 检查 mcp_config.json 格式是否正确"
    echo "  3. 确保所需的运行时（Node.js/Python）已安装"
    echo "  4. 检查环境变量（如 API keys）是否正确配置"
    echo "  5. 查看 Windsurf 输出日志检查错误信息"
    echo ""
}

# ----------------------------------------------------------------------------
# 功能2: 清理启动缓存（解决启动卡顿）- 不会清理对话历史
# ----------------------------------------------------------------------------
clean_startup_cache() {
    print_info "清理启动相关缓存（解决启动卡顿）..."
    
    echo ""
    echo "此操作将清理以下缓存以加速启动:"
    echo "  - GPUCache (GPU渲染缓存)"
    echo "  - CachedData (编辑器缓存数据)"
    echo "  - CachedExtensions (扩展缓存)"
    echo "  - Code Cache (代码缓存)"
    echo "  - 7天以上的日志文件"
    echo ""
    print_success "此操作 不会 清理对话历史！"
    echo ""
    
    if confirm_action; then
        check_windsurf_running
        
        # 备份
        mkdir -p "$BACKUP_DIR"
        
        # 清理 GPU 缓存
        GPU_CACHE="$HOME/Library/Application Support/Windsurf/GPUCache"
        if [ -d "$GPU_CACHE" ]; then
            rm -rf "$GPU_CACHE"
            print_success "已清理 GPUCache"
        fi
        
        # 清理 CachedData
        CACHED_DATA="$WINDSURF_DIR/CachedData"
        if [ -d "$CACHED_DATA" ]; then
            rm -rf "$CACHED_DATA"
            print_success "已清理 CachedData"
        fi
        
        # 清理 CachedExtensions
        CACHED_EXT="$WINDSURF_DIR/CachedExtensions"
        if [ -d "$CACHED_EXT" ]; then
            rm -rf "$CACHED_EXT"
            print_success "已清理 CachedExtensions"
        fi
        
        # 清理 Code Cache
        CODE_CACHE="$HOME/Library/Application Support/Windsurf/Code Cache"
        if [ -d "$CODE_CACHE" ]; then
            rm -rf "$CODE_CACHE"
            print_success "已清理 Code Cache"
        fi
        
        # 清理 logs
        LOGS_DIR="$HOME/Library/Application Support/Windsurf/logs"
        if [ -d "$LOGS_DIR" ]; then
            # 只清理超过7天的日志
            find "$LOGS_DIR" -type f -mtime +7 -delete 2>/dev/null
            print_success "已清理旧日志文件"
        fi
        
        echo ""
        print_success "启动缓存清理完成！"
        print_info "重启 Windsurf 后启动速度应该会改善"
    else
        print_info "已取消操作"
    fi
}

# ----------------------------------------------------------------------------
# 功能8: 重置MCP配置
# ----------------------------------------------------------------------------
reset_mcp_config() {
    print_info "重置 MCP 配置..."
    
    MCP_CONFIG="$WINDSURF_DIR/mcp_config.json"
    
    echo ""
    print_warning "此操作将备份并重置 MCP 配置文件"
    echo "  你需要重新配置 MCP 服务器"
    echo ""
    
    if [ ! -f "$MCP_CONFIG" ]; then
        print_info "MCP 配置文件不存在"
        return 0
    fi
    
    if confirm_action; then
        # 备份
        mkdir -p "$BACKUP_DIR"
        cp "$MCP_CONFIG" "$BACKUP_DIR/mcp_config.json.bak"
        print_info "已备份到: $BACKUP_DIR/mcp_config.json.bak"
        
        # 创建空的配置
        cat > "$MCP_CONFIG" << 'EOF'
{
  "mcpServers": {}
}
EOF
        print_success "MCP 配置已重置"
        print_info "请在 Windsurf 中重新添加 MCP 服务器"
    else
        print_info "已取消操作"
    fi
}

# ----------------------------------------------------------------------------
# 功能4: 清理开发工具缓存（npm/pip/Homebrew/Maven等）
# ----------------------------------------------------------------------------
clean_dev_caches() {
    print_info "扫描开发工具缓存..."
    
    echo ""
    echo -e "${CYAN}正在检测各类开发工具缓存大小...${NC}"
    echo ""
    
    TOTAL_SIZE=0
    CLEANABLE_ITEMS=()
    
    # npm 缓存
    NPM_CACHE="$HOME/.npm"
    if [ -d "$NPM_CACHE" ]; then
        SIZE=$(du -sm "$NPM_CACHE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[npm 缓存]${NC} ~/.npm - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        CLEANABLE_ITEMS+=("npm")
    fi
    
    # pip 缓存
    PIP_CACHE="$HOME/Library/Caches/pip"
    if [ -d "$PIP_CACHE" ]; then
        SIZE=$(du -sm "$PIP_CACHE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[pip 缓存]${NC} ~/Library/Caches/pip - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        CLEANABLE_ITEMS+=("pip")
    fi
    
    # Homebrew 缓存
    BREW_CACHE="$HOME/Library/Caches/Homebrew"
    if [ -d "$BREW_CACHE" ]; then
        SIZE=$(du -sm "$BREW_CACHE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[Homebrew 缓存]${NC} ~/Library/Caches/Homebrew - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        CLEANABLE_ITEMS+=("brew")
    fi
    
    # uv 缓存（Python包管理器）
    UV_CACHE="$HOME/.cache/uv"
    if [ -d "$UV_CACHE" ]; then
        SIZE=$(du -sm "$UV_CACHE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[uv 缓存]${NC} ~/.cache/uv - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        CLEANABLE_ITEMS+=("uv")
    fi
    
    # Maven 缓存
    MAVEN_CACHE="$HOME/.m2/repository"
    if [ -d "$MAVEN_CACHE" ]; then
        SIZE=$(du -sm "$MAVEN_CACHE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[Maven 缓存]${NC} ~/.m2/repository - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        CLEANABLE_ITEMS+=("maven")
    fi
    
    # Gradle 缓存
    GRADLE_CACHE="$HOME/.gradle/caches"
    if [ -d "$GRADLE_CACHE" ]; then
        SIZE=$(du -sm "$GRADLE_CACHE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[Gradle 缓存]${NC} ~/.gradle/caches - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        CLEANABLE_ITEMS+=("gradle")
    fi
    
    # Yarn 缓存
    YARN_CACHE="$HOME/Library/Caches/Yarn"
    if [ -d "$YARN_CACHE" ]; then
        SIZE=$(du -sm "$YARN_CACHE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[Yarn 缓存]${NC} ~/Library/Caches/Yarn - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        CLEANABLE_ITEMS+=("yarn")
    fi
    
    # pnpm 缓存
    PNPM_CACHE="$HOME/Library/pnpm"
    PNPM_STORE="$HOME/.pnpm-store"
    PNPM_SIZE=0
    if [ -d "$PNPM_CACHE" ]; then
        SIZE=$(du -sm "$PNPM_CACHE" 2>/dev/null | awk '{print $1}')
        PNPM_SIZE=$((PNPM_SIZE + SIZE))
    fi
    if [ -d "$PNPM_STORE" ]; then
        SIZE=$(du -sm "$PNPM_STORE" 2>/dev/null | awk '{print $1}')
        PNPM_SIZE=$((PNPM_SIZE + SIZE))
    fi
    if [ $PNPM_SIZE -gt 0 ]; then
        echo -e "  ${GREEN}[pnpm 缓存]${NC} ~/Library/pnpm + ~/.pnpm-store - ${YELLOW}${PNPM_SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + PNPM_SIZE))
        CLEANABLE_ITEMS+=("pnpm")
    fi
    
    # Selenium/WebDriver 缓存
    SELENIUM_CACHE="$HOME/.cache/selenium"
    WDM_CACHE="$HOME/.wdm"
    SELENIUM_SIZE=0
    if [ -d "$SELENIUM_CACHE" ]; then
        SIZE=$(du -sm "$SELENIUM_CACHE" 2>/dev/null | awk '{print $1}')
        SELENIUM_SIZE=$((SELENIUM_SIZE + SIZE))
    fi
    if [ -d "$WDM_CACHE" ]; then
        SIZE=$(du -sm "$WDM_CACHE" 2>/dev/null | awk '{print $1}')
        SELENIUM_SIZE=$((SELENIUM_SIZE + SIZE))
    fi
    if [ $SELENIUM_SIZE -gt 0 ]; then
        echo -e "  ${GREEN}[Selenium/WebDriver]${NC} ~/.cache/selenium + ~/.wdm - ${YELLOW}${SELENIUM_SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SELENIUM_SIZE))
        CLEANABLE_ITEMS+=("selenium")
    fi
    
    # undetected_chromedriver 缓存
    UC_CACHE="$HOME/Library/Application Support/undetected_chromedriver"
    if [ -d "$UC_CACHE" ]; then
        SIZE=$(du -sm "$UC_CACHE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[undetected_chromedriver]${NC} - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        CLEANABLE_ITEMS+=("uc")
    fi
    
    # Go 缓存
    GO_CACHE="$HOME/go/pkg/mod/cache"
    if [ -d "$GO_CACHE" ]; then
        SIZE=$(du -sm "$GO_CACHE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[Go 模块缓存]${NC} ~/go/pkg/mod/cache - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        CLEANABLE_ITEMS+=("go")
    fi
    
    # Cargo/Rust 缓存
    CARGO_CACHE="$HOME/.cargo/registry"
    if [ -d "$CARGO_CACHE" ]; then
        SIZE=$(du -sm "$CARGO_CACHE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[Cargo 缓存]${NC} ~/.cargo/registry - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        CLEANABLE_ITEMS+=("cargo")
    fi
    
    # conda 缓存
    for CONDA_DIR in "$HOME/miniconda3/pkgs" "$HOME/anaconda3/pkgs" "$HOME/opt/anaconda3/pkgs"; do
        if [ -d "$CONDA_DIR" ]; then
            SIZE=$(du -sm "$CONDA_DIR" 2>/dev/null | awk '{print $1}')
            echo -e "  ${GREEN}[conda 包缓存]${NC} $CONDA_DIR - ${YELLOW}${SIZE}MB${NC}"
            TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
            CLEANABLE_ITEMS+=("conda")
            break
        fi
    done
    
    # CocoaPods 缓存
    COCOAPODS_CACHE="$HOME/Library/Caches/CocoaPods"
    if [ -d "$COCOAPODS_CACHE" ]; then
        SIZE=$(du -sm "$COCOAPODS_CACHE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[CocoaPods 缓存]${NC} ~/Library/Caches/CocoaPods - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        CLEANABLE_ITEMS+=("cocoapods")
    fi
    
    # Xcode DerivedData
    XCODE_DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
    if [ -d "$XCODE_DERIVED" ]; then
        SIZE=$(du -sm "$XCODE_DERIVED" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[Xcode DerivedData]${NC} - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        CLEANABLE_ITEMS+=("xcode")
    fi
    
    # Google Chrome 缓存
    CHROME_CACHE="$HOME/Library/Caches/Google"
    if [ -d "$CHROME_CACHE" ]; then
        SIZE=$(du -sm "$CHROME_CACHE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[Google Chrome 缓存]${NC} ~/Library/Caches/Google - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        CLEANABLE_ITEMS+=("chrome")
    fi
    
    echo ""
    echo -e "  ${CYAN}可清理总计: ${YELLOW}${TOTAL_SIZE}MB${NC}"
    echo ""
    
    if [ ${#CLEANABLE_ITEMS[@]} -eq 0 ]; then
        print_info "未检测到可清理的开发工具缓存"
        return 0
    fi
    
    echo -e "${YELLOW}请选择清理方式:${NC}"
    echo "  1) 全部清理（推荐安全项）"
    echo "  2) 逐项选择清理"
    echo "  3) 取消"
    echo ""
    read -p "$(echo -e ${CYAN}请选择 [1-3]: ${NC})" clean_choice
    
    case "$clean_choice" in
        1)
            # 全部清理安全项
            for item in "${CLEANABLE_ITEMS[@]}"; do
                case "$item" in
                    npm)
                        if command -v npm &> /dev/null; then
                            npm cache clean --force 2>/dev/null
                        else
                            rm -rf "$NPM_CACHE/_cacache" 2>/dev/null
                        fi
                        print_success "npm 缓存已清理"
                        ;;
                    pip)
                        if command -v pip3 &> /dev/null; then
                            pip3 cache purge 2>/dev/null
                        else
                            rm -rf "$PIP_CACHE" 2>/dev/null
                        fi
                        print_success "pip 缓存已清理"
                        ;;
                    brew)
                        if command -v brew &> /dev/null; then
                            brew cleanup -s 2>/dev/null
                            brew autoremove 2>/dev/null
                        fi
                        print_success "Homebrew 缓存已清理"
                        ;;
                    uv)
                        rm -rf "$UV_CACHE" 2>/dev/null
                        print_success "uv 缓存已清理"
                        ;;
                    maven)
                        print_warning "Maven 缓存跳过（删除后需重新下载依赖，建议手动清理）"
                        ;;
                    gradle)
                        print_warning "Gradle 缓存跳过（删除后需重新下载依赖，建议手动清理）"
                        ;;
                    yarn)
                        if command -v yarn &> /dev/null; then
                            yarn cache clean 2>/dev/null
                        else
                            rm -rf "$YARN_CACHE" 2>/dev/null
                        fi
                        print_success "Yarn 缓存已清理"
                        ;;
                    pnpm)
                        if command -v pnpm &> /dev/null; then
                            pnpm store prune 2>/dev/null
                        fi
                        print_success "pnpm 缓存已清理"
                        ;;
                    selenium)
                        rm -rf "$SELENIUM_CACHE" 2>/dev/null
                        rm -rf "$WDM_CACHE" 2>/dev/null
                        print_success "Selenium/WebDriver 缓存已清理"
                        ;;
                    uc)
                        rm -rf "$UC_CACHE" 2>/dev/null
                        print_success "undetected_chromedriver 缓存已清理"
                        ;;
                    go)
                        if command -v go &> /dev/null; then
                            go clean -modcache 2>/dev/null
                        fi
                        print_success "Go 模块缓存已清理"
                        ;;
                    cargo)
                        print_warning "Cargo 缓存跳过（建议使用 cargo-cache 工具清理）"
                        ;;
                    conda)
                        if command -v conda &> /dev/null; then
                            conda clean --all -y 2>/dev/null
                        fi
                        print_success "conda 缓存已清理"
                        ;;
                    cocoapods)
                        rm -rf "$COCOAPODS_CACHE" 2>/dev/null
                        print_success "CocoaPods 缓存已清理"
                        ;;
                    xcode)
                        rm -rf "$XCODE_DERIVED" 2>/dev/null
                        print_success "Xcode DerivedData 已清理"
                        ;;
                    chrome)
                        rm -rf "$CHROME_CACHE" 2>/dev/null
                        print_success "Google Chrome 缓存已清理"
                        ;;
                esac
            done
            echo ""
            print_success "开发工具缓存清理完成！"
            ;;
        2)
            # 逐项选择
            for item in "${CLEANABLE_ITEMS[@]}"; do
                case "$item" in
                    npm) label="npm 缓存" ;;
                    pip) label="pip 缓存" ;;
                    brew) label="Homebrew 缓存" ;;
                    uv) label="uv 缓存" ;;
                    maven) label="Maven 缓存" ;;
                    gradle) label="Gradle 缓存" ;;
                    yarn) label="Yarn 缓存" ;;
                    pnpm) label="pnpm 缓存" ;;
                    selenium) label="Selenium/WebDriver 缓存" ;;
                    uc) label="undetected_chromedriver 缓存" ;;
                    go) label="Go 模块缓存" ;;
                    cargo) label="Cargo 缓存" ;;
                    conda) label="conda 包缓存" ;;
                    cocoapods) label="CocoaPods 缓存" ;;
                    xcode) label="Xcode DerivedData" ;;
                    chrome) label="Google Chrome 缓存" ;;
                    *) label="$item" ;;
                esac
                
                read -p "$(echo -e ${YELLOW}清理 $label？[y/N]: ${NC})" yn
                if [ "$yn" = "y" ] || [ "$yn" = "Y" ]; then
                    case "$item" in
                        npm)
                            if command -v npm &> /dev/null; then npm cache clean --force 2>/dev/null
                            else rm -rf "$NPM_CACHE/_cacache" 2>/dev/null; fi
                            ;;
                        pip)
                            if command -v pip3 &> /dev/null; then pip3 cache purge 2>/dev/null
                            else rm -rf "$PIP_CACHE" 2>/dev/null; fi
                            ;;
                        brew)
                            if command -v brew &> /dev/null; then brew cleanup -s 2>/dev/null; brew autoremove 2>/dev/null; fi
                            ;;
                        uv) rm -rf "$UV_CACHE" 2>/dev/null ;;
                        maven) rm -rf "$MAVEN_CACHE" 2>/dev/null ;;
                        gradle) rm -rf "$GRADLE_CACHE" 2>/dev/null ;;
                        yarn)
                            if command -v yarn &> /dev/null; then yarn cache clean 2>/dev/null
                            else rm -rf "$YARN_CACHE" 2>/dev/null; fi
                            ;;
                        pnpm)
                            if command -v pnpm &> /dev/null; then pnpm store prune 2>/dev/null; fi
                            ;;
                        selenium) rm -rf "$SELENIUM_CACHE" "$WDM_CACHE" 2>/dev/null ;;
                        uc) rm -rf "$UC_CACHE" 2>/dev/null ;;
                        go)
                            if command -v go &> /dev/null; then go clean -modcache 2>/dev/null; fi
                            ;;
                        cargo) rm -rf "$CARGO_CACHE" 2>/dev/null ;;
                        conda)
                            if command -v conda &> /dev/null; then conda clean --all -y 2>/dev/null; fi
                            ;;
                        cocoapods) rm -rf "$COCOAPODS_CACHE" 2>/dev/null ;;
                        xcode) rm -rf "$XCODE_DERIVED" 2>/dev/null ;;
                        chrome) rm -rf "$CHROME_CACHE" 2>/dev/null ;;
                    esac
                    print_success "$label 已清理"
                fi
            done
            ;;
        *)
            print_info "已取消操作"
            ;;
    esac
}

# ----------------------------------------------------------------------------
# 功能5: 清理macOS系统缓存
# ----------------------------------------------------------------------------
clean_system_caches() {
    print_info "扫描 macOS 系统缓存..."
    
    echo ""
    echo -e "${CYAN}正在检测系统级缓存...${NC}"
    echo ""
    
    TOTAL_SIZE=0
    
    # ~/Library/Caches 各应用缓存
    USER_CACHE="$HOME/Library/Caches"
    if [ -d "$USER_CACHE" ]; then
        SIZE=$(du -sm "$USER_CACHE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[用户缓存]${NC} ~/Library/Caches - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        
        # 列出 Top 10 大缓存目录
        echo -e "    ${CYAN}Top 10 缓存目录:${NC}"
        du -sm "$USER_CACHE"/*/ 2>/dev/null | sort -rn | head -10 | while read size dir; do
            dirname=$(basename "$dir")
            echo -e "      $dirname - ${YELLOW}${size}MB${NC}"
        done
        echo ""
    fi
    
    # ~/Library/Logs 日志文件
    USER_LOGS="$HOME/Library/Logs"
    if [ -d "$USER_LOGS" ]; then
        SIZE=$(du -sm "$USER_LOGS" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[用户日志]${NC} ~/Library/Logs - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
    fi
    
    # 废纸篓
    TRASH="$HOME/.Trash"
    if [ -d "$TRASH" ] && [ "$(ls -A "$TRASH" 2>/dev/null)" ]; then
        SIZE=$(du -sm "$TRASH" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[废纸篓]${NC} ~/.Trash - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
    fi
    
    # Windsurf 旧备份目录
    BACKUP_COUNT=0
    BACKUP_SIZE=0
    for bdir in "$HOME"/.windsurf-backup-*; do
        if [ -d "$bdir" ]; then
            BACKUP_COUNT=$((BACKUP_COUNT + 1))
            SIZE=$(du -sm "$bdir" 2>/dev/null | awk '{print $1}')
            BACKUP_SIZE=$((BACKUP_SIZE + SIZE))
        fi
    done
    if [ $BACKUP_COUNT -gt 0 ]; then
        echo -e "  ${GREEN}[Windsurf 旧备份]${NC} ${BACKUP_COUNT}个备份目录 - ${YELLOW}${BACKUP_SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + BACKUP_SIZE))
    fi
    
    # 旧诊断报告
    DIAG_COUNT=$(ls "$HOME"/windsurf-diagnostic-*.txt 2>/dev/null | wc -l | tr -d ' ')
    if [ "$DIAG_COUNT" -gt 0 ] 2>/dev/null; then
        echo -e "  ${GREEN}[旧诊断报告]${NC} ${DIAG_COUNT}个文件"
    fi
    
    # DNS 缓存
    echo -e "  ${GREEN}[DNS 缓存]${NC} 系统DNS缓存（可刷新）"
    
    echo ""
    echo -e "  ${CYAN}系统缓存总计: ${YELLOW}${TOTAL_SIZE}MB${NC}"
    echo ""
    
    echo -e "${YELLOW}请选择清理项目:${NC}"
    echo "  1) 清理用户缓存（~/Library/Caches，排除系统关键缓存）"
    echo "  2) 清理旧日志文件（超过30天）"
    echo "  3) 清空废纸篓"
    echo "  4) 清理 Windsurf 旧备份目录"
    echo "  5) 清理旧诊断报告"
    echo "  6) 刷新 DNS 缓存"
    echo "  7) 全部执行（安全项）"
    echo "  0) 取消"
    echo ""
    read -p "$(echo -e ${CYAN}请选择 [0-7]: ${NC})" sys_choice
    
    case "$sys_choice" in
        1)
            print_warning "将清理用户缓存目录（排除 Homebrew 等重要缓存）"
            if confirm_action; then
                # 清理用户缓存，但排除一些重要的
                find "$USER_CACHE" -mindepth 1 -maxdepth 1 -type d \
                    ! -name "Homebrew" \
                    ! -name "com.apple.Safari" \
                    ! -name "CloudKit" \
                    -exec rm -rf {} + 2>/dev/null
                print_success "用户缓存已清理"
            fi
            ;;
        2)
            find "$USER_LOGS" -type f -mtime +30 -delete 2>/dev/null
            print_success "超过30天的旧日志已清理"
            ;;
        3)
            if confirm_action; then
                rm -rf "$TRASH"/* 2>/dev/null
                print_success "废纸篓已清空"
            fi
            ;;
        4)
            if [ $BACKUP_COUNT -gt 0 ]; then
                print_info "将删除 ${BACKUP_COUNT} 个 Windsurf 旧备份目录"
                if confirm_action; then
                    rm -rf "$HOME"/.windsurf-backup-* 2>/dev/null
                    print_success "Windsurf 旧备份已清理"
                fi
            else
                print_info "没有旧备份需要清理"
            fi
            ;;
        5)
            rm -f "$HOME"/windsurf-diagnostic-*.txt 2>/dev/null
            print_success "旧诊断报告已清理"
            ;;
        6)
            sudo dscacheutil -flushcache 2>/dev/null
            sudo killall -HUP mDNSResponder 2>/dev/null
            print_success "DNS 缓存已刷新"
            ;;
        7)
            print_info "执行全部安全清理项..."
            
            # 清理旧日志
            find "$USER_LOGS" -type f -mtime +30 -delete 2>/dev/null
            print_success "旧日志已清理"
            
            # 清理废纸篓
            rm -rf "$TRASH"/* 2>/dev/null
            print_success "废纸篓已清空"
            
            # 清理旧备份
            if [ $BACKUP_COUNT -gt 0 ]; then
                rm -rf "$HOME"/.windsurf-backup-* 2>/dev/null
                print_success "Windsurf 旧备份已清理"
            fi
            
            # 清理旧诊断报告
            rm -f "$HOME"/windsurf-diagnostic-*.txt 2>/dev/null
            print_success "旧诊断报告已清理"
            
            # 刷新DNS
            sudo dscacheutil -flushcache 2>/dev/null
            sudo killall -HUP mDNSResponder 2>/dev/null
            print_success "DNS 缓存已刷新"
            
            echo ""
            print_success "系统缓存清理完成！"
            ;;
        *)
            print_info "已取消操作"
            ;;
    esac
}

# ----------------------------------------------------------------------------
# 功能6: 磁盘空间分析
# ----------------------------------------------------------------------------
analyze_disk_usage() {
    print_info "分析磁盘空间使用情况..."
    
    echo ""
    echo -e "${CYAN}========== 磁盘空间概览 ==========${NC}"
    echo ""
    
    # 磁盘总体使用
    df -h / | awk 'NR==2{printf "  磁盘总容量: %s | 已使用: %s | 可用: %s | 使用率: %s\n", $2, $3, $4, $5}'
    echo ""
    
    # 用户主目录
    HOME_SIZE=$(du -sh "$HOME" 2>/dev/null | awk '{print $1}')
    echo -e "  ${CYAN}用户主目录:${NC} ${YELLOW}$HOME_SIZE${NC}"
    echo ""
    
    # 主要目录大小
    echo -e "  ${CYAN}主要目录占用:${NC}"
    echo ""
    
    for dir in "Library" "Downloads" "Documents" "Desktop" "Movies" "Music" "Pictures"; do
        if [ -d "$HOME/$dir" ]; then
            SIZE=$(du -sh "$HOME/$dir" 2>/dev/null | awk '{print $1}')
            printf "    %-15s %s\n" "$dir" "$SIZE"
        fi
    done
    echo ""
    
    # 隐藏目录 Top 10
    echo -e "  ${CYAN}隐藏目录 Top 10:${NC}"
    echo ""
    du -sm "$HOME"/.[!.]* 2>/dev/null | sort -rn | head -10 | while read size dir; do
        dirname=$(basename "$dir")
        printf "    %-30s %sMB\n" "$dirname" "$size"
    done
    echo ""
    
    # ~/Library 子目录 Top 10
    echo -e "  ${CYAN}~/Library 子目录 Top 10:${NC}"
    echo ""
    du -sm "$HOME"/Library/*/ 2>/dev/null | sort -rn | head -10 | while read size dir; do
        dirname=$(basename "$dir")
        printf "    %-30s %sMB\n" "$dirname" "$size"
    done
    echo ""
    
    # 应用容器 Top 10
    CONTAINERS="$HOME/Library/Containers"
    if [ -d "$CONTAINERS" ]; then
        echo -e "  ${CYAN}应用容器 Top 10 (~/Library/Containers):${NC}"
        echo ""
        du -sm "$CONTAINERS"/*/ 2>/dev/null | sort -rn | head -10 | while read size dir; do
            dirname=$(basename "$dir")
            printf "    %-45s %sMB\n" "$dirname" "$size"
        done
        echo ""
    fi
    
    print_info "分析完成。大型应用缓存建议在对应应用内清理（如微信、QQ等）"
}

# ----------------------------------------------------------------------------
# 主菜单
# ----------------------------------------------------------------------------
show_menu() {
    echo ""
    echo -e "${CYAN}请选择修复选项:${NC}"
    echo ""
    echo -e "${YELLOW}== Windsurf 缓存清理 ==${NC}"
    echo "  1) 清理 Cascade 缓存 (会清理对话历史)"
    echo "  2) 清理启动缓存 (不清理对话历史，推荐)"
    echo "  3) 清理扩展缓存 (不清理对话历史)"
    echo ""
    echo -e "${YELLOW}== 系统缓存清理 ==${NC}"
    echo "  4) 清理开发工具缓存 (npm/pip/Homebrew/Maven等)"
    echo "  5) 清理 macOS 系统缓存 (日志/废纸篓/旧备份等)"
    echo "  6) 磁盘空间分析"
    echo ""
    echo -e "${YELLOW}== MCP 相关 ==${NC}"
    echo "  7) MCP 诊断 (检查MCP加载问题)"
    echo "  8) 重置 MCP 配置"
    echo ""
    echo -e "${YELLOW}== 终端相关 ==${NC}"
    echo "  9) 检测 zsh 主题冲突"
    echo "  10) 配置终端设置"
    echo "  11) 启用 Legacy 终端"
    echo ""
    echo -e "${YELLOW}== 其他 ==${NC}"
    echo "  12) 修复 'Windsurf已损坏' 问题"
    echo "  13) 生成诊断报告"
    echo "  14) 完整修复 (执行所有步骤)"
    echo ""
    echo "  0) 退出"
    echo ""
    read -p "$(echo -e ${CYAN}请输入选项 [0-14]: ${NC})" choice
    
    case $choice in
        1) check_windsurf_running; clean_cascade_cache ;;
        2) clean_startup_cache ;;
        3) check_windsurf_running; clean_extension_cache ;;
        4) clean_dev_caches ;;
        5) clean_system_caches ;;
        6) analyze_disk_usage ;;
        7) diagnose_mcp ;;
        8) reset_mcp_config ;;
        9) detect_zsh_theme_conflicts ;;
        10) configure_terminal_settings ;;
        11) enable_legacy_terminal ;;
        12) fix_damaged_app ;;
        13) generate_diagnostic_report ;;
        14) full_repair ;;
        0) 
            echo ""
            print_info "感谢使用 Windsurf 修复工具"
            exit 0 
            ;;
        *) 
            print_error "无效选项"
            ;;
    esac
}

# ----------------------------------------------------------------------------
# 主程序入口
# ----------------------------------------------------------------------------
main() {
    print_header
    detect_system_info
    
    while true; do
        show_menu
        echo ""
        read -p "$(echo -e ${CYAN}按回车键继续...${NC})"
    done
}

# 执行主程序
main
