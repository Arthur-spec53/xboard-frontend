<template>
  <div class="dashboard-page">
    <!-- 页面头部 -->
    <div class="dashboard-header">
      <TerminalPrompt :user="userStore.email?.split('@')[0] || 'user'" :host="siteName" />
      <div class="header-actions">
        <div class="header-time">
          [SYS_TIME: {{ currentTime }}]
        </div>
        <!-- 用户菜单 -->
        <div class="user-menu" @click="toggleUserMenu">
          <Icon icon="lucide:user" class="user-icon" />
          <span class="user-email">{{ userStore.email || 'User' }}</span>
          <Icon icon="lucide:chevron-down" class="menu-arrow" :class="{ 'menu-open': showUserMenu }" />
          
          <!-- 下拉菜单 -->
          <transition name="menu-fade">
            <div v-if="showUserMenu" class="user-dropdown" @click.stop>
              <div class="menu-item" @click="handleLogout">
                <Icon icon="lucide:log-out" />
                <span>退出登录</span>
              </div>
            </div>
          </transition>
        </div>
      </div>
    </div>
    
    <!-- 系统公告 -->
    <div class="dashboard-section">
      <div class="section-title">
        <span class="terminal-prompt"></span>系统公告
      </div>
      <GeekCard>
        <div v-if="notices.length > 0">
          <div v-for="notice in notices" :key="notice.id" class="notice-item">
            <div class="notice-header">
              <span class="success-marker">[>]</span>
              <span class="notice-title">{{ notice.title }}</span>
              <span class="notice-date">[{{ formatDate(notice.created_at) }}]</span>
            </div>
            <!-- 公告图片 -->
            <div v-if="notice.img_url" class="notice-image">
              <img :src="notice.img_url" :alt="notice.title" @error="handleImageError" />
            </div>
            <!-- 公告内容（经过 HTML 清洗，防止 XSS） -->
            <div class="notice-content" v-html="sanitizeHtml(notice.content)"></div>
            <!-- 公告标签 -->
            <div v-if="notice.tags && notice.tags.length > 0" class="notice-tags">
              <span v-for="tag in notice.tags" :key="tag" class="notice-tag">[{{ tag }}]</span>
            </div>
          </div>
        </div>
        <div v-else class="no-data">
          [暂无公告]
        </div>
      </GeekCard>
    </div>
    
    <!-- 订阅与流量概览 -->
    <div class="dashboard-section">
      <div class="section-title">
        <span class="terminal-prompt"></span>订阅与流量概览
      </div>
      
      <GeekCard title="当前订阅信息" hoverable>
        <div class="subscription-overview">
          <!-- 左侧：订阅状态 -->
          <div class="overview-left">
            <div class="plan-info">
              <div class="plan-name">{{ currentPlanName }}</div>
              <div class="plan-status" :class="userStore.hasActiveSubscription ? 'status-active' : 'status-inactive'">
                <span class="status-marker">●</span>
                {{ userStore.hasActiveSubscription ? '激活中' : '未激活' }}
              </div>
            </div>
            <div class="expiry-info">
              <div class="info-row">
                <span class="info-label">[到期时间]</span>
                <span class="info-value">{{ userStore.expirationInfo.formatted }}</span>
              </div>
              <div class="info-row" v-if="userStore.expirationInfo.daysLeft < 999999">
                <span class="info-label">[剩余天数]</span>
                <span class="info-value">{{ userStore.expirationInfo.daysLeft }} 天</span>
              </div>
              <div class="info-row" v-else>
                <span class="info-label">[订阅类型]</span>
                <span class="info-value">永久套餐</span>
              </div>
            </div>
          </div>
          
          <!-- 右侧：流量使用 -->
          <div class="overview-right">
            <div class="traffic-info">
              <div class="traffic-label">流量使用情况</div>
              <GeekProgressBar
                :current="userStore.trafficUsage.used"
                :total="userStore.trafficUsage.total"
                label="流量"
              />
              <div class="traffic-details">
                <div class="info-row">
                  <span class="info-label">[已用流量]</span>
                  <span class="info-value">{{ userStore.trafficUsage.usedFormatted }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">[总流量]</span>
                  <span class="info-value">{{ userStore.trafficUsage.totalFormatted }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">[剩余流量]</span>
                  <span class="info-value">{{ userStore.trafficUsage.remainingFormatted }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </GeekCard>
    </div>
    
    <!-- 流量明细 -->
    <div class="dashboard-section">
      <div class="section-title">
        <span class="terminal-prompt"></span>流量明细
      </div>
      
      <GeekCard title="最近7天流量使用趋势">
        <div v-if="isLoadingTraffic" class="loading-state">
          [加载中...]
        </div>
        <div v-else-if="trafficLogs.length > 0" class="traffic-chart-container">
          <!-- 堆积面积图 -->
          <div class="chart-wrapper">
            <svg class="traffic-chart" :viewBox="`0 0 ${chartWidth} ${chartHeight}`" preserveAspectRatio="xMidYMid meet">
              <!-- Y轴网格线 -->
              <g class="grid-lines">
                <line v-for="i in 5" :key="'grid-' + i" 
                  :x1="chartPadding.left" 
                  :y1="chartPadding.top + (chartHeight - chartPadding.top - chartPadding.bottom) * i / 5"
                  :x2="chartWidth - chartPadding.right"
                  :y2="chartPadding.top + (chartHeight - chartPadding.top - chartPadding.bottom) * i / 5"
                  class="grid-line"
                />
              </g>
              
              <!-- 下载流量面积 (底层) -->
              <path v-if="downloadAreaPath" :d="downloadAreaPath" class="area-download" />
              
              <!-- 上传流量面积 (叠加在下载上) -->
              <path v-if="uploadAreaPath" :d="uploadAreaPath" class="area-upload" />
              
              <!-- 总流量线 -->
              <path v-if="totalLinePath" :d="totalLinePath" class="line-total" />
              
              <!-- 数据点 -->
              <g v-if="chartPoints.length > 0" class="data-points">
                <template v-for="(chartPoint, index) in chartPoints" :key="'point-' + index">
                  <circle v-if="!isNaN(chartPoint.x) && !isNaN(chartPoint.totalY)"
                    :cx="chartPoint.x"
                    :cy="chartPoint.totalY"
                    r="4"
                    class="data-point"
                  />
                </template>
              </g>
              
              <!-- X轴标签 -->
              <g class="x-axis-labels">
                <text v-for="(log, index) in displayTrafficLogs" :key="'label-' + index"
                  :x="chartPadding.left + (chartWidth - chartPadding.left - chartPadding.right) * index / Math.max(displayTrafficLogs.length - 1, 1)"
                  :y="chartHeight - chartPadding.bottom + 20"
                  class="axis-label"
                  text-anchor="middle"
                >
                  {{ log.shortDate }}
                </text>
              </g>
              
              <!-- Y轴标签 -->
              <g class="y-axis-labels">
                <text v-for="i in 5" :key="'y-label-' + i"
                  :x="chartPadding.left - 10"
                  :y="chartPadding.top + (chartHeight - chartPadding.top - chartPadding.bottom) * (5 - i) / 5 + 5"
                  class="axis-label"
                  text-anchor="end"
                >
                  {{ formatBytes(maxTraffic * i / 5) }}
                </text>
              </g>
            </svg>
          </div>
          
          <!-- 图例 -->
          <div class="chart-legend">
            <div class="legend-item">
              <span class="legend-marker upload"></span>
              <span class="legend-label">上传</span>
            </div>
            <div class="legend-item">
              <span class="legend-marker download"></span>
              <span class="legend-label">下载</span>
            </div>
            <div class="legend-item">
              <span class="legend-marker total"></span>
              <span class="legend-label">总计</span>
            </div>
          </div>
          
          <!-- 数据表格（可折叠） -->
          <details class="traffic-details">
            <summary class="details-summary">[查看详细数据]</summary>
            <div class="traffic-table">
              <div class="table-header">
                <div>[日期]</div>
                <div>[上传]</div>
                <div>[下载]</div>
                <div>[总计]</div>
              </div>
              <div v-for="log in trafficLogs" :key="log.date" class="table-row">
                <div>{{ log.date }}</div>
                <div>{{ log.uploadFormatted }}</div>
                <div>{{ log.downloadFormatted }}</div>
                <div>{{ log.totalFormatted }}</div>
              </div>
            </div>
          </details>
        </div>
        <div v-else class="no-data">
          [暂无流量记录]
        </div>
      </GeekCard>
    </div>
    
    <!-- 一键订阅 -->
    <div class="dashboard-section">
      <div class="section-title">
        <span class="terminal-prompt"></span>一键订阅
      </div>
      <GeekCard title="一键导入配置">
        <div class="subscribe-description">
          <span class="terminal-prompt"></span>
          <span class="hint-text">[提示] 点击下方按钮将自动打开对应客户端并导入配置</span>
        </div>
        
        <div class="subscribe-grid">
          <div class="subscribe-item">
            <div class="client-info">
              <div class="client-name">[CLASH]</div>
              <div class="client-hint">适用于 Windows/Mac/Android</div>
            </div>
            <GeekButton size="sm" @click="openInClient('clash')">
              一键导入
            </GeekButton>
          </div>
          <div class="subscribe-item">
            <div class="client-info">
              <div class="client-name">[V2RAYN/V2RAYNG]</div>
              <div class="client-hint">适用于 Windows/Android</div>
            </div>
            <GeekButton size="sm" @click="openInClient('v2ray')">
              一键导入
            </GeekButton>
          </div>
          <div class="subscribe-item">
            <div class="client-info">
              <div class="client-name">[SINGBOX]</div>
              <div class="client-hint">适用于全平台</div>
            </div>
            <GeekButton size="sm" @click="openInClient('singbox')">
              一键导入
            </GeekButton>
          </div>
          <div class="subscribe-item">
            <div class="client-info">
              <div class="client-name">[SHADOWROCKET]</div>
              <div class="client-hint">适用于 iOS</div>
            </div>
            <GeekButton size="sm" @click="openInClient('shadowrocket')">
              一键导入
            </GeekButton>
          </div>
          <div class="subscribe-item">
            <div class="client-info">
              <div class="client-name">[SURGE]</div>
              <div class="client-hint">适用于 iOS/Mac</div>
            </div>
            <GeekButton size="sm" @click="openInClient('surge')">
              一键导入
            </GeekButton>
          </div>
          <div class="subscribe-item">
            <div class="client-info">
              <div class="client-name">[QUANTUMULT X]</div>
              <div class="client-hint">适用于 iOS</div>
            </div>
            <GeekButton size="sm" @click="openInClient('quantumult')">
              一键导入
            </GeekButton>
          </div>
        </div>
        
        <!-- 手动订阅区域 -->
        <details class="manual-subscribe">
          <summary class="details-summary">[高级] 手动复制订阅链接</summary>
          <div class="subscribe-url">
            <div class="url-row">
              <span class="url-label">通用链接:</span>
              <input 
                type="text" 
                :value="subscribeUrl" 
                readonly 
                class="hacker-input"
                @click="selectAll"
              />
              <GeekButton size="sm" @click="copyUrl">
                {{ urlCopied ? '已复制' : '复制' }}
              </GeekButton>
            </div>
          </div>
        </details>
      </GeekCard>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { useAuthStore } from '@/stores/auth'
import { sanitizeHtml } from '@/utils/sanitize'
import { noticeService, statService, configService } from '@/api'
import { useClipboard } from '@vueuse/core'
import { log, warn, logError } from '@/utils/logger'
import { Icon } from '@iconify/vue'
import GeekCard from '@/components/common/GeekCard.vue'
import GeekButton from '@/components/common/GeekButton.vue'
import GeekProgressBar from '@/components/common/GeekProgressBar.vue'
import TerminalPrompt from '@/components/effects/TerminalPrompt.vue'

const router = useRouter()
const userStore = useUserStore()
const authStore = useAuthStore()
const { copy } = useClipboard()

const urlCopied = ref(false)
const showUserMenu = ref(false)

const currentTime = ref('')
const notices = ref<any[]>([])
const trafficLogs = ref<any[]>([])
const isLoadingTraffic = ref(false)
// 站点名称，优先使用后端配置，仅在未加载时使用通用占位
const siteName = ref('XBoard')
const subscribeUrl = computed(() => userStore.subscription?.subscribe_url || '')

// 图表配置
const chartWidth = 800
const chartHeight = 250  // 调整到合理高度250px
const chartPadding = { top: 20, right: 20, bottom: 40, left: 60 }

// 用于显示的流量日志（倒序，最新的在右边）
const displayTrafficLogs = computed(() => [...trafficLogs.value].reverse())

// 最大流量值（用于Y轴缩放）
const maxTraffic = computed(() => {
  if (trafficLogs.value.length === 0) return 1000000000 // 1GB默认
  return Math.max(...trafficLogs.value.map(log => log.total), 1000000)
})

// 图表数据点
const chartPoints = computed(() => {
  const logs = displayTrafficLogs.value
  if (logs.length === 0) return []
  
  const width = chartWidth - chartPadding.left - chartPadding.right
  const height = chartHeight - chartPadding.top - chartPadding.bottom
  const max = maxTraffic.value
  
  // 避免除以0
  if (max === 0 || logs.length === 0) return []
  
  return logs.map((log, index) => {
    // 处理单个数据点的情况
    const divisor = logs.length > 1 ? (logs.length - 1) : 1
    const x = chartPadding.left + (width * index / divisor)
    
    // 确保log.download和log.total是有效数字
    const download = log.download || 0
    const total = log.total || 0
    
    const downloadY = chartPadding.top + height * (1 - download / max)
    const totalY = chartPadding.top + height * (1 - total / max)
    
    return { x, downloadY, totalY, log }
  })
})

// 下载流量面积路径
const downloadAreaPath = computed(() => {
  const points = chartPoints.value
  if (points.length === 0) return ''
  
  // 检查所有值是否有效
  if (points.some(p => isNaN(p.x) || isNaN(p.downloadY))) {
    warn('[Dashboard] 图表数据包含无效值')
    return ''
  }
  
  const height = chartHeight - chartPadding.bottom
  const firstPoint = points[0]
  const lastPoint = points[points.length - 1]
  if (!firstPoint || !lastPoint) return ''
  
  let path = `M ${firstPoint.x} ${height}`
  
  points.forEach(point => {
    path += ` L ${point.x} ${point.downloadY}`
  })
  
  path += ` L ${lastPoint.x} ${height} Z`
  return path
})

// 上传流量面积路径（堆积在下载上方）
const uploadAreaPath = computed(() => {
  const points = chartPoints.value
  if (points.length === 0) return ''
  
  // 检查所有值是否有效
  if (points.some(p => isNaN(p.x) || isNaN(p.downloadY) || isNaN(p.totalY))) {
    return ''
  }
  
  const firstPoint = points[0]
  if (!firstPoint) return ''
  
  let path = `M ${firstPoint.x} ${firstPoint.downloadY}`
  
  points.forEach(point => {
    path += ` L ${point.x} ${point.totalY}`
  })
  
  for (let i = points.length - 1; i >= 0; i--) {
    const point = points[i]
    if (point) {
      path += ` L ${point.x} ${point.downloadY}`
    }
  }
  
  path += ' Z'
  return path
})

// 总流量线路径
const totalLinePath = computed(() => {
  const points = chartPoints.value
  if (points.length === 0) return ''
  
  // 检查所有值是否有效
  if (points.some(p => isNaN(p.x) || isNaN(p.totalY))) {
    return ''
  }
  
  const firstPoint = points[0]
  if (!firstPoint) return ''
  
  let path = `M ${firstPoint.x} ${firstPoint.totalY}`
  points.slice(1).forEach(point => {
    path += ` L ${point.x} ${point.totalY}`
  })
  
  return path
})

// 当前套餐名称
const currentPlanName = computed(() => {
  log('[Dashboard] subscription:', userStore.subscription)
  log('[Dashboard] hasActiveSubscription:', userStore.hasActiveSubscription)
  log('[Dashboard] expirationInfo:', userStore.expirationInfo)
  
  if (!userStore.subscription) {
    log('[Dashboard] 没有订阅数据')
    return '[未激活]'
  }
  
  // 尝试从subscription.plan获取
  if (userStore.subscription.plan && userStore.subscription.plan.name) {
    log('[Dashboard] 套餐名称:', userStore.subscription.plan.name)
    return `[${userStore.subscription.plan.name}]`
  }
  
  // 如果有订阅但没有plan信息
  if (userStore.hasActiveSubscription) {
    log('[Dashboard] 有激活的订阅')
    return '[已激活]'
  }
  
  log('[Dashboard] 订阅未激活')
  return '[未激活]'
})

// 更新时间
const updateTime = () => {
  const now = new Date()
  currentTime.value = now.toLocaleTimeString('en-US', { hour12: false })
}

const fetchNotices = async () => {
  try {
    log('[Dashboard] 正在获取公告列表...')
    const response = await noticeService.fetch()
    log('[Dashboard] 公告API完整响应:', response)
    
    // 后端返回格式: { data: [...], total: N }
    let noticeList: any[] = []
    
    if (response.data) {
      log('[Dashboard] response.data 的键:', Object.keys(response.data))
      log('[Dashboard] response.data.data 存在?', 'data' in response.data)
      log('[Dashboard] response.data.total:', (response.data as any).total)
      
      // 处理分页格式: { data: [...], total: N }
      if ('data' in response.data && Array.isArray((response.data as any).data)) {
        noticeList = (response.data as any).data
        log('[Dashboard] 使用 response.data.data (分页格式)')
      } 
      // 或直接是数组
      else if (Array.isArray(response.data)) {
        noticeList = response.data
        log('[Dashboard] 使用 response.data (数组格式)')
      }
      
      log('[Dashboard] 原始公告数量:', noticeList.length)
      log('[Dashboard] 原始公告数据:', noticeList)
      
      // 过滤显示的公告
      notices.value = noticeList.filter(notice => {
        if (!notice) return false
        log(`[Dashboard] 公告 ${notice.id}: show=${notice.show}, title=${notice.title}`)
        // show 字段为 true 或不存在时显示
        return notice.show !== false
      })
      
      log('[Dashboard] ✅ 最终显示公告数量:', notices.value.length)
      
      if (notices.value.length === 0 && noticeList.length === 0) {
        warn('[Dashboard] ⚠️ 后端数据库中没有公告数据，请在管理后台添加公告')
      }
    } else {
      logError('[Dashboard] ❌ response.data 为空')
      notices.value = []
    }
  } catch (err) {
    logError('[Dashboard] ❌ 获取公告失败:', err)
    notices.value = []
  }
}

const formatDate = (timestamp: number | string) => {
  try {
    // 如果是时间戳（数字），则乘以1000转换为毫秒
    const date = typeof timestamp === 'number' 
      ? new Date(timestamp * 1000) 
      : new Date(timestamp)
    
    return date.toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    })
  } catch (err) {
    logError('[Dashboard] 日期格式化错误:', err, timestamp)
    return String(timestamp)
  }
}

// 一键在客户端中打开订阅链接
const openInClient = (client: 'clash' | 'v2ray' | 'singbox' | 'shadowrocket' | 'surge' | 'quantumult') => {
  if (!subscribeUrl.value) {
    warn('[Dashboard] 订阅链接为空')
    return
  }

  const encodedUrl = encodeURIComponent(subscribeUrl.value)
  let schemeUrl = ''
  let clientName = ''

  switch (client) {
    case 'clash':
      schemeUrl = `clash://install-config?url=${encodedUrl}`
      clientName = 'Clash'
      break
      
    case 'v2ray':
      // V2rayNG (Android) 正确的格式
      schemeUrl = `v2rayng://install-sub?url=${encodedUrl}&name=Subscription`
      clientName = 'V2rayN/V2rayNG'
      break
      
    case 'singbox':
      schemeUrl = `sing-box://import-remote-profile?url=${encodedUrl}`
      clientName = 'Sing-Box'
      break
      
    case 'shadowrocket':
      schemeUrl = `shadowrocket://add/sub://${encodedUrl}?remark=Subscription`
      clientName = 'Shadowrocket'
      break
      
    case 'surge':
      schemeUrl = `surge:///install-config?url=${encodedUrl}`
      clientName = 'Surge'
      break
      
    case 'quantumult':
      schemeUrl = `quantumult-x:///add-server?server=${encodedUrl}`
      clientName = 'Quantumult X'
      break
  }

  log('[Dashboard] 尝试打开:', clientName)
  log('[Dashboard] URL Scheme:', schemeUrl)
  
  // 检测是否成功打开
  let appOpened = false
  
  // 使用 blur 事件检测是否成功切换到应用
  const blurHandler = () => {
    appOpened = true
    window.removeEventListener('blur', blurHandler)
  }
  window.addEventListener('blur', blurHandler)
  
  // 尝试打开
  window.location.href = schemeUrl
  
  // 1.5秒后检查是否成功
  setTimeout(() => {
    window.removeEventListener('blur', blurHandler)
    
    if (!appOpened) {
      // 未成功打开，提示用户
      const confirmCopy = confirm(`未检测到${clientName}客户端\n\n可能原因:\n1. 客户端未安装\n2. 客户端未运行\n3. 浏览器阻止了URL Scheme\n\n点击"确定"复制订阅链接，手动在客户端中添加。`)
      if (confirmCopy) {
        copy(subscribeUrl.value)
        log('[Dashboard] ✅ 订阅链接已复制')
      }
    } else {
      log('[Dashboard] ✅ 客户端已打开')
    }
  }, 1500)
}

// 复制通用订阅链接
const copyUrl = () => {
  if (subscribeUrl.value) {
    copy(subscribeUrl.value)
    urlCopied.value = true
    setTimeout(() => {
      urlCopied.value = false
    }, 2000)
  }
}

const selectAll = (event: Event) => {
  const target = event.target as HTMLInputElement
  target.select()
}

const handleImageError = (event: Event) => {
  const img = event.target as HTMLImageElement
  log('[Dashboard] 公告图片加载失败:', img.src)
  // 隐藏加载失败的图片
  img.style.display = 'none'
}

// 格式化字节数
const formatBytes = (bytes: number): string => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i]
}

// 获取流量明细
const fetchTrafficLogs = async () => {
  isLoadingTraffic.value = true
  try {
    log('[Dashboard] 正在获取流量明细...')
    const response = await statService.getTrafficLog()
    log('[Dashboard] 流量明细响应:', response)
    
    if (response.success && response.data) {
      let logData: any[] = []
      
      // 处理嵌套格式
      if (Array.isArray(response.data)) {
        logData = response.data
      } else if (typeof response.data === 'object' && response.data !== null) {
        const dataObj = response.data as any
        if (dataObj.data && Array.isArray(dataObj.data)) {
          logData = dataObj.data
        }
      }
      
      // 处理流量数据，取最近7天
      trafficLogs.value = logData.slice(0, 7).map((log: any) => {
        const upload = Number(log.u) || 0
        const download = Number(log.d) || 0
        const total = upload + download
        const usagePercent = userStore.trafficUsage.total > 0 
          ? Math.round((total / userStore.trafficUsage.total) * 100) 
          : 0
        
        let fullDate = ''
        let shortDate = ''
        
        try {
          fullDate = formatDate(log.record_at || log.created_at)
          // 从完整日期中提取短日期 (月/日)
          const dateParts = fullDate.split(' ')
          if (dateParts.length > 0) {
            const dateOnly = dateParts[0]
            if (dateOnly) {
              // 格式如 "2024-10-31" -> "10/31"
              const parts = dateOnly.split('-')
              if (parts.length >= 3) {
                shortDate = `${parts[1]}/${parts[2]}`
              } else {
                shortDate = dateOnly
              }
            } else {
              shortDate = fullDate || 'N/A'
            }
          } else {
            shortDate = fullDate || 'N/A'
          }
        } catch (err) {
          fullDate = String(log.record_at || log.created_at || 'N/A')
          shortDate = fullDate
        }
        
        return {
          date: fullDate,
          shortDate: shortDate, // 用于图表X轴标签
          upload: upload,
          download: download,
          total: total,
          uploadFormatted: formatBytes(upload),
          downloadFormatted: formatBytes(download),
          totalFormatted: formatBytes(total),
          usagePercent: Math.min(Math.max(usagePercent, 0), 100)
        }
      })
      
      log('[Dashboard] ✅ 流量明细加载成功，共', trafficLogs.value.length, '条记录')
      if (trafficLogs.value.length > 0) {
        log('[Dashboard] 第一条数据:', trafficLogs.value[0])
      }
    } else {
      warn('[Dashboard] ⚠️ 流量明细数据为空')
      trafficLogs.value = []
    }
  } catch (err) {
    logError('[Dashboard] ❌ 获取流量明细失败:', err)
    trafficLogs.value = []
  } finally {
    isLoadingTraffic.value = false
  }
}

// 获取站点配置
const fetchSiteConfig = async () => {
  try {
    log('[Dashboard] 正在获取站点配置...')
    const response = await configService.fetchGuest()
    
    if (response && response.data) {
      const { app_name, app_description } = response.data
      
      log('[Dashboard] 配置数据:', { app_name, app_description })
      
      if (app_name && typeof app_name === 'string' && app_name.trim() !== '') {
        siteName.value = app_name.trim()
        log('[Dashboard] ✅ 使用 app_name 作为站点名称:', siteName.value)
      } else if (app_description && typeof app_description === 'string' && app_description.trim() !== '') {
        siteName.value = app_description.trim()
        log('[Dashboard] ✅ 使用 app_description 作为站点名称:', siteName.value)
      } else {
        siteName.value = 'XBoard'
        log('[Dashboard] ✅ 使用默认站点名称:', siteName.value)
      }
    }
  } catch (err) {
    warn('[Dashboard] ⚠️ 获取站点配置失败，使用默认值')
  }
}

// 切换用户菜单
const toggleUserMenu = () => {
  showUserMenu.value = !showUserMenu.value
}

// 处理退出登录
const handleLogout = async () => {
  try {
    log('[Dashboard] 执行退出登录')
    
    // 清除认证状态
    authStore.logout()
    
    // 清除用户数据
    userStore.$reset()
    
    log('[Dashboard] ✅ 退出登录成功')
    
    // 跳转到登录页
    await router.push('/login')
  } catch (error) {
    logError('[Dashboard] ❌ 退出登录失败:', error)
  }
}

// 点击外部关闭菜单
const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (!target.closest('.user-menu')) {
    showUserMenu.value = false
  }
}

onMounted(async () => {
  updateTime()
  setInterval(updateTime, 1000)
  
  // 获取站点配置
  fetchSiteConfig()
  
  // 加载用户数据
  await userStore.refreshAll()
  fetchNotices()
  
  // 获取流量明细
  fetchTrafficLogs()
  
  // 监听点击外部关闭菜单
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  // 移除事件监听
  document.removeEventListener('click', handleClickOutside)
})
</script>

<style scoped>
.dashboard-page {
  padding: 2rem;
  font-family: var(--font-mono);
  color: var(--hacker-primary);
}

.notice-item {
  padding: 1rem 0;
  border-bottom: 1px solid var(--hacker-primary-dim);
}

.notice-item:last-child {
  border-bottom: none;
}

.notice-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}

.notice-title {
  color: var(--hacker-primary-bright);
  font-weight: bold;
}

.notice-date {
  margin-left: auto;
  font-size: 12px;
  color: var(--hacker-text-dim);
}

.notice-content {
  padding-left: 1.5rem;
  font-size: 12px;
  color: var(--hacker-text-dim);
  line-height: 1.6;
}

/* 公告HTML内容样式 */
.notice-content :deep(p) {
  margin: 0.5rem 0;
}

.notice-content :deep(ol),
.notice-content :deep(ul) {
  margin: 0.5rem 0;
  padding-left: 1.5rem;
  list-style: none;
}

.notice-content :deep(li) {
  margin: 0.25rem 0;
  color: var(--hacker-primary);
  position: relative;
}

.notice-content :deep(li)::before {
  content: '>';
  position: absolute;
  left: -1rem;
  color: var(--hacker-primary-bright);
}

.notice-content :deep(a) {
  color: var(--hacker-primary-bright);
  text-decoration: underline;
}

.notice-content :deep(strong) {
  color: var(--hacker-primary-bright);
  font-weight: bold;
}

/* 公告图片 */
.notice-image {
  margin: 1rem 0;
  padding: 0.5rem;
  border: 1px solid var(--hacker-primary-dim);
  background: rgba(0, 255, 0, 0.05);
  text-align: center;
  overflow: hidden;
}

.notice-image img {
  max-width: 400px; /* 限制最大宽度 */
  max-height: 250px; /* 限制最大高度 */
  width: auto;
  height: auto;
  border: 2px solid var(--hacker-primary);
  box-shadow: 0 0 10px var(--hacker-primary-dim);
  transition: all 0.3s ease;
  object-fit: contain; /* 保持图片比例 */
  cursor: pointer; /* 添加指针样式，暗示可点击 */
  background: transparent; /* 确保透明背景 */
}

.notice-image img:hover {
  border-color: var(--hacker-primary-bright);
  box-shadow: 0 0 20px var(--hacker-primary);
}

/* 移动端图片优化 */
@media (max-width: 640px) {
  .notice-image {
    padding: 0.25rem;
    margin: 0.5rem 0;
  }
  
  .notice-image img {
    max-width: 100%;
    max-height: 200px;
  }
}

/* 公告标签 */
.notice-tags {
  display: flex;
  gap: 0.5rem;
  margin-top: 0.5rem;
  flex-wrap: wrap;
}

.notice-tag {
  font-size: 11px;
  color: var(--hacker-primary);
  border: 1px solid var(--hacker-primary-dim);
  padding: 0.2rem 0.5rem;
  background: rgba(0, 255, 0, 0.1);
}

/* 订阅与流量概览 */
.subscription-overview {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
  padding: 1rem 0;
}

.overview-left,
.overview-right {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.plan-info {
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--hacker-primary-dim);
}

.plan-name {
  font-size: 24px;
  font-weight: bold;
  color: var(--hacker-primary-bright);
  text-shadow: var(--glow-md);
  margin-bottom: 0.5rem;
}

.plan-status {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 14px;
}

.status-active {
  color: var(--hacker-primary);
}

.status-inactive {
  color: var(--hacker-error);
}

.status-marker {
  font-size: 20px;
  animation: pulse 2s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.expiry-info,
.traffic-details {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 13px;
}

.info-label {
  color: var(--hacker-text-dim);
}

.info-value {
  color: var(--hacker-primary-bright);
  font-weight: bold;
}

.traffic-label {
  font-size: 14px;
  font-weight: bold;
  color: var(--hacker-primary);
  margin-bottom: 0.5rem;
}

/* 流量明细图表 */
.traffic-chart-container {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.chart-wrapper {
  width: 100%;
  overflow-x: auto;
}

.traffic-chart {
  width: 100%;
  height: auto;
  max-width: 100%;
}

.grid-line {
  stroke: var(--hacker-primary-dim);
  stroke-width: 1;
  stroke-dasharray: 2,2;
  opacity: 0.3;
}

.area-download {
  fill: rgba(0, 255, 100, 0.3);
  stroke: none;
}

.area-upload {
  fill: rgba(0, 200, 255, 0.3);
  stroke: none;
}

.line-total {
  fill: none;
  stroke: var(--hacker-primary-bright);
  stroke-width: 2;
  filter: drop-shadow(0 0 3px var(--hacker-primary));
}

.data-point {
  fill: var(--hacker-primary-bright);
  stroke: var(--hacker-primary);
  stroke-width: 2;
  filter: drop-shadow(0 0 5px var(--hacker-primary));
  transition: r 0.2s;
}

.data-point:hover {
  r: 6;
}

.axis-label {
  fill: var(--hacker-primary);
  font-size: 11px;
  font-family: var(--font-mono);
}

/* 图例 */
.chart-legend {
  display: flex;
  justify-content: center;
  gap: 2rem;
  padding: 1rem 0;
  border-top: 1px solid var(--hacker-primary-dim);
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 12px;
}

.legend-marker {
  width: 20px;
  height: 12px;
  border: 1px solid var(--hacker-primary-dim);
}

.legend-marker.upload {
  background: rgba(0, 200, 255, 0.5);
}

.legend-marker.download {
  background: rgba(0, 255, 100, 0.5);
}

.legend-marker.total {
  height: 2px;
  background: var(--hacker-primary-bright);
  box-shadow: 0 0 3px var(--hacker-primary);
}

.legend-label {
  color: var(--hacker-primary);
}

/* 详细数据（可折叠） */
.traffic-details {
  border-top: 1px solid var(--hacker-primary-dim);
  padding-top: 1rem;
}

.details-summary {
  color: var(--hacker-primary);
  cursor: pointer;
  user-select: none;
  padding: 0.5rem 0;
  font-size: 12px;
  transition: color 0.3s;
}

.details-summary:hover {
  color: var(--hacker-primary-bright);
  text-shadow: var(--glow-sm);
}

/* 流量明细表格 */
.traffic-table {
  font-size: 12px;
  margin-top: 1rem;
}

.traffic-table .table-header,
.traffic-table .table-row {
  display: grid;
  grid-template-columns: 1.5fr 1fr 1fr 1fr;
  gap: 1rem;
  padding: 0.75rem 0;
  border-bottom: 1px solid var(--hacker-primary-dim);
  align-items: center;
}

.traffic-table .table-header {
  color: var(--hacker-primary-bright);
  font-weight: bold;
  text-shadow: var(--glow-sm);
}

.traffic-table .table-row:hover {
  background: rgba(0, 255, 0, 0.05);
}

.loading-state {
  text-align: center;
  padding: 2rem 0;
  color: var(--hacker-text-dim);
  font-style: italic;
}

/* 响应式 */
@media (max-width: 768px) {
  .subscription-overview {
    grid-template-columns: 1fr;
    gap: 1rem;
  }
  
  .chart-legend {
    flex-wrap: wrap;
    gap: 1rem;
  }
  
  .traffic-table .table-header,
  .traffic-table .table-row {
    grid-template-columns: 1fr 1fr 1fr;
    font-size: 10px;
  }
  
  .traffic-table .table-header div:nth-child(4),
  .traffic-table .table-row div:nth-child(4) {
    display: none;
  }
}

.subscribe-description {
  margin-bottom: 1.5rem;
  padding: 1rem;
  background: rgba(0, 255, 0, 0.05);
  border: 1px solid var(--hacker-primary-dim);
  border-left: 3px solid var(--hacker-primary);
}

.hint-text {
  color: var(--hacker-primary);
  font-size: 12px;
  margin-left: 0.5rem;
}

.subscribe-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1.5rem;
  margin-bottom: 1.5rem;
}

@media (max-width: 1024px) {
  .subscribe-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 640px) {
  .subscribe-grid {
    grid-template-columns: 1fr;
  }
}

.subscribe-item {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  padding: 1rem;
  border: 1px solid var(--hacker-primary-dim);
  background: rgba(0, 255, 0, 0.03);
  transition: all 0.3s ease;
}

.subscribe-item:hover {
  border-color: var(--hacker-primary);
  background: rgba(0, 255, 0, 0.08);
  box-shadow: var(--glow-sm);
}

.client-info {
  flex: 1;
}

.client-name {
  font-weight: bold;
  color: var(--hacker-primary-bright);
  font-size: 13px;
  margin-bottom: 0.25rem;
}

.client-hint {
  font-size: 11px;
  color: var(--hacker-text-dim);
  font-style: italic;
}

/* 手动订阅 */
.manual-subscribe {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--hacker-primary-dim);
}

.subscribe-url {
  margin-top: 1rem;
}

.url-row {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.url-label {
  color: var(--hacker-primary);
  font-size: 12px;
  white-space: nowrap;
}

.url-row .hacker-input {
  background: transparent;
  border: 1px solid var(--hacker-primary-dim);
  color: var(--hacker-primary);
  font-family: var(--font-mono);
  flex: 1;
  padding: 0.5rem;
  font-size: 12px;
  outline: none;
  cursor: pointer;
  transition: all 0.3s;
}

.url-row .hacker-input:hover,
.url-row .hacker-input:focus {
  border-color: var(--hacker-primary);
  background: rgba(0, 255, 0, 0.05);
}

.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--hacker-primary);
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 2rem;
}

.header-time {
  font-size: 12px;
  color: var(--hacker-text-dim);
}

/* 用户菜单 */
.user-menu {
  position: relative;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: rgba(0, 255, 65, 0.05);
  border: 1px solid var(--hacker-primary-dim);
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.3s ease;
  user-select: none;
}

.user-menu:hover {
  background: rgba(0, 255, 65, 0.1);
  border-color: var(--hacker-primary);
  box-shadow: 0 0 10px rgba(0, 255, 65, 0.3);
}

.user-icon {
  font-size: 1.2rem;
  color: var(--hacker-primary);
}

.user-email {
  font-size: 0.9rem;
  color: var(--hacker-primary);
  font-family: var(--font-mono);
}

.menu-arrow {
  font-size: 1rem;
  color: var(--hacker-primary);
  transition: transform 0.3s ease;
}

.menu-arrow.menu-open {
  transform: rotate(180deg);
}

/* 下拉菜单 */
.user-dropdown {
  position: absolute;
  top: calc(100% + 0.5rem);
  right: 0;
  min-width: 200px;
  background: rgba(0, 0, 0, 0.95);
  border: 1px solid var(--hacker-primary);
  border-radius: 4px;
  box-shadow: 0 4px 20px rgba(0, 255, 65, 0.3);
  z-index: 1000;
  overflow: hidden;
}

.menu-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  color: var(--hacker-primary);
  font-family: var(--font-mono);
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.2s ease;
  border-bottom: 1px solid rgba(0, 255, 65, 0.1);
}

.menu-item:last-child {
  border-bottom: none;
}

.menu-item:hover {
  background: rgba(0, 255, 65, 0.1);
  padding-left: 1.25rem;
}

.menu-item svg {
  font-size: 1.1rem;
}

/* 菜单过渡动画 */
.menu-fade-enter-active,
.menu-fade-leave-active {
  transition: all 0.3s ease;
}

.menu-fade-enter-from {
  opacity: 0;
  transform: translateY(-10px);
}

.menu-fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

.dashboard-section {
  margin-bottom: 3rem;
}

.section-title {
  font-size: 16px;
  font-weight: bold;
  color: var(--hacker-primary-bright);
  text-transform: uppercase;
  letter-spacing: 2px;
  margin-bottom: 1rem;
  text-shadow: var(--glow-sm);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  align-items: stretch; /* 确保所有卡片高度一致 */
}

.stats-grid > * {
  display: flex;
  flex-direction: column;
}

/* 确保卡片内容有合理的布局 */
.stats-grid :deep(.card-body-content) {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  min-height: 150px; /* 设置最小高度确保一致性 */
}

.stat-value {
  font-size: 24px;
  font-weight: bold;
  color: var(--hacker-primary-bright);
  margin: 1rem 0;
  text-shadow: var(--glow-md);
  flex-shrink: 0; /* 防止标题被压缩 */
}

.stat-detail {
  margin: 0.5rem 0;
  font-size: 12px;
  color: var(--hacker-text-dim);
  line-height: 1.5;
}

.no-data {
  text-align: center;
  padding: 2rem;
  color: var(--hacker-text-dim);
  opacity: 0.5;
}

/* ============================================
   移动端适配
============================================ */
@media (max-width: 1023px) {
  .dashboard-page {
    padding: 1rem;
  }
  
  .dashboard-header {
    flex-direction: column;
    gap: 1rem;
    align-items: flex-start;
  }
  
  .header-actions {
    flex-direction: column;
    gap: 0.5rem;
    width: 100%;
  }
  
  .user-menu {
    width: 100%;
    justify-content: space-between;
  }
  
  .user-dropdown {
    left: 0;
    right: 0;
  }
  
  .stats-grid {
    grid-template-columns: 1fr;
    gap: 1rem;
  }
  
  .stat-item {
    padding: 1rem;
  }
  
  .traffic-chart-container {
    height: 200px;
  }
  
  .notice-header {
    flex-wrap: wrap;
  }
  
  .notice-date {
    margin-left: 0;
    width: 100%;
  }
}

/* 小屏手机适配 */
@media (max-width: 640px) {
  .dashboard-page {
    padding: 0.5rem;
  }
  
  .section-title {
    font-size: 14px;
  }
  
  .stat-value {
    font-size: 20px;
  }
  
  .stat-label {
    font-size: 10px;
  }
  
  .user-email {
    display: none;
  }
  
  .traffic-chart-container {
    height: 150px;
  }
}
</style>
