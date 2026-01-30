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
# 功能3: 配置终端设置
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
# 功能4: 检查更新问题
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
# 功能5: 修复PowerShell执行策略
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
# 功能6: 生成诊断报告
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
# 功能7: 清理临时文件
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
# 功能8: 完整修复
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
# 功能9: 网络白名单检查
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
    Write-Host "  1) 清理 Cascade 缓存 (解决启动失败/卡顿)"
    Write-Host "  2) 清理扩展缓存"
    Write-Host "  3) 配置终端设置"
    Write-Host "  4) 检查更新问题"
    Write-Host "  5) 修复 PowerShell 执行策略"
    Write-Host "  6) 生成诊断报告"
    Write-Host "  7) 清理临时文件"
    Write-Host "  8) 检查网络连接"
    Write-Host "  9) 完整修复 (执行所有步骤)"
    Write-Host ""
    Write-Host "  0) 退出"
    Write-Host ""
    
    $choice = Read-Host "请输入选项 [0-9]"
    
    switch ($choice) {
        "1" { if (Test-WindsurfRunning) { Clear-CascadeCache } }
        "2" { if (Test-WindsurfRunning) { Clear-ExtensionCache } }
        "3" { Set-TerminalSettings }
        "4" { Test-UpdateIssues }
        "5" { Set-PSExecutionPolicy }
        "6" { New-DiagnosticReport }
        "7" { Clear-TempFiles }
        "8" { Test-NetworkWhitelist }
        "9" { Start-FullRepair }
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
