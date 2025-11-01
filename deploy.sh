#!/bin/bash

#═══════════════════════════════════════════════════════════════════════
# XBoard 前端一键部署脚本
# 版本: 1.0.0
# 作者: XBoard Team
# 描述: 保姆级部署脚本，小白也能轻松部署
#═══════════════════════════════════════════════════════════════════════

set -e  # 遇到错误立即退出

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
    echo "  🚀 XBoard 前端一键部署脚本 v1.0.0"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
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

# 检查是否为root用户
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_warning "检测到您正在使用 root 用户运行脚本"
        if ! confirm "是否继续？" "y"; then
            print_info "部署已取消"
            exit 0
        fi
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

# 自动构建项目
auto_build() {
    print_step "准备构建项目..."
    
    # 检查 package.json 是否存在
    if [ ! -f "$SCRIPT_DIR/package.json" ]; then
        print_error "未找到 package.json，请确认这是 XBoard 前端项目目录"
        exit 1
    fi
    
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
    
    # API 反向代理
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
    
    # API 反向代理
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
    print_success "═══ Nginx 部署完成！ =══"
    echo ""
    print_info "前端部署信息:"
    if [ "$enable_ssl" = true ] && [ -f "/etc/letsencrypt/live/$primary_domain/fullchain.pem" ]; then
        echo "  访问地址: https://$primary_domain"
    else
        echo "  访问地址: http://$primary_domain"
    fi
    echo "  所有域名: $domains"
    echo "  静态文件: $web_root"
    echo ""
    print_info "后端 API 配置:"
    echo "  后端地址: $api_backend"
    echo "  代理规则: /api/* → $api_backend/api/*"
    echo ""
    print_info "配置文件:"
    echo "  Nginx 配置: $config_file"
    echo ""
    print_warning "重要提示："
    echo ""
    echo "1. 前后端分离架构已配置完成"
    echo "   • 前端静态文件由 Nginx 直接服务"
    echo "   • 后端 API 请求通过 Nginx 反向代理"
    echo ""
    echo "2. 确保后端服务正常运行"
    echo "   • 后端应该监听在: $api_backend"
    echo "   • 检查命令: curl $api_backend/api/v1/guest/comm/config"
    echo ""
    echo "3. 防火墙端口开放"
    echo "   • 80 (HTTP)"
    if [ "$enable_ssl" = true ]; then
        echo "   • 443 (HTTPS)"
    fi
    echo ""
    echo "   Ubuntu/Debian:"
    echo "     sudo ufw allow 80/tcp && sudo ufw allow 443/tcp"
    echo ""
    echo "   CentOS/RHEL:"
    echo "     sudo firewall-cmd --add-service=http --permanent"
    echo "     sudo firewall-cmd --add-service=https --permanent"
    echo "     sudo firewall-cmd --reload"
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
    echo "请选择部署方式:"
    echo ""
    echo "  1) Nginx 部署 (推荐) - 自动配置 Nginx"
    echo "  2) Docker 部署 - 容器化部署"
    echo "  3) 简单部署 - 仅复制文件"
    echo "  4) 查看部署信息"
    echo "  5) 退出"
    echo ""
    read -p "请输入选项 [1-5]: " choice
    
    case $choice in
        1)
            ensure_nginx
            deploy_nginx
            ;;
        2)
            ensure_docker
            deploy_docker
            ;;
        3)
            deploy_simple
            ;;
        4)
            show_deploy_info
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
    
    # 检查
    check_root
    detect_os
    check_prerequisites
    
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

# 错误处理
trap 'print_error "部署过程中发生错误，请查看日志: $LOG_FILE"; log "ERROR: $BASH_COMMAND failed"' ERR

# 运行主程序
main "$@"

