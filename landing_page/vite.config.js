import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  // React + Motion (drag, layout, scroll) land around 160 kB gzipped.
  build: { chunkSizeWarningLimit: 600 },
})
