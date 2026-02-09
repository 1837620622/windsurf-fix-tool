# ============================================================================
# Windsurf 修复工具 - Windows 版本 (PowerShell)
# 用于修复 Windsurf IDE 卡顿、Shell无法连接等常见问题
# 基于官方文档: https://docs.windsurf.com/troubleshooting/windsurf-common-issues
# 使用方法: 以管理员身份运行 PowerShell，执行 .\fix-windsurf-win.ps1
# ============================================================================

#Requires -Version 5.1

# ----------------------------------------------------------------------------
# 编码设置
# ----------------------------------------------------------------------------
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ----------------------------------------------------------------------------
# 路径定义
# ----------------------------------------------------------------------------
$CodeiumDir = "$env:USERPROFILE\.codeium"
$WindsurfDir = "$CodeiumDir\windsurf"
$CascadeDir = "$WindsurfDir\cascade"
$BackupDir = "$env:USERPROFILE\.windsurf-backup-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$SettingsJsonPath = "$env:APPDATA\Windsurf\User\settings.json"

# ----------------------------------------------------------------------------
# 颜色输出函数
# ----------------------------------------------------------------------------
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    switch ($Type) {
        "Info"    { Write-Host "[信息] " -ForegroundColor Blue -NoNewline; Write-Host $Message }
        "Success" { Write-Host "[成功] " -ForegroundColor Green -NoNewline; Write-Host $Message }
        "Warning" { Write-Host "[警告] " -ForegroundColor Yellow -NoNewline; Write-Host $Message }
        "Error"   { Write-Host "[错误] " -ForegroundColor Red -NoNewline; Write-Host $Message }
        "Header"  { Write-Host $Message -ForegroundColor Cyan }
    }
}

function Write-Header {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Windsurf 修复工具 - Windows" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

# ----------------------------------------------------------------------------
# 确认操作函数
# ----------------------------------------------------------------------------
function Confirm-Action {
    param([string]$Message = "确认执行此操作？")
    
    $choice = Read-Host "$Message [y/N]"
    return ($choice -eq 'y' -or $choice -eq 'Y')
}

# ----------------------------------------------------------------------------
# 检测系统信息
# ----------------------------------------------------------------------------
function Get-SystemInfo {
    Write-ColorOutput "正在检测系统信息..." "Info"
    
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $arch = if ([Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
    
    Write-Host ""
    Write-Host "  Windows版本: " -NoNewline; Write-Host "$($osInfo.Caption)" -ForegroundColor Green
    Write-Host "  系统架构: " -NoNewline; Write-Host "$arch" -ForegroundColor Green
    Write-Host "  用户目录: " -NoNewline; Write-Host "$env:USERPROFILE" -ForegroundColor Green
    Write-Host ""
}

# ----------------------------------------------------------------------------
# 检查管理员权限
# ----------------------------------------------------------------------------
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ----------------------------------------------------------------------------
# 检查Windsurf是否正在运行
# ----------------------------------------------------------------------------
function Test-WindsurfRunning {
    $processes = Get-Process -Name "Windsurf" -ErrorAction SilentlyContinue
    
    if ($processes) {
        Write-ColorOutput "检测到 Windsurf 正在运行" "Warning"
        Write-Host "  请先关闭 Windsurf 再执行修复操作"
        
        if (Confirm-Action "是否自动关闭Windsurf？") {
            $processes | Stop-Process -Force
            Start-Sleep -Seconds 2
            Write-ColorOutput "Windsurf 已关闭" "Success"
            return $true
        }
        else {
            Write-ColorOutput "请手动关闭 Windsurf 后重试" "Error"
            return $false
        }
    }
    return $true
}

# ----------------------------------------------------------------------------
# 功能1: 清理Cascade缓存
# ----------------------------------------------------------------------------
function Clear-CascadeCache {
    Write-ColorOutput "清理 Cascade 缓存..." "Info"
    Write-ColorOutput "此操作将删除对话历史和本地设置！" "Warning"
    
    if (-not (Test-Path $CascadeDir)) {
        Write-ColorOutput "Cascade 缓存目录不存在，无需清理" "Info"
        return
    }
    
    if (Confirm-Action) {
        # 备份
        try {
            New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
            Copy-Item -Path $CascadeDir -Destination "$BackupDir\cascade" -Recurse -Force
            Write-ColorOutput "已备份到: $BackupDir" "Info"
        }
        catch {
            Write-ColorOutput "备份失败: $_" "Warning"
        }
        
        # 删除
        try {
            Remove-Item -Path $CascadeDir -Recurse -Force
            Write-ColorOutput "Cascade 缓存已清理" "Success"
        }
        catch {
            Write-ColorOutput "清理失败: $_" "Error"
        }
    }
    else {
        Write-ColorOutput "已取消操作" "Info"
    }
}

# ----------------------------------------------------------------------------
# 功能2: 清理扩展缓存
# ----------------------------------------------------------------------------
function Clear-ExtensionCache {
    Write-ColorOutput "清理扩展缓存..." "Info"
    
    $cacheDir = "$WindsurfDir\CachedData"
    
    if (Confirm-Action) {
        if (Test-Path $cacheDir) {
            try {
                Remove-Item -Path $cacheDir -Recurse -Force
                Write-ColorOutput "已清理 CachedData" "Success"
            }
            catch {
                Write-ColorOutput "清理失败: $_" "Error"
            }
        }
        else {
            Write-ColorOutput "CachedData 目录不存在" "Info"
        }
        
        Write-ColorOutput "扩展缓存清理完成" "Success"
    }
    else {
        Write-ColorOutput "已取消操作" "Info"
    }
}

# ----------------------------------------------------------------------------
# 功能3: 清理启动缓存（不清理对话历史）
# ----------------------------------------------------------------------------
function Clear-StartupCache {
    Write-ColorOutput "清理启动相关缓存（解决启动卡顿）..." "Info"
    
    Write-Host ""
    Write-Host "此操作将清理以下缓存以加速启动:"
    Write-Host "  - GPUCache (GPU渲染缓存)"
    Write-Host "  - CachedData (编辑器缓存数据)"
    Write-Host "  - CachedExtensions (扩展缓存)"
    Write-Host "  - Code Cache (代码缓存)"
    Write-Host "  - 7天以上的日志文件"
    Write-Host ""
    Write-ColorOutput "此操作 不会 清理对话历史！" "Success"
    Write-Host ""
    
    if (Confirm-Action) {
        if (-not (Test-WindsurfRunning)) { return }
        
        $windsurfAppData = "$env:APPDATA\Windsurf"
        
        # 清理 GPUCache
        $gpuCache = "$windsurfAppData\GPUCache"
        if (Test-Path $gpuCache) {
            Remove-Item -Path $gpuCache -Recurse -Force -ErrorAction SilentlyContinue
            Write-ColorOutput "已清理 GPUCache" "Success"
        }
        
        # 清理 CachedData
        $cachedData = "$WindsurfDir\CachedData"
        if (Test-Path $cachedData) {
            Remove-Item -Path $cachedData -Recurse -Force -ErrorAction SilentlyContinue
            Write-ColorOutput "已清理 CachedData" "Success"
        }
        
        # 清理 CachedExtensions
        $cachedExt = "$WindsurfDir\CachedExtensions"
        if (Test-Path $cachedExt) {
            Remove-Item -Path $cachedExt -Recurse -Force -ErrorAction SilentlyContinue
            Write-ColorOutput "已清理 CachedExtensions" "Success"
        }
        
        # 清理 Code Cache
        $codeCache = "$windsurfAppData\Code Cache"
        if (Test-Path $codeCache) {
            Remove-Item -Path $codeCache -Recurse -Force -ErrorAction SilentlyContinue
            Write-ColorOutput "已清理 Code Cache" "Success"
        }
        
        # 清理旧日志
        $logsDir = "$windsurfAppData\logs"
        if (Test-Path $logsDir) {
            Get-ChildItem -Path $logsDir -File -Recurse | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-ColorOutput "已清理旧日志文件" "Success"
        }
        
        Write-Host ""
        Write-ColorOutput "启动缓存清理完成！" "Success"
        Write-ColorOutput "重启 Windsurf 后启动速度应该会改善" "Info"
    }
    else {
        Write-ColorOutput "已取消操作" "Info"
    }
}

# ----------------------------------------------------------------------------
# 功能4: MCP诊断
# ----------------------------------------------------------------------------
function Test-MCP {
    Write-ColorOutput "MCP (Model Context Protocol) 诊断..." "Info"
    
    $mcpConfig = "$WindsurfDir\mcp_config.json"
    $mcpConfigOld = "$CodeiumDir\mcp_config.json"
    
    Write-Host ""
    Write-Host "MCP 配置文件状态:" -ForegroundColor Cyan
    Write-Host ""
    
    if (Test-Path $mcpConfig) {
        Write-ColorOutput "找到 MCP 配置: $mcpConfig" "Success"
        Write-Host ""
        Write-Host "配置内容预览:"
        Get-Content $mcpConfig -TotalCount 30 | ForEach-Object { Write-Host "  $_" }
        Write-Host ""
        
        # 验证 JSON 格式
        try {
            $null = Get-Content $mcpConfig -Raw | ConvertFrom-Json
            Write-ColorOutput "MCP 配置 JSON 格式有效" "Success"
        }
        catch {
            Write-ColorOutput "MCP 配置 JSON 格式无效！" "Error"
        }
    }
    else {
        Write-ColorOutput "未找到 MCP 配置文件: $mcpConfig" "Warning"
    }
    
    if (Test-Path $mcpConfigOld) {
        Write-ColorOutput "发现旧版 MCP 配置: $mcpConfigOld" "Info"
    }
    
    Write-Host ""
    Write-Host "运行时检查:" -ForegroundColor Cyan
    Write-Host ""
    
    # 检查 Node.js
    try {
        $nodeVersion = & node --version 2>$null
        Write-ColorOutput "Node.js: $nodeVersion" "Success"
    }
    catch {
        Write-ColorOutput "未找到 Node.js" "Warning"
    }
    
    # 检查 npx
    try {
        $null = Get-Command npx -ErrorAction Stop
        Write-ColorOutput "npx 可用" "Success"
    }
    catch {
        Write-ColorOutput "未找到 npx" "Warning"
    }
    
    # 检查 Python
    try {
        $pyVersion = & python --version 2>$null
        Write-ColorOutput "Python: $pyVersion" "Success"
    }
    catch {
        Write-ColorOutput "未找到 Python" "Warning"
    }
    
    # 检查 uvx
    try {
        $null = Get-Command uvx -ErrorAction Stop
        Write-ColorOutput "uvx 可用" "Success"
    }
    catch {
        Write-ColorOutput "uvx 未安装" "Info"
    }
}

# ----------------------------------------------------------------------------
# 功能5: 重置MCP配置
# ----------------------------------------------------------------------------
function Reset-MCPConfig {
    Write-ColorOutput "重置 MCP 配置..." "Info"
    
    $mcpConfig = "$WindsurfDir\mcp_config.json"
    
    Write-Host ""
    Write-ColorOutput "此操作将备份并重置 MCP 配置文件" "Warning"
    Write-Host ""
    
    if (-not (Test-Path $mcpConfig)) {
        Write-ColorOutput "MCP 配置文件不存在" "Info"
        return
    }
    
    if (Confirm-Action) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
        Copy-Item -Path $mcpConfig -Destination "$BackupDir\mcp_config.json.bak" -Force
        Write-ColorOutput "已备份到: $BackupDir\mcp_config.json.bak" "Info"
        
        @'
{
  "mcpServers": {}
}
'@ | Out-File -FilePath $mcpConfig -Encoding UTF8
        
        Write-ColorOutput "MCP 配置已重置" "Success"
    }
    else {
        Write-ColorOutput "已取消操作" "Info"
    }
}

# ----------------------------------------------------------------------------
# 功能6: 清理开发工具缓存
# ----------------------------------------------------------------------------
function Clear-DevCaches {
    Write-ColorOutput "扫描开发工具缓存..." "Info"
    
    Write-Host ""
    Write-Host "正在检测各类开发工具缓存大小..." -ForegroundColor Cyan
    Write-Host ""
    
    $totalSize = 0
    $cleanableItems = @()
    
    # npm 缓存
    $npmCache = "$env:APPDATA\npm-cache"
    if (Test-Path $npmCache) {
        $size = [math]::Round((Get-ChildItem $npmCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host "  [npm 缓存] $npmCache - " -NoNewline; Write-Host "${size}MB" -ForegroundColor Yellow
        $totalSize += $size
        $cleanableItems += "npm"
    }
    
    # pip 缓存
    $pipCache = "$env:LOCALAPPDATA\pip\cache"
    if (Test-Path $pipCache) {
        $size = [math]::Round((Get-ChildItem $pipCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host "  [pip 缓存] $pipCache - " -NoNewline; Write-Host "${size}MB" -ForegroundColor Yellow
        $totalSize += $size
        $cleanableItems += "pip"
    }
    
    # uv 缓存
    $uvCache = "$env:LOCALAPPDATA\uv\cache"
    if (Test-Path $uvCache) {
        $size = [math]::Round((Get-ChildItem $uvCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host "  [uv 缓存] $uvCache - " -NoNewline; Write-Host "${size}MB" -ForegroundColor Yellow
        $totalSize += $size
        $cleanableItems += "uv"
    }
    
    # Maven 缓存
    $mavenCache = "$env:USERPROFILE\.m2\repository"
    if (Test-Path $mavenCache) {
        $size = [math]::Round((Get-ChildItem $mavenCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host "  [Maven 缓存] $mavenCache - " -NoNewline; Write-Host "${size}MB" -ForegroundColor Yellow
        $totalSize += $size
        $cleanableItems += "maven"
    }
    
    # Gradle 缓存
    $gradleCache = "$env:USERPROFILE\.gradle\caches"
    if (Test-Path $gradleCache) {
        $size = [math]::Round((Get-ChildItem $gradleCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host "  [Gradle 缓存] $gradleCache - " -NoNewline; Write-Host "${size}MB" -ForegroundColor Yellow
        $totalSize += $size
        $cleanableItems += "gradle"
    }
    
    # Yarn 缓存
    $yarnCache = "$env:LOCALAPPDATA\Yarn\Cache"
    if (Test-Path $yarnCache) {
        $size = [math]::Round((Get-ChildItem $yarnCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host "  [Yarn 缓存] $yarnCache - " -NoNewline; Write-Host "${size}MB" -ForegroundColor Yellow
        $totalSize += $size
        $cleanableItems += "yarn"
    }
    
    # pnpm 缓存
    $pnpmStore = "$env:LOCALAPPDATA\pnpm-store"
    if (Test-Path $pnpmStore) {
        $size = [math]::Round((Get-ChildItem $pnpmStore -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host "  [pnpm 缓存] $pnpmStore - " -NoNewline; Write-Host "${size}MB" -ForegroundColor Yellow
        $totalSize += $size
        $cleanableItems += "pnpm"
    }
    
    # NuGet 缓存
    $nugetCache = "$env:USERPROFILE\.nuget\packages"
    if (Test-Path $nugetCache) {
        $size = [math]::Round((Get-ChildItem $nugetCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host "  [NuGet 缓存] $nugetCache - " -NoNewline; Write-Host "${size}MB" -ForegroundColor Yellow
        $totalSize += $size
        $cleanableItems += "nuget"
    }
    
    # Selenium/WebDriver 缓存
    $seleniumCache = "$env:USERPROFILE\.cache\selenium"
    $wdmCache = "$env:USERPROFILE\.wdm"
    $selSize = 0
    if (Test-Path $seleniumCache) {
        $selSize += [math]::Round((Get-ChildItem $seleniumCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
    }
    if (Test-Path $wdmCache) {
        $selSize += [math]::Round((Get-ChildItem $wdmCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
    }
    if ($selSize -gt 0) {
        Write-Host "  [Selenium/WebDriver] - " -NoNewline; Write-Host "${selSize}MB" -ForegroundColor Yellow
        $totalSize += $selSize
        $cleanableItems += "selenium"
    }
    
    # Go 缓存
    $goCache = "$env:USERPROFILE\go\pkg\mod\cache"
    if (Test-Path $goCache) {
        $size = [math]::Round((Get-ChildItem $goCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host "  [Go 模块缓存] $goCache - " -NoNewline; Write-Host "${size}MB" -ForegroundColor Yellow
        $totalSize += $size
        $cleanableItems += "go"
    }
    
    # Cargo/Rust 缓存
    $cargoCache = "$env:USERPROFILE\.cargo\registry"
    if (Test-Path $cargoCache) {
        $size = [math]::Round((Get-ChildItem $cargoCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host "  [Cargo 缓存] $cargoCache - " -NoNewline; Write-Host "${size}MB" -ForegroundColor Yellow
        $totalSize += $size
        $cleanableItems += "cargo"
    }
    
    # conda 缓存
    foreach ($condaDir in @("$env:USERPROFILE\miniconda3\pkgs", "$env:USERPROFILE\anaconda3\pkgs")) {
        if (Test-Path $condaDir) {
            $size = [math]::Round((Get-ChildItem $condaDir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
            Write-Host "  [conda 包缓存] $condaDir - " -NoNewline; Write-Host "${size}MB" -ForegroundColor Yellow
            $totalSize += $size
            $cleanableItems += "conda"
            break
        }
    }
    
    Write-Host ""
    Write-Host "  可清理总计: " -NoNewline -ForegroundColor Cyan; Write-Host "${totalSize}MB" -ForegroundColor Yellow
    Write-Host ""
    
    if ($cleanableItems.Count -eq 0) {
        Write-ColorOutput "未检测到可清理的开发工具缓存" "Info"
        return
    }
    
    Write-Host "请选择清理方式:" -ForegroundColor Yellow
    Write-Host "  1) 全部清理（推荐安全项）"
    Write-Host "  2) 逐项选择清理"
    Write-Host "  3) 取消"
    Write-Host ""
    $cleanChoice = Read-Host "请选择 [1-3]"
    
    switch ($cleanChoice) {
        "1" {
            foreach ($item in $cleanableItems) {
                switch ($item) {
                    "npm" {
                        try { & npm cache clean --force 2>$null } catch { Remove-Item "$npmCache\_cacache" -Recurse -Force -ErrorAction SilentlyContinue }
                        Write-ColorOutput "npm 缓存已清理" "Success"
                    }
                    "pip" {
                        try { & pip cache purge 2>$null } catch { Remove-Item $pipCache -Recurse -Force -ErrorAction SilentlyContinue }
                        Write-ColorOutput "pip 缓存已清理" "Success"
                    }
                    "uv" {
                        Remove-Item $uvCache -Recurse -Force -ErrorAction SilentlyContinue
                        Write-ColorOutput "uv 缓存已清理" "Success"
                    }
                    "maven" { Write-ColorOutput "Maven 缓存跳过（删除后需重新下载依赖）" "Warning" }
                    "gradle" { Write-ColorOutput "Gradle 缓存跳过（删除后需重新下载依赖）" "Warning" }
                    "yarn" {
                        try { & yarn cache clean 2>$null } catch { Remove-Item $yarnCache -Recurse -Force -ErrorAction SilentlyContinue }
                        Write-ColorOutput "Yarn 缓存已清理" "Success"
                    }
                    "pnpm" {
                        try { & pnpm store prune 2>$null } catch {}
                        Write-ColorOutput "pnpm 缓存已清理" "Success"
                    }
                    "nuget" { Write-ColorOutput "NuGet 缓存跳过（建议使用 dotnet nuget locals all --clear）" "Warning" }
                    "selenium" {
                        Remove-Item $seleniumCache -Recurse -Force -ErrorAction SilentlyContinue
                        Remove-Item $wdmCache -Recurse -Force -ErrorAction SilentlyContinue
                        Write-ColorOutput "Selenium/WebDriver 缓存已清理" "Success"
                    }
                    "go" {
                        try { & go clean -modcache 2>$null } catch {}
                        Write-ColorOutput "Go 模块缓存已清理" "Success"
                    }
                    "cargo" { Write-ColorOutput "Cargo 缓存跳过" "Warning" }
                    "conda" {
                        try { & conda clean --all -y 2>$null } catch {}
                        Write-ColorOutput "conda 缓存已清理" "Success"
                    }
                }
            }
            Write-Host ""
            Write-ColorOutput "开发工具缓存清理完成！" "Success"
        }
        "2" {
            foreach ($item in $cleanableItems) {
                $label = switch ($item) {
                    "npm" { "npm 缓存" }
                    "pip" { "pip 缓存" }
                    "uv" { "uv 缓存" }
                    "maven" { "Maven 缓存" }
                    "gradle" { "Gradle 缓存" }
                    "yarn" { "Yarn 缓存" }
                    "pnpm" { "pnpm 缓存" }
                    "nuget" { "NuGet 缓存" }
                    "selenium" { "Selenium/WebDriver 缓存" }
                    "go" { "Go 模块缓存" }
                    "cargo" { "Cargo 缓存" }
                    "conda" { "conda 包缓存" }
                    default { $item }
                }
                
                if (Confirm-Action "清理 ${label}？") {
                    switch ($item) {
                        "npm" { try { & npm cache clean --force 2>$null } catch { Remove-Item "$npmCache\_cacache" -Recurse -Force -ErrorAction SilentlyContinue } }
                        "pip" { try { & pip cache purge 2>$null } catch { Remove-Item $pipCache -Recurse -Force -ErrorAction SilentlyContinue } }
                        "uv" { Remove-Item $uvCache -Recurse -Force -ErrorAction SilentlyContinue }
                        "maven" { Remove-Item $mavenCache -Recurse -Force -ErrorAction SilentlyContinue }
                        "gradle" { Remove-Item $gradleCache -Recurse -Force -ErrorAction SilentlyContinue }
                        "yarn" { try { & yarn cache clean 2>$null } catch { Remove-Item $yarnCache -Recurse -Force -ErrorAction SilentlyContinue } }
                        "pnpm" { try { & pnpm store prune 2>$null } catch {} }
                        "nuget" { try { & dotnet nuget locals all --clear 2>$null } catch { Remove-Item $nugetCache -Recurse -Force -ErrorAction SilentlyContinue } }
                        "selenium" { Remove-Item $seleniumCache, $wdmCache -Recurse -Force -ErrorAction SilentlyContinue }
                        "go" { try { & go clean -modcache 2>$null } catch {} }
                        "cargo" { Remove-Item $cargoCache -Recurse -Force -ErrorAction SilentlyContinue }
                        "conda" { try { & conda clean --all -y 2>$null } catch {} }
                    }
                    Write-ColorOutput "$label 已清理" "Success"
                }
            }
        }
        default { Write-ColorOutput "已取消操作" "Info" }
    }
}

# ----------------------------------------------------------------------------
# 功能7: 清理Windows系统缓存
# ----------------------------------------------------------------------------
function Clear-SystemCaches {
    Write-ColorOutput "扫描 Windows 系统缓存..." "Info"
    
    Write-Host ""
    Write-Host "正在检测系统级缓存..." -ForegroundColor Cyan
    Write-Host ""
    
    $totalSize = 0
    
    # 用户临时文件
    $userTemp = $env:TEMP
    if (Test-Path $userTemp) {
        $size = [math]::Round((Get-ChildItem $userTemp -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host "  [用户临时文件] $userTemp - " -NoNewline; Write-Host "${size}MB" -ForegroundColor Yellow
        $totalSize += $size
    }
    
    # Windows 临时文件
    $winTemp = "$env:SystemRoot\Temp"
    if (Test-Path $winTemp) {
        $size = [math]::Round((Get-ChildItem $winTemp -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host "  [Windows 临时文件] $winTemp - " -NoNewline; Write-Host "${size}MB" -ForegroundColor Yellow
        $totalSize += $size
    }
    
    # 回收站
    $recycleBin = (New-Object -ComObject Shell.Application).Namespace(0xA)
    $rbCount = $recycleBin.Items().Count
    if ($rbCount -gt 0) {
        Write-Host "  [回收站] ${rbCount}个项目" -ForegroundColor Green
    }
    
    # Windows Update 缓存
    $wuCache = "$env:SystemRoot\SoftwareDistribution\Download"
    if (Test-Path $wuCache) {
        $size = [math]::Round((Get-ChildItem $wuCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host "  [Windows Update 缓存] - " -NoNewline; Write-Host "${size}MB" -ForegroundColor Yellow
        $totalSize += $size
    }
    
    # Windsurf 旧备份
    $backups = Get-ChildItem "$env:USERPROFILE\.windsurf-backup-*" -Directory -ErrorAction SilentlyContinue
    if ($backups) {
        $bkSize = [math]::Round(($backups | Get-ChildItem -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
        Write-Host "  [Windsurf 旧备份] $($backups.Count)个备份目录 - " -NoNewline; Write-Host "${bkSize}MB" -ForegroundColor Yellow
        $totalSize += $bkSize
    }
    
    # 旧诊断报告
    $diagReports = Get-ChildItem "$env:USERPROFILE\windsurf-diagnostic-*.txt" -ErrorAction SilentlyContinue
    if ($diagReports) {
        Write-Host "  [旧诊断报告] $($diagReports.Count)个文件" -ForegroundColor Green
    }
    
    # DNS 缓存
    Write-Host "  [DNS 缓存] 系统DNS缓存（可刷新）" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "  系统缓存总计: " -NoNewline -ForegroundColor Cyan; Write-Host "${totalSize}MB" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "请选择清理项目:" -ForegroundColor Yellow
    Write-Host "  1) 清理用户临时文件"
    Write-Host "  2) 清理 Windows 临时文件（需管理员）"
    Write-Host "  3) 清空回收站"
    Write-Host "  4) 清理 Windsurf 旧备份目录"
    Write-Host "  5) 清理旧诊断报告"
    Write-Host "  6) 刷新 DNS 缓存"
    Write-Host "  7) 全部执行（安全项）"
    Write-Host "  0) 取消"
    Write-Host ""
    $sysChoice = Read-Host "请选择 [0-7]"
    
    switch ($sysChoice) {
        "1" {
            Get-ChildItem $userTemp -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-ColorOutput "用户临时文件已清理（保留7天内）" "Success"
        }
        "2" {
            if (Test-Administrator) {
                Get-ChildItem $winTemp -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-ColorOutput "Windows 临时文件已清理" "Success"
            }
            else {
                Write-ColorOutput "需要管理员权限" "Error"
            }
        }
        "3" {
            if (Confirm-Action) {
                Clear-RecycleBin -Force -ErrorAction SilentlyContinue
                Write-ColorOutput "回收站已清空" "Success"
            }
        }
        "4" {
            if ($backups) {
                Write-ColorOutput "将删除 $($backups.Count) 个 Windsurf 旧备份目录" "Info"
                if (Confirm-Action) {
                    $backups | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                    Write-ColorOutput "Windsurf 旧备份已清理" "Success"
                }
            }
            else {
                Write-ColorOutput "没有旧备份需要清理" "Info"
            }
        }
        "5" {
            if ($diagReports) {
                $diagReports | Remove-Item -Force -ErrorAction SilentlyContinue
                Write-ColorOutput "旧诊断报告已清理" "Success"
            }
        }
        "6" {
            ipconfig /flushdns 2>$null | Out-Null
            Write-ColorOutput "DNS 缓存已刷新" "Success"
        }
        "7" {
            Write-ColorOutput "执行全部安全清理项..." "Info"
            
            Get-ChildItem $userTemp -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-ColorOutput "用户临时文件已清理" "Success"
            
            if ($backups) {
                $backups | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-ColorOutput "Windsurf 旧备份已清理" "Success"
            }
            
            if ($diagReports) {
                $diagReports | Remove-Item -Force -ErrorAction SilentlyContinue
                Write-ColorOutput "旧诊断报告已清理" "Success"
            }
            
            ipconfig /flushdns 2>$null | Out-Null
            Write-ColorOutput "DNS 缓存已刷新" "Success"
            
            Write-Host ""
            Write-ColorOutput "系统缓存清理完成！" "Success"
        }
        default { Write-ColorOutput "已取消操作" "Info" }
    }
}

# ----------------------------------------------------------------------------
# 功能8: 磁盘空间分析
# ----------------------------------------------------------------------------
function Get-DiskAnalysis {
    Write-ColorOutput "分析磁盘空间使用情况..." "Info"
    
    Write-Host ""
    Write-Host "========== 磁盘空间概览 ==========" -ForegroundColor Cyan
    Write-Host ""
    
    # 磁盘总体使用
    Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        $free = [math]::Round($_.FreeSpace / 1GB, 2)
        $total = [math]::Round($_.Size / 1GB, 2)
        $used = [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)
        $pct = [math]::Round(($_.Size - $_.FreeSpace) / $_.Size * 100, 1)
        Write-Host "  $($_.DeviceID) 总容量: ${total}GB | 已使用: ${used}GB | 可用: ${free}GB | 使用率: ${pct}%"
    }
    Write-Host ""
    
    # 用户主目录
    Write-Host "  用户主目录主要文件夹:" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($dir in @("Downloads", "Documents", "Desktop", "Videos", "Music", "Pictures")) {
        $path = "$env:USERPROFILE\$dir"
        if (Test-Path $path) {
            $size = [math]::Round((Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
            Write-Host ("    {0,-15} {1}MB" -f $dir, $size)
        }
    }
    Write-Host ""
    
    # AppData 大小
    Write-Host "  AppData 目录:" -ForegroundColor Cyan
    Write-Host ""
    foreach ($dir in @("Local", "Roaming", "LocalLow")) {
        $path = "$env:USERPROFILE\AppData\$dir"
        if (Test-Path $path) {
            $size = [math]::Round((Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)
            Write-Host ("    {0,-15} {1}MB" -f $dir, $size)
        }
    }
    Write-Host ""
    
    Write-ColorOutput "分析完成。大型应用缓存建议在对应应用内清理" "Info"
}

# ----------------------------------------------------------------------------
# 功能9: 配置终端设置
# ----------------------------------------------------------------------------
function Set-TerminalSettings {
    Write-ColorOutput "配置终端设置..." "Info"
    
    Write-Host ""
    Write-Host "推荐的终端配置:"
    Write-Host '  "terminal.integrated.defaultProfile.windows": "PowerShell"' -ForegroundColor Green
    Write-Host ""
    
    if (Test-Path $SettingsJsonPath) {
        Write-ColorOutput "settings.json 位置: $SettingsJsonPath" "Info"
        
        $content = Get-Content $SettingsJsonPath -Raw -ErrorAction SilentlyContinue
        if ($content -match "terminal.integrated.defaultProfile.windows") {
            Write-ColorOutput "终端配置已存在" "Info"
            $content | Select-String "terminal.integrated.defaultProfile" | ForEach-Object { Write-Host "  $_" }
        }
        else {
            Write-ColorOutput "未找到终端配置，建议手动添加" "Warning"
        }
    }
    else {
        Write-ColorOutput "未找到 settings.json 文件" "Warning"
        Write-ColorOutput "Windsurf 可能尚未创建配置文件，请先启动一次 Windsurf" "Info"
    }
}

# ----------------------------------------------------------------------------
# 功能11: 检查更新问题
# ----------------------------------------------------------------------------
function Test-UpdateIssues {
    Write-ColorOutput "检查更新相关问题..." "Info"
    
    Write-Host ""
    
    # 检查是否以管理员身份运行
    if (Test-Administrator) {
        Write-ColorOutput "当前以管理员身份运行" "Warning"
        Write-Host ""
        Write-Host "  Windsurf 以管理员模式运行时无法自动更新"
        Write-Host "  解决方案: 以普通用户权限运行 Windsurf"
        Write-Host ""
    }
    else {
        Write-ColorOutput "以普通用户权限运行（正常）" "Success"
    }
    
    # 检查用户安装 vs 系统安装
    $userInstall = Test-Path "$env:LOCALAPPDATA\Programs\Windsurf"
    $systemInstall = Test-Path "$env:ProgramFiles\Windsurf"
    
    if ($userInstall) {
        Write-ColorOutput "检测到用户范围安装: $env:LOCALAPPDATA\Programs\Windsurf" "Info"
    }
    if ($systemInstall) {
        Write-ColorOutput "检测到系统范围安装: $env:ProgramFiles\Windsurf" "Info"
    }
}

# ----------------------------------------------------------------------------
# 功能10: 修复PowerShell执行策略
# ----------------------------------------------------------------------------
function Set-PSExecutionPolicy {
    Write-ColorOutput "检查 PowerShell 执行策略..." "Info"
    
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    Write-Host ""
    Write-Host "  当前执行策略: " -NoNewline; Write-Host "$currentPolicy" -ForegroundColor Yellow
    Write-Host ""
    
    if ($currentPolicy -eq "Restricted") {
        Write-ColorOutput "执行策略为 Restricted，可能导致脚本问题" "Warning"
        Write-Host ""
        Write-Host "  建议设置为 RemoteSigned"
        Write-Host "  命令: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
        Write-Host ""
        
        if (Confirm-Action "是否修改执行策略为 RemoteSigned？") {
            try {
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
                Write-ColorOutput "执行策略已更新" "Success"
            }
            catch {
                Write-ColorOutput "修改失败: $_" "Error"
            }
        }
    }
    else {
        Write-ColorOutput "执行策略正常" "Success"
    }
}

# ----------------------------------------------------------------------------
# 功能14: 生成诊断报告
# ----------------------------------------------------------------------------
function New-DiagnosticReport {
    Write-ColorOutput "生成诊断报告..." "Info"
    
    $reportFile = "$env:USERPROFILE\windsurf-diagnostic-$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    $report = @"
==========================================
Windsurf 诊断报告 - Windows
生成时间: $(Get-Date)
==========================================

## 系统信息
$((Get-CimInstance -ClassName Win32_OperatingSystem).Caption)
架构: $(if ([Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" })
用户: $env:USERNAME

## PowerShell 信息
版本: $($PSVersionTable.PSVersion)
执行策略: $(Get-ExecutionPolicy -Scope CurrentUser)

## Windsurf 安装状态
用户安装路径: $env:LOCALAPPDATA\Programs\Windsurf
$(if (Test-Path "$env:LOCALAPPDATA\Programs\Windsurf") { "存在" } else { "不存在" })

系统安装路径: $env:ProgramFiles\Windsurf
$(if (Test-Path "$env:ProgramFiles\Windsurf") { "存在" } else { "不存在" })

## Codeium 目录状态
路径: $CodeiumDir
$(if (Test-Path $CodeiumDir) { "存在" } else { "不存在" })

## Cascade 缓存状态
路径: $CascadeDir
$(if (Test-Path $CascadeDir) { 
    $size = (Get-ChildItem $CascadeDir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    "存在 - 大小: $([math]::Round($size/1MB, 2)) MB"
} else { "不存在" })

## 网络状态
$(try { 
    $result = Test-NetConnection -ComputerName "codeium.com" -Port 443 -WarningAction SilentlyContinue
    "codeium.com 连接: $(if ($result.TcpTestSucceeded) { '成功' } else { '失败' })"
} catch { "无法测试网络连接" })

## 磁盘空间
$(Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'" | ForEach-Object {
    "C盘可用空间: $([math]::Round($_.FreeSpace/1GB, 2)) GB / $([math]::Round($_.Size/1GB, 2)) GB"
})

## 管理员权限
$(if (Test-Administrator) { "以管理员身份运行" } else { "普通用户权限" })

"@
    
    $report | Out-File -FilePath $reportFile -Encoding UTF8
    Write-ColorOutput "诊断报告已保存: $reportFile" "Success"
}

# ----------------------------------------------------------------------------
# 功能13: 清理Windsurf临时文件
# ----------------------------------------------------------------------------
function Clear-TempFiles {
    Write-ColorOutput "清理临时文件..." "Info"
    
    $tempDirs = @(
        "$env:TEMP\windsurf*",
        "$env:TEMP\codeium*"
    )
    
    if (Confirm-Action) {
        foreach ($pattern in $tempDirs) {
            $items = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
            if ($items) {
                foreach ($item in $items) {
                    try {
                        Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
                        Write-ColorOutput "已删除: $($item.Name)" "Success"
                    }
                    catch {
                        Write-ColorOutput "无法删除: $($item.Name)" "Warning"
                    }
                }
            }
        }
        Write-ColorOutput "临时文件清理完成" "Success"
    }
    else {
        Write-ColorOutput "已取消操作" "Info"
    }
}

# ----------------------------------------------------------------------------
# 功能15: 完整修复
# ----------------------------------------------------------------------------
function Start-FullRepair {
    Write-ColorOutput "执行完整修复..." "Info"
    Write-ColorOutput "此操作将执行所有修复步骤" "Warning"
    
    if (Confirm-Action) {
        if (-not (Test-WindsurfRunning)) {
            return
        }
        
        Clear-CascadeCache
        Clear-ExtensionCache
        Clear-StartupCache
        Set-TerminalSettings
        Test-UpdateIssues
        Set-PSExecutionPolicy
        Clear-TempFiles
        New-DiagnosticReport
        
        Write-Host ""
        Write-ColorOutput "完整修复已完成！" "Success"
        Write-ColorOutput "请重新启动 Windsurf" "Info"
    }
    else {
        Write-ColorOutput "已取消操作" "Info"
    }
}

# ----------------------------------------------------------------------------
# 功能12: 网络白名单检查
# ----------------------------------------------------------------------------
function Test-NetworkWhitelist {
    Write-ColorOutput "检查网络连接..." "Info"
    
    $domains = @(
        "codeium.com",
        "windsurf.com",
        "codeiumdata.com"
    )
    
    Write-Host ""
    Write-Host "检查以下域名的连接状态:"
    Write-Host ""
    
    foreach ($domain in $domains) {
        Write-Host "  测试 $domain... " -NoNewline
        try {
            $result = Test-NetConnection -ComputerName $domain -Port 443 -WarningAction SilentlyContinue -InformationLevel Quiet
            if ($result) {
                Write-Host "成功" -ForegroundColor Green
            }
            else {
                Write-Host "失败" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "错误" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "如果连接失败，请将以下域名加入防火墙/VPN白名单:"
    Write-Host "  *.codeium.com" -ForegroundColor Yellow
    Write-Host "  *.windsurf.com" -ForegroundColor Yellow
    Write-Host "  *.codeiumdata.com" -ForegroundColor Yellow
    Write-Host ""
}

# ----------------------------------------------------------------------------
# 主菜单
# ----------------------------------------------------------------------------
function Show-Menu {
    Write-Host ""
    Write-Host "请选择修复选项:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "== Windsurf 缓存清理 ==" -ForegroundColor Yellow
    Write-Host "  1) 清理 Cascade 缓存 (会清理对话历史)"
    Write-Host "  2) 清理启动缓存 (不清理对话历史，推荐)"
    Write-Host "  3) 清理扩展缓存 (不清理对话历史)"
    Write-Host ""
    Write-Host "== 系统缓存清理 ==" -ForegroundColor Yellow
    Write-Host "  4) 清理开发工具缓存 (npm/pip/NuGet/Maven等)"
    Write-Host "  5) 清理 Windows 系统缓存 (临时文件/回收站/旧备份等)"
    Write-Host "  6) 磁盘空间分析"
    Write-Host ""
    Write-Host "== MCP 相关 ==" -ForegroundColor Yellow
    Write-Host "  7) MCP 诊断 (检查MCP加载问题)"
    Write-Host "  8) 重置 MCP 配置"
    Write-Host ""
    Write-Host "== 终端相关 ==" -ForegroundColor Yellow
    Write-Host "  9) 配置终端设置"
    Write-Host "  10) 修复 PowerShell 执行策略"
    Write-Host ""
    Write-Host "== 其他 ==" -ForegroundColor Yellow
    Write-Host "  11) 检查更新问题"
    Write-Host "  12) 检查网络连接"
    Write-Host "  13) 清理 Windsurf 临时文件"
    Write-Host "  14) 生成诊断报告"
    Write-Host "  15) 完整修复 (执行所有步骤)"
    Write-Host ""
    Write-Host "  0) 退出"
    Write-Host ""
    
    $choice = Read-Host "请输入选项 [0-15]"
    
    switch ($choice) {
        "1" { if (Test-WindsurfRunning) { Clear-CascadeCache } }
        "2" { Clear-StartupCache }
        "3" { if (Test-WindsurfRunning) { Clear-ExtensionCache } }
        "4" { Clear-DevCaches }
        "5" { Clear-SystemCaches }
        "6" { Get-DiskAnalysis }
        "7" { Test-MCP }
        "8" { Reset-MCPConfig }
        "9" { Set-TerminalSettings }
        "10" { Set-PSExecutionPolicy }
        "11" { Test-UpdateIssues }
        "12" { Test-NetworkWhitelist }
        "13" { Clear-TempFiles }
        "14" { New-DiagnosticReport }
        "15" { Start-FullRepair }
        "0" { 
            Write-Host ""
            Write-ColorOutput "感谢使用 Windsurf 修复工具" "Info"
            exit 
        }
        default { Write-ColorOutput "无效选项" "Error" }
    }
}

# ----------------------------------------------------------------------------
# 主程序入口
# ----------------------------------------------------------------------------
function Main {
    Write-Header
    Get-SystemInfo
    
    while ($true) {
        Show-Menu
        Write-Host ""
        Read-Host "按回车键继续..."
    }
}

# 执行主程序
Main
