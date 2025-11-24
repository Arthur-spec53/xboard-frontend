# NeoTerminal

<div align="center">

```
    _   __           ______                    _             __
   / | / /__  ____  /_  __/__  _________ ___  (_)___  ____ _/ /
  /  |/ / _ \/ __ \  / / / _ \/ ___/ __ `__ \/ / __ \/ __ `/ / 
 / /|  /  __/ /_/ / / / /  __/ /  / / / / / / / / / / /_/ / /  
/_/ |_/\___/\____/ /_/  \___/_/  /_/ /_/ /_/_/_/ /_/\__,_/_/   
```

![NeoTerminal](https://img.shields.io/badge/NeoTerminal-v1.0.0-00ff41?style=for-the-badge)
![Vue.js](https://img.shields.io/badge/Vue.js-3.5-4FC08D?style=for-the-badge&logo=vue.js)
![TypeScript](https://img.shields.io/badge/TypeScript-5.9-3178C6?style=for-the-badge&logo=typescript)
![License](https://img.shields.io/badge/License-MIT-00ff41?style=for-the-badge)

**赛博朋克风格的 XBoard 前端主题，致敬《黑客帝国》**

*终端美学，极客之选*

[English](README.md) | 简体中文

[✨ 特性](#-特性) • [📱 演示](#-演示) • [🚀 快速开始](#-快速开始) • [📖 文档](#-文档)

</div>

---

## 🎨 关于 NeoTerminal

**NeoTerminal** 是一款为 XBoard 设计的前沿主题，灵感来源于《黑客帝国》和赛博朋克美学。它将您的 XBoard 界面转变为一个时尚的黑客风格终端，配以霓虹绿色点缀、矩阵雨特效和 ASCII 艺术字。

### ✨ 核心亮点

- 🎯 **黑客帝国美学**：流动的矩阵雨动画和终端风格的用户界面
- 💚 **霓虹设计**：赛博朋克风格的配色方案，带有发光效果
- 📱 **完整响应式**：完美的移动端适配，配有汉堡菜单
- ⚡ **高性能**：优化的构建配置，代码分割和懒加载
- 🛡️ **安全第一**：Token 管理、自动登出和 CORS 处理
- 🚀 **一键部署**：包含自动化的 Nginx 部署脚本

---

## ✨ 特性

### 🎭 界面/体验

- ✅ **终端风格界面**：贯穿始终的命令行美学
- ✅ **矩阵雨动画**：动态背景，代码雨效果
- ✅ **ASCII 艺术 Logo**：动态的站点名称 ASCII 艺术字
- ✅ **霓虹发光效果**：赛博朋克风格的光影效果
- ✅ **扫描线特效**：CRT 显示器模拟覆盖层
- ✅ **流畅动画**：GPU 加速的过渡效果

### 📱 移动优先

- ✅ **响应式设计**：三个断点（1024px, 768px, 640px）
- ✅ **汉堡菜单**：滑入式侧边栏导航
- ✅ **触摸优化**：适合手指操作的按钮尺寸
- ✅ **自适应图片**：移动端自动缩放图片
- ✅ **精简 Header**：移动端优化的信息显示

### 🔧 技术特性（用“网站特点”来理解就好）

- ✅ **响应式界面引擎**：支持按需加载与页面级组件拆分，首屏加载快、切换无明显卡顿
- ✅ **类型安全的业务代码**：在开发阶段就能发现大部分类型和接口问题，减少线上低级错误
- ✅ **集中式数据存储**：用户信息、订阅数据、统计信息等集中管理，保证不同页面看到的数据是一致的
- ✅ **单页应用导航**：地址栏变化与内容切换在前端完成，避免整页刷新，体验更接近桌面应用
- ✅ **内置 HTTP 客户端**：统一处理令牌、超时、错误提示，把请求逻辑从页面里抽离出来

### 🚀 部署工具

- ✅ **自动化 Nginx 脚本**：一键部署命令
- ✅ **Node.js 自动检测**：版本检查和升级
- ✅ **多域名支持**：轻松配置多个域名
- ✅ **SSL/HTTPS 就绪**：自动 Certbot 集成
- ✅ **健康检查**：部署后验证
- ✅ **一键卸载**：干净的移除选项

---

## 📱 演示

### 桌面端视图
```
┌─────────────────────────────────────────────────┐
│  [侧边栏]    │  矩阵雨背景                      │
│             │  ╔══════════════════════════╗    │
│  • 仪表盘   │  ║  系统状态                ║    │
│  • 套餐     │  ║  ──────────────────────  ║    │
│  • 节点     │  ║  [订阅信息]              ║    │
│  • 订单     │  ║  [流量图表]              ║    │
│  • 工单     │  ║  [快捷操作]              ║    │
│             │  ╚══════════════════════════╝    │
└─────────────────────────────────────────────────┘
```

### 移动端视图
```
┌───────────────────────┐
│ ☰          [头像]     │  ← 精简的 Header
├───────────────────────┤
│                       │
│   [仪表盘卡片]        │
│   [单列布局]          │
│                       │
└───────────────────────┘
```

---

## 🚀 快速开始

### 环境要求

- **Node.js**：v18.0.0 或更高版本（推荐 LTS）
- **npm**：v9.0.0 或更高版本
- **XBoard 后端**：运行中的实例，可访问 API

### 安装步骤

在正常使用场景下，推荐直接使用打包好的前端资源或一键部署脚本。以下命令仅供需要自行构建的运维或开发人员参考：

```bash
# 安装依赖（仅在自行构建时需要）
npm install

# 构建生产版本
npm run build
```

---

## 📦 生产环境部署

### 方案一：自动化 Nginx 部署（推荐）

我们的**保姆级**部署脚本会处理一切：

```bash
# 赋予脚本执行权限
chmod +x deploy.sh

# 运行部署脚本
sudo ./deploy.sh
```

脚本会自动完成：
1. ✅ 检查并升级 Node.js 到最新 LTS 版本
2. ✅ 安装系统依赖
3. ✅ 配置防火墙（端口 80, 443）
4. ✅ 构建前端项目
5. ✅ 设置 Nginx 反向代理
6. ✅ 配置 SSL（Certbot，可选）
7. ✅ 运行健康检查
8. ✅ 生成部署报告

### 方案二：手动部署

```bash
# 生产环境构建
npm run build

# 输出目录为 'dist'
# 将 'dist' 目录部署到您的 Web 服务器
```

### 配置说明

开发环境配置，编辑 `vite.config.ts`：

```typescript
proxy: {
  '/api': {
    target: 'http://your-backend-api.com',  // 您的 XBoard 后端地址
    changeOrigin: true,
    secure: false
  }
}
```

生产环境部署脚本会自动配置 Nginx。

---

## 📖 文档

我们提供了完整的文档：

- 📘 [**快速开始指南**](DEPLOY_README.md) - 5 分钟快速上手
- 📗 [**部署指南**](DEPLOY_GUIDE.md) - 详细的部署说明
- 📙 [**部署说明**](DEPLOYMENT_NOTE.md) - 架构决策说明
- 📕 [**修复和更新**](FIXES_v2.md) - 2.0 版本改进

> 💡 **站点名称小贴士**  
> - 主题会优先使用后端接口 `/api/v1/guest/comm/config` 返回的 `app_name` 作为站点名称。  
> - 如果后端没有配置 `app_name`，则会自动回退使用 `app_description`（站点描述），最后才使用默认值 `XBoard`。  
> - 建议在 XBoard 后台的“系统设置 / 站点设置”中填写 **站点名称(app_name)**，站点描述仅用于副标题或宣传语，这样前端能在标题、侧边栏和仪表盘中正确展示您的品牌名称。

> 🛠 **高级：如何在后端修正站点名称字段**  
> 某些旧版本或自定义环境中，后端接口可能没有正确返回 `app_name`，只返回了 `app_description`。为了兼容这类情况，可以在后端按以下方式修改：  
> 1. 编辑 `xboard-backend/app/Http/Controllers/V1/Guest/CommController.php` 中的 `config()` 方法。  
> 2. 在构建 `$data` 之前增加如下逻辑：  
>    ```php
>    $appName = admin_setting('app_name');
>    $appDesc = admin_setting('app_description');
>    if (empty($appName) && !empty($appDesc)) {
>        $appName = $appDesc;
>    }
>    ```  
> 3. 然后在 `$data` 数组中使用 `$appName` / `$appDesc`：  
>    ```php
>    'app_name'        => $appName ?: 'XBoard',
>    'app_description' => $appDesc,
>    ```  
> 4. 修改完成后执行 `php artisan optimize:clear && php artisan config:clear` 并重启后端服务，使配置生效。

---

## 🛠️ 开发指南

### 项目结构

```
neoterminal/
├── src/
│   ├── api/              # API 客户端和服务
│   ├── assets/           # 静态资源
│   ├── components/       # 页面组件与基础组件
│   │   ├── common/       # 共享组件
│   │   ├── effects/      # 视觉特效
│   │   └── layout/       # 布局组件
│   ├── router/           # 前端路由配置
│   ├── stores/           # 全局状态库
│   ├── types/            # 类型定义
│   ├── utils/            # 工具函数
│   └── views/            # 页面组件
├── deploy.sh             # 自动化部署脚本
├── vite.config.ts        # Vite 配置
└── package.json          # 项目元数据
```

### 实现特点（不展开具体技术名词）

- **现代化前端架构**：采用组件化 + 单页应用模式，支持代码拆分和懒加载，保证在功能丰富的前提下仍有良好的加载速度。
- **工程化开发流程**：内置脚本支持本地开发、构建、预览与自动部署，前端代码改动后可以快速得到反馈。
- **可维护的样式体系**：通过变量与原子化类名组合控制主题色、阴影、边框与排版，实现整体统一的“终端 + 赛博朋克”风格。
- **安全友好**：请求层统一附带认证信息和错误处理，避免在每个页面重复写复杂的安全逻辑。

---

## 🎨 自定义

### 配色方案

主题使用 CSS 变量，方便自定义：

```css
:root {
  --hacker-primary: #00ff41;           /* 霓虹绿 */
  --hacker-primary-bright: #7fff7f;    /* 亮绿色 */
  --hacker-primary-dim: rgba(0, 255, 65, 0.3);
  --hacker-bg: #0a0e17;                /* 深色背景 */
  --hacker-surface: #141821;           /* 表面颜色 */
}
```

### ASCII Logo

编辑 `src/components/layout/Sidebar.vue` 来自定义 ASCII 艺术 Logo：

```typescript
const generateAsciiLogo = (name: string) => {
  // 在此处添加您的自定义 ASCII 艺术
}
```

### 静态界面预览（本地文件）

- 我们提供了一个**纯静态的界面预览文件**，方便在不连接后端的情况下快速查看主题大致效果。  
- 文件路径：`docs/neoterminal-demo.html`  
- 使用方式：  
  - 克隆本仓库后，直接在本地浏览器中打开该 HTML 文件即可预览；  
  - 或将该文件部署到您自己的前端站点中，用于给最终用户展示界面风格。  
- 注意：这是**示意性页面**，不包含真实数据和交互逻辑，仅用于文档展示。

---

## 🌟 主要功能展示

### 仪表盘页面
- 📊 实时流量统计
- 📈 历史流量图表
- 💳 订阅信息展示
- 🔔 系统公告提醒
- 🚀 一键订阅链接

### 套餐购买
- 💰 套餐列表展示
- 🎯 周期选择（月付/季付/年付）
- 💳 在线支付集成
- 🎁 优惠码支持

### 节点管理
- 🌍 节点列表展示
- 📶 节点延迟显示
- ✅ 在线状态检测
- 📋 一键复制配置

### 工单系统
- 💬 创建工单
- 📝 工单回复
- 🏷️ 工单状态跟踪
- 📎 附件上传支持

---

## 🤝 贡献指南

欢迎贡献！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支（`git checkout -b feature/AmazingFeature`）
3. 提交您的更改（`git commit -m 'Add some AmazingFeature'`）
4. 推送到分支（`git push origin feature/AmazingFeature`）
5. 开启一个 Pull Request

### 代码规范

- 使用 TypeScript 编写代码
- 遵循 Vue 3 最佳实践
- 添加必要的注释
- 确保所有功能都能正常工作

---

## 📝 许可证

本项目采用 **MIT 许可证** - 详见 [LICENSE](LICENSE) 文件。

---

## 🙏 致谢

- 灵感来源于**《黑客帝国》**电影系列
- 赛博朋克 2077 UI 美学
- 终端和命令行界面设计
- XBoard 社区

---

## 📞 支持

- 🐛 **Bug 报告**：[GitHub Issues](https://github.com/Arthur-spec53/NeoTerminal/issues)
- 💬 **讨论**：[GitHub Discussions](https://github.com/Arthur-spec53/NeoTerminal/discussions)
- 📧 **联系方式**：在 GitHub 上创建 Issue

---

## ❓ 常见问题

### 1. 如何修改 API 地址？

**开发环境**：编辑 `vite.config.ts` 中的 `proxy.target`

**生产环境**：运行 `deploy.sh` 脚本时会提示输入后端 API 地址

### 2. 支持哪些浏览器？

- ✅ Chrome / Edge（推荐）
- ✅ Firefox
- ✅ Safari
- ✅ 微信内置浏览器

### 3. 移动端如何使用？

完全支持移动端！使用汉堡菜单（左上角 ☰）打开侧边栏导航。

### 4. 如何卸载？

运行 `sudo ./deploy.sh --uninstall` 即可完全卸载。

### 5. 支持多域名吗？

支持！部署时可以输入多个域名，用空格分隔。

---

## 🔄 更新日志

### v1.0.0 (2025-11-02)
- 🎉 首个稳定版本发布
- ✨ 完整移动端适配
- 🎨 黑客帝国主题设计
- 🚀 保姆级部署脚本
- 📱 三个响应式断点
- 💚 动态 ASCII Logo
- 🛡️ Token 安全管理
- ⚡ 性能优化

---

## 🌟 Star 历史

如果您喜欢 NeoTerminal，请在 GitHub 上给它一个 ⭐！

---

## 📸 截图展示

### 桌面端
![Desktop Dashboard](https://via.placeholder.com/800x450/0a0e17/00ff41?text=Desktop+Dashboard)

### 移动端
![Mobile View](https://via.placeholder.com/375x667/0a0e17/00ff41?text=Mobile+View)

### 矩阵雨效果
![Matrix Rain](https://via.placeholder.com/800x450/0a0e17/00ff41?text=Matrix+Rain+Effect)

---

## 💡 小贴士

### 性能优化建议
1. 使用 CDN 加速静态资源
2. 启用 Gzip/Brotli 压缩
3. 配置浏览器缓存
4. 使用 HTTP/2 协议

### 安全建议
1. 始终使用 HTTPS
2. 定期更新依赖包
3. 配置 CSP 头
4. 启用 HSTS

---

<div align="center">

**用 💚 制作，致敬黑客精神**

*醒来吧，Neo……矩阵拥有了你。*

**Made by [Arthur-spec53](https://github.com/Arthur-spec53)**

[⬆ 回到顶部](#neoterminal)

</div>

