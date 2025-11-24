<template>
  <aside class="sidebar" :class="{ 'open': isOpen }">
    <div class="sidebar-header">
      <router-link to="/" class="logo-link">
        <pre class="ascii-logo">{{ asciiLogo }}</pre>
      </router-link>
    </div>
    <nav class="main-nav">
      <ul>
        <li v-for="item in navigation" :key="item.name">
          <router-link :to="item.path" class="nav-link" active-class="active" @click="handleNavClick">
            <span class="nav-icon">{{ item.icon }}</span>
            <span class="nav-text">{{ item.name }}</span>
          </router-link>
        </li>
      </ul>
    </nav>
    <div class="sidebar-footer">
      <div class="version">[v1.0.0-HACKER]</div>
    </div>
  </aside>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { configService } from '@/api'
import { log, warn } from '@/utils/logger'

// Props
interface Props {
  isOpen?: boolean
}

withDefaults(defineProps<Props>(), {
  isOpen: false
})

// Emits
const emit = defineEmits<{
  close: []
}>()

// 默认站点名仅作为后端配置尚未加载时的占位显示
const siteName = ref('XBoard')
const asciiLogo = ref('')

// 点击导航项时关闭侧边栏（移动端）
const handleNavClick = () => {
  if (window.innerWidth < 1024) {
    emit('close')
  }
}

const navigation = [
  { name: '仪表盘', path: '/dashboard', icon: '>' },
  { name: '使用文档', path: '/docs', icon: '?' },
  { name: '我的订单', path: '/billing/orders', icon: '*' },
  { name: '我的邀请', path: '/billing/invite', icon: '+' },
  { name: '购买订阅', path: '/subscription/plans', icon: '$' },
  { name: '节点列表', path: '/nodes', icon: '#' },
  { name: '个人中心', path: '/user/profile', icon: '@' },
  { name: '我的工单', path: '/user/tickets', icon: '!' },
  { name: '流量明细', path: '/user/traffic', icon: '~' },
]

// 生成 ASCII 艺术字
const generateAsciiLogo = (name: string) => {
  // 预设的 ASCII 艺术字（仅针对少数常见名称）
  const asciiArtPresets: Record<string, string> = {
    XBoard: `
╦ ╦╔╗ ╔═╗╔═╗╦═╗╔╦╗
╔╩╦╝╠╩╗║ ║╠═╣╠╦╝ ║║
╩ ╚═╚═╝╚═╝╩ ╩╩╚══╩╝`
  }
  
  // 如果有预设，使用预设
  if (asciiArtPresets[name]) {
    return asciiArtPresets[name]
  }
  
  // 否则使用简化的边框风格
  const nameChars = name.split('').join(' ')
  const borderLength = nameChars.length + 4
  const border = '═'.repeat(borderLength)
  
  return `
╔${border}╗
║  ${nameChars}  ║
╚${border}╝`
}

// 获取站点配置
const fetchSiteConfig = async () => {
  try {
    const response = await configService.fetchGuest()
    if (response && response.data) {
      const { app_name, app_description } = response.data

      // 站点名优先使用 app_name，其次描述，最后使用通用默认值
      if (app_name && typeof app_name === 'string' && app_name.trim() !== '') {
        siteName.value = app_name.trim()
        log('[Sidebar] ✅ 使用 app_name 作为站点名称:', siteName.value)
      } else if (app_description && typeof app_description === 'string' && app_description.trim() !== '') {
        siteName.value = app_description.trim()
        log('[Sidebar] ✅ 使用 app_description 作为站点名称:', siteName.value)
      } else {
        siteName.value = 'XBoard'
        log('[Sidebar] ✅ 使用默认站点名称:', siteName.value)
      }

      // 生成 ASCII 艺术字
      asciiLogo.value = generateAsciiLogo(siteName.value)
    }
  } catch (error) {
    warn('[Sidebar] ⚠️ 获取站点配置失败，使用默认值')
    asciiLogo.value = generateAsciiLogo(siteName.value)
  }
}

onMounted(() => {
  // 先设置默认 ASCII logo
  asciiLogo.value = generateAsciiLogo(siteName.value)
  // 然后尝试加载配置
  fetchSiteConfig()
})
</script>

<style scoped>

.sidebar {
  width: 250px;
  height: 100vh;
  position: fixed;
  top: 0;
  left: 0;
  background: var(--hacker-bg);
  border-right: 1px solid var(--hacker-border);
  display: flex;
  flex-direction: column;
  z-index: 1000;
  box-shadow: var(--glow-lg);
  transition: transform 0.3s ease;
}

/* 移动端适配 */
@media (max-width: 1023px) {
  .sidebar {
    transform: translateX(-100%);
  }
  
  .sidebar.open {
    transform: translateX(0);
  }
}

/* 小屏手机适配 */
@media (max-width: 640px) {
  .sidebar {
    width: 280px;
    max-width: 85vw;
  }
}

.sidebar-header {
  padding: 1rem;
  text-align: center;
  border-bottom: 1px solid var(--hacker-border);
}

.logo-link {
  text-decoration: none;
  display: block;
  overflow-x: auto;
}

.ascii-logo {
  font-family: var(--font-mono);
  font-size: 11px;
  line-height: 1.1;
  color: var(--hacker-primary);
  text-shadow: 0 0 5px rgba(0, 255, 65, 0.5),
               0 0 10px rgba(0, 255, 65, 0.3);
  animation: glow-pulse 2s ease-in-out infinite;
  margin: 0;
  padding: 0.5rem;
  white-space: pre;
  text-align: center;
}

@keyframes glow-pulse {
  0%, 100% {
    text-shadow: 0 0 5px rgba(0, 255, 65, 0.5),
                 0 0 10px rgba(0, 255, 65, 0.3);
  }
  50% {
    text-shadow: 0 0 8px rgba(0, 255, 65, 0.7),
                 0 0 15px rgba(0, 255, 65, 0.5),
                 0 0 20px rgba(0, 255, 65, 0.3);
  }
}

.main-nav {
  flex-grow: 1;
  padding: 1rem 0;
}

.main-nav ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.nav-link {
  display: flex;
  align-items: center;
  padding: 0.75rem 1.5rem;
  color: var(--hacker-primary);
  text-decoration: none;
  transition: all 0.2s ease;
  font-size: 14px;
  border-left: 3px solid transparent;
}

.nav-link:hover {
  background: var(--hacker-primary-translucent);
  color: var(--hacker-primary-bright);
  border-left-color: var(--hacker-primary);
}

.nav-link.active {
  background: var(--hacker-primary-translucent);
  color: var(--hacker-primary-bright);
  border-left-color: var(--hacker-primary-bright);
  box-shadow: inset 3px 0 15px -5px var(--hacker-primary-bright);
}

.nav-icon {
  margin-right: 1rem;
  color: var(--hacker-primary-bright);
  font-weight: bold;
  font-size: 16px;
  width: 20px;
  display: inline-block;
  text-align: center;
}

.nav-link:hover .nav-icon,
.nav-link.active .nav-icon {
  text-shadow: var(--glow-md);
}

.sidebar-footer {
  padding: 1rem;
  text-align: center;
  font-size: 12px;
  color: var(--hacker-text-dim);
  border-top: 1px solid var(--hacker-border);
}
</style>
