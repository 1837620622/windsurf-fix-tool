#!/bin/bash

# ============================================================================
# Windsurf 修复工具 - macOS 版本
# 用于修复 Windsurf IDE 卡顿、Shell无法连接等常见问题
# 基于官方文档: https://docs.windsurf.com/troubleshooting/windsurf-common-issues
# ============================================================================

set -e

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
# 功能2: 清理扩展缓存
# ----------------------------------------------------------------------------
clean_extension_cache() {
    print_info "清理扩展缓存..."
    
    EXTENSIONS_DIR="$WINDSURF_DIR/extensions"
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
# 功能3: 修复"Windsurf已损坏"问题
# ----------------------------------------------------------------------------
fix_damaged_app() {
    print_info "修复 'Windsurf已损坏' 问题..."
    
    if [ ! -d "$WINDSURF_APP" ]; then
        print_error "未找到 Windsurf 应用: $WINDSURF_APP"
        print_info "请确保 Windsurf 已安装在 /Applications 目录"
        return 1
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
# 功能4: 配置终端设置
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
# 功能5: 检测zsh主题冲突
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
# 功能6: 生成诊断报告
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
# 功能7: 完整修复（执行所有修复步骤）
# ----------------------------------------------------------------------------
full_repair() {
    print_info "执行完整修复..."
    print_warning "此操作将执行所有修复步骤"
    
    if confirm_action; then
        check_windsurf_running
        clean_cascade_cache
        clean_extension_cache
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
# 功能8: 启用Legacy终端
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
# 功能9: MCP诊断与修复
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
# 功能10: 清理启动缓存（解决启动卡顿）- 不会清理对话历史
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
# 功能11: 重置MCP配置
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
# 主菜单
# ----------------------------------------------------------------------------
show_menu() {
    echo ""
    echo -e "${CYAN}请选择修复选项:${NC}"
    echo ""
    echo -e "${YELLOW}== 缓存清理 ==${NC}"
    echo "  1) 清理 Cascade 缓存 (会清理对话历史)"
    echo "  2) 清理启动缓存 (不清理对话历史，推荐)"
    echo "  3) 清理扩展缓存 (不清理对话历史)"
    echo ""
    echo -e "${YELLOW}== MCP 相关 ==${NC}"
    echo "  4) MCP 诊断 (检查MCP加载问题)"
    echo "  5) 重置 MCP 配置"
    echo ""
    echo -e "${YELLOW}== 终端相关 ==${NC}"
    echo "  6) 检测 zsh 主题冲突"
    echo "  7) 配置终端设置"
    echo "  8) 启用 Legacy 终端"
    echo ""
    echo -e "${YELLOW}== 其他 ==${NC}"
    echo "  9) 修复 'Windsurf已损坏' 问题"
    echo "  10) 生成诊断报告"
    echo "  11) 完整修复 (执行所有步骤)"
    echo ""
    echo "  0) 退出"
    echo ""
    read -p "$(echo -e ${CYAN}请输入选项 [0-11]: ${NC})" choice
    
    case $choice in
        1) check_windsurf_running; clean_cascade_cache ;;
        2) clean_startup_cache ;;
        3) check_windsurf_running; clean_extension_cache ;;
        4) diagnose_mcp ;;
        5) reset_mcp_config ;;
        6) detect_zsh_theme_conflicts ;;
        7) configure_terminal_settings ;;
        8) enable_legacy_terminal ;;
        9) fix_damaged_app ;;
        10) generate_diagnostic_report ;;
        11) full_repair ;;
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
