<template>
  <div class="login-page">
    <!-- Matrix 背景 -->
    <MatrixRain />
    
    <!-- 扫描线效果 -->
    <ScanLines />
    
    <!-- 登录容器 -->
    <div class="login-container">
      <!-- 系统启动动画 -->
      <div v-if="showBootSequence" class="boot-sequence">
        <TypingText 
          text="初始化安全系统..." 
          :speed="30"
          @complete="bootStep1Complete"
        />
        <div v-if="bootStep >= 1" class="boot-line">
          <TypingText 
            text="> 加载认证模块... [完成]" 
            :speed="20"
            @complete="bootStep2Complete"
          />
        </div>
        <div v-if="bootStep >= 2" class="boot-line">
          <TypingText 
            text="> 建立安全连接... [完成]" 
            :speed="20"
            @complete="bootStep3Complete"
          />
        </div>
        <div v-if="bootStep >= 3" class="boot-line">
          <TypingText 
            text="> 准备就绪" 
            :speed="20"
            @complete="showLoginForm"
          />
        </div>
      </div>
      
      <!-- 登录表单 -->
      <div v-if="!showBootSequence" class="login-form">
        <!-- 标题 -->
        <div class="login-header">
          <pre class="ascii-logo">
  ██████╗ ██╗    ██╗  ██╗██╗   ██╗
 ██╔═══██╗██║    ██║ ██╔╝██║   ██║
 ██║   ██║██║    █████╔╝ ██║   ██║
 ██║▄▄ ██║██║    ██╔═██╗ ██║   ██║
 ╚██████╔╝██║    ██║  ██╗╚██████╔╝
  ╚══▀▀═╝ ╚═╝    ╚═╝  ╚═╝ ╚═════╝ 
  安全访问终端
          </pre>
          <TerminalPrompt user="guest" :host="siteName" symbol="#" />
        </div>
        
        <!-- 输入区域 -->
        <div class="login-inputs">
          <GeekInput
            v-model="email"
            label="邮箱地址"
            placeholder="输入您的邮箱..."
            prefix=">"
            :error="emailError"
          />
          
          <GeekInput
            v-model="password"
            type="password"
            label="密码"
            placeholder="输入您的密码..."
            prefix=">"
            :error="passwordError"
          />
        </div>
        
        <!-- 错误信息 -->
        <div v-if="loginError" class="login-error">
          <div class="error-line">[!] 认证失败</div>
          <div class="error-line">[!] {{ loginError }}</div>
          <div class="error-line">[!] 重试连接? [Y/N]</div>
        </div>
        
        <!-- 按钮组 -->
        <div class="login-actions">
          <GeekButton
            :loading="isLoading"
            :disabled="!canSubmit"
            @click="handleLogin"
            size="lg"
          >
            {{ isLoading ? '认证中' : '执行登录' }}
          </GeekButton>
        </div>
        
        <!-- 底部链接 -->
        <div class="login-footer">
          <div class="footer-line">
            <span class="terminal-prompt"></span>
            <router-link to="/register" class="login-link">创建新账户</router-link>
          </div>
          <div class="footer-line">
            <span class="terminal-prompt"></span>
            <router-link to="/forgot-password" class="login-link">恢复访问权限</router-link>
          </div>
        </div>
        
        <!-- 系统信息 -->
        <div class="system-info">
          <div class="info-line">[系统] 安全等级: 最高</div>
          <div class="info-line">[系统] 加密方式: AES-256</div>
          <div class="info-line">[系统] 状态: 运行中</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { configService } from '@/api'
import { log, warn, logError } from '@/utils/logger'
import MatrixRain from '@/components/effects/MatrixRain.vue'
import ScanLines from '@/components/effects/ScanLines.vue'
import TypingText from '@/components/effects/TypingText.vue'
import TerminalPrompt from '@/components/effects/TerminalPrompt.vue'
import GeekInput from '@/components/common/GeekInput.vue'
import GeekButton from '@/components/common/GeekButton.vue'

const router = useRouter()
const authStore = useAuthStore()

// 站点名称，优先使用后端配置，仅在未加载时使用通用占位
const siteName = ref('XBoard')

// 启动序列
const showBootSequence = ref(true)
const bootStep = ref(0)

const bootStep1Complete = () => { bootStep.value = 1 }
const bootStep2Complete = () => { bootStep.value = 2 }
const bootStep3Complete = () => { bootStep.value = 3 }
const showLoginForm = () => {
  setTimeout(() => {
    showBootSequence.value = false
  }, 500)
}

// 表单数据
const email = ref('')
const password = ref('')
const emailError = ref('')
const passwordError = ref('')
const loginError = ref('')
const isLoading = ref(false)

// 获取站点配置
const fetchSiteConfig = async () => {
  try {
    const response = await configService.fetchGuest()
    if (response && response.data) {
      const { app_name, app_description } = response.data
      // 从配置中获取站点名称：优先名称，其次描述，最后通用默认值
      siteName.value =
        (typeof app_name === 'string' && app_name.trim() !== '' ? app_name.trim() : undefined) ||
        (typeof app_description === 'string' && app_description.trim() !== '' ? app_description.trim() : undefined) ||
        'XBoard'
      log('[Login] ✅ 站点名称已加载:', siteName.value)
    }
  } catch (err) {
    // 配置加载失败不影响登录功能，静默使用默认值
    warn('[Login] 配置加载失败，使用默认站点名称')
  }
}

// 验证
const canSubmit = computed(() => {
  return email.value.length > 0 && password.value.length > 0
})

// 登录处理
const handleLogin = async () => {
  emailError.value = ''
  passwordError.value = ''
  loginError.value = ''
  
  // 简单验证
  if (!email.value.includes('@')) {
    emailError.value = '邮箱格式无效'
    return
  }
  
  if (password.value.length < 8) {
    passwordError.value = '密码至少需要8个字符'
    return
  }
  
  isLoading.value = true
  
  try {
    const success = await authStore.login({
      email: email.value,
      password: password.value
    })
    
    if (success) {
      // 登录成功，跳转到 Dashboard
      log('✅ 登录成功 - 跳转到仪表盘...')
      await router.push('/dashboard')
    } else {
      // 登录失败，显示错误信息
      loginError.value = authStore.error || '认证失败'
    }
  } catch (err: any) {
    // 捕获网络错误等异常
    logError('❌ 登录错误:', err)
    loginError.value = err.message || '连接错误'
  } finally {
    isLoading.value = false
  }
}

// 组件挂载时获取站点配置
onMounted(() => {
  fetchSiteConfig()
})
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--hacker-bg);
  padding: 2rem;
  position: relative;
}

.login-container {
  width: 100%;
  max-width: 600px;
  z-index: 10;
}

/* 启动序列 */
.boot-sequence {
  font-family: var(--font-mono);
  color: var(--hacker-primary);
  font-size: 14px;
  line-height: 2;
}

.boot-line {
  margin-top: 0.5rem;
}

/* 登录表单 */
.login-form {
  border: 1px solid var(--hacker-primary);
  padding: 2rem;
  background: rgba(0, 0, 0, 0.8);
  box-shadow: var(--glow-md);
}

.login-header {
  margin-bottom: 2rem;
  text-align: center;
}

.ascii-logo {
  color: var(--hacker-primary-bright);
  font-size: 12px;
  line-height: 1.2;
  text-shadow: var(--glow-md);
  margin-bottom: 1rem;
  white-space: pre;
}

.login-inputs {
  margin: 2rem 0;
}

.login-error {
  margin: 1rem 0;
  padding: 1rem;
  border: 1px solid var(--hacker-error);
  background: rgba(255, 0, 0, 0.1);
  font-family: var(--font-mono);
  color: var(--hacker-error);
  font-size: 12px;
}

.error-line {
  margin: 0.25rem 0;
}

.login-actions {
  margin: 2rem 0;
}

.login-actions button {
  width: 100%;
}

.login-footer {
  margin-top: 2rem;
  padding-top: 1rem;
  border-top: 1px solid var(--hacker-primary-dim);
}

.footer-line {
  margin: 0.5rem 0;
  font-family: var(--font-mono);
  font-size: 12px;
}

.login-link {
  color: var(--hacker-primary);
  text-decoration: none;
  text-transform: uppercase;
  transition: all 0.3s ease;
}

.login-link:hover {
  color: var(--hacker-primary-bright);
  text-shadow: var(--glow-sm);
}

.system-info {
  margin-top: 2rem;
  padding-top: 1rem;
  border-top: 1px solid var(--hacker-primary-dim);
  font-family: var(--font-mono);
  font-size: 10px;
  color: var(--hacker-text-dim);
  opacity: 0.7;
}

.info-line {
  margin: 0.25rem 0;
}

/* 响应式 */
@media (max-width: 768px) {
  .login-page {
    padding: 1rem;
  }
  
  .login-form {
    padding: 1.5rem;
  }
  
  .ascii-logo {
    font-size: 10px;
  }
}
</style>
