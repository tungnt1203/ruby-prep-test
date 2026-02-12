import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    tailwindcss()
  ],
  server: {
    host: '0.0.0.0',
    port: 3036,
    strictPort: true,
    origin: 'http://localhost:3036',
    cors: true,
    hmr: {
      host: 'localhost',
      port: 3036,
      clientPort: 3036,
    },
    watch: {
      usePolling: true, // Required for Docker
    },
  },
})
