import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  // 环境变量配置
  define: {
    'import.meta.env.VITE_API_BASE_URL': JSON.stringify('/api/v1')
  },
  server: {
    port: 5173,
    proxy: {
      // 代理 API 请求（开发环境使用，请修改为你的后端地址）
      // 生产环境请使用 deploy.sh 脚本自动配置 Nginx 反向代理
      '/api': {
        target: 'http://localhost:8080', // 修改为你的后端 API 地址
        changeOrigin: true,
        secure: false
      }
    }
  },
  // 生产环境构建配置
  build: {
    // 代码混淆和压缩
    minify: 'terser',
    terserOptions: {
      compress: {
        // 移除console
        drop_console: true,
        drop_debugger: true,
        // 移除未使用的代码
        pure_funcs: ['console.log', 'console.info', 'console.debug', 'console.warn']
      },
      mangle: {
        // 混淆变量名
        safari10: true
      },
      format: {
        // 移除注释
        comments: false
      }
    },
    // 分块策略
    rollupOptions: {
      output: {
        // 手动分块
        manualChunks: {
          'vue-vendor': ['vue', 'vue-router', 'pinia'],
          'utils': ['axios', '@vueuse/core']
        },
        // 文件名混淆
        chunkFileNames: 'assets/[name]-[hash].js',
        entryFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash].[ext]'
      }
    },
    // 生成source map但不内联（用于错误追踪，但不暴露源代码）
    sourcemap: false,
    // CSS代码分割
    cssCodeSplit: true,
    // 资源内联限制
    assetsInlineLimit: 4096
  }
})
