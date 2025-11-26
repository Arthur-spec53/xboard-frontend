#!/bin/bash

#═══════════════════════════════════════════════════════════════════════
# XBoard 前端一键部署脚本
# 版本: 2.0.0
# 作者: XBoard Team
# 描述: 终极保姆级部署脚本 - 从零生产环境到完整部署
#       自动安装所有依赖、配置系统、部署应用
#═══════════════════════════════════════════════════════════════════════

set -e  # 遇到错误立即退出

# 全局变量
DEPLOYMENT_START_TIME=$(date +%s)
DEPLOYMENT_REPORT_FILE=""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="${SCRIPT_DIR}/dist"
BACKUP_DIR="${SCRIPT_DIR}/backups"
LOG_FILE="${SCRIPT_DIR}/deploy.log"

#═══════════════════════════════════════════════════════════════════════
# 辅助函数
#═══════════════════════════════════════════════════════════════════════

# 打印带颜色的消息
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

# 打印标题
print_banner() {
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "  🚀 XBoard 前端终极部署脚本 v2.0.0"
    echo "  📦 从零环境到生产部署 - 全自动"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

# 打印进度条
print_progress() {
    local current=$1
    local total=$2
    local message=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r${BLUE}进度: ["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%% - %s${NC}" "$percent" "$message"
    
    if [ $current -eq $total ]; then
        echo ""
    fi
}

# 日志记录
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 确认提示
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -p "$prompt" response
    response=${response:-$default}
    
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

#═══════════════════════════════════════════════════════════════════════
# 系统环境检测和初始化
#═══════════════════════════════════════════════════════════════════════

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_warning "建议使用 root 用户或 sudo 运行此脚本"
        print_info "如果遇到权限问题，请使用: sudo bash $0"
        if ! confirm "是否继续？" "n"; then
            exit 0
        fi
    fi
}

# 检查系统资源
check_system_resources() {
    print_step "检查系统资源..."
    
    # 检查内存
    local total_mem=$(free -m | awk '/^Mem:/{print $2}')
    local available_mem=$(free -m | awk '/^Mem:/{print $7}')
    
    print_info "系统内存: ${total_mem}MB (可用: ${available_mem}MB)"
    
    if [ "$total_mem" -lt 512 ]; then
        print_warning "系统内存较低 (< 512MB)，可能影响编译速度"
        
        # 检查swap
        local swap=$(free -m | awk '/^Swap:/{print $2}')
        if [ "$swap" -lt 1024 ]; then
            print_warning "Swap 空间不足 (< 1GB)"
            if confirm "是否自动创建 2GB Swap？" "y"; then
                create_swap
            fi
        fi
    fi
    
    # 检查磁盘空间
    local available_disk=$(df -BG "$SCRIPT_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
    print_info "可用磁盘空间: ${available_disk}GB"
    
    if [ "$available_disk" -lt 2 ]; then
        print_error "磁盘空间不足 (< 2GB)，无法继续部署"
        print_info "需要至少 2GB 可用空间用于编译和部署"
        exit 1
    elif [ "$available_disk" -lt 5 ]; then
        print_warning "磁盘空间较低 (< 5GB)"
        if ! confirm "是否继续？" "y"; then
            exit 0
        fi
    fi
    
    # 检查CPU
    local cpu_cores=$(nproc)
    print_info "CPU 核心数: $cpu_cores"
    
    if [ "$cpu_cores" -lt 2 ]; then
        print_warning "CPU 核心较少，编译可能较慢"
    fi
    
    print_success "系统资源检查通过"
}

# 创建 Swap 空间
create_swap() {
    print_step "创建 2GB Swap 空间..."
    
    # 检查是否已存在swap文件
    if [ -f /swapfile ]; then
        print_info "已存在 /swapfile"
        if ! confirm "是否删除并重新创建？" "n"; then
            return 0
        fi
        sudo swapoff /swapfile 2>/dev/null || true
        sudo rm /swapfile
    fi
    
    # 创建swap
    sudo dd if=/dev/zero of=/swapfile bs=1M count=2048 status=progress
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    
    # 添加到fstab
    if ! grep -q '/swapfile' /etc/fstab; then
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    fi
    
    print_success "Swap 创建完成"
}

# 检查网络连接
check_network() {
    print_step "检查网络连接..."
    
    local test_urls=("www.google.com" "github.com" "registry.npmjs.org")
    local failed_count=0
    
    for url in "${test_urls[@]}"; do
        if ! ping -c 1 -W 3 "$url" >/dev/null 2>&1; then
            ((failed_count++))
        fi
    done
    
    if [ "$failed_count" -eq ${#test_urls[@]} ]; then
        print_error "网络连接失败，请检查网络设置"
        exit 1
    elif [ "$failed_count" -gt 0 ]; then
        print_warning "部分网络连接不稳定，可能影响下载速度"
    else
        print_success "网络连接正常"
    fi
}

# 安装基础依赖
install_base_dependencies() {
    print_step "安装系统基础依赖..."
    
    local packages_to_install=()
    
    # 检查必需的命令
    local required_commands=("curl" "wget" "git" "tar" "gzip" "unzip")
    
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            packages_to_install+=("$cmd")
        fi
    done
    
    # 添加其他必需包
    case "$OS" in
        ubuntu|debian)
            # 检查并添加需要的包
            ! command_exists dig && packages_to_install+=("dnsutils")
            ! dpkg -l | grep -q "ca-certificates" && packages_to_install+=("ca-certificates")
            ! dpkg -l | grep -q "gnupg" && packages_to_install+=("gnupg")
            ! dpkg -l | grep -q "lsb-release" && packages_to_install+=("lsb-release")
            ! dpkg -l | grep -q "build-essential" && packages_to_install+=("build-essential")
            ;;
        centos|rhel|fedora)
            ! command_exists dig && packages_to_install+=("bind-utils")
            ! rpm -q ca-certificates &>/dev/null && packages_to_install+=("ca-certificates")
            ! rpm -q gnupg2 &>/dev/null && packages_to_install+=("gnupg2")
            ;;
    esac
    
    if [ ${#packages_to_install[@]} -eq 0 ]; then
        print_success "所有基础依赖已安装"
        return 0
    fi
    
    print_info "需要安装以下包: ${packages_to_install[*]}"
    
    case "$OS" in
        ubuntu|debian)
            print_info "更新软件包列表..."
            sudo apt-get update -qq
            print_info "安装依赖包..."
            sudo apt-get install -y -qq "${packages_to_install[@]}"
            ;;
        centos|rhel)
            sudo yum install -y "${packages_to_install[@]}"
            ;;
        fedora)
            sudo dnf install -y "${packages_to_install[@]}"
            ;;
        *)
            print_error "不支持的操作系统: $OS"
            return 1
            ;;
    esac
    
    print_success "基础依赖安装完成"
}

# 配置系统优化
configure_system() {
    print_step "配置系统优化..."
    
    # 设置时区
    if [ -f /etc/timezone ]; then
        current_timezone=$(cat /etc/timezone)
    else
        current_timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
    fi
    
    print_info "当前时区: $current_timezone"
    
    if [ "$current_timezone" != "Asia/Shanghai" ]; then
        if confirm "是否设置时区为 Asia/Shanghai？" "y"; then
            sudo timedatectl set-timezone Asia/Shanghai 2>/dev/null || sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
            print_success "时区已设置为 Asia/Shanghai"
        fi
    fi
    
    # 增加文件描述符限制
    print_info "优化文件描述符限制..."
    
    if ! grep -q "# XBoard deployment" /etc/security/limits.conf; then
        sudo tee -a /etc/security/limits.conf > /dev/null << 'EOF'

# XBoard deployment
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
EOF
        print_success "文件描述符限制已优化"
    else
        print_info "文件描述符限制已配置"
    fi
    
    print_success "系统优化完成"
}

# 配置防火墙
configure_firewall() {
    print_step "配置防火墙..."
    
    local ports_to_open=("80/tcp" "443/tcp")
    local firewall_configured=false
    
    # 检测防火墙类型
    if command_exists ufw; then
        print_info "检测到 UFW 防火墙"
        
        # 检查UFW是否启用
        if sudo ufw status | grep -q "Status: active"; then
            for port in "${ports_to_open[@]}"; do
                if ! sudo ufw status | grep -q "$port"; then
                    print_info "开放端口: $port"
                    sudo ufw allow "$port" comment "XBoard Frontend"
                fi
            done
            firewall_configured=true
            print_success "UFW 防火墙已配置"
        else
            print_info "UFW 未启用"
            if confirm "是否启用 UFW 并配置规则？" "y"; then
                # 确保SSH端口开放
                sudo ufw allow 22/tcp comment "SSH"
                # 开放HTTP/HTTPS
                for port in "${ports_to_open[@]}"; do
                    sudo ufw allow "$port" comment "XBoard Frontend"
                done
                # 启用UFW
                echo "y" | sudo ufw enable
                firewall_configured=true
                print_success "UFW 已启用并配置"
            fi
        fi
    elif command_exists firewall-cmd; then
        print_info "检测到 firewalld"
        
        if sudo systemctl is-active --quiet firewalld; then
            for service in "http" "https"; do
                if ! sudo firewall-cmd --list-services | grep -q "$service"; then
                    print_info "开放服务: $service"
                    sudo firewall-cmd --permanent --add-service="$service"
                fi
            done
            sudo firewall-cmd --reload
            firewall_configured=true
            print_success "firewalld 已配置"
        else
            print_info "firewalld 未运行"
            if confirm "是否启动 firewalld 并配置规则？" "y"; then
                sudo systemctl start firewalld
                sudo systemctl enable firewalld
                sudo firewall-cmd --permanent --add-service=http
                sudo firewall-cmd --permanent --add-service=https
                sudo firewall-cmd --reload
                firewall_configured=true
                print_success "firewalld 已启动并配置"
            fi
        fi
    else
        print_warning "未检测到防火墙 (UFW/firewalld)"
        print_info "请手动确保以下端口已开放: 80, 443"
    fi
    
    if [ "$firewall_configured" = true ]; then
        print_success "防火墙配置完成"
        print_info "已开放端口: 80 (HTTP), 443 (HTTPS)"
    fi
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="centos"
    else
        OS=$(uname -s)
    fi
    
    print_info "检测到操作系统: $OS $OS_VERSION"
    log "Operating System: $OS $OS_VERSION"
}

# 检查 Node.js 版本是否满足要求
check_node_version() {
    local node_version=$(node -v | sed 's/v//')
    local major_version=$(echo "$node_version" | cut -d. -f1)
    
    # Vite 7 需要 Node.js 20.19+ 或 22.12+
    if [ "$major_version" -lt 20 ]; then
        return 1
    fi
    
    return 0
}

# 检查并安装 Node.js
ensure_nodejs() {
    print_step "检查 Node.js 环境..."
    
    local need_install=false
    local need_upgrade=false
    
    if command_exists node && command_exists npm; then
        local node_version=$(node -v)
        local npm_version=$(npm -v)
        print_info "检测到 Node.js $node_version, npm $npm_version"
        log "Node.js: $node_version, npm: $npm_version"
        
        # 检查版本是否满足要求
        if ! check_node_version; then
            print_warning "当前 Node.js 版本过低"
            print_warning "Vite 7 需要 Node.js 20.19+ 或 22.12+"
            need_upgrade=true
            
            if ! confirm "是否自动升级到最新 LTS 版本？" "y"; then
                print_error "需要 Node.js 20+ 才能继续，部署已取消"
                print_info "您可以手动升级 Node.js 后重新运行此脚本"
                exit 1
            fi
        else
            print_success "Node.js 版本满足要求"
            return 0
        fi
    else
        print_warning "未检测到 Node.js 或 npm"
        need_install=true
        
        if ! confirm "是否自动安装最新 LTS 版本的 Node.js？" "y"; then
            print_error "Node.js 是必需的，部署已取消"
            exit 1
        fi
    fi
    
    if [ "$need_install" = true ] || [ "$need_upgrade" = true ]; then
        print_step "安装/升级 Node.js (最新 LTS 版本)..."
        
        case "$OS" in
            ubuntu|debian)
                # 清理旧版本
                if [ "$need_upgrade" = true ]; then
                    print_info "清理旧版本..."
                    sudo apt-get remove -y nodejs npm 2>/dev/null || true
                fi
                
                # 安装最新 LTS 版本
                print_info "添加 NodeSource 仓库 (LTS)..."
                curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
                
                print_info "安装 Node.js..."
                sudo apt-get install -y nodejs
                ;;
            centos|rhel)
                if [ "$need_upgrade" = true ]; then
                    sudo yum remove -y nodejs npm 2>/dev/null || true
                fi
                
                curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
                sudo yum install -y nodejs
                ;;
            fedora)
                if [ "$need_upgrade" = true ]; then
                    sudo dnf remove -y nodejs npm 2>/dev/null || true
                fi
                
                # Fedora 使用最新版本
                sudo dnf install -y nodejs npm
                ;;
            *)
                print_error "不支持的操作系统，请手动安装 Node.js"
                print_info "访问: https://nodejs.org/ 下载安装"
                exit 1
                ;;
        esac
        
        # 验证安装
        if command_exists node && command_exists npm; then
            local new_version=$(node -v)
            print_success "Node.js 安装成功: $new_version"
            log "Node.js installed: $new_version"
            
            # 再次检查版本
            if ! check_node_version; then
                print_error "安装的 Node.js 版本仍不满足要求"
                print_info "请访问 https://nodejs.org/ 手动安装最新 LTS 版本"
                exit 1
            fi
        else
            print_error "Node.js 安装失败"
            exit 1
        fi
    fi
}

# 生成或验证 .env.production
generate_env_production() {
    local api_url="${1:-/api/v1}"
    
    print_step "配置生产环境变量..."
    
    local env_file="$SCRIPT_DIR/.env.production"
    
    # 检查是否存在
    if [ -f "$env_file" ]; then
        print_info "检测到现有 .env.production"
        
        # 检查 VITE_API_BASE_URL 配置
        if grep -q "VITE_API_BASE_URL" "$env_file"; then
            local current_api=$(grep "VITE_API_BASE_URL" "$env_file" | cut -d= -f2 | tr -d '"' | tr -d "'")
            
            # 检查是否是绝对 URL（不应该是）
            if [[ "$current_api" =~ ^https?:// ]]; then
                print_warning "检测到 .env.production 中使用了绝对 URL: $current_api"
                print_warning "这会导致前端直接访问后端，绕过 Nginx 代理"
                
                if confirm "是否修改为相对路径 '$api_url'？" "y"; then
                    sed -i "s|VITE_API_BASE_URL=.*|VITE_API_BASE_URL=$api_url|g" "$env_file"
                    print_success "已更新为: $api_url"
                else
                    print_warning "保持原配置，但可能导致 CORS 问题"
                fi
            else
                print_success "API 配置正确: $current_api"
            fi
        else
            # 添加配置
            echo "VITE_API_BASE_URL=$api_url" >> "$env_file"
            print_success "已添加 VITE_API_BASE_URL=$api_url"
        fi
    else
        # 创建新文件
        print_info "创建 .env.production..."
        cat > "$env_file" << EOF
# XBoard 前端生产环境配置
# 由部署脚本自动生成

# API 基础路径（相对路径，通过 Nginx 代理）
VITE_API_BASE_URL=$api_url

# 生产环境标识
NODE_ENV=production
EOF
        print_success ".env.production 已创建"
    fi
    
    # 显示最终配置
    echo ""
    print_info "当前环境变量配置:"
    cat "$env_file" | grep -v "^#" | grep -v "^$"
    echo ""
}

# 检查并修复 vite.config.ts
check_vite_config() {
    print_step "检查 Vite 配置..."
    
    local vite_config="$SCRIPT_DIR/vite.config.ts"
    
    if [ ! -f "$vite_config" ]; then
        print_warning "未找到 vite.config.ts"
        return 0
    fi
    
    # 检查是否硬编码了 API URL
    if grep -q "VITE_API_BASE_URL.*https\?://" "$vite_config"; then
        print_error "检测到 vite.config.ts 中硬编码了绝对 API URL！"
        print_info "这会导致前端直接访问后端，绕过 Nginx 代理"
        
        # 显示问题行
        echo ""
        print_warning "问题配置:"
        grep -n "VITE_API_BASE_URL" "$vite_config" | head -3
        echo ""
        
        print_info "正确的配置应该是:"
        echo "  define: {"
        echo "    'import.meta.env.VITE_API_BASE_URL': JSON.stringify('/api/v1')"
        echo "  }"
        echo ""
        
        if confirm "是否自动修复？" "y"; then
            # 备份
            cp "$vite_config" "$vite_config.backup"
            
            # 修复：将绝对 URL 替换为相对路径
            sed -i "s|'import.meta.env.VITE_API_BASE_URL':.*JSON.stringify(['\"]https\?://[^'\"]*['\"])|'import.meta.env.VITE_API_BASE_URL': JSON.stringify('/api/v1')|g" "$vite_config"
            
            print_success "已修复 vite.config.ts (备份: vite.config.ts.backup)"
            
            # 显示修复后的配置
            echo ""
            print_info "修复后的配置:"
            grep -n "VITE_API_BASE_URL" "$vite_config" | head -3
            echo ""
        else
            print_error "未修复，构建可能会出现 CORS 问题"
            return 1
        fi
    else
        print_success "Vite 配置检查通过"
    fi
}

# 测试后端 API 可用性
test_backend_api() {
    local api_backend="$1"
    
    print_step "测试后端 API 可用性..."
    
    # 测试路径
    local test_url="$api_backend/api/v1/guest/comm/config"
    
    print_info "测试 URL: $test_url"
    
    # 发送请求
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$test_url" 2>/dev/null || echo "000")
    
    if [ "$response_code" = "200" ]; then
        print_success "✓ 后端 API 可访问 (HTTP $response_code)"
        
        # 检查 CORS 头
        local cors_header=$(curl -s -I "$test_url" 2>/dev/null | grep -i "access-control-allow-origin" || echo "")
        if [ -n "$cors_header" ]; then
            print_success "✓ 后端已配置 CORS: $cors_header"
        else
            print_warning "⚠ 后端未返回 CORS 头，可能需要配置"
        fi
        
        return 0
    elif [ "$response_code" = "000" ]; then
        print_error "✗ 无法连接到后端 API"
        print_info "可能原因："
        echo "  • 后端服务未启动"
        echo "  • 网络不可达"
        echo "  • 防火墙阻止"
        echo "  • URL 配置错误"
    else
        print_warning "⚠ 后端响应异常 (HTTP $response_code)"
    fi
    
    echo ""
    print_warning "后端 API 不可用，但前端仍可以部署"
    if ! confirm "是否继续部署？" "y"; then
        print_info "部署已取消，请先确保后端正常运行"
        exit 1
    fi
    
    return 1
}

# 自动构建项目
auto_build() {
    print_step "准备构建项目..."
    
    # 检查 package.json 是否存在
    if [ ! -f "$SCRIPT_DIR/package.json" ]; then
        print_error "未找到 package.json，请确认这是 XBoard 前端项目目录"
        exit 1
    fi
    
    # 生成/检查环境变量配置
    generate_env_production "/api/v1"
    
    # 检查并修复 vite.config.ts
    check_vite_config
    
    # 检查 node_modules 是否存在
    if [ ! -d "$SCRIPT_DIR/node_modules" ]; then
        print_step "安装项目依赖..."
        print_info "这可能需要几分钟，请耐心等待..."
        
        cd "$SCRIPT_DIR"
        npm install --production=false
        
        if [ $? -eq 0 ]; then
            print_success "依赖安装完成"
            log "npm install completed"
        else
            print_error "依赖安装失败"
            exit 1
        fi
    else
        print_success "检测到 node_modules 已存在"
    fi
    
    # 构建项目
    print_step "构建生产版本..."
    print_info "正在编译和优化代码，请稍候..."
    
    cd "$SCRIPT_DIR"
    npm run build
    
    if [ $? -eq 0 ]; then
        print_success "项目构建完成"
        log "npm run build completed"
        
        # 显示构建结果
        if [ -d "$DIST_DIR" ]; then
            local file_count=$(find "$DIST_DIR" -type f | wc -l)
            local dist_size=$(du -sh "$DIST_DIR" | cut -f1)
            print_info "构建文件: $file_count 个，总大小: $dist_size"
        fi
    else
        print_error "项目构建失败"
        print_info "请检查 $LOG_FILE 获取详细错误信息"
        exit 1
    fi
}

# 检查必要的目录和文件
check_prerequisites() {
    print_step "检查部署前置条件..."
    
    # 如果 dist 目录不存在，自动构建
    if [ ! -d "$DIST_DIR" ]; then
        print_warning "未找到 dist 目录，将自动构建项目"
        
        # 确保 Node.js 已安装
        ensure_nodejs
        
        # 自动构建
        auto_build
    fi
    
    # 再次检查 dist 目录
    if [ ! -d "$DIST_DIR" ]; then
        print_error "构建后仍未找到 dist 目录"
        exit 1
    fi
    
    if [ ! -f "$DIST_DIR/index.html" ]; then
        print_error "dist 目录中未找到 index.html！构建可能未完成"
        exit 1
    fi
    
    print_success "前置条件检查通过"
}

#═══════════════════════════════════════════════════════════════════════
# Nginx 部署相关函数
#═══════════════════════════════════════════════════════════════════════

# 安装 Nginx
install_nginx() {
    print_step "安装 Nginx..."
    
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y nginx
            ;;
        centos|rhel|fedora)
            sudo yum install -y nginx || sudo dnf install -y nginx
            ;;
        *)
            print_error "不支持的操作系统，请手动安装 Nginx"
            return 1
            ;;
    esac
    
    print_success "Nginx 安装完成"
}

# 检查并安装 Nginx
ensure_nginx() {
    if command_exists nginx; then
        print_success "检测到 Nginx 已安装"
        nginx -v
    else
        print_warning "未检测到 Nginx"
        if confirm "是否自动安装 Nginx？" "y"; then
            install_nginx
        else
            print_error "Nginx 是必需的，部署已取消"
            exit 1
        fi
    fi
}

#═══════════════════════════════════════════════════════════════════════
# SSL 证书相关函数
#═══════════════════════════════════════════════════════════════════════

# 安装 certbot
install_certbot() {
    print_step "安装 Certbot..."
    
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y certbot python3-certbot-nginx
            ;;
        centos|rhel)
            sudo yum install -y epel-release
            sudo yum install -y certbot python3-certbot-nginx
            ;;
        fedora)
            sudo dnf install -y certbot python3-certbot-nginx
            ;;
        *)
            print_error "不支持的操作系统，请手动安装 Certbot"
            return 1
            ;;
    esac
    
    print_success "Certbot 安装完成"
}

# 确保 certbot 已安装
ensure_certbot() {
    if command_exists certbot; then
        print_success "检测到 Certbot 已安装"
        certbot --version
        return 0
    else
        print_warning "未检测到 Certbot"
        if confirm "是否自动安装 Certbot？" "y"; then
            install_certbot
            return $?
        else
            print_warning "跳过 SSL 证书配置"
            return 1
        fi
    fi
}

# 验证域名解析
verify_domain() {
    local domain="$1"
    
    print_step "验证域名解析..."
    
    # 获取服务器公网IP
    server_ip=$(curl -s ifconfig.me || curl -s icanhazip.com || curl -s ipinfo.io/ip)
    
    if [ -z "$server_ip" ]; then
        print_warning "无法获取服务器公网IP"
        return 1
    fi
    
    print_info "服务器IP: $server_ip"
    
    # 查询域名解析
    domain_ip=$(dig +short "$domain" @8.8.8.8 | tail -n1)
    
    if [ -z "$domain_ip" ]; then
        print_error "域名未解析或解析失败"
        print_info "请确保域名 $domain 已经正确解析到 $server_ip"
        return 1
    fi
    
    print_info "域名解析IP: $domain_ip"
    
    # 比较IP
    if [ "$server_ip" = "$domain_ip" ]; then
        print_success "域名解析验证成功！"
        return 0
    else
        print_error "域名解析的IP ($domain_ip) 与服务器IP ($server_ip) 不匹配"
        print_info "请确保域名已正确解析，并等待DNS传播完成（可能需要几分钟到几小时）"
        return 1
    fi
}

# 申请 SSL 证书（支持多域名）
request_ssl_certificate() {
    local domains="$1"
    local web_root="$2"
    local email="$3"
    
    print_step "申请 SSL 证书..."
    
    # 将域名字符串转换为数组
    IFS=' ' read -ra domain_array <<< "$domains"
    local primary_domain="${domain_array[0]}"
    
    # 验证主域名解析
    print_info "验证主域名: $primary_domain"
    if ! verify_domain "$primary_domain"; then
        print_warning "主域名验证失败，但您可以选择继续（不推荐）"
        if ! confirm "是否继续申请证书？（需要域名正确解析）" "n"; then
            return 1
        fi
    fi
    
    # 构建 certbot 命令参数
    local certbot_args="certonly --webroot --webroot-path=$web_root --email $email --agree-tos --no-eff-email --force-renewal"
    
    # 添加所有域名
    for domain in "${domain_array[@]}"; do
        certbot_args="$certbot_args -d $domain"
        print_info "包含域名: $domain"
    done
    
    # 使用 webroot 方式申请证书
    print_info "使用 Let's Encrypt 申请证书..."
    print_info "这可能需要几秒钟..."
    
    if sudo certbot $certbot_args; then
        print_success "SSL 证书申请成功！"
        print_info "证书位置: /etc/letsencrypt/live/$primary_domain/"
        print_success "证书涵盖以下域名: $domains"
        return 0
    else
        print_error "SSL 证书申请失败"
        print_info "常见原因："
        echo "  1. 域名未正确解析到服务器"
        echo "  2. 80端口未开放或被占用"
        echo "  3. 防火墙阻止了Let's Encrypt的验证请求"
        echo "  4. 多个域名中有部分未正确解析"
        return 1
    fi
}

# 配置 SSL 自动续期
setup_ssl_renewal() {
    print_step "配置 SSL 证书自动续期..."
    
    # 测试续期
    if sudo certbot renew --dry-run; then
        print_success "SSL 证书自动续期配置成功"
        print_info "证书将在到期前自动续期"
    else
        print_warning "SSL 自动续期测试失败，请手动检查"
    fi
}

# 生成带 HTTPS 的 Nginx 配置（支持多域名）
generate_nginx_config_https() {
    local domains="$1"
    local web_root="$2"
    local api_backend="$3"
    local config_file="$4"
    
    # 获取第一个域名作为主域名（用于证书路径）
    IFS=' ' read -ra domain_array <<< "$domains"
    local primary_domain="${domain_array[0]}"
    
    local cert_path="/etc/letsencrypt/live/$primary_domain/fullchain.pem"
    local key_path="/etc/letsencrypt/live/$primary_domain/privkey.pem"
    
    cat > "$config_file" << EOF
# XBoard 前端 Nginx 配置 (HTTPS)
# 生成时间: $(date)
# 域名: $domains
#
# ═══════════════════════════════════════════════════════════════
# 前后端分离架构说明:
#   • 前端: 静态文件（HTML/CSS/JS）存放在 $web_root
#   • 后端: API 服务运行在 $api_backend
#   • Nginx 负责服务前端文件并代理 API 请求到后端
#   • 所有 HTTP 流量自动重定向到 HTTPS
# ═══════════════════════════════════════════════════════════════

# HTTP 服务器 - 重定向到 HTTPS
server {
    listen 80;
    server_name $domains;
    
    # Let's Encrypt 验证
    location ^~ /.well-known/acme-challenge/ {
        root $web_root;
    }
    
    # 其他请求重定向到 HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS 服务器
server {
    listen 443 ssl http2;
    server_name $domains;
    
    # SSL 证书配置
    ssl_certificate $cert_path;
    ssl_certificate_key $key_path;
    
    # SSL 优化配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # 前端静态文件根目录
    root $web_root;
    index index.html;
    
    # 访问日志
    access_log /var/log/nginx/xboard-https-access.log;
    error_log /var/log/nginx/xboard-https-error.log;
    
    # Gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;
    
    # SPA 路由支持
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # API 与订阅链接反向代理
    # - /api/* → 后端 API（JSON 接口）
    # - /s/*   → 订阅链接（YAML/其他格式）
    location /api {
        proxy_pass $api_backend;
        
        # 代理请求头
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        
        # WebSocket 支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # 禁用缓冲以支持流式响应
        proxy_buffering off;
        
        # CORS 处理 - 让后端的 CORS 头透传，不干预
        # 不添加、不删除、不修改 CORS 头，完全由后端控制
    }

    # 订阅链接 /s/* 反向代理到同一后端
    location /s/ {
        proxy_pass $api_backend;

        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_buffering off;
    }
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # 安全头
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # 隐藏 Nginx 版本号
    server_tokens off;
}
EOF
    
    print_success "HTTPS Nginx 配置文件已生成: $config_file"
}

# 生成 Nginx 配置文件（支持多域名）
generate_nginx_config() {
    local domains="$1"
    local web_root="$2"
    local api_backend="$3"
    local config_file="$4"
    
    cat > "$config_file" << EOF
# XBoard 前端 Nginx 配置
# 生成时间: $(date)
# 域名: $domains
#
# ═══════════════════════════════════════════════════════════════
# 前后端分离架构说明:
#   • 前端: 静态文件（HTML/CSS/JS）存放在 $web_root
#   • 后端: API 服务运行在 $api_backend
#   • Nginx 负责服务前端文件并代理 API 请求到后端
# ═══════════════════════════════════════════════════════════════

server {
    listen 80;
    server_name $domains;
    
    # 前端静态文件根目录
    root $web_root;
    index index.html;
    
    # 访问日志
    access_log /var/log/nginx/xboard-access.log;
    error_log /var/log/nginx/xboard-error.log;
    
    # Gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;
    
    # SPA 路由支持
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # API 与订阅链接反向代理
    # - /api/* → 后端 API（JSON 接口）
    # - /s/*   → 订阅链接（YAML/其他格式）
    location /api {
        proxy_pass $api_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket 支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # 订阅链接 /s/* 反向代理到同一后端
    location /s/ {
        proxy_pass $api_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # 隐藏 Nginx 版本号
    server_tokens off;
}

# HTTPS 配置 (需要配置SSL证书)
# server {
#     listen 443 ssl http2;
#     server_name $domains;
#     
#     ssl_certificate /path/to/your/certificate.crt;
#     ssl_certificate_key /path/to/your/private.key;
#     
#     # SSL 配置
#     ssl_protocols TLSv1.2 TLSv1.3;
#     ssl_ciphers HIGH:!aNULL:!MD5;
#     ssl_prefer_server_ciphers on;
#     
#     # 其他配置同上...
# }
EOF
    
    print_success "Nginx 配置文件已生成: $config_file"
}

# 部署到 Nginx
deploy_nginx() {
    print_step "开始 Nginx 部署..."
    
    # 获取配置信息
    echo ""
    print_info "═══ 前后端分离架构说明 ═══"
    echo ""
    echo "本系统采用前后端分离架构:"
    echo "  • 前端: 静态文件（HTML/CSS/JS）由 Nginx 直接服务"
    echo "  • 后端: API 服务，通过反向代理访问"
    echo ""
    
    print_info "域名配置："
    echo "  - 单个域名: example.com"
    echo "  - 多个域名: example.com www.example.com (用空格分隔)"
    echo "  - 本地测试: localhost"
    echo ""
    read -p "请输入前端访问域名: " domains
    domains=${domains:-localhost}
    
    echo ""
    print_info "前端部署目录配置："
    echo "  这是前端静态文件（HTML/CSS/JS）的存放位置"
    echo "  Nginx 会从这个目录读取并服务前端文件"
    echo ""
    read -p "前端文件部署目录 (默认: /var/www/xboard): " web_root
    web_root=${web_root:-/var/www/xboard}
    
    echo ""
    print_info "后端 API 配置："
    echo "  这是后端 API 服务的访问地址（XBoard 后端）"
    echo "  Nginx 会将 /api/* 请求代理到此地址"
    echo ""
    read -p "后端 API 地址 (默认: http://localhost:7001): " api_backend
    api_backend=${api_backend:-http://localhost:7001}
    
    # 测试后端 API
    echo ""
    test_backend_api "$api_backend"
    
    # 询问是否配置 SSL
    enable_ssl=false
    ssl_email=""
    
    # 检查是否为本地域名
    if [[ "$domains" != "localhost" ]] && [[ "$domains" != "127.0.0.1" ]] && [[ "$domains" != *"localhost"* ]]; then
        echo ""
        print_info "检测到您使用了真实域名: $domains"
        if confirm "是否配置 HTTPS (SSL证书)？" "y"; then
            enable_ssl=true
            read -p "请输入您的邮箱地址 (用于SSL证书通知): " ssl_email
            
            # 验证邮箱格式
            while [[ ! "$ssl_email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
                print_warning "邮箱格式不正确"
                read -p "请重新输入邮箱地址: " ssl_email
            done
        fi
    else
        print_info "使用 localhost，跳过 SSL 配置"
    fi
    
    # 确认信息
    echo ""
    print_info "═══ 部署配置确认 ═══"
    echo ""
    echo "前端配置:"
    echo "  访问域名: $domains"
    echo "  部署目录: $web_root (前端静态文件)"
    echo ""
    echo "后端配置:"
    echo "  API 地址: $api_backend (后端服务)"
    echo "  代理规则: /api/* → $api_backend/api/*"
    echo ""
    if [ "$enable_ssl" = true ]; then
        echo "HTTPS: 启用"
        echo "邮箱: $ssl_email"
        echo ""
    else
        echo "HTTPS: 不启用"
        echo ""
    fi
    echo "架构说明:"
    echo "  • 用户访问 $domains → Nginx 返回前端静态文件"
    echo "  • 前端调用 /api/* → Nginx 代理到 $api_backend"
    echo ""
    
    if ! confirm "确认以上配置无误？" "y"; then
        print_info "部署已取消"
        return 1
    fi
    
    # 创建网站目录
    print_step "创建网站目录..."
    sudo mkdir -p "$web_root"
    
    # 备份旧文件
    if [ -d "$web_root" ] && [ "$(ls -A $web_root)" ]; then
        print_step "备份现有文件..."
        backup_name="backup-$(date +%Y%m%d-%H%M%S)"
        sudo mkdir -p "$BACKUP_DIR"
        sudo cp -r "$web_root" "$BACKUP_DIR/$backup_name"
        print_success "备份已保存到: $BACKUP_DIR/$backup_name"
    fi
    
    # 复制文件
    print_step "复制文件到网站目录..."
    sudo cp -r "$DIST_DIR"/* "$web_root/"
    sudo chown -R www-data:www-data "$web_root" 2>/dev/null || sudo chown -R nginx:nginx "$web_root" 2>/dev/null || true
    print_success "文件复制完成"
    
    # 生成 Nginx 配置 (先生成 HTTP 版本)
    print_step "生成 Nginx 配置..."
    config_file="$SCRIPT_DIR/nginx-xboard.conf"
    generate_nginx_config "$domains" "$web_root" "$api_backend" "$config_file"
    
    # 应用配置并启动服务
    print_step "应用 Nginx 配置..."
    if [ -d "/etc/nginx/sites-available" ]; then
        # Debian/Ubuntu 风格
        sudo cp "$config_file" "/etc/nginx/sites-available/xboard"
        sudo ln -sf "/etc/nginx/sites-available/xboard" "/etc/nginx/sites-enabled/xboard"
    else
        # CentOS/RHEL 风格
        sudo cp "$config_file" "/etc/nginx/conf.d/xboard.conf"
    fi
    
    # 测试配置
    print_step "测试 Nginx 配置..."
    if sudo nginx -t; then
        print_success "Nginx 配置测试通过"
        
        # 重启 Nginx
        print_step "重启 Nginx 服务..."
        sudo systemctl restart nginx || sudo service nginx restart
        print_success "Nginx 已重启"
        
        # 检查服务状态
        if sudo systemctl is-active --quiet nginx 2>/dev/null || sudo service nginx status >/dev/null 2>&1; then
            print_success "Nginx 服务运行正常"
        else
            print_error "Nginx 服务启动失败，请检查日志"
            return 1
        fi
    else
        print_error "Nginx 配置测试失败，请检查配置文件"
        return 1
    fi
    
    # 配置 SSL
    if [ "$enable_ssl" = true ]; then
        echo ""
        print_step "开始配置 HTTPS..."
        
        # 确保 certbot 已安装
        if ensure_certbot; then
            # 申请证书
            if request_ssl_certificate "$domains" "$web_root" "$ssl_email"; then
                # 重新生成 HTTPS 配置
                print_step "生成 HTTPS 配置..."
                generate_nginx_config_https "$domains" "$web_root" "$api_backend" "$config_file"
                
                # 重新应用配置
                if [ -d "/etc/nginx/sites-available" ]; then
                    sudo cp "$config_file" "/etc/nginx/sites-available/xboard"
                else
                    sudo cp "$config_file" "/etc/nginx/conf.d/xboard.conf"
                fi
                
                # 测试并重启
                if sudo nginx -t; then
                    sudo systemctl reload nginx || sudo service nginx reload
                    print_success "HTTPS 配置已应用"
                    
                    # 配置自动续期
                    setup_ssl_renewal
                    
                    # 获取主域名用于显示
                    IFS=' ' read -ra domain_array <<< "$domains"
                    local primary_domain="${domain_array[0]}"
                    
                    echo ""
                    print_success "═══ HTTPS 配置完成！ =══"
                    print_info "HTTPS 访问地址: https://$primary_domain"
                    print_info "所有域名: $domains"
                    print_info "HTTP 会自动重定向到 HTTPS"
                else
                    print_error "HTTPS 配置测试失败"
                fi
            else
                print_warning "SSL 证书申请失败，已保留 HTTP 配置"
                print_info "您可以稍后手动申请证书"
            fi
        fi
    fi
    
    # 获取主域名用于显示
    IFS=' ' read -ra domain_array <<< "$domains"
    local primary_domain="${domain_array[0]}"
    
    echo ""
    
    echo ""
    print_success "═══ Nginx 部署完成！ ==="
    
    # 执行健康检查
    echo ""
    perform_health_check "$primary_domain" "$enable_ssl"
    
    # 生成部署报告
    echo ""
    generate_deployment_report "$domains" "$web_root" "$api_backend" "$enable_ssl"
    
    echo ""
    print_success "🎉 部署全部完成！"
    echo ""
    print_info "快速访问:"
    if [ "$enable_ssl" = true ] && [ -f "/etc/letsencrypt/live/$primary_domain/fullchain.pem" ]; then
        echo "  🌐 前端: https://$primary_domain"
        echo "  🔌 API: https://$primary_domain/api/"
    else
        echo "  🌐 前端: http://$primary_domain"
        echo "  🔌 API: http://$primary_domain/api/"
    fi
    echo ""
    print_info "管理命令:"
    echo "  查看日志: sudo tail -f /var/log/nginx/xboard-access.log"
    echo "  重启服务: sudo systemctl restart nginx"
    echo "  卸载前端: $0 --uninstall"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════
# Docker 部署相关函数
#═══════════════════════════════════════════════════════════════════════

# 安装 Docker
install_docker() {
    print_step "安装 Docker..."
    
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo systemctl start docker
    sudo systemctl enable docker
    rm get-docker.sh
    
    print_success "Docker 安装完成"
}

# 确保 Docker 已安装
ensure_docker() {
    if command_exists docker; then
        print_success "检测到 Docker 已安装"
        docker --version
    else
        print_warning "未检测到 Docker"
        if confirm "是否自动安装 Docker？" "y"; then
            install_docker
        else
            print_error "Docker 是必需的，部署已取消"
            exit 1
        fi
    fi
}

# 生成 Dockerfile
generate_dockerfile() {
    cat > "$SCRIPT_DIR/Dockerfile" << 'EOF'
FROM nginx:alpine

# 复制构建产物
COPY dist/ /usr/share/nginx/html/

# 复制 Nginx 配置
COPY docker-nginx.conf /etc/nginx/conf.d/default.conf

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF
    
    print_success "Dockerfile 已生成"
}

# 生成 Docker Nginx 配置
generate_docker_nginx_config() {
    local api_backend="$1"
    
    cat > "$SCRIPT_DIR/docker-nginx.conf" << EOF
server {
    listen 80;
    server_name localhost;
    
    root /usr/share/nginx/html;
    index index.html;
    
    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    location /api {
        proxy_pass $api_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # 订阅链接 /s/* 反向代理到同一后端
    location /s/ {
        proxy_pass $api_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    print_success "Docker Nginx 配置已生成"
}

# 生成 docker-compose.yml
generate_docker_compose() {
    local port="$1"
    
    cat > "$SCRIPT_DIR/docker-compose.yml" << EOF
version: '3.8'

services:
  xboard-frontend:
    build: .
    container_name: xboard-frontend
    restart: unless-stopped
    ports:
      - "$port:80"
    networks:
      - xboard-network
    environment:
      - TZ=Asia/Shanghai
    volumes:
      - ./logs:/var/log/nginx

networks:
  xboard-network:
    driver: bridge
EOF
    
    print_success "docker-compose.yml 已生成"
}

# Docker 部署
deploy_docker() {
    print_step "开始 Docker 部署..."
    
    # 获取配置
    read -p "请输入后端API地址 (默认: http://host.docker.internal:7001): " api_backend
    api_backend=${api_backend:-http://host.docker.internal:7001}
    
    read -p "请输入映射端口 (默认: 80): " port
    port=${port:-80}
    
    # 确认配置
    echo ""
    print_info "═══ Docker 部署配置 ═══"
    echo "后端API: $api_backend"
    echo "映射端口: $port"
    echo ""
    
    if ! confirm "确认配置无误？" "y"; then
        print_info "部署已取消"
        return 1
    fi
    
    # 生成文件
    generate_dockerfile
    generate_docker_nginx_config "$api_backend"
    generate_docker_compose "$port"
    
    # 构建镜像
    if confirm "是否立即构建 Docker 镜像？" "y"; then
        print_step "构建 Docker 镜像..."
        docker build -t xboard-frontend:latest .
        print_success "镜像构建完成"
        
        # 运行容器
        if confirm "是否使用 docker-compose 启动服务？" "y"; then
            print_step "启动 Docker 容器..."
            docker-compose down 2>/dev/null || true
            docker-compose up -d
            
            # 检查容器状态
            sleep 3
            if docker ps | grep -q xboard-frontend; then
                print_success "容器启动成功"
                
                echo ""
                print_success "═══ Docker 部署完成！ =══"
                print_info "访问地址: http://localhost:$port"
                print_info "容器名称: xboard-frontend"
                print_info ""
                print_info "管理命令:"
                echo "  查看日志: docker-compose logs -f"
                echo "  停止服务: docker-compose down"
                echo "  重启服务: docker-compose restart"
            else
                print_error "容器启动失败，请检查 Docker 日志"
            fi
        else
            print_info "Docker 文件已生成，您可以手动运行："
            echo "  docker build -t xboard-frontend:latest ."
            echo "  docker-compose up -d"
        fi
    else
        print_info "Docker 文件已生成但未构建"
    fi
}

#═══════════════════════════════════════════════════════════════════════
# 部署后健康检查
#═══════════════════════════════════════════════════════════════════════

# 健康检查
perform_health_check() {
    local domain="$1"
    local enable_ssl="$2"
    
    print_step "执行部署后健康检查..."
    
    local protocol="http"
    [ "$enable_ssl" = true ] && protocol="https"
    
    local check_passed=0
    local check_failed=0
    
    # 1. 检查 Nginx 服务状态
    print_info "[1/5] 检查 Nginx 服务状态..."
    if sudo systemctl is-active --quiet nginx 2>/dev/null; then
        print_success "  ✓ Nginx 服务正在运行"
        ((check_passed++))
    else
        print_error "  ✗ Nginx 服务未运行"
        ((check_failed++))
    fi
    
    # 2. 检查 Nginx 配置
    print_info "[2/5] 检查 Nginx 配置..."
    if sudo nginx -t 2>/dev/null; then
        print_success "  ✓ Nginx 配置有效"
        ((check_passed++))
    else
        print_error "  ✗ Nginx 配置错误"
        ((check_failed++))
    fi
    
    # 3. 检查端口监听
    print_info "[3/5] 检查端口监听..."
    if sudo netstat -tuln 2>/dev/null | grep -q ":80 " || sudo ss -tuln 2>/dev/null | grep -q ":80 "; then
        print_success "  ✓ 端口 80 正在监听"
        ((check_passed++))
    else
        print_error "  ✗ 端口 80 未监听"
        ((check_failed++))
    fi
    
    if [ "$enable_ssl" = true ]; then
        if sudo netstat -tuln 2>/dev/null | grep -q ":443 " || sudo ss -tuln 2>/dev/null | grep -q ":443 "; then
            print_success "  ✓ 端口 443 正在监听"
            ((check_passed++))
        else
            print_error "  ✗ 端口 443 未监听"
            ((check_failed++))
        fi
    fi
    
    # 4. 测试本地访问
    print_info "[4/5] 测试本地访问..."
    if curl -s -o /dev/null -w "%{http_code}" http://localhost/ | grep -q "200"; then
        print_success "  ✓ 本地访问正常 (HTTP 200)"
        ((check_passed++))
    else
        print_warning "  ⚠ 本地访问可能存在问题"
        ((check_failed++))
    fi
    
    # 5. 测试域名访问（如果不是localhost）
    if [ "$domain" != "localhost" ] && [ "$domain" != "127.0.0.1" ]; then
        print_info "[5/5] 测试域名访问..."
        local status_code=$(curl -s -o /dev/null -w "%{http_code}" -L "$protocol://$domain/" 2>/dev/null || echo "000")
        
        if [ "$status_code" = "200" ]; then
            print_success "  ✓ 域名访问正常 ($protocol://$domain/)"
            ((check_passed++))
        else
            print_warning "  ⚠ 域名访问失败 (HTTP $status_code)"
            print_info "    可能原因: DNS未生效、防火墙阻止、SSL证书问题"
            ((check_failed++))
        fi
    fi
    
    # 总结
    echo ""
    local total_checks=$((check_passed + check_failed))
    print_info "健康检查结果: $check_passed/$total_checks 通过"
    
    if [ $check_failed -eq 0 ]; then
        print_success "✓ 所有检查通过！部署成功！"
        return 0
    elif [ $check_passed -gt $check_failed ]; then
        print_warning "⚠ 部分检查未通过，但核心功能可能正常"
        return 1
    else
        print_error "✗ 多项检查失败，请检查配置"
        return 2
    fi
}

#═══════════════════════════════════════════════════════════════════════
# 卸载功能
#═══════════════════════════════════════════════════════════════════════

# 一键卸载
uninstall_xboard() {
    print_step "XBoard 前端卸载向导"
    
    echo ""
    print_warning "⚠️  警告：卸载将删除以下内容："
    echo "  • Nginx 配置文件"
    echo "  • 网站文件"
    echo "  • 部署备份"
    echo ""
    print_info "注意：不会卸载 Nginx、Node.js 等系统软件"
    echo ""
    
    if ! confirm "确认要卸载 XBoard 前端吗？" "n"; then
        print_info "取消卸载"
        return 0
    fi
    
    local uninstall_count=0
    
    # 1. 停止 Nginx
    if sudo systemctl is-active --quiet nginx 2>/dev/null; then
        print_step "停止 Nginx 服务..."
        sudo systemctl stop nginx
        ((uninstall_count++))
    fi
    
    # 2. 删除 Nginx 配置
    print_step "删除 Nginx 配置..."
    if [ -f "/etc/nginx/sites-available/xboard" ]; then
        sudo rm -f /etc/nginx/sites-available/xboard
        sudo rm -f /etc/nginx/sites-enabled/xboard
        print_success "已删除 Debian/Ubuntu 风格配置"
        ((uninstall_count++))
    fi
    
    if [ -f "/etc/nginx/conf.d/xboard.conf" ]; then
        sudo rm -f /etc/nginx/conf.d/xboard.conf
        print_success "已删除 CentOS/RHEL 风格配置"
        ((uninstall_count++))
    fi
    
    # 3. 询问是否删除网站文件
    if confirm "是否删除网站文件？" "y"; then
        local common_paths=(
            "/var/www/xboard"
            "/usr/share/nginx/html/xboard"
            "/var/www/html/xboard"
        )
        
        for path in "${common_paths[@]}"; do
            if [ -d "$path" ]; then
                print_info "删除: $path"
                sudo rm -rf "$path"
                ((uninstall_count++))
            fi
        done
    fi
    
    # 4. 询问是否删除备份
    if [ -d "$BACKUP_DIR" ]; then
        if confirm "是否删除备份文件？" "n"; then
            print_info "删除备份: $BACKUP_DIR"
            rm -rf "$BACKUP_DIR"
            ((uninstall_count++))
        fi
    fi
    
    # 5. 询问是否删除 SSL 证书
    if [ -d "/etc/letsencrypt/live" ]; then
        local cert_dirs=$(sudo find /etc/letsencrypt/live -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
        if [ -n "$cert_dirs" ]; then
            echo ""
            print_info "发现以下 SSL 证书:"
            echo "$cert_dirs"
            echo ""
            if confirm "是否删除 SSL 证书？" "n"; then
                print_warning "正在删除证书..."
                sudo certbot delete --cert-name "*" 2>/dev/null || true
                ((uninstall_count++))
            fi
        fi
    fi
    
    # 6. 重启 Nginx
    if sudo systemctl is-active --quiet nginx 2>/dev/null; then
        print_step "重启 Nginx..."
        if sudo nginx -t 2>/dev/null; then
            sudo systemctl start nginx
            print_success "Nginx 已重启"
        else
            print_warning "Nginx 配置有误，已保持停止状态"
        fi
    fi
    
    # 7. 清理项目文件
    if [ -f "$SCRIPT_DIR/nginx-xboard.conf" ]; then
        rm -f "$SCRIPT_DIR/nginx-xboard.conf"
    fi
    if [ -f "$SCRIPT_DIR/docker-nginx.conf" ]; then
        rm -f "$SCRIPT_DIR/docker-nginx.conf"
    fi
    if [ -f "$SCRIPT_DIR/Dockerfile" ]; then
        rm -f "$SCRIPT_DIR/Dockerfile"
    fi
    if [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
        rm -f "$SCRIPT_DIR/docker-compose.yml"
    fi
    
    echo ""
    print_success "卸载完成！共删除 $uninstall_count 项"
    print_info "如需重新部署，可再次运行此脚本"
}

#═══════════════════════════════════════════════════════════════════════
# 生成部署报告
#═══════════════════════════════════════════════════════════════════════

# 生成部署报告
generate_deployment_report() {
    local domain="$1"
    local web_root="$2"
    local api_backend="$3"
    local enable_ssl="$4"
    
    DEPLOYMENT_REPORT_FILE="$SCRIPT_DIR/deployment-report-$(date +%Y%m%d-%H%M%S).txt"
    
    local deployment_time=$(($(date +%s) - DEPLOYMENT_START_TIME))
    local deployment_minutes=$((deployment_time / 60))
    local deployment_seconds=$((deployment_time % 60))
    
    cat > "$DEPLOYMENT_REPORT_FILE" << EOF
═══════════════════════════════════════════════════════════════════════
  XBoard 前端部署报告
═══════════════════════════════════════════════════════════════════════

生成时间: $(date '+%Y-%m-%d %H:%M:%S %Z')
部署耗时: ${deployment_minutes}分${deployment_seconds}秒

─────────────────────────────────────────────────────────────────────
📋 系统信息
─────────────────────────────────────────────────────────────────────

操作系统: $OS $OS_VERSION
内核版本: $(uname -r)
主机名: $(hostname)
CPU 核心: $(nproc)
总内存: $(free -h | awk '/^Mem:/{print $2}')
可用内存: $(free -h | awk '/^Mem:/{print $7}')
磁盘空间: $(df -h "$SCRIPT_DIR" | awk 'NR==2 {print $4}') 可用

─────────────────────────────────────────────────────────────────────
🚀 部署配置
─────────────────────────────────────────────────────────────────────

访问域名: $domain
网站根目录: $web_root
后端API: $api_backend
HTTPS: $([ "$enable_ssl" = true ] && echo "已启用" || echo "未启用")

─────────────────────────────────────────────────────────────────────
📦 已安装组件
─────────────────────────────────────────────────────────────────────

Node.js: $(node -v 2>/dev/null || echo "未安装")
npm: $(npm -v 2>/dev/null || echo "未安装")
Nginx: $(nginx -v 2>&1 | cut -d/ -f2 || echo "未安装")
Certbot: $(certbot --version 2>&1 | head -n1 || echo "未安装")
Git: $(git --version 2>/dev/null | cut -d' ' -f3 || echo "未安装")

─────────────────────────────────────────────────────────────────────
🔧 配置文件
─────────────────────────────────────────────────────────────────────

Nginx 配置: $([ -f "/etc/nginx/sites-available/xboard" ] && echo "/etc/nginx/sites-available/xboard" || echo "/etc/nginx/conf.d/xboard.conf")
访问日志: /var/log/nginx/xboard-access.log
错误日志: /var/log/nginx/xboard-error.log
部署日志: $LOG_FILE

─────────────────────────────────────────────────────────────────────
🌐 访问信息
─────────────────────────────────────────────────────────────────────

前端访问: $([ "$enable_ssl" = true ] && echo "https" || echo "http")://$domain
API 代理: $([ "$enable_ssl" = true ] && echo "https" || echo "http")://$domain/api/

─────────────────────────────────────────────────────────────────────
📝 重要提示
─────────────────────────────────────────────────────────────────────

1. 确保后端服务运行在: $api_backend
   测试命令: curl $api_backend/api/v1/guest/comm/config

2. 如已启用防火墙，确保开放以下端口:
   - 80  (HTTP)
   - 443 (HTTPS)

3. SSL 证书自动续期已配置 (如已启用)
   测试续期: sudo certbot renew --dry-run

4. 查看 Nginx 日志:
   访问日志: sudo tail -f /var/log/nginx/xboard-access.log
   错误日志: sudo tail -f /var/log/nginx/xboard-error.log

5. 管理命令:
   重启 Nginx:   sudo systemctl restart nginx
   查看状态:     sudo systemctl status nginx
   测试配置:     sudo nginx -t
   卸载前端:     $0 --uninstall

─────────────────────────────────────────────────────────────────────
✨ 部署完成
─────────────────────────────────────────────────────────────────────

感谢使用 XBoard 部署脚本！
如有问题，请查看: $LOG_FILE

EOF

    print_success "部署报告已生成: $DEPLOYMENT_REPORT_FILE"
    
    # 显示报告内容
    echo ""
    print_info "═══ 部署报告摘要 ═══"
    echo ""
    cat "$DEPLOYMENT_REPORT_FILE" | grep -A 100 "访问信息"
}

#═══════════════════════════════════════════════════════════════════════
# 简单部署（直接复制文件）
#═══════════════════════════════════════════════════════════════════════

deploy_simple() {
    print_step "简单部署模式..."
    
    read -p "请输入目标目录 (例: /var/www/html): " target_dir
    
    if [ -z "$target_dir" ]; then
        print_error "目标目录不能为空"
        return 1
    fi
    
    # 创建目录
    if [ ! -d "$target_dir" ]; then
        if confirm "目录不存在，是否创建？" "y"; then
            sudo mkdir -p "$target_dir"
        else
            return 1
        fi
    fi
    
    # 备份
    if [ -d "$target_dir" ] && [ "$(ls -A $target_dir)" ]; then
        if confirm "目标目录不为空，是否备份现有文件？" "y"; then
            backup_name="backup-$(date +%Y%m%d-%H%M%S)"
            sudo mkdir -p "$BACKUP_DIR"
            sudo cp -r "$target_dir" "$BACKUP_DIR/$backup_name"
            print_success "备份已保存: $BACKUP_DIR/$backup_name"
        fi
    fi
    
    # 复制文件
    print_step "复制文件..."
    sudo cp -r "$DIST_DIR"/* "$target_dir/"
    print_success "文件已复制到: $target_dir"
    
    echo ""
    print_info "提示: 您还需要配置 Web 服务器指向该目录"
}

#═══════════════════════════════════════════════════════════════════════
# 主菜单
#═══════════════════════════════════════════════════════════════════════

show_menu() {
    echo ""
    echo "请选择操作:"
    echo ""
    echo "  1) 全自动部署 (Nginx + HTTPS) [推荐]"
    echo "  2) 简单部署 (仅复制文件)"
    echo "  3) 查看部署信息"
    echo "  4) 卸载 XBoard 前端"
    echo "  5) 退出"
    echo ""
    read -p "请输入选项 [1-5]: " choice
    
    case $choice in
        1)
            ensure_nginx
            deploy_nginx
            ;;
        2)
            deploy_simple
            ;;
        3)
            show_deploy_info
            ;;
        4)
            uninstall_xboard
            ;;
        5)
            print_info "退出部署脚本"
            exit 0
            ;;
        *)
            print_error "无效的选项"
            show_menu
            ;;
    esac
}

# 显示部署信息
show_deploy_info() {
    echo ""
    print_info "═══ 部署环境信息 =══"
    echo ""
    echo "操作系统: $OS $OS_VERSION"
    echo "脚本目录: $SCRIPT_DIR"
    echo "构建目录: $DIST_DIR"
    echo "备份目录: $BACKUP_DIR"
    echo "日志文件: $LOG_FILE"
    echo ""
    
    if [ -d "$DIST_DIR" ]; then
        dist_size=$(du -sh "$DIST_DIR" | cut -f1)
        file_count=$(find "$DIST_DIR" -type f | wc -l)
        echo "构建大小: $dist_size"
        echo "文件数量: $file_count"
    else
        print_warning "未找到构建目录"
    fi
    
    echo ""
    echo "已安装的工具:"
    command_exists nginx && echo "  ✓ Nginx: $(nginx -v 2>&1 | cut -d/ -f2)" || echo "  ✗ Nginx"
    command_exists docker && echo "  ✓ Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')" || echo "  ✗ Docker"
    echo ""
}

#═══════════════════════════════════════════════════════════════════════
# 主程序
#═══════════════════════════════════════════════════════════════════════

main() {
    # 初始化
    print_banner
    log "===== 部署开始 ====="
    
    # 第一阶段: 系统环境初始化
    echo ""
    print_step "🔍 第一阶段: 系统环境检查"
    print_progress 1 10 "检查运行权限"
    check_root
    
    print_progress 2 10 "检测操作系统"
    detect_os
    
    print_progress 3 10 "检查系统资源"
    check_system_resources
    
    print_progress 4 10 "检查网络连接"
    check_network
    
    # 第二阶段: 安装基础依赖
    echo ""
    print_step "📦 第二阶段: 安装基础依赖"
    print_progress 5 10 "安装系统依赖"
    install_base_dependencies
    
    # 第三阶段: 系统配置优化
    echo ""
    print_step "⚙️  第三阶段: 系统配置优化"
    print_progress 6 10 "配置系统设置"
    configure_system
    
    print_progress 7 10 "配置防火墙"
    configure_firewall
    
    # 第四阶段: 项目构建准备
    echo ""
    print_step "🏗️  第四阶段: 项目构建准备"
    print_progress 8 10 "检查构建环境"
    check_prerequisites
    
    print_progress 10 10 "环境初始化完成"
    echo ""
    
    print_success "✅ 系统环境初始化完成！"
    print_info "所有依赖已就绪，可以开始部署"
    
    # 显示菜单
    show_menu
    
    # 询问是否继续
    echo ""
    if confirm "是否继续其他操作？" "n"; then
        show_menu
    fi
    
    echo ""
    print_success "感谢使用 XBoard 部署脚本！"
    log "===== 部署完成 ====="
}

# 处理命令行参数
handle_arguments() {
    case "${1:-}" in
        --uninstall|-u)
            print_banner
            uninstall_xboard
            exit 0
            ;;
        --help|-h)
            print_banner
            echo ""
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --uninstall, -u    卸载 XBoard 前端"
            echo "  --help, -h         显示此帮助信息"
            echo "  --version, -v      显示版本信息"
            echo ""
            echo "无参数运行将进入交互式部署向导"
            exit 0
            ;;
        --version|-v)
            echo "XBoard 前端部署脚本 v2.0.0"
            echo "终极保姆级部署 - 从零环境到生产部署"
            exit 0
            ;;
        "")
            # 无参数，正常运行
            return 0
            ;;
        *)
            echo "错误: 未知参数 '$1'"
            echo "使用 '$0 --help' 查看帮助"
            exit 1
            ;;
    esac
}

# 错误处理
trap 'print_error "部署过程中发生错误，请查看日志: $LOG_FILE"; log "ERROR: $BASH_COMMAND failed"' ERR

# 处理参数并运行主程序
handle_arguments "$@"
main

