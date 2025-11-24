<template>
  <div class="forgot-password-page">
    <!-- Matrix 背景 -->
    <MatrixRain />
    
    <!-- 扫描线效果 -->
    <ScanLines />
    
    <!-- 找回密码容器 -->
    <div class="forgot-password-container">
      <!-- 找回密码表单 -->
      <div class="forgot-password-form">
        <!-- 标题 -->
        <div class="forgot-password-header">
          <pre class="ascii-logo">
  ██████╗ ██╗    ██╗  ██╗██╗   ██╗
 ██╔═══██╗██║    ██║ ██╔╝██║   ██║
 ██║   ██║██║    █████╔╝ ██║   ██║
 ██║▄▄ ██║██║    ██╔═██╗ ██║   ██║
 ╚██████╔╝██║    ██║  ██╗╚██████╔╝
  ╚══▀▀═╝ ╚═╝    ╚═╝  ╚═╝ ╚═════╝ 
  恢复访问权限
          </pre>
          <TerminalPrompt user="guest" :host="siteName" symbol="#" />
        </div>
        
        <!-- 输入区域 -->
        <div class="forgot-password-inputs">
          <GeekInput
            v-model="email"
            label="邮箱地址"
            placeholder="输入您的邮箱..."
            prefix=">"
            :error="emailError"
          />
          
          <GeekInput
            v-model="emailCode"
            label="邮箱验证码"
            placeholder="输入验证码..."
            prefix=">"
            :error="emailCodeError"
          >
            <template #suffix>
              <GeekButton 
                @click="handleSendEmailCode" 
                :disabled="emailCodeSending || emailCodeCountdown > 0"
                size="sm"
              >
                {{ emailCodeCountdown > 0 ? `${emailCodeCountdown}秒` : '发送验证码' }}
              </GeekButton>
            </template>
          </GeekInput>
          
          <GeekInput
            v-model="password"
            type="password"
            label="新密码"
            placeholder="输入新密码 (至少8个字符)..."
            prefix=">"
            :error="passwordError"
          />
          
          <GeekInput
            v-model="passwordConfirm"
            type="password"
            label="确认新密码"
            placeholder="再次输入新密码..."
            prefix=">"
            :error="passwordConfirmError"
          />
        </div>
        
        <!-- 错误信息 -->
        <div v-if="resetError" class="reset-error">
          <div class="error-line">[!] 重置失败</div>
          <div class="error-line">[!] {{ resetError }}</div>
        </div>
        
        <!-- 成功信息 -->
        <div v-if="resetSuccess" class="reset-success">
          <div class="success-line">[✓] 密码重置成功</div>
          <div class="success-line">[✓] 正在跳转到登录页面...</div>
        </div>
        
        <!-- 按钮组 -->
        <div class="reset-actions">
          <GeekButton
            :loading="isLoading"
            :disabled="!canSubmit"
            @click="handleResetPassword"
            size="lg"
          >
            {{ isLoading ? '重置中' : '重置密码' }}
          </GeekButton>
        </div>
        
        <!-- 底部链接 -->
        <div class="reset-footer">
          <div class="footer-line">
            <span class="terminal-prompt"></span>
            <router-link to="/login" class="reset-link">返回登录</router-link>
          </div>
          <div class="footer-line">
            <span class="terminal-prompt"></span>
            <router-link to="/register" class="reset-link">创建新账户</router-link>
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
import { authService, configService } from '@/api'
import MatrixRain from '@/components/effects/MatrixRain.vue'
import ScanLines from '@/components/effects/ScanLines.vue'
import TerminalPrompt from '@/components/effects/TerminalPrompt.vue'
import GeekInput from '@/components/common/GeekInput.vue'
import GeekButton from '@/components/common/GeekButton.vue'

const router = useRouter()

// 站点名称，优先来自后端配置
const siteName = ref('XBoard')

// 表单数据
const email = ref('')
const emailCode = ref('')
const password = ref('')
const passwordConfirm = ref('')

// 错误信息
const emailError = ref('')
const emailCodeError = ref('')
const passwordError = ref('')
const passwordConfirmError = ref('')
const resetError = ref('')
const resetSuccess = ref(false)

// 邮箱验证码
const emailCodeSending = ref(false)
const emailCodeCountdown = ref(0)

const isLoading = ref(false)

// 获取系统配置
const fetchConfig = async () => {
  try {
    const response = await configService.fetchGuest()
    if (response.success && response.data) {
      const { app_name, app_description } = response.data
      siteName.value =
        (typeof app_name === 'string' && app_name.trim() !== '' ? app_name.trim() : undefined) ||
        (typeof app_description === 'string' && app_description.trim() !== '' ? app_description.trim() : undefined) ||
        'XBoard'
    }
  } catch (error) {
    console.error('[ForgotPassword] 获取配置失败:', error)
  }
}

// 验证
const canSubmit = computed(() => {
  return email.value.length > 0 && 
         emailCode.value.length > 0 &&
         password.value.length > 0 && 
         passwordConfirm.value.length > 0
})

// 发送邮箱验证码
const handleSendEmailCode = async () => {
  emailCodeError.value = ''
  
  if (!email.value.includes('@')) {
    emailCodeError.value = '邮箱格式无效'
    return
  }
  
  emailCodeSending.value = true
  
  try {
    const response = await authService.sendPasswordResetCode(email.value)
    if (response.success) {
      console.log('[ForgotPassword] 验证码已发送')
      // 开始倒计时
      emailCodeCountdown.value = 60
      const timer = setInterval(() => {
        emailCodeCountdown.value--
        if (emailCodeCountdown.value <= 0) {
          clearInterval(timer)
        }
      }, 1000)
    } else {
      emailCodeError.value = response.message || '发送失败'
    }
  } catch (error: any) {
    console.error('[ForgotPassword] 发送验证码失败:', error)
    emailCodeError.value = error.message || '发送失败'
  } finally {
    emailCodeSending.value = false
  }
}

// 重置密码处理
const handleResetPassword = async () => {
  emailError.value = ''
  emailCodeError.value = ''
  passwordError.value = ''
  passwordConfirmError.value = ''
  resetError.value = ''
  
  // 验证
  if (!email.value.includes('@')) {
    emailError.value = '邮箱格式无效'
    return
  }
  
  if (!emailCode.value) {
    emailCodeError.value = '请输入邮箱验证码'
    return
  }
  
  if (password.value.length < 8) {
    passwordError.value = '密码至少需要8个字符'
    return
  }
  
  if (password.value !== passwordConfirm.value) {
    passwordConfirmError.value = '两次输入的密码不一致'
    return
  }
  
  isLoading.value = true
  
  try {
    const response = await authService.resetPassword({
      email: email.value,
      email_code: emailCode.value,
      password: password.value,
      password_confirmation: passwordConfirm.value
    })
    
    if (response.success) {
      console.log('[ForgotPassword] ✅ 密码重置成功')
      resetSuccess.value = true
      
      // 3秒后跳转到登录页
      setTimeout(() => {
        router.push('/login')
      }, 3000)
    } else {
      resetError.value = response.message || '重置失败'
    }
  } catch (error: any) {
    console.error('[ForgotPassword] ❌ 重置错误:', error)
    resetError.value = error.message || '连接错误'
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  fetchConfig()
})
</script>

<style scoped>
.forgot-password-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--hacker-bg);
  padding: 2rem;
  position: relative;
}

.forgot-password-container {
  width: 100%;
  max-width: 600px;
  z-index: 10;
}

.forgot-password-form {
  border: 1px solid var(--hacker-primary);
  padding: 2rem;
  background: rgba(0, 0, 0, 0.8);
  box-shadow: var(--glow-md);
}

.forgot-password-header {
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

.forgot-password-inputs {
  margin: 2rem 0;
}

.forgot-password-inputs > * {
  margin-bottom: 1rem;
}

.reset-error {
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

.reset-success {
  margin: 1rem 0;
  padding: 1rem;
  border: 1px solid var(--hacker-primary);
  background: rgba(0, 255, 0, 0.1);
  font-family: var(--font-mono);
  color: var(--hacker-primary);
  font-size: 12px;
}

.success-line {
  margin: 0.25rem 0;
}

.reset-actions {
  margin: 2rem 0;
}

.reset-actions button {
  width: 100%;
}

.reset-footer {
  margin-top: 2rem;
  padding-top: 1rem;
  border-top: 1px solid var(--hacker-primary-dim);
}

.footer-line {
  margin: 0.5rem 0;
  font-family: var(--font-mono);
  font-size: 12px;
}

.reset-link {
  color: var(--hacker-primary);
  text-decoration: none;
  text-transform: uppercase;
  transition: all 0.3s ease;
}

.reset-link:hover {
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
  .forgot-password-page {
    padding: 1rem;
  }
  
  .forgot-password-form {
    padding: 1.5rem;
  }
  
  .ascii-logo {
    font-size: 10px;
  }
}
</style>

