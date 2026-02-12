#!/bin/bash
# ============================================================================
# macOS 系统数据安全清理脚本
# 针对你的系统定制，只清理可安全删除的缓存和临时文件
# 不会清理：应用程序、用户文档、聊天记录、邮件、配置文件
# 作者: 传康KK
# GitHub: https://github.com/1837620622/windsurf-fix-tool
# ============================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 统计变量
TOTAL_FREED=0

# ----------------------------------------------------------------------------
# 工具函数
# ----------------------------------------------------------------------------
print_info()    { echo -e "${BLUE}[信息]${NC} $1"; }
print_success() { echo -e "${GREEN}[完成]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[警告]${NC} $1"; }
print_error()   { echo -e "${RED}[错误]${NC} $1"; }

# 获取目录大小（字节）
get_size_bytes() {
    if [ -d "$1" ] || [ -f "$1" ]; then
        du -sk "$1" 2>/dev/null | awk '{print $1 * 1024}'
    else
        echo 0
    fi
}

# 格式化大小显示
format_size() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        echo "$(echo "scale=1; $bytes / 1073741824" | bc)GB"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(echo "scale=1; $bytes / 1048576" | bc)MB"
    elif [ "$bytes" -ge 1024 ]; then
        echo "$(echo "scale=0; $bytes / 1024" | bc)KB"
    else
        echo "${bytes}B"
    fi
}

# 确认操作
confirm() {
    read -p "$(echo -e ${YELLOW}$1 [y/N]: ${NC})" choice
    case "$choice" in
        y|Y ) return 0;;
        * ) return 1;;
    esac
}

# 安全删除目录内容（保留目录本身）
safe_clean_dir() {
    local dir="$1"
    local desc="$2"
    if [ -d "$dir" ]; then
        local size=$(get_size_bytes "$dir")
        if [ "$size" -gt 0 ]; then
            echo -e "  ${CYAN}$desc${NC}: $(format_size $size)"
            if confirm "  清理此项？"; then
                rm -rf "$dir"/* 2>/dev/null
                rm -rf "$dir"/.[!.]* 2>/dev/null
                TOTAL_FREED=$((TOTAL_FREED + size))
                print_success "  已清理 $(format_size $size)"
            else
                print_info "  已跳过"
            fi
        fi
    fi
}

# 安全删除整个目录
safe_remove_dir() {
    local dir="$1"
    local desc="$2"
    if [ -d "$dir" ]; then
        local size=$(get_size_bytes "$dir")
        if [ "$size" -gt 0 ]; then
            echo -e "  ${CYAN}$desc${NC}: $(format_size $size)"
            if confirm "  清理此项？"; then
                rm -rf "$dir" 2>/dev/null
                TOTAL_FREED=$((TOTAL_FREED + size))
                print_success "  已清理 $(format_size $size)"
            else
                print_info "  已跳过"
            fi
        fi
    fi
}

# ----------------------------------------------------------------------------
# 启动横幅
# ----------------------------------------------------------------------------
echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  macOS 系统数据安全清理工具${NC}"
echo -e "${CYAN}  by 传康KK${NC}"
echo -e "${CYAN}  github.com/1837620622/windsurf-fix-tool${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
print_warning "此脚本只清理缓存和临时文件，不会删除重要数据"
print_info "每一步都会询问确认，可随时跳过"
echo ""

# ============================================================================
# 第一部分：低风险清理（纯缓存，删除后系统自动重建）
# ============================================================================
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  第一部分: 低风险清理（纯缓存，系统会自动重建）${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# 1. 用户缓存目录
print_info "1. 用户应用缓存 (~/Library/Caches)"
safe_clean_dir "$HOME/Library/Caches" "用户应用缓存"
echo ""

# 2. Apple 照片分析缓存（3.1GB）
print_info "2. Apple 照片分析缓存 (mediaanalysisd)"
print_warning "删除后系统会在后台重新分析照片，不影响照片本身"
MEDIA_ANALYSIS="$HOME/Library/Containers/com.apple.mediaanalysisd"
if [ -d "$MEDIA_ANALYSIS" ]; then
    # 只清理Data/Library/Caches部分
    MEDIA_CACHE="$MEDIA_ANALYSIS/Data/Library/Caches"
    if [ -d "$MEDIA_CACHE" ]; then
        safe_clean_dir "$MEDIA_CACHE" "照片分析缓存"
    else
        # 如果没有Caches子目录，检查整体大小
        size=$(get_size_bytes "$MEDIA_ANALYSIS")
        echo -e "  ${CYAN}照片分析数据${NC}: $(format_size $size)"
        print_info "  此目录包含照片ML分析数据，删除后系统会重新分析"
        if confirm "  清理此项？"; then
            rm -rf "$MEDIA_ANALYSIS/Data/Library" 2>/dev/null
            TOTAL_FREED=$((TOTAL_FREED + size))
            print_success "  已清理 $(format_size $size)"
        else
            print_info "  已跳过"
        fi
    fi
fi
echo ""

# 3. Homebrew 缓存清理
print_info "3. Homebrew 缓存和旧版本"
if command -v brew &>/dev/null; then
    BREW_CACHE=$(brew --cache 2>/dev/null)
    if [ -n "$BREW_CACHE" ] && [ -d "$BREW_CACHE" ]; then
        size=$(get_size_bytes "$BREW_CACHE")
        echo -e "  ${CYAN}Homebrew 下载缓存${NC}: $(format_size $size)"
    fi
    if confirm "  运行 brew cleanup（清理旧版本和缓存）？"; then
        before=$(df -k / | tail -1 | awk '{print $4}')
        brew cleanup --prune=all 2>/dev/null
        after=$(df -k / | tail -1 | awk '{print $4}')
        freed=$(( (after - before) * 1024 ))
        if [ "$freed" -gt 0 ]; then
            TOTAL_FREED=$((TOTAL_FREED + freed))
            print_success "  已释放 $(format_size $freed)"
        else
            print_success "  Homebrew 缓存已是最新"
        fi
    else
        print_info "  已跳过"
    fi
fi
echo ""

# 4. npm 缓存
print_info "4. npm 缓存"
if command -v npm &>/dev/null; then
    NPM_CACHE="$HOME/.npm"
    safe_clean_dir "$NPM_CACHE/_cacache" "npm 下载缓存"
    # 清理npx缓存
    safe_clean_dir "$NPM_CACHE/_npx" "npx 临时缓存"
fi
echo ""

# 5. pip 缓存
print_info "5. pip 缓存"
PIP_CACHE="$HOME/Library/Caches/pip"
if [ -d "$PIP_CACHE" ]; then
    safe_clean_dir "$PIP_CACHE" "pip 下载缓存"
fi
echo ""

# 6. Maven 缓存（旧仓库数据）
print_info "6. Maven 本地仓库"
M2_REPO="$HOME/.m2/repository"
if [ -d "$M2_REPO" ]; then
    size=$(get_size_bytes "$M2_REPO")
    echo -e "  ${CYAN}Maven 本地仓库${NC}: $(format_size $size)"
    print_warning "  清理后需重新下载依赖（如果你还在用Maven项目的话）"
    if confirm "  清理此项？"; then
        rm -rf "$M2_REPO" 2>/dev/null
        TOTAL_FREED=$((TOTAL_FREED + size))
        print_success "  已清理 $(format_size $size)"
    else
        print_info "  已跳过"
    fi
fi
echo ""

# 7. Playwright 浏览器缓存
print_info "7. Playwright 浏览器缓存"
safe_remove_dir "$HOME/Library/Caches/ms-playwright" "Playwright 浏览器"
echo ""

# 8. DNS 缓存
print_info "8. DNS 缓存刷新"
if confirm "  刷新 DNS 缓存？"; then
    sudo dscacheutil -flushcache 2>/dev/null
    sudo killall -HUP mDNSResponder 2>/dev/null
    print_success "  DNS 缓存已刷新"
else
    print_info "  已跳过"
fi
echo ""

# ============================================================================
# 第二部分：中等风险清理（应用缓存，不影响核心功能）
# ============================================================================
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  第二部分: 中等风险清理（应用缓存，建议先关闭对应应用）${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# 9. 微信缓存（6.9GB 大头！）
print_info "9. 微信缓存"
WECHAT_CONTAINER="$HOME/Library/Containers/com.tencent.xinWeChat"
if [ -d "$WECHAT_CONTAINER" ]; then
    size=$(get_size_bytes "$WECHAT_CONTAINER")
    echo -e "  ${CYAN}微信容器数据${NC}: $(format_size $size)"
    print_warning "  建议在微信 → 设置 → 通用 → 存储空间 中清理更安全"
    print_warning "  或者清理缓存部分（不删除聊天记录本体）"
    
    # 只清理缓存目录，保留聊天数据
    WECHAT_CACHE="$WECHAT_CONTAINER/Data/Library/Caches"
    if [ -d "$WECHAT_CACHE" ]; then
        safe_clean_dir "$WECHAT_CACHE" "微信缓存文件"
    fi
    
    # 清理微信临时文件
    WECHAT_TMP="$WECHAT_CONTAINER/Data/tmp"
    if [ -d "$WECHAT_TMP" ]; then
        safe_clean_dir "$WECHAT_TMP" "微信临时文件"
    fi
fi
echo ""

# 10. WPS 缓存
print_info "10. WPS Office 缓存"
WPS_CONTAINER="$HOME/Library/Containers/com.kingsoft.wpsoffice.mac"
if [ -d "$WPS_CONTAINER" ]; then
    WPS_CACHE="$WPS_CONTAINER/Data/Library/Caches"
    if [ -d "$WPS_CACHE" ]; then
        safe_clean_dir "$WPS_CACHE" "WPS 缓存"
    fi
    WPS_TMP="$WPS_CONTAINER/Data/tmp"
    if [ -d "$WPS_TMP" ]; then
        safe_clean_dir "$WPS_TMP" "WPS 临时文件"
    fi
fi
echo ""

# 11. Telegram 缓存
print_info "11. Telegram 缓存"
TG_CACHE="$HOME/Library/Group Containers/6N38VWS5BX.ru.keepcoder.Telegram"
if [ -d "$TG_CACHE" ]; then
    size=$(get_size_bytes "$TG_CACHE")
    echo -e "  ${CYAN}Telegram 数据${NC}: $(format_size $size)"
    print_warning "  建议在 Telegram → 设置 → 数据和存储 → 存储用量 中清理"
    if confirm "  清理 Telegram 缓存文件？"; then
        # 只清理Caches和tmp
        find "$TG_CACHE" -name "Caches" -type d -exec rm -rf {} + 2>/dev/null
        find "$TG_CACHE" -name "tmp" -type d -exec rm -rf {} + 2>/dev/null
        print_success "  已清理 Telegram 缓存"
    else
        print_info "  已跳过"
    fi
fi
echo ""

# 12. QQ 缓存
print_info "12. QQ 缓存"
QQ_CONTAINER="$HOME/Library/Containers/com.tencent.qq"
if [ -d "$QQ_CONTAINER" ]; then
    QQ_CACHE="$QQ_CONTAINER/Data/Library/Caches"
    if [ -d "$QQ_CACHE" ]; then
        safe_clean_dir "$QQ_CACHE" "QQ 缓存"
    fi
fi
echo ""

# 13. Google Chrome 缓存
print_info "13. Google Chrome 缓存"
CHROME_CACHE="$HOME/Library/Application Support/Google/Chrome/Default/Service Worker"
CHROME_CACHE2="$HOME/Library/Application Support/Google/Chrome/Default/Cache"
CHROME_CODE="$HOME/Library/Application Support/Google/Chrome/Default/Code Cache"
safe_remove_dir "$CHROME_CACHE" "Chrome Service Worker 缓存"
safe_remove_dir "$CHROME_CACHE2" "Chrome 网页缓存"
safe_remove_dir "$CHROME_CODE" "Chrome 代码缓存"
echo ""

# 14. Windsurf 缓存
print_info "14. Windsurf IDE 缓存"
WS_DIR="$HOME/Library/Application Support/Windsurf"
if [ -d "$WS_DIR" ]; then
    safe_remove_dir "$WS_DIR/CachedData" "Windsurf CachedData"
    safe_remove_dir "$WS_DIR/GPUCache" "Windsurf GPUCache"
    safe_remove_dir "$WS_DIR/Code Cache" "Windsurf Code Cache"
    
    WS_STORAGE="$WS_DIR/WebStorage"
    if [ -d "$WS_STORAGE" ]; then
        size=$(get_size_bytes "$WS_STORAGE")
        echo -e "  ${CYAN}Windsurf WebStorage${NC}: $(format_size $size)"
        print_warning "  清理此项可能需要重新登录 Windsurf 的一些服务"
        if confirm "  清理此项？"; then
            rm -rf "$WS_STORAGE" 2>/dev/null
            TOTAL_FREED=$((TOTAL_FREED + size))
            print_success "  已清理 $(format_size $size)"
        else
            print_info "  已跳过"
        fi
    fi
fi
echo ""

# ============================================================================
# 第三部分：开发工具清理
# ============================================================================
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  第三部分: 开发工具清理${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# 15. 不活跃项目的 node_modules
print_info "15. 不活跃项目的 node_modules"
print_warning "以下 node_modules 可以清理，需要时用 npm install 重新安装"
echo ""
NODE_MODULES_TOTAL=0
while IFS= read -r dir; do
    if [ -d "$dir" ]; then
        size=$(get_size_bytes "$dir")
        NODE_MODULES_TOTAL=$((NODE_MODULES_TOTAL + size))
        echo -e "  ${CYAN}$(echo $dir | sed "s|$HOME|~|")${NC}: $(format_size $size)"
    fi
done < <(find "$HOME/Downloads" -maxdepth 3 -name "node_modules" -type d 2>/dev/null)

if [ "$NODE_MODULES_TOTAL" -gt 0 ]; then
    echo ""
    echo -e "  合计: $(format_size $NODE_MODULES_TOTAL)"
    if confirm "  清理 Downloads 下的所有 node_modules？"; then
        find "$HOME/Downloads" -maxdepth 3 -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null
        TOTAL_FREED=$((TOTAL_FREED + NODE_MODULES_TOTAL))
        print_success "  已清理"
    else
        print_info "  已跳过"
    fi
fi
echo ""

# 16. __pycache__ 目录
print_info "16. Python __pycache__ 缓存"
PYCACHE_COUNT=$(find "$HOME" -maxdepth 6 -name "__pycache__" -type d 2>/dev/null | wc -l | tr -d ' ')
if [ "$PYCACHE_COUNT" -gt 0 ]; then
    echo -e "  找到 ${CYAN}$PYCACHE_COUNT${NC} 个 __pycache__ 目录"
    if confirm "  清理所有 __pycache__？"; then
        find "$HOME" -maxdepth 6 -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
        print_success "  已清理"
    else
        print_info "  已跳过"
    fi
fi
echo ""

# ============================================================================
# 第四部分：系统级清理（需要 sudo）
# ============================================================================
echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}  第四部分: 系统级清理（需要管理员密码）${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# 17. 系统诊断日志（2.7GB）
print_info "17. 系统诊断日志 (/private/var/db/diagnostics)"
if [ -d "/private/var/db/diagnostics" ]; then
    size=$(du -sk /private/var/db/diagnostics 2>/dev/null | awk '{print $1 * 1024}')
    echo -e "  ${CYAN}系统诊断日志${NC}: $(format_size $size)"
    print_warning "  这些是 Apple 统一日志，删除后不影响系统运行"
    if confirm "  清理此项（需要 sudo）？"; then
        sudo rm -rf /private/var/db/diagnostics/* 2>/dev/null
        sudo rm -rf /private/var/db/uuidtext/* 2>/dev/null
        TOTAL_FREED=$((TOTAL_FREED + size))
        # 加上 uuidtext
        uuidtext_size=$(du -sk /private/var/db/uuidtext 2>/dev/null | awk '{print $1 * 1024}')
        TOTAL_FREED=$((TOTAL_FREED + uuidtext_size))
        print_success "  已清理系统诊断日志和 UUID 文本"
    else
        print_info "  已跳过"
    fi
fi
echo ""

# 18. 系统日志
print_info "18. 系统日志 (/private/var/log)"
if [ -d "/private/var/log" ]; then
    size=$(du -sk /private/var/log 2>/dev/null | awk '{print $1 * 1024}')
    echo -e "  ${CYAN}系统日志${NC}: $(format_size $size)"
    print_warning "  只清理超过30天的旧日志文件"
    if confirm "  清理旧日志（需要 sudo）？"; then
        sudo find /private/var/log -name "*.log" -mtime +30 -delete 2>/dev/null
        sudo find /private/var/log -name "*.gz" -mtime +30 -delete 2>/dev/null
        sudo find /private/var/log -name "*.bz2" -mtime +30 -delete 2>/dev/null
        print_success "  已清理30天以上的旧日志"
    else
        print_info "  已跳过"
    fi
fi
echo ""

# 19. 临时文件夹
print_info "19. 系统临时文件 (/private/var/folders)"
if [ -d "/private/var/folders" ]; then
    size=$(du -sk /private/var/folders 2>/dev/null | awk '{print $1 * 1024}')
    echo -e "  ${CYAN}系统临时文件${NC}: $(format_size $size)"
    print_warning "  只清理超过7天的临时文件"
    if confirm "  清理旧临时文件（需要 sudo）？"; then
        sudo find /private/var/folders -name "C" -type d -mindepth 3 -maxdepth 3 2>/dev/null | while read d; do
            sudo find "$d" -mtime +7 -delete 2>/dev/null
        done
        print_success "  已清理7天以上的临时文件"
    else
        print_info "  已跳过"
    fi
fi
echo ""

# ============================================================================
# 清理完成
# ============================================================================
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  清理完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "本次清理释放空间: ${GREEN}$(format_size $TOTAL_FREED)${NC}"
echo ""
print_info "额外建议:"
echo -e "  ${CYAN}1.${NC} 微信(6.9GB): 打开微信 → 设置 → 通用 → 存储空间 → 管理"
echo -e "  ${CYAN}2.${NC} Telegram(1.3GB): 打开 Telegram → 设置 → 数据和存储 → 存储用量"
echo -e "  ${CYAN}3.${NC} 如果不再使用 Logic Pro X(4GB), 可在 /Applications 中删除"
echo -e "  ${CYAN}4.${NC} MATLAB(14GB) 占用最大，确认是否还需要使用"
echo -e "  ${CYAN}5.${NC} 推荐使用 Mole 工具做更深度清理: brew install tw93/brew/mole && mo clean --dry-run"
echo ""
print_warning "清理后建议重启电脑，让系统重新计算存储空间"
echo ""
