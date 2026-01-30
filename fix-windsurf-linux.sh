#!/bin/bash

# ============================================================================
# Windsurf 修复工具 - Linux 版本
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
BACKUP_DIR="$HOME/.windsurf-backup-$(date +%Y%m%d_%H%M%S)"

# 尝试查找Windsurf安装路径
WINDSURF_BIN=""
for path in "/opt/Windsurf" "/usr/share/windsurf" "$HOME/.local/share/windsurf" "/usr/local/bin/windsurf"; do
    if [ -e "$path" ]; then
        WINDSURF_BIN="$path"
        break
    fi
done

# ----------------------------------------------------------------------------
# 工具函数
# ----------------------------------------------------------------------------
print_header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Windsurf 修复工具 - Linux${NC}"
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
    
    # 检测发行版
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$NAME $VERSION_ID"
    else
        DISTRO="Unknown"
    fi
    
    # 检测内核版本
    KERNEL=$(uname -r)
    
    # 检测架构
    ARCH=$(uname -m)
    
    echo ""
    echo -e "  发行版: ${GREEN}$DISTRO${NC}"
    echo -e "  内核版本: ${GREEN}$KERNEL${NC}"
    echo -e "  架构: ${GREEN}$ARCH${NC}"
    if [ -n "$WINDSURF_BIN" ]; then
        echo -e "  Windsurf路径: ${GREEN}$WINDSURF_BIN${NC}"
    else
        echo -e "  Windsurf路径: ${YELLOW}未检测到${NC}"
    fi
    echo ""
}

# ----------------------------------------------------------------------------
# 检查Windsurf是否正在运行
# ----------------------------------------------------------------------------
check_windsurf_running() {
    if pgrep -f "windsurf" > /dev/null 2>&1; then
        print_warning "检测到 Windsurf 正在运行"
        echo -e "  请先关闭 Windsurf 再执行修复操作"
        read -p "$(echo -e ${YELLOW}是否自动关闭Windsurf？[y/N]: ${NC})" choice
        case "$choice" in
            y|Y )
                pkill -f "windsurf" 2>/dev/null || true
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
    
    CACHE_DIR="$WINDSURF_DIR/CachedData"
    
    if confirm_action; then
        if [ -d "$CACHE_DIR" ]; then
            rm -rf "$CACHE_DIR"
            print_success "已清理 CachedData"
        else
            print_info "CachedData 目录不存在"
        fi
        
        print_success "扩展缓存清理完成"
    else
        print_info "已取消操作"
    fi
}

# ----------------------------------------------------------------------------
# 功能3: 修复chrome-sandbox权限问题
# ----------------------------------------------------------------------------
fix_chrome_sandbox() {
    print_info "修复 chrome-sandbox 权限问题..."
    
    echo ""
    echo "此问题通常导致 Windsurf 静默崩溃或无法启动"
    echo ""
    
    # 查找chrome-sandbox
    SANDBOX_PATH=""
    for path in "/opt/Windsurf/chrome-sandbox" "/usr/share/windsurf/chrome-sandbox" "$HOME/.local/share/windsurf/chrome-sandbox"; do
        if [ -f "$path" ]; then
            SANDBOX_PATH="$path"
            break
        fi
    done
    
    if [ -z "$SANDBOX_PATH" ]; then
        print_warning "未找到 chrome-sandbox 文件"
        read -p "$(echo -e ${YELLOW}请输入 Windsurf 安装路径: ${NC})" custom_path
        if [ -f "$custom_path/chrome-sandbox" ]; then
            SANDBOX_PATH="$custom_path/chrome-sandbox"
        else
            print_error "未找到 chrome-sandbox"
            return 1
        fi
    fi
    
    echo ""
    echo "将执行以下命令修复权限:"
    echo "  sudo chown root:root $SANDBOX_PATH"
    echo "  sudo chmod 4755 $SANDBOX_PATH"
    echo ""
    
    if confirm_action; then
        sudo chown root:root "$SANDBOX_PATH"
        sudo chmod 4755 "$SANDBOX_PATH"
        print_success "chrome-sandbox 权限已修复"
    else
        print_info "已取消操作"
    fi
}

# ----------------------------------------------------------------------------
# 功能4: 配置终端设置
# ----------------------------------------------------------------------------
configure_terminal_settings() {
    print_info "配置终端设置..."
    
    SETTINGS_JSON="$HOME/.config/Windsurf/User/settings.json"
    
    echo ""
    echo "推荐的终端配置:"
    echo -e "  ${GREEN}\"terminal.integrated.defaultProfile.linux\": \"bash\"${NC}"
    echo ""
    
    if [ -f "$SETTINGS_JSON" ]; then
        print_info "settings.json 位置: $SETTINGS_JSON"
        
        if grep -q "terminal.integrated.defaultProfile.linux" "$SETTINGS_JSON" 2>/dev/null; then
            print_info "终端配置已存在"
            grep "terminal.integrated.defaultProfile" "$SETTINGS_JSON" | head -1
        else
            print_warning "未找到终端配置，建议手动添加"
        fi
    else
        print_warning "未找到 settings.json 文件"
        print_info "Windsurf 可能尚未创建配置文件"
    fi
}

# ----------------------------------------------------------------------------
# 功能5: 修复systemd终端上下文跟踪问题
# ----------------------------------------------------------------------------
fix_systemd_osc_context() {
    print_info "检测 systemd 终端上下文跟踪问题..."
    
    echo ""
    echo "此问题常见于 Fedora 43+ 等新版本发行版"
    echo "systemd 的 OSC 3008 转义序列可能干扰 Cascade 的输出解析"
    echo ""
    
    # 检测是否存在问题文件
    OSC_SCRIPT="/etc/profile.d/80-systemd-osc-context.sh"
    if [ -f "$OSC_SCRIPT" ]; then
        print_warning "检测到 systemd OSC 上下文脚本: $OSC_SCRIPT"
        echo ""
        echo "建议解决方案:"
        echo "1. 修改 ~/.bashrc 避免 source /etc/bashrc"
        echo "2. 创建专用于 Windsurf 的简化 shell 配置"
        echo ""
        
        read -p "$(echo -e ${YELLOW}是否创建 Windsurf 专用的 bashrc？[y/N]: ${NC})" choice
        case "$choice" in
            y|Y )
                create_windsurf_bashrc
                ;;
        esac
    else
        print_info "未检测到 systemd OSC 上下文脚本"
    fi
    
    # 检查bashrc中是否source了/etc/bashrc
    if [ -f "$HOME/.bashrc" ]; then
        if grep -q "source /etc/bashrc\|. /etc/bashrc" "$HOME/.bashrc" 2>/dev/null; then
            print_warning "~/.bashrc 中 source 了 /etc/bashrc，可能导致问题"
        fi
    fi
}

# ----------------------------------------------------------------------------
# 创建Windsurf专用bashrc
# ----------------------------------------------------------------------------
create_windsurf_bashrc() {
    WINDSURF_BASHRC="$HOME/.bashrc.windsurf"
    
    cat > "$WINDSURF_BASHRC" << 'EOF'
# ============================================================================
# Windsurf 专用 bash 配置
# 此配置避免加载可能干扰 Cascade 的系统脚本
# ============================================================================

# 基础环境变量
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export EDITOR="code"
export LANG="en_US.UTF-8"

# 简单提示符
PS1='[\u@\h \W]\$ '

# 加载用户别名（如果存在）
[ -f ~/.bash_aliases ] && source ~/.bash_aliases

# 历史记录配置
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups

# 自动补全
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi
EOF
    
    print_success "已创建 Windsurf 专用 bashrc: $WINDSURF_BASHRC"
    echo ""
    print_info "使用方法: 在 Windsurf 设置中添加:"
    echo '  "terminal.integrated.shellArgs.linux": ["--rcfile", "~/.bashrc.windsurf"]'
}

# ----------------------------------------------------------------------------
# 功能6: 检测zsh/bash主题冲突
# ----------------------------------------------------------------------------
detect_shell_theme_conflicts() {
    print_info "检测 shell 主题冲突..."
    
    CONFLICTS_FOUND=0
    
    # 检测 .bashrc
    if [ -f "$HOME/.bashrc" ]; then
        echo ""
        echo "检查 ~/.bashrc..."
        
        if grep -q "PS0\|PROMPT_COMMAND" "$HOME/.bashrc" 2>/dev/null; then
            print_warning "检测到 PS0 或 PROMPT_COMMAND 配置"
            CONFLICTS_FOUND=1
        fi
    fi
    
    # 检测 .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        echo ""
        echo "检查 ~/.zshrc..."
        
        if grep -q "ZSH_THEME=" "$HOME/.zshrc" 2>/dev/null; then
            THEME=$(grep "ZSH_THEME=" "$HOME/.zshrc" | grep -v "^#" | head -1)
            if [ -n "$THEME" ]; then
                print_warning "检测到 Oh My Zsh 主题: $THEME"
                CONFLICTS_FOUND=1
            fi
        fi
        
        if grep -q "p10k\|powerlevel" "$HOME/.zshrc" 2>/dev/null; then
            print_warning "检测到 Powerlevel10k 配置"
            CONFLICTS_FOUND=1
        fi
        
        if grep -q "oh-my-posh" "$HOME/.zshrc" 2>/dev/null; then
            print_warning "检测到 oh-my-posh 配置"
            CONFLICTS_FOUND=1
        fi
    fi
    
    if [ $CONFLICTS_FOUND -eq 1 ]; then
        echo ""
        echo -e "${YELLOW}建议:${NC} 如果终端会话卡住，请尝试:"
        echo "  1. 创建简化的 shell 配置专用于 Windsurf"
        echo "  2. 临时注释掉复杂的主题配置"
    else
        print_success "未检测到已知的主题冲突"
    fi
}

# ----------------------------------------------------------------------------
# 功能7: 生成诊断报告
# ----------------------------------------------------------------------------
generate_diagnostic_report() {
    print_info "生成诊断报告..."
    
    REPORT_FILE="$HOME/windsurf-diagnostic-$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=========================================="
        echo "Windsurf 诊断报告 - Linux"
        echo "生成时间: $(date)"
        echo "=========================================="
        echo ""
        
        echo "## 系统信息"
        echo "发行版:"
        cat /etc/os-release 2>/dev/null | head -5
        echo ""
        echo "内核: $(uname -r)"
        echo "架构: $(uname -m)"
        echo ""
        
        echo "## Windsurf 安装状态"
        which windsurf 2>/dev/null || echo "windsurf 不在 PATH 中"
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
            du -sh "$CASCADE_DIR" 2>/dev/null
        else
            echo "目录不存在"
        fi
        echo ""
        
        echo "## Shell 配置"
        echo "默认Shell: $SHELL"
        echo ""
        
        echo "## 网络状态"
        echo "ping codeium.com:"
        ping -c 2 codeium.com 2>/dev/null || echo "无法ping"
        echo ""
        
        echo "## 磁盘空间"
        df -h / 2>/dev/null | head -2
        echo ""
        
        echo "## chrome-sandbox 状态"
        for path in "/opt/Windsurf/chrome-sandbox" "/usr/share/windsurf/chrome-sandbox"; do
            if [ -f "$path" ]; then
                ls -la "$path"
            fi
        done
        echo ""
        
    } > "$REPORT_FILE"
    
    print_success "诊断报告已保存: $REPORT_FILE"
}

# ----------------------------------------------------------------------------
# 功能8: 完整修复
# ----------------------------------------------------------------------------
full_repair() {
    print_info "执行完整修复..."
    print_warning "此操作将执行所有修复步骤"
    
    if confirm_action; then
        check_windsurf_running
        clean_cascade_cache
        clean_extension_cache
        fix_chrome_sandbox
        configure_terminal_settings
        fix_systemd_osc_context
        detect_shell_theme_conflicts
        generate_diagnostic_report
        
        echo ""
        print_success "完整修复已完成！"
        print_info "请重新启动 Windsurf"
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
    echo "  1) 清理 Cascade 缓存 (解决启动失败/卡顿)"
    echo "  2) 清理扩展缓存"
    echo "  3) 修复 chrome-sandbox 权限 (解决静默崩溃)"
    echo "  4) 配置终端设置"
    echo "  5) 修复 systemd 终端上下文问题"
    echo "  6) 检测 shell 主题冲突"
    echo "  7) 生成诊断报告"
    echo "  8) 完整修复 (执行所有步骤)"
    echo ""
    echo "  0) 退出"
    echo ""
    read -p "$(echo -e ${CYAN}请输入选项 [0-8]: ${NC})" choice
    
    case $choice in
        1) check_windsurf_running; clean_cascade_cache ;;
        2) check_windsurf_running; clean_extension_cache ;;
        3) fix_chrome_sandbox ;;
        4) configure_terminal_settings ;;
        5) fix_systemd_osc_context ;;
        6) detect_shell_theme_conflicts ;;
        7) generate_diagnostic_report ;;
        8) full_repair ;;
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
