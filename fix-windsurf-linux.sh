#!/bin/bash

# ============================================================================
# Windsurf 修复工具 - Linux 版本
# 用于修复 Windsurf IDE 卡顿、Shell无法连接等常见问题
# 基于官方文档: https://docs.windsurf.com/troubleshooting/windsurf-common-issues
# 作者: 传康KK
# GitHub: https://github.com/1837620622/windsurf-fix-tool
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
# 功能9: 修复chrome-sandbox权限问题
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
# 功能10: 配置终端设置
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
# 功能11: 修复systemd终端上下文跟踪问题
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
        
        # 清理 GPU 缓存
        GPU_CACHE="$HOME/.config/Windsurf/GPUCache"
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
        CODE_CACHE="$HOME/.config/Windsurf/Code Cache"
        if [ -d "$CODE_CACHE" ]; then
            rm -rf "$CODE_CACHE"
            print_success "已清理 Code Cache"
        fi
        
        # 清理 logs
        LOGS_DIR="$HOME/.config/Windsurf/logs"
        if [ -d "$LOGS_DIR" ]; then
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
# 功能7: MCP诊断与修复
# ----------------------------------------------------------------------------
diagnose_mcp() {
    print_info "MCP (Model Context Protocol) 诊断..."
    
    MCP_CONFIG="$WINDSURF_DIR/mcp_config.json"
    MCP_CONFIG_OLD="$CODEIUM_DIR/mcp_config.json"
    
    echo ""
    echo -e "${CYAN}MCP 配置文件状态:${NC}"
    echo ""
    
    if [ -f "$MCP_CONFIG" ]; then
        print_success "找到 MCP 配置: $MCP_CONFIG"
        echo ""
        echo "配置内容预览:"
        head -30 "$MCP_CONFIG" 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done
        echo ""
        
        if command -v python3 &> /dev/null; then
            if python3 -c "import json; json.load(open('$MCP_CONFIG'))" 2>/dev/null; then
                print_success "MCP 配置 JSON 格式有效"
            else
                print_error "MCP 配置 JSON 格式无效！"
            fi
        fi
    else
        print_warning "未找到 MCP 配置文件: $MCP_CONFIG"
    fi
    
    if [ -f "$MCP_CONFIG_OLD" ]; then
        print_info "发现旧版 MCP 配置: $MCP_CONFIG_OLD"
    fi
    
    echo ""
    echo -e "${CYAN}运行时检查:${NC}"
    echo ""
    
    if command -v node &> /dev/null; then
        print_success "Node.js: $(node --version 2>/dev/null)"
    else
        print_warning "未找到 Node.js"
    fi
    
    if command -v npx &> /dev/null; then
        print_success "npx 可用"
    else
        print_warning "未找到 npx"
    fi
    
    if command -v python3 &> /dev/null; then
        print_success "Python3: $(python3 --version 2>/dev/null)"
    else
        print_warning "未找到 Python3"
    fi
    
    if command -v uvx &> /dev/null; then
        print_success "uvx 可用"
    else
        print_info "uvx 未安装"
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
    echo ""
    
    if [ ! -f "$MCP_CONFIG" ]; then
        print_info "MCP 配置文件不存在"
        return 0
    fi
    
    if confirm_action; then
        mkdir -p "$BACKUP_DIR"
        cp "$MCP_CONFIG" "$BACKUP_DIR/mcp_config.json.bak"
        print_info "已备份到: $BACKUP_DIR/mcp_config.json.bak"
        
        cat > "$MCP_CONFIG" << 'EOF'
{
  "mcpServers": {}
}
EOF
        print_success "MCP 配置已重置"
    else
        print_info "已取消操作"
    fi
}

# ----------------------------------------------------------------------------
# 功能4: 清理开发工具缓存（npm/pip/Maven等）
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
    PIP_CACHE="$HOME/.cache/pip"
    if [ -d "$PIP_CACHE" ]; then
        SIZE=$(du -sm "$PIP_CACHE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[pip 缓存]${NC} ~/.cache/pip - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        CLEANABLE_ITEMS+=("pip")
    fi
    
    # apt 缓存 (Debian/Ubuntu)
    APT_CACHE="/var/cache/apt/archives"
    if [ -d "$APT_CACHE" ]; then
        SIZE=$(sudo du -sm "$APT_CACHE" 2>/dev/null | awk '{print $1}')
        if [ -n "$SIZE" ] && [ "$SIZE" -gt 0 ] 2>/dev/null; then
            echo -e "  ${GREEN}[apt 缓存]${NC} /var/cache/apt/archives - ${YELLOW}${SIZE}MB${NC}"
            TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
            CLEANABLE_ITEMS+=("apt")
        fi
    fi
    
    # yum/dnf 缓存 (RHEL/Fedora)
    YUM_CACHE="/var/cache/yum"
    DNF_CACHE="/var/cache/dnf"
    if [ -d "$YUM_CACHE" ] || [ -d "$DNF_CACHE" ]; then
        CACHE_DIR="${DNF_CACHE:-$YUM_CACHE}"
        SIZE=$(sudo du -sm "$CACHE_DIR" 2>/dev/null | awk '{print $1}')
        if [ -n "$SIZE" ] && [ "$SIZE" -gt 0 ] 2>/dev/null; then
            echo -e "  ${GREEN}[yum/dnf 缓存]${NC} $CACHE_DIR - ${YELLOW}${SIZE}MB${NC}"
            TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
            CLEANABLE_ITEMS+=("yum")
        fi
    fi
    
    # uv 缓存
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
    YARN_CACHE="$HOME/.cache/yarn"
    if [ -d "$YARN_CACHE" ]; then
        SIZE=$(du -sm "$YARN_CACHE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[Yarn 缓存]${NC} ~/.cache/yarn - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        CLEANABLE_ITEMS+=("yarn")
    fi
    
    # pnpm 缓存
    PNPM_STORE="$HOME/.pnpm-store"
    if [ -d "$PNPM_STORE" ]; then
        SIZE=$(du -sm "$PNPM_STORE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[pnpm 缓存]${NC} ~/.pnpm-store - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
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
        echo -e "  ${GREEN}[Selenium/WebDriver]${NC} - ${YELLOW}${SELENIUM_SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SELENIUM_SIZE))
        CLEANABLE_ITEMS+=("selenium")
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
    for CONDA_DIR in "$HOME/miniconda3/pkgs" "$HOME/anaconda3/pkgs"; do
        if [ -d "$CONDA_DIR" ]; then
            SIZE=$(du -sm "$CONDA_DIR" 2>/dev/null | awk '{print $1}')
            echo -e "  ${GREEN}[conda 包缓存]${NC} $CONDA_DIR - ${YELLOW}${SIZE}MB${NC}"
            TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
            CLEANABLE_ITEMS+=("conda")
            break
        fi
    done
    
    # Docker 缓存
    if command -v docker &> /dev/null; then
        DOCKER_SIZE=$(docker system df 2>/dev/null | awk 'NR>1{gsub(/[A-Za-z]/,"",$4); sum+=$4} END{printf "%.0f", sum}' 2>/dev/null)
        if [ -n "$DOCKER_SIZE" ] && [ "$DOCKER_SIZE" -gt 0 ] 2>/dev/null; then
            echo -e "  ${GREEN}[Docker 可回收]${NC} - ${YELLOW}约${DOCKER_SIZE}MB${NC}"
            CLEANABLE_ITEMS+=("docker")
        fi
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
            for item in "${CLEANABLE_ITEMS[@]}"; do
                case "$item" in
                    npm)
                        if command -v npm &> /dev/null; then npm cache clean --force 2>/dev/null
                        else rm -rf "$NPM_CACHE/_cacache" 2>/dev/null; fi
                        print_success "npm 缓存已清理"
                        ;;
                    pip)
                        if command -v pip3 &> /dev/null; then pip3 cache purge 2>/dev/null
                        else rm -rf "$PIP_CACHE" 2>/dev/null; fi
                        print_success "pip 缓存已清理"
                        ;;
                    apt)
                        sudo apt-get clean 2>/dev/null
                        print_success "apt 缓存已清理"
                        ;;
                    yum)
                        if command -v dnf &> /dev/null; then sudo dnf clean all 2>/dev/null
                        else sudo yum clean all 2>/dev/null; fi
                        print_success "yum/dnf 缓存已清理"
                        ;;
                    uv)
                        rm -rf "$UV_CACHE" 2>/dev/null
                        print_success "uv 缓存已清理"
                        ;;
                    maven)
                        print_warning "Maven 缓存跳过（删除后需重新下载依赖）"
                        ;;
                    gradle)
                        print_warning "Gradle 缓存跳过（删除后需重新下载依赖）"
                        ;;
                    yarn)
                        if command -v yarn &> /dev/null; then yarn cache clean 2>/dev/null
                        else rm -rf "$YARN_CACHE" 2>/dev/null; fi
                        print_success "Yarn 缓存已清理"
                        ;;
                    pnpm)
                        if command -v pnpm &> /dev/null; then pnpm store prune 2>/dev/null; fi
                        print_success "pnpm 缓存已清理"
                        ;;
                    selenium)
                        rm -rf "$SELENIUM_CACHE" "$WDM_CACHE" 2>/dev/null
                        print_success "Selenium/WebDriver 缓存已清理"
                        ;;
                    go)
                        if command -v go &> /dev/null; then go clean -modcache 2>/dev/null; fi
                        print_success "Go 模块缓存已清理"
                        ;;
                    cargo)
                        print_warning "Cargo 缓存跳过"
                        ;;
                    conda)
                        if command -v conda &> /dev/null; then conda clean --all -y 2>/dev/null; fi
                        print_success "conda 缓存已清理"
                        ;;
                    docker)
                        docker system prune -f 2>/dev/null
                        print_success "Docker 缓存已清理"
                        ;;
                esac
            done
            echo ""
            print_success "开发工具缓存清理完成！"
            ;;
        2)
            for item in "${CLEANABLE_ITEMS[@]}"; do
                case "$item" in
                    npm) label="npm 缓存" ;;
                    pip) label="pip 缓存" ;;
                    apt) label="apt 缓存" ;;
                    yum) label="yum/dnf 缓存" ;;
                    uv) label="uv 缓存" ;;
                    maven) label="Maven 缓存" ;;
                    gradle) label="Gradle 缓存" ;;
                    yarn) label="Yarn 缓存" ;;
                    pnpm) label="pnpm 缓存" ;;
                    selenium) label="Selenium/WebDriver 缓存" ;;
                    go) label="Go 模块缓存" ;;
                    cargo) label="Cargo 缓存" ;;
                    conda) label="conda 包缓存" ;;
                    docker) label="Docker 可回收空间" ;;
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
                        apt) sudo apt-get clean 2>/dev/null ;;
                        yum)
                            if command -v dnf &> /dev/null; then sudo dnf clean all 2>/dev/null
                            else sudo yum clean all 2>/dev/null; fi
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
                        go)
                            if command -v go &> /dev/null; then go clean -modcache 2>/dev/null; fi
                            ;;
                        cargo) rm -rf "$CARGO_CACHE" 2>/dev/null ;;
                        conda)
                            if command -v conda &> /dev/null; then conda clean --all -y 2>/dev/null; fi
                            ;;
                        docker) docker system prune -f 2>/dev/null ;;
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
# 功能5: 清理Linux系统缓存
# ----------------------------------------------------------------------------
clean_system_caches() {
    print_info "扫描 Linux 系统缓存..."
    
    echo ""
    echo -e "${CYAN}正在检测系统级缓存...${NC}"
    echo ""
    
    TOTAL_SIZE=0
    
    # 用户缓存目录
    USER_CACHE="$HOME/.cache"
    if [ -d "$USER_CACHE" ]; then
        SIZE=$(du -sm "$USER_CACHE" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[用户缓存]${NC} ~/.cache - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        
        echo -e "    ${CYAN}Top 10 缓存目录:${NC}"
        du -sm "$USER_CACHE"/*/ 2>/dev/null | sort -rn | head -10 | while read size dir; do
            dirname=$(basename "$dir")
            echo -e "      $dirname - ${YELLOW}${size}MB${NC}"
        done
        echo ""
    fi
    
    # 系统日志
    SYS_LOG="/var/log"
    if [ -d "$SYS_LOG" ]; then
        SIZE=$(sudo du -sm "$SYS_LOG" 2>/dev/null | awk '{print $1}')
        if [ -n "$SIZE" ]; then
            echo -e "  ${GREEN}[系统日志]${NC} /var/log - ${YELLOW}${SIZE}MB${NC}"
            TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        fi
    fi
    
    # 临时文件
    TMP_DIR="/tmp"
    if [ -d "$TMP_DIR" ]; then
        SIZE=$(du -sm "$TMP_DIR" 2>/dev/null | awk '{print $1}')
        echo -e "  ${GREEN}[临时文件]${NC} /tmp - ${YELLOW}${SIZE}MB${NC}"
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
    fi
    
    # Windsurf 旧备份
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
    
    # systemd journal 日志
    if command -v journalctl &> /dev/null; then
        JOURNAL_SIZE=$(journalctl --disk-usage 2>/dev/null | grep -oP '[\d.]+[GMKT]' | head -1)
        if [ -n "$JOURNAL_SIZE" ]; then
            echo -e "  ${GREEN}[systemd 日志]${NC} - ${YELLOW}${JOURNAL_SIZE}${NC}"
        fi
    fi
    
    echo ""
    echo -e "  ${CYAN}系统缓存总计: ${YELLOW}${TOTAL_SIZE}MB${NC}"
    echo ""
    
    echo -e "${YELLOW}请选择清理项目:${NC}"
    echo "  1) 清理用户缓存 (~/.cache，排除关键缓存)"
    echo "  2) 清理旧日志文件（超过30天）"
    echo "  3) 清理 /tmp 临时文件（超过7天）"
    echo "  4) 清理 Windsurf 旧备份目录"
    echo "  5) 清理旧诊断报告"
    echo "  6) 清理 systemd journal 日志（保留最近7天）"
    echo "  7) 刷新 DNS 缓存"
    echo "  8) 全部执行（安全项）"
    echo "  0) 取消"
    echo ""
    read -p "$(echo -e ${CYAN}请选择 [0-8]: ${NC})" sys_choice
    
    case "$sys_choice" in
        1)
            print_warning "将清理用户缓存目录"
            if confirm_action; then
                find "$USER_CACHE" -mindepth 1 -maxdepth 1 -type d \
                    ! -name "fontconfig" \
                    ! -name "mesa_shader_cache" \
                    -exec rm -rf {} + 2>/dev/null
                print_success "用户缓存已清理"
            fi
            ;;
        2)
            sudo find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null
            sudo find /var/log -type f -name "*.gz" -mtime +30 -delete 2>/dev/null
            print_success "超过30天的旧日志已清理"
            ;;
        3)
            sudo find /tmp -type f -mtime +7 -delete 2>/dev/null
            print_success "/tmp 中超过7天的临时文件已清理"
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
            if command -v journalctl &> /dev/null; then
                sudo journalctl --vacuum-time=7d 2>/dev/null
                print_success "systemd journal 日志已清理（保留7天）"
            else
                print_info "系统未使用 systemd journal"
            fi
            ;;
        7)
            if command -v systemd-resolve &> /dev/null; then
                sudo systemd-resolve --flush-caches 2>/dev/null
            elif command -v resolvectl &> /dev/null; then
                sudo resolvectl flush-caches 2>/dev/null
            fi
            print_success "DNS 缓存已刷新"
            ;;
        8)
            print_info "执行全部安全清理项..."
            
            sudo find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null
            sudo find /var/log -type f -name "*.gz" -mtime +30 -delete 2>/dev/null
            print_success "旧日志已清理"
            
            sudo find /tmp -type f -mtime +7 -delete 2>/dev/null
            print_success "旧临时文件已清理"
            
            if [ $BACKUP_COUNT -gt 0 ]; then
                rm -rf "$HOME"/.windsurf-backup-* 2>/dev/null
                print_success "Windsurf 旧备份已清理"
            fi
            
            rm -f "$HOME"/windsurf-diagnostic-*.txt 2>/dev/null
            print_success "旧诊断报告已清理"
            
            if command -v journalctl &> /dev/null; then
                sudo journalctl --vacuum-time=7d 2>/dev/null
                print_success "systemd journal 日志已清理"
            fi
            
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
    
    df -h / | awk 'NR==2{printf "  磁盘总容量: %s | 已使用: %s | 可用: %s | 使用率: %s\n", $2, $3, $4, $5}'
    echo ""
    
    HOME_SIZE=$(du -sh "$HOME" 2>/dev/null | awk '{print $1}')
    echo -e "  ${CYAN}用户主目录:${NC} ${YELLOW}$HOME_SIZE${NC}"
    echo ""
    
    echo -e "  ${CYAN}主要目录占用:${NC}"
    echo ""
    for dir in "Downloads" "Documents" "Desktop" "Videos" "Music" "Pictures"; do
        if [ -d "$HOME/$dir" ]; then
            SIZE=$(du -sh "$HOME/$dir" 2>/dev/null | awk '{print $1}')
            printf "    %-15s %s\n" "$dir" "$SIZE"
        fi
    done
    echo ""
    
    echo -e "  ${CYAN}隐藏目录 Top 10:${NC}"
    echo ""
    du -sm "$HOME"/.[!.]* 2>/dev/null | sort -rn | head -10 | while read size dir; do
        dirname=$(basename "$dir")
        printf "    %-30s %sMB\n" "$dirname" "$size"
    done
    echo ""
    
    print_info "分析完成"
}

# ----------------------------------------------------------------------------
# 功能12: 检测shell主题冲突
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
# 功能13: 生成诊断报告
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
# 功能14: 完整修复
# ----------------------------------------------------------------------------
full_repair() {
    print_info "执行完整修复..."
    print_warning "此操作将执行所有修复步骤"
    
    if confirm_action; then
        check_windsurf_running
        clean_cascade_cache
        clean_extension_cache
        clean_startup_cache
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
    echo -e "${YELLOW}== Windsurf 缓存清理 ==${NC}"
    echo "  1) 清理 Cascade 缓存 (会清理对话历史)"
    echo "  2) 清理启动缓存 (不清理对话历史，推荐)"
    echo "  3) 清理扩展缓存 (不清理对话历史)"
    echo ""
    echo -e "${YELLOW}== 系统缓存清理 ==${NC}"
    echo "  4) 清理开发工具缓存 (npm/pip/apt/Maven等)"
    echo "  5) 清理 Linux 系统缓存 (日志/临时文件/旧备份等)"
    echo "  6) 磁盘空间分析"
    echo ""
    echo -e "${YELLOW}== MCP 相关 ==${NC}"
    echo "  7) MCP 诊断 (检查MCP加载问题)"
    echo "  8) 重置 MCP 配置"
    echo ""
    echo -e "${YELLOW}== 终端相关 ==${NC}"
    echo "  9) 修复 chrome-sandbox 权限 (解决静默崩溃)"
    echo "  10) 配置终端设置"
    echo "  11) 修复 systemd 终端上下文问题"
    echo "  12) 检测 shell 主题冲突"
    echo ""
    echo -e "${YELLOW}== 其他 ==${NC}"
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
        9) fix_chrome_sandbox ;;
        10) configure_terminal_settings ;;
        11) fix_systemd_osc_context ;;
        12) detect_shell_theme_conflicts ;;
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
