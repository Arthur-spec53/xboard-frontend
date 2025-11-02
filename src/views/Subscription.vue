<template>
  <div class="subscription-container">
    <TerminalPrompt command="subscription --info" />
    
    <!-- 加载状态 -->
    <div v-if="loading" class="loading-state">
      <div class="loading-spinner"></div>
      <p>正在获取订阅信息...</p>
    </div>
    
    <!-- 错误状态 -->
    <div v-else-if="error" class="error-state">
      <div class="error-icon">⚠️</div>
      <p>{{ error }}</p>
      <button @click="fetchData" class="retry-btn">重试</button>
    </div>
    
    <!-- 订阅信息 -->
    <div v-else-if="subscription" class="subscription-content">
      
      <!-- 订阅链接 -->
      <GeekCard title="订阅地址" class="subscribe-url-card">
        <div class="url-section">
          <p class="help-text">
            复制下方链接到 Clash、V2Ray 等客户端使用
          </p>
          
          <div class="url-box">
            <input 
              ref="urlInput"
              type="text" 
              :value="subscription.subscribe_url" 
              readonly 
              class="url-input"
              @focus="$event.target.select()"
            />
            <button @click="copyUrl" class="copy-btn" :class="{ copied: isCopied }">
              <span v-if="!isCopied">📋 复制</span>
              <span v-else>✅ 已复制</span>
            </button>
          </div>
          
          <div class="url-actions">
            <button @click="openUrl" class="action-btn">
              🔗 在浏览器中打开
            </button>
            <button @click="showQRCode" class="action-btn">
              📱 显示二维码
            </button>
          </div>
        </div>
      </GeekCard>
      
      <!-- 流量信息 -->
      <GeekCard title="流量统计" class="traffic-card">
        <div class="traffic-info">
          <div class="traffic-progress">
            <div class="progress-bar">
              <div 
                class="progress-fill" 
                :style="{ width: usagePercentage + '%' }"
              ></div>
            </div>
            <p class="progress-text">
              已使用 {{ formatBytes(usedTraffic) }} / 总计 {{ formatBytes(subscription.transfer_enable) }}
              <span class="percentage">({{ usagePercentage }}%)</span>
            </p>
          </div>
          
          <div class="traffic-details">
            <div class="detail-item">
              <span class="label">⬆️ 上传:</span>
              <span class="value">{{ formatBytes(subscription.u) }}</span>
            </div>
            <div class="detail-item">
              <span class="label">⬇️ 下载:</span>
              <span class="value">{{ formatBytes(subscription.d) }}</span>
            </div>
            <div class="detail-item" v-if="subscription.next_reset_at">
              <span class="label">🔄 重置时间:</span>
              <span class="value">{{ formatDate(subscription.next_reset_at) }}</span>
            </div>
          </div>
        </div>
      </GeekCard>
      
      <!-- 订阅详情 -->
      <GeekCard title="订阅详情" class="details-card">
        <div class="details-grid">
          <div class="detail-row">
            <span class="detail-label">📅 到期时间:</span>
            <span class="detail-value" :class="{ expired: isExpired }">
              {{ formatDate(subscription.expired_at) }}
              <span v-if="isExpired" class="expired-tag">已过期</span>
              <span v-else-if="daysRemaining <= 7" class="warning-tag">剩余 {{ daysRemaining }} 天</span>
            </span>
          </div>
          
          <div class="detail-row" v-if="subscription.plan">
            <span class="detail-label">📦 套餐名称:</span>
            <span class="detail-value">{{ subscription.plan.name }}</span>
          </div>
          
          <div class="detail-row" v-if="subscription.device_limit">
            <span class="detail-label">📱 设备限制:</span>
            <span class="detail-value">{{ subscription.device_limit }} 台</span>
          </div>
          
          <div class="detail-row" v-if="subscription.speed_limit">
            <span class="detail-label">⚡ 速度限制:</span>
            <span class="detail-value">{{ formatSpeed(subscription.speed_limit) }}</span>
          </div>
          
          <div class="detail-row">
            <span class="detail-label">🔑 UUID:</span>
            <span class="detail-value mono">{{ subscription.uuid }}</span>
          </div>
        </div>
      </GeekCard>
      
      <!-- 使用说明 -->
      <GeekCard title="使用指南" class="guide-card">
        <div class="guide-content">
          <h3>📱 客户端推荐</h3>
          <div class="client-list">
            <div class="client-item">
              <strong>Windows:</strong> Clash for Windows, V2RayN
            </div>
            <div class="client-item">
              <strong>macOS:</strong> ClashX, V2RayX
            </div>
            <div class="client-item">
              <strong>Android:</strong> Clash for Android, V2RayNG
            </div>
            <div class="client-item">
              <strong>iOS:</strong> Shadowrocket, Quantumult X
            </div>
          </div>
          
          <h3 class="mt-4">📖 导入步骤</h3>
          <ol class="guide-steps">
            <li>复制上方的订阅地址</li>
            <li>打开客户端，找到"订阅"或"配置"选项</li>
            <li>选择"从URL导入"或"添加订阅"</li>
            <li>粘贴订阅地址并保存</li>
            <li>更新订阅后即可使用</li>
          </ol>
          
          <div class="warning-box">
            ⚠️ 请勿将订阅地址分享给他人，以免造成流量盗用
          </div>
        </div>
      </GeekCard>
      
    </div>
    
    <!-- 无订阅状态 -->
    <div v-else class="no-subscription">
      <div class="empty-icon">📭</div>
      <p>您当前没有激活的订阅</p>
      <router-link to="/plans" class="purchase-btn">前往购买套餐</router-link>
    </div>
    
    <!-- 二维码弹窗 -->
    <div v-if="showQR" class="qr-modal" @click.self="showQR = false">
      <div class="qr-content">
        <button @click="showQR = false" class="close-btn">✕</button>
        <h3>订阅二维码</h3>
        <div id="qrcode" class="qr-code"></div>
        <p class="qr-hint">使用手机客户端扫描此二维码</p>
      </div>
    </div>
    
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useUserStore } from '@/stores/user'
import TerminalPrompt from '@/components/effects/TerminalPrompt.vue'
import GeekCard from '@/components/common/GeekCard.vue'

const userStore = useUserStore()

const loading = ref(false)
const error = ref('')
const isCopied = ref(false)
const showQR = ref(false)
const urlInput = ref<HTMLInputElement>()

const subscription = computed(() => userStore.subscription)

// 已使用流量
const usedTraffic = computed(() => {
  if (!subscription.value) return 0
  return subscription.value.u + subscription.value.d
})

// 使用百分比
const usagePercentage = computed(() => {
  if (!subscription.value || subscription.value.transfer_enable === 0) return 0
  return Math.min(Math.round((usedTraffic.value / subscription.value.transfer_enable) * 100), 100)
})

// 是否过期
const isExpired = computed(() => {
  if (!subscription.value) return false
  return Date.now() > subscription.value.expired_at * 1000
})

// 剩余天数
const daysRemaining = computed(() => {
  if (!subscription.value) return 0
  const diff = subscription.value.expired_at * 1000 - Date.now()
  return Math.ceil(diff / (1000 * 60 * 60 * 24))
})

// 格式化字节
const formatBytes = (bytes: number): string => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i]
}

// 格式化速度
const formatSpeed = (bytesPerSecond: number): string => {
  return formatBytes(bytesPerSecond) + '/s'
}

// 格式化日期
const formatDate = (timestamp: number): string => {
  const date = new Date(timestamp * 1000)
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// 复制订阅地址
const copyUrl = async () => {
  if (!subscription.value) return
  
  try {
    await navigator.clipboard.writeText(subscription.value.subscribe_url)
    isCopied.value = true
    setTimeout(() => {
      isCopied.value = false
    }, 2000)
  } catch (err) {
    // 降级方案
    urlInput.value?.select()
    document.execCommand('copy')
    isCopied.value = true
    setTimeout(() => {
      isCopied.value = false
    }, 2000)
  }
}

// 在浏览器中打开
const openUrl = () => {
  if (!subscription.value) return
  window.open(subscription.value.subscribe_url, '_blank')
}

// 显示二维码
const showQRCode = async () => {
  if (!subscription.value) return
  
  showQR.value = true
  
  // 等待 DOM 更新
  await new Promise(resolve => setTimeout(resolve, 100))
  
  // 动态加载 QRCode 库
  if (typeof (window as any).QRCode === 'undefined') {
    const script = document.createElement('script')
    script.src = 'https://cdn.jsdelivr.net/npm/qrcodejs@1.0.0/qrcode.min.js'
    script.onload = () => generateQR()
    document.head.appendChild(script)
  } else {
    generateQR()
  }
}

// 生成二维码
const generateQR = () => {
  const qrContainer = document.getElementById('qrcode')
  if (!qrContainer || !subscription.value) return
  
  qrContainer.innerHTML = ''
  
  new (window as any).QRCode(qrContainer, {
    text: subscription.value.subscribe_url,
    width: 256,
    height: 256,
    colorDark: '#00ff41',
    colorLight: '#000000',
    correctLevel: (window as any).QRCode.CorrectLevel.H
  })
}

// 获取数据
const fetchData = async () => {
  loading.value = true
  error.value = ''
  
  try {
    await userStore.fetchSubscription()
    
    if (!subscription.value) {
      error.value = '未获取到订阅信息'
    }
  } catch (err: any) {
    error.value = err.message || '获取订阅信息失败，请稍后重试'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  // 如果 store 中没有订阅信息，则获取
  if (!subscription.value) {
    fetchData()
  }
})
</script>

<style scoped>
.subscription-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

/* 加载和错误状态 */
.loading-state,
.error-state,
.no-subscription {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 400px;
  text-align: center;
}

.loading-spinner {
  width: 50px;
  height: 50px;
  border: 3px solid rgba(0, 255, 65, 0.1);
  border-top-color: var(--hacker-primary);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.error-icon,
.empty-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.retry-btn,
.purchase-btn {
  margin-top: 1rem;
  padding: 0.75rem 2rem;
  background: var(--hacker-primary);
  color: #000;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: bold;
  text-decoration: none;
  display: inline-block;
  transition: all 0.3s;
}

.retry-btn:hover,
.purchase-btn:hover {
  background: var(--hacker-secondary);
  box-shadow: 0 0 20px rgba(0, 255, 65, 0.5);
}

/* 订阅内容 */
.subscription-content {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

/* 订阅链接卡片 */
.subscribe-url-card {
  background: linear-gradient(135deg, rgba(0, 255, 65, 0.05), rgba(0, 150, 255, 0.05));
}

.url-section .help-text {
  color: var(--hacker-secondary);
  margin-bottom: 1rem;
  font-size: 0.9rem;
}

.url-box {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.url-input {
  flex: 1;
  padding: 0.75rem;
  background: rgba(0, 255, 65, 0.05);
  border: 1px solid var(--hacker-primary);
  border-radius: 4px;
  color: var(--hacker-primary);
  font-family: 'Courier New', monospace;
  font-size: 0.85rem;
  outline: none;
}

.url-input:focus {
  box-shadow: 0 0 10px rgba(0, 255, 65, 0.3);
}

.copy-btn {
  padding: 0.75rem 1.5rem;
  background: var(--hacker-primary);
  color: #000;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.3s;
  white-space: nowrap;
}

.copy-btn:hover {
  background: var(--hacker-secondary);
  box-shadow: 0 0 15px rgba(0, 255, 65, 0.5);
}

.copy-btn.copied {
  background: #00ff88;
}

.url-actions {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.action-btn {
  padding: 0.5rem 1rem;
  background: rgba(0, 255, 65, 0.1);
  border: 1px solid var(--hacker-primary);
  border-radius: 4px;
  color: var(--hacker-primary);
  cursor: pointer;
  font-size: 0.9rem;
  transition: all 0.3s;
}

.action-btn:hover {
  background: rgba(0, 255, 65, 0.2);
  box-shadow: 0 0 10px rgba(0, 255, 65, 0.3);
}

/* 流量信息 */
.traffic-info {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.progress-bar {
  width: 100%;
  height: 24px;
  background: rgba(0, 255, 65, 0.1);
  border: 1px solid var(--hacker-primary);
  border-radius: 12px;
  overflow: hidden;
  position: relative;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--hacker-primary), var(--hacker-secondary));
  transition: width 0.5s ease;
  position: relative;
  overflow: hidden;
}

.progress-fill::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.3), transparent);
  animation: shimmer 2s infinite;
}

@keyframes shimmer {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}

.progress-text {
  margin-top: 0.5rem;
  color: var(--hacker-primary);
  font-family: 'Courier New', monospace;
}

.percentage {
  color: var(--hacker-secondary);
  font-weight: bold;
}

.traffic-details {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}

.detail-item {
  display: flex;
  justify-content: space-between;
  padding: 0.75rem;
  background: rgba(0, 255, 65, 0.05);
  border: 1px solid rgba(0, 255, 65, 0.2);
  border-radius: 4px;
}

.detail-item .label {
  color: var(--hacker-secondary);
}

.detail-item .value {
  color: var(--hacker-primary);
  font-family: 'Courier New', monospace;
  font-weight: bold;
}

/* 订阅详情 */
.details-grid {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem;
  background: rgba(0, 255, 65, 0.05);
  border-left: 3px solid var(--hacker-primary);
  border-radius: 4px;
}

.detail-label {
  color: var(--hacker-secondary);
  font-weight: 500;
}

.detail-value {
  color: var(--hacker-primary);
  font-family: 'Courier New', monospace;
}

.detail-value.mono {
  font-size: 0.85rem;
  word-break: break-all;
}

.detail-value.expired {
  color: #ff4444;
}

.expired-tag,
.warning-tag {
  display: inline-block;
  margin-left: 0.5rem;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: bold;
}

.expired-tag {
  background: #ff4444;
  color: #000;
}

.warning-tag {
  background: #ffaa00;
  color: #000;
}

/* 使用指南 */
.guide-content h3 {
  color: var(--hacker-primary);
  font-size: 1.1rem;
  margin-bottom: 1rem;
}

.client-list,
.guide-steps {
  margin-bottom: 1.5rem;
}

.client-item {
  padding: 0.5rem 0;
  color: #aaa;
  border-bottom: 1px solid rgba(0, 255, 65, 0.1);
}

.client-item strong {
  color: var(--hacker-primary);
  margin-right: 0.5rem;
}

.guide-steps {
  padding-left: 1.5rem;
  color: #aaa;
  line-height: 2;
}

.guide-steps li {
  margin-bottom: 0.5rem;
}

.warning-box {
  padding: 1rem;
  background: rgba(255, 170, 0, 0.1);
  border: 1px solid #ffaa00;
  border-radius: 4px;
  color: #ffaa00;
  font-weight: 500;
}

/* 二维码弹窗 */
.qr-modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.9);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  animation: fadeIn 0.3s;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.qr-content {
  position: relative;
  padding: 2rem;
  background: #111;
  border: 2px solid var(--hacker-primary);
  border-radius: 8px;
  text-align: center;
  box-shadow: 0 0 50px rgba(0, 255, 65, 0.5);
}

.close-btn {
  position: absolute;
  top: 1rem;
  right: 1rem;
  width: 32px;
  height: 32px;
  background: rgba(255, 0, 0, 0.2);
  border: 1px solid #ff4444;
  border-radius: 50%;
  color: #ff4444;
  font-size: 1.2rem;
  cursor: pointer;
  transition: all 0.3s;
}

.close-btn:hover {
  background: #ff4444;
  color: #000;
}

.qr-content h3 {
  color: var(--hacker-primary);
  margin-bottom: 1rem;
}

.qr-code {
  display: inline-block;
  padding: 1rem;
  background: #000;
  border: 2px solid var(--hacker-primary);
  border-radius: 8px;
}

.qr-hint {
  margin-top: 1rem;
  color: var(--hacker-secondary);
  font-size: 0.9rem;
}

/* 移动端适配 */
@media (max-width: 768px) {
  .subscription-container {
    padding: 1rem;
  }
  
  .url-box {
    flex-direction: column;
  }
  
  .copy-btn {
    width: 100%;
  }
  
  .traffic-details {
    grid-template-columns: 1fr;
  }
  
  .detail-row {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
}
</style>
