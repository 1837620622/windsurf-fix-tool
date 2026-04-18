#!/bin/bash
# 统一 UTF-8 终端环境，降低中文输出在部分终端中的显示异常概率。
export LANG="${LANG:-C.UTF-8}"
export LC_ALL="${LC_ALL:-C.UTF-8}"

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
SECTION_BAR="--------------------------------------------"

# 统计变量
TOTAL_FREED=0

# ----------------------------------------------------------------------------
# 工具函数
# ----------------------------------------------------------------------------
print_info()    { echo -e "${BLUE}[信息]${NC} $1"; }
print_success() { echo -e "${GREEN}[完成]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[警告]${NC} $1"; }

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
    echo -ne "${YELLOW}$1 [y/N]: ${NC}"
    read -r choice
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
echo -e "\n${GREEN}${SECTION_BAR}${NC}"
echo -e "${GREEN}  第一部分: 低风险清理（纯缓存，系统会自动重建）${NC}"
echo -e "${GREEN}${SECTION_BAR}${NC}\n"

# 1. 用户缓存目录
print_info "1. 用户应用缓存 (~/Library/Caches)"
safe_clean_dir "$HOME/Library/Caches" "用户应用缓存"
echo ""

# 2. 用户日志目录
print_info "2. 用户日志目录 (~/Library/Logs)"
safe_clean_dir "$HOME/Library/Logs" "用户日志"
echo ""

# 3. Apple 照片分析缓存（3.1GB）
print_info "3. Apple 照片分析缓存 (mediaanalysisd)"
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

# 4. Homebrew 缓存清理
print_info "4. Homebrew 缓存和旧版本"
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

# 5. npm 缓存
print_info "5. npm 缓存"
NPM_CACHE="$HOME/.npm"
if [ -d "$NPM_CACHE" ]; then
    safe_clean_dir "$NPM_CACHE/_cacache" "npm 下载缓存"
    # 清理npx缓存
    safe_clean_dir "$NPM_CACHE/_npx" "npx 临时缓存"
fi
echo ""

# 6. 通用隐藏缓存
print_info "6. 通用隐藏缓存 (~/.cache 与 node-gyp)"
safe_remove_dir "$HOME/.cache/codex-runtimes" "codex runtimes 下载缓存"
safe_remove_dir "$HOME/.cache/uv" "uv 包缓存"
safe_remove_dir "$HOME/.cache/selenium" "Selenium 驱动缓存"
safe_remove_dir "$HOME/.cache/vscode-ripgrep" "VS Code ripgrep 缓存"
safe_remove_dir "$HOME/.wdm" "WebDriver Manager 缓存"
safe_remove_dir "$HOME/Library/Caches/node-gyp" "node-gyp 构建缓存"
echo ""

# 7. pip 缓存
print_info "7. pip 缓存"
PIP_CACHE="$HOME/Library/Caches/pip"
if [ -d "$PIP_CACHE" ]; then
    safe_clean_dir "$PIP_CACHE" "pip 下载缓存"
fi
echo ""

# 8. Maven 缓存（旧仓库数据）
print_info "8. Maven 本地仓库"
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

# 9. Playwright 浏览器缓存
print_info "9. Playwright 浏览器缓存"
safe_remove_dir "$HOME/Library/Caches/ms-playwright" "Playwright 浏览器"
echo ""

# 10. DNS 缓存
print_info "10. DNS 缓存刷新"
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
echo -e "\n${YELLOW}${SECTION_BAR}${NC}"
echo -e "${YELLOW}  第二部分: 中等风险清理（应用缓存，建议先关闭对应应用）${NC}"
echo -e "${YELLOW}${SECTION_BAR}${NC}\n"

# 10. 微信缓存
print_info "10. 微信缓存"
WECHAT_CONTAINER="$HOME/Library/Containers/com.tencent.xinWeChat"
if [ -d "$WECHAT_CONTAINER" ]; then
    size=$(get_size_bytes "$WECHAT_CONTAINER")
    echo -e "  ${CYAN}微信容器数据${NC}: $(format_size $size)"
    
    WECHAT_DATA="$WECHAT_CONTAINER/Data/Library/Application Support/com.tencent.xinWeChat"
    WECHAT_CACHE="$WECHAT_CONTAINER/Data/Library/Caches"
    WECHAT_TMP="$WECHAT_CONTAINER/Data/tmp"
    
    CLEANED=0
    
    if [ -d "$WECHAT_CACHE" ]; then
        cache_size=$(get_size_bytes "$WECHAT_CACHE")
        if [ "$cache_size" -gt 0 ]; then
            echo -e "    ${CYAN}缓存目录${NC}: $(format_size $cache_size)"
            if confirm "    清理缓存目录？"; then
                rm -rf "$WECHAT_CACHE"/* 2>/dev/null
                rm -rf "$WECHAT_CACHE"/.[!.]* 2>/dev/null
                TOTAL_FREED=$((TOTAL_FREED + cache_size))
                CLEANED=1
                print_success "    缓存已清理"
            fi
        fi
    fi
    
    if [ -d "$WECHAT_TMP" ]; then
        tmp_size=$(get_size_bytes "$WECHAT_TMP")
        if [ "$tmp_size" -gt 0 ]; then
            echo -e "    ${CYAN}临时文件${NC}: $(format_size $tmp_size)"
            if confirm "    清理临时文件？"; then
                rm -rf "$WECHAT_TMP"/* 2>/dev/null
                rm -rf "$WECHAT_TMP"/.[!.]* 2>/dev/null
                TOTAL_FREED=$((TOTAL_FREED + tmp_size))
                CLEANED=1
                print_success "    临时文件已清理"
            fi
        fi
    fi
    
    if [ -d "$WECHAT_DATA" ]; then
        MSG_TEMP="$WECHAT_DATA/2.0b4.0.1.15/Message/MessageTemp"
        FILE_CACHE="$WECHAT_DATA/2.0b4.0.0.15/FileStorage/Cache"
        IMAGE_CACHE="$WECHAT_DATA/2.0b4.0.0.15/FileStorage/ImageCache"
        VIDEO_CACHE="$WECHAT_DATA/2.0b4.0.0.15/FileStorage/VideoCache"
        
        for cache_dir in "$MSG_TEMP" "$FILE_CACHE" "$IMAGE_CACHE" "$VIDEO_CACHE"; do
            if [ -d "$cache_dir" ]; then
                cache_size=$(get_size_bytes "$cache_dir")
                if [ "$cache_size" -gt 0 ]; then
                    dir_name=$(basename "$cache_dir")
                    echo -e "    ${CYAN}$dir_name${NC}: $(format_size $cache_size)"
                    if confirm "    清理 $dir_name？"; then
                        rm -rf "$cache_dir"/* 2>/dev/null
                        rm -rf "$cache_dir"/.[!.]* 2>/dev/null
                        TOTAL_FREED=$((TOTAL_FREED + cache_size))
                        CLEANED=1
                        print_success "    $dir_name 已清理"
                    fi
                fi
            fi
        done
    fi
    
    if [ "$CLEANED" -eq 0 ]; then
        print_info "  无可清理项或已跳过"
    fi
fi
echo ""

# 11. WPS 缓存
print_info "11. WPS Office 缓存"
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

# 12. Telegram 缓存
print_info "12. Telegram 缓存"
TG_CACHE="$HOME/Library/Group Containers/6N38VWS5BX.ru.keepcoder.Telegram"
if [ -d "$TG_CACHE" ]; then
    size=$(get_size_bytes "$TG_CACHE")
    echo -e "  ${CYAN}Telegram 数据${NC}: $(format_size $size)"
    if confirm "  清理 Telegram 缓存文件？"; then
        find "$TG_CACHE" -name "Caches" -type d -exec rm -rf {} + 2>/dev/null
        find "$TG_CACHE" -name "tmp" -type d -exec rm -rf {} + 2>/dev/null
        print_success "  已清理 Telegram 缓存"
    else
        print_info "  已跳过"
    fi
fi
echo ""

# 13. QQ 缓存
print_info "13. QQ 缓存"
QQ_CONTAINER="$HOME/Library/Containers/com.tencent.qq"
if [ -d "$QQ_CONTAINER" ]; then
    size=$(get_size_bytes "$QQ_CONTAINER")
    echo -e "  ${CYAN}QQ容器数据${NC}: $(format_size $size)"

    QQ_CACHE="$QQ_CONTAINER/Data/Library/Caches"
    QQ_TMP="$QQ_CONTAINER/Data/tmp"

    CLEANED=0

    if [ -d "$QQ_CACHE" ]; then
        cache_size=$(get_size_bytes "$QQ_CACHE")
        if [ "$cache_size" -gt 0 ]; then
            echo -e "    ${CYAN}缓存目录${NC}: $(format_size $cache_size)"
            if confirm "    清理缓存目录？"; then
                rm -rf "$QQ_CACHE"/* 2>/dev/null
                rm -rf "$QQ_CACHE"/.[!.]* 2>/dev/null
                TOTAL_FREED=$((TOTAL_FREED + cache_size))
                CLEANED=1
                print_success "    缓存已清理"
            fi
        fi
    fi

    if [ -d "$QQ_TMP" ]; then
        tmp_size=$(get_size_bytes "$QQ_TMP")
        if [ "$tmp_size" -gt 0 ]; then
            echo -e "    ${CYAN}临时文件${NC}: $(format_size $tmp_size)"
            if confirm "    清理临时文件？"; then
                rm -rf "$QQ_TMP"/* 2>/dev/null
                rm -rf "$QQ_TMP"/.[!.]* 2>/dev/null
                TOTAL_FREED=$((TOTAL_FREED + tmp_size))
                CLEANED=1
                print_success "    临时文件已清理"
            fi
        fi
    fi

    QQ_DATA="$QQ_CONTAINER/Data/Library/Application Support/QQ"
    if [ -d "$QQ_DATA" ]; then
        IMAGE_CACHE="$QQ_DATA/Image"
        FILE_CACHE="$QQ_DATA/FileRecv"
        LOG_CACHE="$QQ_DATA/Logs"

        for cache_dir in "$IMAGE_CACHE" "$FILE_CACHE" "$LOG_CACHE"; do
            if [ -d "$cache_dir" ]; then
                cache_size=$(get_size_bytes "$cache_dir")
                if [ "$cache_size" -gt 0 ]; then
                    dir_name=$(basename "$cache_dir")
                    echo -e "    ${CYAN}$dir_name${NC}: $(format_size $cache_size)"
                    if confirm "    清理 $dir_name？"; then
                        rm -rf "$cache_dir"/* 2>/dev/null
                        rm -rf "$cache_dir"/.[!.]* 2>/dev/null
                        TOTAL_FREED=$((TOTAL_FREED + cache_size))
                        CLEANED=1
                        print_success "    $dir_name 已清理"
                    fi
                fi
            fi
        done
    fi

    if [ "$CLEANED" -eq 0 ]; then
        print_info "  无可清理项或已跳过"
    fi
fi
echo ""

# 14. Google Chrome 缓存
print_info "14. Google Chrome 缓存"
CHROME_CACHE="$HOME/Library/Application Support/Google/Chrome/Default/Service Worker"
CHROME_CACHE2="$HOME/Library/Application Support/Google/Chrome/Default/Cache"
CHROME_CODE="$HOME/Library/Application Support/Google/Chrome/Default/Code Cache"
CHROME_COMPONENT="$HOME/Library/Application Support/Google/Chrome/component_crx_cache"
CHROME_SODA_LANG="$HOME/Library/Application Support/Google/Chrome/SODALanguagePacks"
CHROME_SODA="$HOME/Library/Application Support/Google/Chrome/SODA"
CHROME_MODEL="$HOME/Library/Application Support/Google/Chrome/optimization_guide_model_store"
CHROME_GR_SHADER="$HOME/Library/Application Support/Google/Chrome/GrShaderCache"
CHROME_GRAPHITE="$HOME/Library/Application Support/Google/Chrome/GraphiteDawnCache"
CHROME_SHADER="$HOME/Library/Application Support/Google/Chrome/ShaderCache"
CHROME_BROWSER_METRICS="$HOME/Library/Application Support/Google/Chrome/BrowserMetrics"
CHROME_SNAPSHOTS="$HOME/Library/Application Support/Google/Chrome/Snapshots"
CHROME_EXT_CRX="$HOME/Library/Application Support/Google/Chrome/extensions_crx_cache"
CHROME_CRASHPAD="$HOME/Library/Application Support/Google/Chrome/Crashpad"
safe_remove_dir "$CHROME_CACHE" "Chrome Service Worker 缓存"
safe_remove_dir "$CHROME_CACHE2" "Chrome 网页缓存"
safe_remove_dir "$CHROME_CODE" "Chrome 代码缓存"
safe_remove_dir "$CHROME_COMPONENT" "Chrome 组件下载缓存"
safe_remove_dir "$CHROME_SODA_LANG" "Chrome 语音语言包缓存"
safe_remove_dir "$CHROME_SODA" "Chrome 语音模型缓存"
safe_remove_dir "$CHROME_MODEL" "Chrome 优化模型缓存"
safe_remove_dir "$CHROME_GR_SHADER" "Chrome GrShader 缓存"
safe_remove_dir "$CHROME_GRAPHITE" "Chrome GraphiteDawn 缓存"
safe_remove_dir "$CHROME_SHADER" "Chrome Shader 缓存"
safe_remove_dir "$CHROME_BROWSER_METRICS" "Chrome BrowserMetrics 缓存"
safe_remove_dir "$CHROME_SNAPSHOTS" "Chrome Snapshots 缓存"
safe_remove_dir "$CHROME_EXT_CRX" "Chrome 扩展安装包缓存"
safe_remove_dir "$CHROME_CRASHPAD" "Chrome Crashpad 缓存"
echo ""

# 15. 系统级桌面图片缓存
print_info "15. 桌面图片缓存 (/Library/Caches/Desktop Pictures)"
safe_remove_dir "/Library/Caches/Desktop Pictures" "桌面图片缓存"
echo ""

# 16. Windsurf 缓存
print_info "16. Windsurf IDE 缓存"
WS_DIR="$HOME/Library/Application Support/Windsurf"
if [ -d "$WS_DIR" ]; then
    safe_remove_dir "$WS_DIR/Cache" "Windsurf Cache"
    safe_remove_dir "$WS_DIR/CachedData" "Windsurf CachedData"
    safe_remove_dir "$WS_DIR/GPUCache" "Windsurf GPUCache"
    safe_remove_dir "$WS_DIR/Code Cache" "Windsurf Code Cache"
    safe_remove_dir "$WS_DIR/DawnWebGPUCache" "Windsurf DawnWebGPUCache"
    safe_remove_dir "$WS_DIR/DawnGraphiteCache" "Windsurf DawnGraphiteCache"
    
    WS_STORAGE="$WS_DIR/WebStorage"
    if [ -d "$WS_STORAGE" ]; then
        size=$(get_size_bytes "$WS_STORAGE")
        echo -e "  ${CYAN}Windsurf WebStorage${NC}: $(format_size $size)"
        print_warning "  此目录更接近登录态和内嵌网页会话数据，默认不建议清理"
        print_info "  已保留，如需处理请在明确接受重新登录风险后手动删除"
    fi
fi
echo ""

# 17. Choice 临时与日志缓存
print_info "17. Choice 临时与日志缓存"
CHOICE_DIR="$HOME/Library/Application Support/Choice"
if [ -d "$CHOICE_DIR" ]; then
    safe_remove_dir "$CHOICE_DIR/temp" "Choice 临时目录"
    safe_remove_dir "$CHOICE_DIR/logs" "Choice 日志目录"
    safe_remove_dir "$CHOICE_DIR/crash/Reports" "Choice 崩溃报告"
    safe_remove_dir "$CHOICE_DIR/crash/Data" "Choice 崩溃数据"
fi
echo ""

# 18. MathWorks 日志与本地作业缓存
print_info "18. MathWorks 日志与本地作业缓存"
MATHWORKS_DIR="$HOME/Library/Application Support/MathWorks"
if [ -d "$MATHWORKS_DIR" ]; then
    safe_remove_dir "$MATHWORKS_DIR/ServiceHost/logs" "MathWorks ServiceHost 日志"
    safe_remove_dir "$MATHWORKS_DIR/MATLAB/local_cluster_jobs" "MathWorks 本地作业缓存"
fi
echo ""

# ============================================================================
# 第三部分：开发工具清理
# ============================================================================
echo -e "\n${BLUE}${SECTION_BAR}${NC}"
echo -e "${BLUE}  第三部分: 开发工具清理${NC}"
echo -e "${BLUE}${SECTION_BAR}${NC}\n"

# 19. Safari 浏览器缓存
print_info "19. Safari 浏览器缓存"
SAFARI_CACHE="$HOME/Library/Caches/com.apple.Safari"
SAFARI_WEBKIT="$HOME/Library/Caches/com.apple.WebKit.WebContent"
SAFARI_FS="$HOME/Library/Safari/LocalStorage"
SAFARI_ICONS="$HOME/Library/Safari/Icons"
SAFARI_PERF="$HOME/Library/Caches/com.apple.Safari/PerSitePreferences"

for cache_dir in "$SAFARI_CACHE" "$SAFARI_WEBKIT" "$SAFARI_FS" "$SAFARI_ICONS" "$SAFARI_PERF"; do
    if [ -d "$cache_dir" ]; then
        cache_size=$(get_size_bytes "$cache_dir")
        if [ "$cache_size" -gt 0 ]; then
            dir_name=$(basename "$cache_dir")
            echo -e "  ${CYAN}$dir_name${NC}: $(format_size $cache_size)"
            if confirm "  清理 $dir_name？"; then
                rm -rf "$cache_dir"/* 2>/dev/null
                rm -rf "$cache_dir"/.[!.]* 2>/dev/null
                TOTAL_FREED=$((TOTAL_FREED + cache_size))
                print_success "  $dir_name 已清理"
            fi
        fi
    fi
done
echo ""

# 16. Xcode 缓存和派生数据
print_info "16. Xcode 派生数据和缓存"
XCODE_DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
XCODE_ARCHIVES="$HOME/Library/Developer/Xcode/Archives"
XCODE_DOCC="$HOME/Library/Developer/Shared/Documentation/DocSets"
XCODE_SIMULATOR="$HOME/Library/Developer/CoreSimulator"
XCODE_SIM_RUNTIME="$HOME/Library/Developer/CoreSimulator/Profiles/Runtimes"

for cache_dir in "$XCODE_DERIVED" "$XCODE_ARCHIVES"; do
    if [ -d "$cache_dir" ]; then
        cache_size=$(get_size_bytes "$cache_dir")
        if [ "$cache_size" -gt 0 ]; then
            dir_name=$(basename "$cache_dir")
            echo -e "  ${CYAN}$dir_name${NC}: $(format_size $cache_size)"
            if confirm "  清理 $dir_name？"; then
                rm -rf "$cache_dir"/* 2>/dev/null
                rm -rf "$cache_dir"/.[!.]* 2>/dev/null
                TOTAL_FREED=$((TOTAL_FREED + cache_size))
                print_success "  $dir_name 已清理"
            fi
        fi
    fi
done

if [ -d "$XCODE_SIMULATOR" ]; then
    sim_size=$(get_size_bytes "$XCODE_SIMULATOR")
    if [ "$sim_size" -gt 0 ]; then
        echo -e "  ${CYAN}CoreSimulator${NC}: $(format_size $sim_size)"
        if confirm "  清理模拟器数据？"; then
            rm -rf "$XCODE_SIMULATOR"/* 2>/dev/null
            rm -rf "$XCODE_SIMULATOR"/.[!.]* 2>/dev/null
            TOTAL_FREED=$((TOTAL_FREED + sim_size))
            print_success "  CoreSimulator 已清理"
        fi
    fi
fi
echo ""

# 17. iOS/iPadOS 备份文件
print_info "17. iOS/iPadOS 备份文件"
IOS_BACKUP="$HOME/Library/Application Support/MobileSync/Backup"
if [ -d "$IOS_BACKUP" ]; then
    backup_size=$(get_size_bytes "$IOS_BACKUP")
    if [ "$backup_size" -gt 0 ]; then
        echo -e "  ${CYAN}iOS 备份${NC}: $(format_size $backup_size)"
        print_warning "  删除后需重新备份设备"
        if confirm "  清理 iOS 备份？"; then
            rm -rf "$IOS_BACKUP"/* 2>/dev/null
            rm -rf "$IOS_BACKUP"/.[!.]* 2>/dev/null
            TOTAL_FREED=$((TOTAL_FREED + backup_size))
            print_success "  iOS 备份已清理"
        fi
    fi
fi
echo ""

# 20. 不活跃项目的 node_modules
print_info "20. 不活跃项目的 node_modules"
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

# 22. __pycache__ 目录
print_info "22. Python __pycache__ 缓存"
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
echo -e "\n${RED}${SECTION_BAR}${NC}"
echo -e "${RED}  第四部分: 系统级清理（需要管理员密码）${NC}"
echo -e "${RED}${SECTION_BAR}${NC}\n"

# 25. 系统诊断日志（2.7GB）
print_info "25. 系统诊断日志 (/private/var/db/diagnostics)"
if [ -d "/private/var/db/diagnostics" ]; then
    size=$(du -sk /private/var/db/diagnostics 2>/dev/null | awk '{print $1 * 1024}')
    echo -e "  ${CYAN}系统诊断日志${NC}: $(format_size $size)"
    print_warning "  这些是 Apple 统一日志，删除后不影响系统运行"
    # 在清理前先计算 uuidtext 大小
    uuidtext_size=$(du -sk /private/var/db/uuidtext 2>/dev/null | awk '{print $1 * 1024}')
    if confirm "  清理此项（需要 sudo）？"; then
        sudo rm -rf /private/var/db/diagnostics/* 2>/dev/null
        sudo rm -rf /private/var/db/uuidtext/* 2>/dev/null
        TOTAL_FREED=$((TOTAL_FREED + size))
        TOTAL_FREED=$((TOTAL_FREED + uuidtext_size))
        print_success "  已清理系统诊断日志和 UUID 文本"
    else
        print_info "  已跳过"
    fi
fi
echo ""

# 26. 系统日志
print_info "26. 系统日志 (/private/var/log)"
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

# 27. 临时文件夹（已排除 ask-continue-ports）
print_info "27. 系统临时文件 (/private/var/folders)"
if [ -d "/private/var/folders" ]; then
    size=$(du -sk /private/var/folders 2>/dev/null | awk '{print $1 * 1024}')
    echo -e "  ${CYAN}系统临时文件${NC}: $(format_size $size)"
    print_warning "  只清理超过7天的临时文件"
    print_warning "  [安全] 已排除 ask-continue-ports 相关文件"
    if confirm "  清理旧临时文件（需要 sudo）？"; then
        # 先查找所有 C 目录，然后清理时排除包含 ask-continue-ports 的路径
        sudo find /private/var/folders -name "C" -type d -mindepth 3 -maxdepth 3 2>/dev/null | while read d; do
            # 只删除超过7天的文件，但跳过 ask-continue-ports
            sudo find "$d" -mtime +7 ! -path "*ask-continue-ports*" -delete 2>/dev/null
        done
        # 额外确保 /private/tmp/ask-continue-ports 不被误删（显式保护）
        if [ -e "/private/tmp/ask-continue-ports" ]; then
            print_info "  已保护 /private/tmp/ask-continue-ports"
        fi
        print_success "  已清理7天以上的临时文件（ask-continue-ports 已保留）"
    else
        print_info "  已跳过"
    fi
fi
echo ""

# 28. /private/var/folders 定向垃圾清理
print_info "28. /private/var/folders 定向垃圾清理"
print_warning "只清理 3 天以上、已识别为可重复生成的临时克隆、memmap 和构建缓存"
TARGET_PATHS=()
while IFS= read -r path; do TARGET_PATHS+=("$path"); done < <(find /private/var/folders -path "*/X/com.google.Chrome.code_sign_clone" -mtime +3 2>/dev/null)
while IFS= read -r path; do TARGET_PATHS+=("$path"); done < <(find /private/var/folders -path "*/T/joblib_memmapping_folder_*" -mtime +3 2>/dev/null)
while IFS= read -r path; do TARGET_PATHS+=("$path"); done < <(find /private/var/folders -path "*/T/node-gyp-tmp-*" -mtime +3 2>/dev/null)
while IFS= read -r path; do TARGET_PATHS+=("$path"); done < <(find /private/var/folders -path "*/T/node-compile-cache" -mtime +3 2>/dev/null)

TARGET_TOTAL=0
for path in "${TARGET_PATHS[@]}"; do
    if [ -e "$path" ]; then
        size=$(get_size_bytes "$path")
        if [ "$size" -gt 0 ]; then
            echo -e "  ${CYAN}$path${NC}: $(format_size $size)"
            TARGET_TOTAL=$((TARGET_TOTAL + size))
        fi
    fi
done

RECENT_COUNT=0
while IFS= read -r _; do
    RECENT_COUNT=$((RECENT_COUNT + 1))
done < <(
    find /private/var/folders \( -path "*/X/com.google.Chrome.code_sign_clone" \
        -o -path "*/T/joblib_memmapping_folder_*" \
        -o -path "*/T/node-gyp-tmp-*" \
        -o -path "*/T/node-compile-cache" \) -mtime -3 2>/dev/null
)

if [ "$RECENT_COUNT" -gt 0 ] 2>/dev/null; then
    print_info "  检测到 $RECENT_COUNT 个近期仍在活跃的临时目录，出于安全未纳入本次清理"
fi

if [ "$TARGET_TOTAL" -gt 0 ]; then
    echo -e "  ${CYAN}合计${NC}: $(format_size $TARGET_TOTAL)"
    if confirm "  清理这些陈旧定向临时垃圾？"; then
        for path in "${TARGET_PATHS[@]}"; do
            if [ -e "$path" ]; then
                rm -rf "$path" 2>/dev/null || sudo rm -rf "$path" 2>/dev/null
            fi
        done
        TOTAL_FREED=$((TOTAL_FREED + TARGET_TOTAL))
        print_success "  定向临时垃圾已清理"
    else
        print_info "  已跳过"
    fi
else
    print_info "  未检测到可清理的陈旧定向临时垃圾"
fi
echo ""

# ============================================================================
# 第五部分: AI 工具深度清理 (Claude Code / Codex / Gemini CLI / OpenCode)
# ============================================================================
echo -e "\n${CYAN}${SECTION_BAR}${NC}"
echo -e "${CYAN}  第五部分: AI 工具深度清理 (Claude/Codex/Gemini/OpenCode)${NC}"
echo -e "${CYAN}${SECTION_BAR}${NC}\n"

# 20. Claude Code 缓存清理
print_info "20. Claude Code 缓存"
CLAUDE_DIR="$HOME/.claude"
if [ -d "$CLAUDE_DIR" ]; then
    CLAUDE_CACHE="$CLAUDE_DIR/cache"
    CLAUDE_DEBUG="$CLAUDE_DIR/debug"
    CLAUDE_DOWNLOADS="$CLAUDE_DIR/downloads"
    CLAUDE_PASTE="$CLAUDE_DIR/paste-cache"
    CLAUDE_PLUGINS_CACHE="$CLAUDE_DIR/plugins/cache"
    CLAUDE_SESSION_DATA="$CLAUDE_DIR/session-data"
    CLAUDE_FILE_HISTORY="$CLAUDE_DIR/file-history"
    CLAUDE_SHELL_SNAPSHOTS="$CLAUDE_DIR/shell-snapshots"
    CLAUDE_TASKS="$CLAUDE_DIR/tasks"
    CLAUDE_TODOS="$CLAUDE_DIR/todos"
    CLAUDE_SESSION_ENV="$CLAUDE_DIR/session-env"
    CLAUDE_IDE="$CLAUDE_DIR/ide"
    CLAUDE_METRICS="$CLAUDE_DIR/metrics"
    CLAUDE_TELEMETRY="$CLAUDE_DIR/telemetry"
    CLAUDE_BACKUPS="$CLAUDE_DIR/backups"

    for cache_dir in "$CLAUDE_CACHE" "$CLAUDE_DEBUG" "$CLAUDE_DOWNLOADS" "$CLAUDE_PASTE" "$CLAUDE_PLUGINS_CACHE" "$CLAUDE_SESSION_DATA" "$CLAUDE_FILE_HISTORY" "$CLAUDE_SHELL_SNAPSHOTS" "$CLAUDE_TASKS" "$CLAUDE_TODOS" "$CLAUDE_SESSION_ENV" "$CLAUDE_IDE" "$CLAUDE_METRICS" "$CLAUDE_TELEMETRY" "$CLAUDE_BACKUPS"; do
        if [ -d "$cache_dir" ]; then
            cache_size=$(get_size_bytes "$cache_dir")
            if [ "$cache_size" -gt 0 ]; then
                dir_name=$(basename "$cache_dir")
                echo -e "    ${CYAN}$dir_name${NC}: $(format_size $cache_size)"
                if confirm "    清理 $dir_name？"; then
                    rm -rf "$cache_dir"/* 2>/dev/null
                    rm -rf "$cache_dir"/.[!.]* 2>/dev/null
                    TOTAL_FREED=$((TOTAL_FREED + cache_size))
                    print_success "    $dir_name 已清理"
                fi
            fi
        fi
    done
else
    print_info "  未检测到 Claude Code"
fi
echo ""

# 21. OpenAI Codex 缓存清理
print_info "21. OpenAI Codex 缓存"
CODEX_DIR="$HOME/.codex"
if [ -d "$CODEX_DIR" ]; then
    CODEX_TMP="$CODEX_DIR/.tmp"
    CODEX_TMP2="$CODEX_DIR/tmp"
    CODEX_CACHE="$CODEX_DIR/cache"
    CODEX_LOG="$CODEX_DIR/log"
    CODEX_PLUGINS="$CODEX_DIR/plugins/cache"
    CODEX_SHM="$CODEX_DIR/logs_1.sqlite-shm"
    CODEX_WAL="$CODEX_DIR/logs_1.sqlite-wal"
    CODEX_MODELS="$CODEX_DIR/models_cache.json"
    CODEX_SKILLS="$CODEX_DIR/vendor_imports/skills-curated-cache.json"

    for cache_dir in "$CODEX_TMP" "$CODEX_TMP2" "$CODEX_CACHE" "$CODEX_LOG" "$CODEX_PLUGINS"; do
        if [ -d "$cache_dir" ]; then
            cache_size=$(get_size_bytes "$cache_dir")
            if [ "$cache_size" -gt 0 ]; then
                dir_name=$(basename "$cache_dir")
                echo -e "    ${CYAN}$dir_name${NC}: $(format_size $cache_size)"
                if confirm "    清理 $dir_name？"; then
                    rm -rf "$cache_dir"/* 2>/dev/null
                    rm -rf "$cache_dir"/.[!.]* 2>/dev/null
                    TOTAL_FREED=$((TOTAL_FREED + cache_size))
                    print_success "    $dir_name 已清理"
                fi
            fi
        fi
    done

    for cache_file in "$CODEX_SHM" "$CODEX_WAL" "$CODEX_MODELS" "$CODEX_SKILLS"; do
        if [ -f "$cache_file" ]; then
            file_size=$(get_size_bytes "$cache_file")
            if [ "$file_size" -gt 0 ]; then
                file_name=$(basename "$cache_file")
                echo -e "    ${CYAN}$file_name${NC}: $(format_size $file_size)"
                if confirm "    清理 $file_name？"; then
                    rm -f "$cache_file" 2>/dev/null
                    TOTAL_FREED=$((TOTAL_FREED + file_size))
                    print_success "    $file_name 已清理"
                fi
            fi
        fi
    done
else
    print_info "  未检测到 OpenAI Codex"
fi
echo ""

# 22. Gemini CLI 缓存清理
print_info "22. Gemini CLI 缓存"
GEMINI_DIR="$HOME/.gemini"
if [ -d "$GEMINI_DIR" ]; then
    GEMINI_CACHE="$GEMINI_DIR/cache"
    GEMINI_TMP="$GEMINI_DIR/tmp"
    GEMINI_TELEMETRY="$GEMINI_DIR/telemetry.log"

    for cache_dir in "$GEMINI_CACHE" "$GEMINI_TMP"; do
        if [ -d "$cache_dir" ]; then
            cache_size=$(get_size_bytes "$cache_dir")
            if [ "$cache_size" -gt 0 ]; then
                dir_name=$(basename "$cache_dir")
                echo -e "    ${CYAN}$dir_name${NC}: $(format_size $cache_size)"
                if confirm "    清理 $dir_name？"; then
                    rm -rf "$cache_dir"/* 2>/dev/null
                    rm -rf "$cache_dir"/.[!.]* 2>/dev/null
                    TOTAL_FREED=$((TOTAL_FREED + cache_size))
                    print_success "    $dir_name 已清理"
                fi
            fi
        fi
    done

    if [ -f "$GEMINI_TELEMETRY" ]; then
        tel_size=$(get_size_bytes "$GEMINI_TELEMETRY")
        if [ "$tel_size" -gt 0 ]; then
            echo -e "    ${CYAN}telemetry.log${NC}: $(format_size $tel_size)"
            if confirm "    清理 telemetry.log？"; then
                rm -f "$GEMINI_TELEMETRY" 2>/dev/null
                TOTAL_FREED=$((TOTAL_FREED + tel_size))
                print_success "    telemetry.log 已清理"
            fi
        fi
    fi
else
    print_info "  未检测到 Gemini CLI"
fi
echo ""

# 23. OpenCode 缓存清理
print_info "23. OpenCode 缓存"
OPENCODE_CACHE="$HOME/Library/Caches/opencode"
OPENCODE_DATA="$HOME/.local/share/opencode"
OPENCODE_CONFIG="$HOME/.config/opencode"
OPENCODE_LOG="$HOME/Library/Logs/opencode"

if [ -d "$OPENCODE_CACHE" ] || [ -d "$OPENCODE_DATA" ] || [ -d "$OPENCODE_CONFIG" ] || [ -d "$OPENCODE_LOG" ]; then
    for cache_dir in "$OPENCODE_CACHE" "$OPENCODE_DATA/tool-output" "$OPENCODE_DATA/log" "$OPENCODE_DATA/snapshot" "$OPENCODE_LOG"; do
        if [ -d "$cache_dir" ]; then
            cache_size=$(get_size_bytes "$cache_dir")
            if [ "$cache_size" -gt 0 ]; then
                dir_name=$(basename "$cache_dir")
                echo -e "    ${CYAN}$dir_name${NC}: $(format_size $cache_size)"
                if confirm "    清理 $dir_name？"; then
                    rm -rf "$cache_dir"/* 2>/dev/null
                    rm -rf "$cache_dir"/.[!.]* 2>/dev/null
                    TOTAL_FREED=$((TOTAL_FREED + cache_size))
                    print_success "    $dir_name 已清理"
                fi
            fi
        fi
    done

    OPENCODE_DB_SHM="$OPENCODE_DATA/opencode.db-shm"
    OPENCODE_DB_WAL="$OPENCODE_DATA/opencode.db-wal"
    for db_file in "$OPENCODE_DB_SHM" "$OPENCODE_DB_WAL"; do
        if [ -f "$db_file" ]; then
            db_size=$(get_size_bytes "$db_file")
            if [ "$db_size" -gt 0 ]; then
                file_name=$(basename "$db_file")
                echo -e "    ${CYAN}$file_name${NC}: $(format_size $db_size)"
                if confirm "    清理 $file_name？"; then
                    rm -f "$db_file" 2>/dev/null
                    TOTAL_FREED=$((TOTAL_FREED + db_size))
                    print_success "    $file_name 已清理"
                fi
            fi
        fi
    done
else
    print_info "  未检测到 OpenCode"
fi
echo ""

# ============================================================================
# 清理完成
# ============================================================================
echo -e "\n${GREEN}${SECTION_BAR}${NC}"
echo -e "${GREEN}  清理完成！${NC}"
echo -e "${GREEN}${SECTION_BAR}${NC}\n"

echo -e "本次清理释放空间: ${GREEN}$(format_size $TOTAL_FREED)${NC}"
echo ""
print_warning "清理后建议重启电脑，让系统重新计算存储空间"
echo ""
