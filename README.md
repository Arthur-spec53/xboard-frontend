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

**A cyberpunk-styled XBoard theme with Matrix aesthetics**

*Terminal Aesthetics, Geek's Choice | 终端美学，极客之选*

English | [简体中文](README_CN.md)

[✨ Features](#-features) • [📱 Demo](#-demo) • [🚀 Quick Start](#-quick-start) • [📖 Documentation](#-documentation)

</div>

---

## 🎨 About NeoTerminal

**NeoTerminal** is a cutting-edge frontend theme for XBoard, inspired by *The Matrix* and cyberpunk aesthetics. It transforms your XBoard interface into a sleek, hacker-style terminal with neon green accents, matrix rain effects, and ASCII art.

### ✨ Key Highlights

- 🎯 **Matrix Aesthetics**: Falling matrix rain animation and terminal-style UI
- 💚 **Neon Design**: Cyberpunk-inspired color scheme with glowing effects
- 📱 **Fully Responsive**: Perfect mobile adaptation with hamburger menu
- ⚡ **High Performance**: Optimized build with code splitting and lazy loading
- 🛡️ **Security First**: Token management, auto-logout, and CORS handling
- 🚀 **One-Click Deploy**: Automated Nginx deployment script included

---

## ✨ Features

### 🎭 UI/UX

- ✅ **Terminal-Style Interface**: Command-line aesthetics throughout
- ✅ **Matrix Rain Animation**: Animated background with falling code
- ✅ **ASCII Art Logo**: Dynamic site name in ASCII art
- ✅ **Neon Glow Effects**: Cyberpunk-inspired lighting and shadows
- ✅ **Scan Lines Effect**: CRT monitor simulation overlay
- ✅ **Smooth Animations**: GPU-accelerated transitions

### 📱 Mobile First

- ✅ **Responsive Design**: Three breakpoints (1024px, 768px, 640px)
- ✅ **Hamburger Menu**: Slide-in sidebar navigation
- ✅ **Touch Optimized**: Finger-friendly button sizes
- ✅ **Adaptive Images**: Auto-scaling images for mobile
- ✅ **Simplified Header**: Mobile-optimized information display

### 🔧 Technical

- ✅ **Vue 3 Composition API**: Modern reactive framework
- ✅ **TypeScript**: Type-safe codebase
- ✅ **Pinia State Management**: Centralized data store
- ✅ **Vite Build Tool**: Lightning-fast HMR
- ✅ **Axios HTTP Client**: Automatic token and error handling
- ✅ **Vue Router**: SPA navigation

### 🚀 Deployment

- ✅ **Automated Nginx Script**: One-command deployment
- ✅ **Node.js Auto-Detection**: Version check and upgrade
- ✅ **Multi-Domain Support**: Configure multiple domains easily
- ✅ **SSL/HTTPS Ready**: Automatic Certbot integration
- ✅ **Health Checks**: Post-deployment validation
- ✅ **One-Click Uninstall**: Clean removal option

---

## 📱 Demo

### Desktop View
```
┌─────────────────────────────────────────────────┐
│  [Sidebar]  │  Matrix Rain Background         │
│             │  ╔══════════════════════════╗    │
│  • Dashboard│  ║  SYSTEM STATUS           ║    │
│  • Plans    │  ║  ──────────────────────  ║    │
│  • Nodes    │  ║  [Subscription Info]     ║    │
│  • Orders   │  ║  [Traffic Chart]         ║    │
│  • Tickets  │  ║  [Quick Actions]         ║    │
│             │  ╚══════════════════════════╝    │
└─────────────────────────────────────────────────┘
```

### Mobile View
```
┌───────────────────────┐
│ ☰          [Avatar]   │  ← Simplified Header
├───────────────────────┤
│                       │
│   [Dashboard Cards]   │
│   [Single Column]     │
│                       │
└───────────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites

- **Node.js**: v18.0.0 or higher (LTS recommended)
- **npm**: v9.0.0 or higher
- **XBoard Backend**: Running instance with API access

### Installation

在正常使用场景下，推荐直接使用已构建好的前端资源包或一键部署脚本。下面的命令仅供需要自行构建的运维或开发人员参考：

```bash
# Install dependencies (only required if you build from source)
npm install

# Build for production
npm run build
```

---

## 📦 Production Deployment

### Option 1: Automated Nginx Deployment (Recommended)

Our **babysitter-level** deployment script handles everything:

```bash
# Make the script executable
chmod +x deploy.sh

# Run the deployment script
sudo ./deploy.sh
```

The script will:
1. ✅ Check and upgrade Node.js to latest LTS
2. ✅ Install system dependencies
3. ✅ Configure firewall (ports 80, 443)
4. ✅ Build the frontend
5. ✅ Setup Nginx with reverse proxy
6. ✅ Configure SSL with Certbot (optional)
7. ✅ Run health checks
8. ✅ Generate deployment report

### Option 2: Manual Deployment

```bash
# Build for production
npm run build

# The output will be in the 'dist' directory
# Deploy 'dist' to your web server
```

### Configuration

For development, edit `vite.config.ts`:

```typescript
proxy: {
  '/api': {
    target: 'http://your-backend-api.com',  // Your XBoard backend
    changeOrigin: true,
    secure: false
  }
}
```

For production, the deployment script will configure Nginx automatically.

---

## 📖 Documentation

Comprehensive documentation is available:

- 📘 [**Quick Start Guide**](DEPLOY_README.md) - Get started in 5 minutes
- 📗 [**Deployment Guide**](DEPLOY_GUIDE.md) - Detailed deployment instructions
- 📙 [**Deployment Notes**](DEPLOYMENT_NOTE.md) - Architecture decisions
- 📕 [**Fixes & Updates**](FIXES_v2.md) - Version 2.0 improvements

> 💡 **Tip about site name configuration**  
> - The theme reads the site name from the backend API `/api/v1/guest/comm/config`, using the `app_name` field first.  
> - If `app_name` is not configured, it will gracefully fall back to `app_description` (site description), and only then to the default `XBoard`.  
> - It is recommended to set **Site Name (app_name)** in the XBoard admin panel (System Settings → Site Settings), and use the description only as a subtitle/tagline, so that the frontend can display your brand name correctly in the browser title, sidebar and dashboard.

> 🛠 **Advanced: fixing `app_name` on the backend**  
> In some environments, the backend API may return only `app_description` without a proper `app_name`. To make the theme work out of the box:  
> 1. Edit `xboard-backend/app/Http/Controllers/V1/Guest/CommController.php` and locate the `config()` method.  
> 2. Before building the `$data` array, add:  
>    ```php
>    $appName = admin_setting('app_name');
>    $appDesc = admin_setting('app_description');
>    if (empty($appName) && !empty($appDesc)) {
>        $appName = $appDesc;
>    }
>    ```  
> 3. Then use `$appName` / `$appDesc` in `$data`:  
>    ```php
>    'app_name'        => $appName ?: 'XBoard',
>    'app_description' => $appDesc,
>    ```  
> 4. After the change, run `php artisan optimize:clear && php artisan config:clear` (and restart the backend if needed) to make the new behavior take effect.

---

## 🛠️ Development

### Project Structure

```
neoterminal/
├── src/
│   ├── api/              # API client and services
│   ├── assets/           # Static assets
│   ├── components/       # Vue components
│   │   ├── common/       # Shared components
│   │   ├── effects/      # Visual effects
│   │   └── layout/       # Layout components
│   ├── router/           # Vue Router configuration
│   ├── stores/           # Pinia stores
│   ├── types/            # TypeScript types
│   ├── utils/            # Utility functions
│   └── views/            # Page components
├── deploy.sh             # Automated deployment script
├── vite.config.ts        # Vite configuration
└── package.json          # Project metadata
```

### Key Technologies

| Technology | Version | Purpose |
|------------|---------|---------|
| Vue.js | 3.5 | Frontend framework |
| TypeScript | 5.9 | Type safety |
| Vite | 7.1 | Build tool |
| Pinia | 3.0 | State management |
| Vue Router | 4.6 | Routing |
| Axios | 1.13 | HTTP client |
| Tailwind CSS | 4.1 | Utility-first CSS |

---

## 🎨 Customization

### Color Scheme

The theme uses CSS variables for easy customization:

```css
:root {
  --hacker-primary: #00ff41;           /* Neon green */
  --hacker-primary-bright: #7fff7f;    /* Bright green */
  --hacker-primary-dim: rgba(0, 255, 65, 0.3);
  --hacker-bg: #0a0e17;                /* Dark background */
  --hacker-surface: #141821;           /* Surface color */
}
```

### ASCII Logo

Edit `src/components/layout/Sidebar.vue` to customize the ASCII art logo:

```typescript
const generateAsciiLogo = (name: string) => {
  // Add your custom ASCII art here
}
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Inspired by **The Matrix** movie franchise
- Cyberpunk 2077 UI aesthetics
- Terminal and command-line interfaces
- The XBoard community

---

## 📞 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/Arthur-spec53/NeoTerminal/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/Arthur-spec53/NeoTerminal/discussions)
- 📧 **Email**: Create an issue on GitHub

---

## 🌟 Star History

If you like NeoTerminal, please give it a ⭐ on GitHub!

---

<div align="center">

**Made with 💚 by [Arthur-spec53](https://github.com/Arthur-spec53)**

*Wake up, Neo... The Matrix has you.*

</div>
