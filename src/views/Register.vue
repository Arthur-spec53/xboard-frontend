<template>
  <div class="register-page">
    <!-- Matrix 背景 -->
    <MatrixRain />
    
    <!-- 扫描线效果 -->
    <ScanLines />
    
    <!-- 注册容器 -->
    <div class="register-container">
      <!-- 注册表单 -->
      <div class="register-form">
        <!-- 标题 -->
        <div class="register-header">
          <pre class="ascii-logo">
  ██████╗ ██╗    ██╗  ██╗██╗   ██╗
 ██╔═══██╗██║    ██║ ██╔╝██║   ██║
 ██║   ██║██║    █████╔╝ ██║   ██║
 ██║▄▄ ██║██║    ██╔═██╗ ██║   ██║
 ╚██████╔╝██║    ██║  ██╗╚██████╔╝
  ╚══▀▀═╝ ╚═╝    ╚═╝  ╚═╝ ╚═════╝ 
  创建新账户
          </pre>
          <TerminalPrompt user="guest" :host="siteName" symbol="#" />
        </div>
        
        <!-- 输入区域 -->
        <div class="register-inputs">
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
            placeholder="输入密码 (至少8个字符)..."
            prefix=">"
            :error="passwordError"
          />
          
          <GeekInput
            v-model="passwordConfirm"
            type="password"
            label="确认密码"
            placeholder="再次输入密码..."
            prefix=">"
            :error="passwordConfirmError"
          />
          
          <GeekInput
            v-if="isInviteRequired"
            v-model="inviteCode"
            label="邀请码"
            placeholder="输入邀请码..."
            prefix=">"
            :error="inviteCodeError"
          />
          
          <GeekInput
            v-if="isEmailVerifyRequired"
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
        </div>
        
        <!-- 错误信息 -->
        <div v-if="registerError" class="register-error">
          <div class="error-line">[!] 注册失败</div>
          <div class="error-line">[!] {{ registerError }}</div>
        </div>
        
        <!-- 成功信息 -->
        <div v-if="registerSuccess" class="register-success">
          <div class="success-line">[✓] 注册成功</div>
          <div class="success-line">[✓] 正在跳转到登录页面...</div>
        </div>
        
        <!-- 按钮组 -->
        <div class="register-actions">
          <GeekButton
            :loading="isLoading"
            :disabled="!canSubmit"
            @click="handleRegister"
            size="lg"
          >
            {{ isLoading ? '注册中' : '执行注册' }}
          </GeekButton>
        </div>
        
        <!-- 底部链接 -->
        <div class="register-footer">
          <div class="footer-line">
            <span class="terminal-prompt"></span>
            <router-link to="/login" class="register-link">返回登录</router-link>
          </div>
        </div>
        
        <!-- 系统信息 -->
        <div class="system-info">
          <div class="info-line">[系统] 邮箱验证: {{ isEmailVerifyRequired ? '需要' : '不需要' }}</div>
          <div class="info-line">[系统] 邀请码: {{ isInviteRequired ? '必需' : '可选' }}</div>
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

// 系统配置
const isEmailVerifyRequired = ref(false)
const isInviteRequired = ref(false)

// 表单数据
const email = ref('')
const password = ref('')
const passwordConfirm = ref('')
const inviteCode = ref('')
const emailCode = ref('')

// 错误信息
const emailError = ref('')
const passwordError = ref('')
const passwordConfirmError = ref('')
const inviteCodeError = ref('')
const emailCodeError = ref('')
const registerError = ref('')
const registerSuccess = ref(false)

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
      isEmailVerifyRequired.value = response.data.is_email_verify === 1
      isInviteRequired.value = response.data.is_invite_force === 1
      console.log('[Register] 配置加载:', { 
        siteName: siteName.value, 
        emailVerify: isEmailVerifyRequired.value,
        inviteRequired: isInviteRequired.value
      })
    }
  } catch (error) {
    console.error('[Register] 获取配置失败:', error)
  }
}

// 验证
const canSubmit = computed(() => {
  return email.value.length > 0 && 
         password.value.length > 0 && 
         passwordConfirm.value.length > 0 &&
         (!isInviteRequired.value || inviteCode.value.length > 0) &&
         (!isEmailVerifyRequired.value || emailCode.value.length > 0)
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
    const response = await authService.sendEmailVerifyCode(email.value)
    if (response.success) {
      console.log('[Register] 验证码已发送')
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
    console.error('[Register] 发送验证码失败:', error)
    emailCodeError.value = error.message || '发送失败'
  } finally {
    emailCodeSending.value = false
  }
}

// 注册处理
const handleRegister = async () => {
  emailError.value = ''
  passwordError.value = ''
  passwordConfirmError.value = ''
  inviteCodeError.value = ''
  emailCodeError.value = ''
  registerError.value = ''
  
  // 验证
  if (!email.value.includes('@')) {
    emailError.value = '邮箱格式无效'
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
  
  if (isInviteRequired.value && !inviteCode.value) {
    inviteCodeError.value = '请输入邀请码'
    return
  }
  
  if (isEmailVerifyRequired.value && !emailCode.value) {
    emailCodeError.value = '请输入邮箱验证码'
    return
  }
  
  isLoading.value = true
  
  try {
    const registerData: any = {
      email: email.value,
      password: password.value,
      password_confirmation: passwordConfirm.value
    }
    
    if (inviteCode.value) {
      registerData.invite_code = inviteCode.value
    }
    
    if (emailCode.value) {
      registerData.email_code = emailCode.value
    }
    
    const response = await authService.register(registerData)
    
    if (response.success) {
      console.log('[Register] ✅ 注册成功')
      registerSuccess.value = true
      
      // 3秒后跳转到登录页
      setTimeout(() => {
        router.push('/login')
      }, 3000)
    } else {
      registerError.value = response.message || '注册失败'
    }
  } catch (error: any) {
    console.error('[Register] ❌ 注册错误:', error)
    registerError.value = error.message || '连接错误'
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  fetchConfig()
})
</script>

<style scoped>
.register-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--hacker-bg);
  padding: 2rem;
  position: relative;
}

.register-container {
  width: 100%;
  max-width: 600px;
  z-index: 10;
}

.register-form {
  border: 1px solid var(--hacker-primary);
  padding: 2rem;
  background: rgba(0, 0, 0, 0.8);
  box-shadow: var(--glow-md);
}

.register-header {
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

.register-inputs {
  margin: 2rem 0;
}

.register-inputs > * {
  margin-bottom: 1rem;
}

.register-error {
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

.register-success {
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

.register-actions {
  margin: 2rem 0;
}

.register-actions button {
  width: 100%;
}

.register-footer {
  margin-top: 2rem;
  padding-top: 1rem;
  border-top: 1px solid var(--hacker-primary-dim);
}

.footer-line {
  margin: 0.5rem 0;
  font-family: var(--font-mono);
  font-size: 12px;
}

.register-link {
  color: var(--hacker-primary);
  text-decoration: none;
  text-transform: uppercase;
  transition: all 0.3s ease;
}

.register-link:hover {
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
  .register-page {
    padding: 1rem;
  }
  
  .register-form {
    padding: 1.5rem;
  }
  
  .ascii-logo {
    font-size: 10px;
  }
}
</style>

