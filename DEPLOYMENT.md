# XBoard 前端部署指南

## 📦 打包信息

- **构建日期**: 2025-11-01
- **打包大小**: 约 420KB (未压缩)
- **压缩包大小**: 约 102KB
- **构建工具**: Vite 7.1.12
- **框架**: Vue 3.5.22

---

## 📁 文件结构

```
dist/
├── index.html          # 主页面入口 (1.35KB)
├── vite.svg            # 默认图标
└── assets/             # 静态资源目录
    ├── *.css          # 样式文件 (已压缩和代码分割)
    └── *.js           # JavaScript文件 (已压缩、混淆和代码分割)
```

---

## 🚀 部署方式

### 方式 1: Nginx 部署 (推荐)

#### 1.1 解压文件
```bash
# 如果使用压缩包
tar -xzf xboard-frontend-dist.tar.gz

# 或直接使用dist目录
cp -r dist /var/www/xboard-frontend
```

#### 1.2 Nginx 配置示例
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    # 前端文件路径
    root /var/www/xboard-frontend/dist;
    index index.html;
    
    # Gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_vary on;
    
    # SPA 路由支持
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # API 代理 (代理到后端)
    # - /api/* → 后端 API JSON 接口
    # - /s/*   → 订阅链接 (YAML/其他格式)
    location /api {
        proxy_pass http://localhost:7001;  # 后端API地址
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 订阅链接反向代理到同一后端
    location /s/ {
        proxy_pass http://localhost:7001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
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
}
```

#### 1.3 启用配置
```bash
# 测试配置
sudo nginx -t

# 重载配置
sudo nginx -s reload
```

---

### 方式 2: Apache 部署

#### 2.1 .htaccess 配置
在 `dist/` 目录下创建 `.htaccess` 文件：

```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>

# Gzip 压缩
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/json
</IfModule>

# 浏览器缓存
<IfModule mod_expires.c>
  ExpiresActive On
  ExpiresByType image/jpg "access 1 year"
  ExpiresByType image/jpeg "access 1 year"
  ExpiresByType image/gif "access 1 year"
  ExpiresByType image/png "access 1 year"
  ExpiresByType image/svg+xml "access 1 year"
  ExpiresByType text/css "access 1 month"
  ExpiresByType application/javascript "access 1 month"
  ExpiresByType application/x-javascript "access 1 month"
  ExpiresByType text/javascript "access 1 month"
</IfModule>
```

---

### 方式 3: Docker 部署

#### 3.1 创建 Dockerfile
```dockerfile
FROM nginx:alpine

# 复制构建产物
COPY dist/ /usr/share/nginx/html/

# 复制 Nginx 配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

#### 3.2 构建和运行
```bash
# 构建镜像
docker build -t xboard-frontend .

# 运行容器
docker run -d -p 80:80 --name xboard-frontend xboard-frontend
```

---

### 方式 4: 静态托管服务

可以直接部署到以下平台：
- **Vercel**: `vercel deploy`
- **Netlify**: 拖拽 `dist` 目录
- **GitHub Pages**: 推送到 `gh-pages` 分支
- **Cloudflare Pages**: 连接 Git 仓库

---

## ⚙️ 环境变量配置

### API 地址配置

前端通过 Vite 的代理功能连接后端API。在生产环境中，有两种方式配置API地址：

#### 方式 1: 使用相对路径 (推荐)
前端请求 `/api/*`，通过 Nginx 反向代理到后端。

#### 方式 2: 修改API基础URL
编辑 `src/api/client.ts`:
```typescript
const apiClient = axios.create({
  baseURL: 'https://api.your-domain.com',  // 修改为你的后端API地址
  timeout: 30000,
  withCredentials: true
})
```

然后重新构建：
```bash
npm run build
```

---

## 🔒 安全特性

本构建已启用以下安全特性：

✅ **代码混淆**: 使用 Terser 进行代码混淆
✅ **控制台禁用**: 生产环境自动移除所有 console 输出
✅ **Token加密**: localStorage 中的敏感数据经过加密
✅ **CSP策略**: 实施内容安全策略
✅ **请求签名**: API请求包含时间戳防重放
✅ **开发工具检测**: 检测并提示开发者工具
✅ **Iframe防护**: 防止页面被嵌入iframe

---

## 🧪 本地预览

如果想在本地预览生产构建：

```bash
# 方式 1: 使用 Vite 预览
npm run preview

# 方式 2: 使用 http-server
npx http-server dist -p 8080

# 方式 3: 使用 Python
cd dist && python3 -m http.server 8080
```

---

## 📊 性能优化

已实施的优化：

✅ **代码分割**: 按路由自动分割代码
✅ **Tree Shaking**: 移除未使用的代码
✅ **资源压缩**: Gzip 压缩率约 65-75%
✅ **懒加载**: 路由和组件按需加载
✅ **资源哈希**: 文件名包含内容哈希，利于缓存
✅ **CSS提取**: CSS 独立文件，并行加载

### 文件大小分析

- **最大JS文件**: vue-vendor (99KB / 37KB gzipped)
- **最大CSS文件**: Dashboard (10KB / 2KB gzipped)
- **总资源大小**: 约 420KB (约 102KB gzipped)

---

## 🔧 故障排查

### 1. 页面刷新 404 错误
**原因**: SPA 路由未配置
**解决**: 确保服务器配置了 `try_files` 或 `.htaccess` 重写规则

### 2. API 请求失败
**原因**: API 代理未配置或CORS问题
**解决**: 
- 检查 Nginx 反向代理配置
- 或在后端启用 CORS

### 3. 静态资源加载失败
**原因**: 路径错误
**解决**: 确保 `base` 配置正确（默认为 `/`）

### 4. 白屏问题
**原因**: JavaScript 错误或兼容性问题
**解决**: 
- 检查浏览器控制台错误
- 确保浏览器版本支持（建议 Chrome 90+）

---

## 📞 支持

如有问题，请检查：
1. Nginx/Apache 错误日志
2. 浏览器开发者工具控制台
3. 网络请求状态

---

## 🎉 部署完成检查清单

- [ ] 构建无错误完成
- [ ] 静态文件上传到服务器
- [ ] Web 服务器配置正确
- [ ] SPA 路由正常工作（刷新不404）
- [ ] API 代理配置正确
- [ ] SSL 证书配置（生产环境）
- [ ] 静态资源缓存生效
- [ ] Gzip 压缩启用
- [ ] 安全头配置
- [ ] 功能测试通过

---

**祝部署顺利！** 🚀

