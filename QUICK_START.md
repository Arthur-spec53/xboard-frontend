# 🚀 XBoard 前端快速部署指南

> **保姆级教程，3分钟轻松部署！**

---

## 📋 目录

- [Linux 一键部署](#linux-一键部署)
- [Windows 一键部署](#windows-一键部署)
- [常见问题](#常见问题)
- [手动部署](#手动部署)

---

## 🐧 Linux 一键部署

### 前置要求
- 已完成构建（`npm run build`）或拥有 `dist` 目录
- 具有 `sudo` 权限（部分操作需要）

### 一键部署命令

```bash
# 1. 进入项目目录
cd /path/to/frontend

# 2. 给脚本添加执行权限
chmod +x deploy.sh

# 3. 运行部署脚本
./deploy.sh
```

### 操作流程

脚本会引导您完成以下步骤：

#### **步骤 1: 选择部署方式**

```
请选择部署方式:
  1) Nginx 部署 (推荐) - 自动配置 Nginx
  2) Docker 部署 - 容器化部署
  3) 简单部署 - 仅复制文件
  4) 查看部署信息
  5) 退出

请输入选项 [1-5]:
```

**推荐选择 1 (Nginx 部署)**

#### **步骤 2: 配置参数**

如果选择 Nginx 部署，脚本会询问：

```
请输入域名 (例: www.example.com 或 localhost): localhost
请输入网站根目录 (默认: /var/www/xboard): /var/www/xboard
请输入后端API地址 (默认: http://localhost:7001): http://localhost:7001
```

**小白用户建议直接按回车使用默认值！**

#### **步骤 3: 确认并部署**

```
═══ 部署配置确认 ═══
域名: localhost
网站目录: /var/www/xboard
后端API: http://localhost:7001

确认以上配置无误？ [Y/n]: y
```

输入 `y` 或直接回车即可开始部署！

#### **步骤 4: 完成**

看到以下信息表示部署成功：

```
✓ Nginx 部署完成！
ℹ 访问地址: http://localhost
ℹ 网站目录: /var/www/xboard
ℹ 配置文件: nginx-xboard.conf
```

---

## 🪟 Windows 一键部署

### 前置要求
- 已完成构建（`npm run build`）或拥有 `dist` 目录
- 管理员权限

### 一键部署步骤

#### **步骤 1: 以管理员身份运行 PowerShell**

1. 按 `Win + X`
2. 选择"Windows PowerShell (管理员)"

#### **步骤 2: 执行部署脚本**

```powershell
# 1. 进入项目目录
cd C:\path\to\frontend

# 2. 允许脚本执行（首次需要）
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 3. 运行部署脚本
.\deploy.ps1
```

#### **步骤 3: 选择部署方式**

```
请选择部署方式:
  1) IIS 部署 (推荐) - 自动配置 IIS
  2) 简单部署 - 仅复制文件
  3) 查看部署信息
  4) 退出

请输入选项 [1-4]: 1
```

**推荐选择 1 (IIS 部署)**

#### **步骤 4: 配置参数**

```
请输入网站名称 (默认: XBoard): XBoard
请输入网站根目录 (默认: C:\inetpub\wwwroot\xboard): 
请输入端口号 (默认: 80): 80
```

**直接按回车使用默认值即可！**

#### **步骤 5: 完成**

```
✓ IIS 部署完成！
ℹ 访问地址: http://localhost:80
ℹ 网站名称: XBoard
ℹ 网站目录: C:\inetpub\wwwroot\xboard
```

---

## ❓ 常见问题

### 问题 1: 脚本提示"权限不足"

**解决方案 (Linux):**
```bash
sudo ./deploy.sh
```

**解决方案 (Windows):**
- 确保以管理员身份运行 PowerShell

---

### 问题 2: 提示"未找到 dist 目录"

**原因:** 还没有构建项目

**解决方案:**
```bash
# 安装依赖（如果还没安装）
npm install

# 构建项目
npm run build
```

---

### 问题 3: Nginx 部署后访问显示 502 错误

**原因:** 后端 API 没有启动或配置错误

**检查步骤:**
1. 确认后端服务已启动
   ```bash
   # 检查后端是否在运行
   curl http://localhost:7001/api/v1/guest/comm/config
   ```

2. 如果后端未启动，先启动后端服务

3. 检查 Nginx 配置中的 API 代理地址是否正确

---

### 问题 4: 页面刷新后出现 404

**原因:** SPA 路由未正确配置

**解决方案:**

**Nginx:**
配置文件中应包含：
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

**IIS:**
确保 `web.config` 文件存在（脚本会自动生成）

---

### 问题 5: Docker 部署后无法访问后端 API

**原因:** Docker 容器网络隔离

**解决方案:**
使用 `host.docker.internal` 而非 `localhost`:
```
后端API地址: http://host.docker.internal:7001
```

或者将前后端放在同一个 Docker 网络中。

---

### 问题 6: Windows IIS 部署提示需要重启

**原因:** IIS 功能首次安装需要重启

**解决方案:**
1. 保存工作
2. 重启电脑
3. 重新运行部署脚本

---

## 📝 手动部署

如果自动部署脚本无法使用，可以手动部署：

### 方式 1: 复制文件

```bash
# 1. 复制 dist 目录到 Web 服务器根目录
cp -r dist/* /var/www/html/

# 2. 设置权限
sudo chown -R www-data:www-data /var/www/html/
```

### 方式 2: 使用 HTTP 服务器

```bash
# 使用 Python 快速启动服务器（仅用于测试）
cd dist
python3 -m http.server 8080
```

访问: http://localhost:8080

⚠️ **注意:** 此方法不支持 API 代理，仅用于前端测试！

---

## 🎯 部署完成后的测试

### 1. 访问测试

在浏览器中打开部署地址（例如 `http://localhost`）

### 2. 功能测试

- [ ] 页面正常加载
- [ ] 登录功能正常
- [ ] API 请求成功
- [ ] 页面路由切换正常
- [ ] 刷新页面不出现 404

### 3. 性能测试

打开浏览器开发者工具（F12）：

- 检查网络请求是否正常
- 查看资源加载速度
- 确认 Gzip 压缩已启用

---

## 🔧 高级配置

### 配置 HTTPS

部署脚本生成的 Nginx 配置文件中包含 HTTPS 配置注释，您可以：

1. 获取 SSL 证书（推荐使用 Let's Encrypt）
2. 取消配置文件中 HTTPS 部分的注释
3. 修改证书路径
4. 重启 Nginx

### 自定义 API 地址

如果后端 API 不在同一服务器：

**Nginx:**
修改 `proxy_pass` 配置（包括订阅路径 `/s/*`）：
```nginx
location /api {
    proxy_pass https://api.example.com;
}

location /s/ {
    proxy_pass https://api.example.com;
}
```

**前端代码:**
修改 `src/api/client.ts` 中的 `baseURL`，然后重新构建。

---

## 📞 获取帮助

### 查看日志

**Linux:**
```bash
# 部署脚本日志
cat deploy.log

# Nginx 错误日志
sudo tail -f /var/log/nginx/error.log
```

**Windows:**
```powershell
# 部署脚本日志
Get-Content deploy.log

# IIS 日志
# 位置: C:\inetpub\logs\LogFiles
```

### 检查服务状态

**Nginx:**
```bash
sudo systemctl status nginx
sudo nginx -t  # 测试配置
```

**IIS:**
```powershell
Get-Website
Get-WebAppPoolState XBoardAppPool
```

---

## 🎉 部署成功！

恭喜您成功部署 XBoard 前端！

接下来您可以：

1. ✅ 配置域名和 SSL 证书
2. ✅ 调整后端 API 配置
3. ✅ 优化性能和缓存
4. ✅ 设置定期备份

如有问题，请参考：
- 📖 [详细部署文档](./DEPLOYMENT.md)
- 📖 [构建信息](./BUILD_INFO.txt)
- 📖 [开发文档](./working.md)

---

**祝您使用愉快！** 🚀

