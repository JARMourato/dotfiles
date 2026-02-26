import { defineConfig } from 'tsup';

export default defineConfig({
  entry: ['src/index.ts'],
  format: ['cjs'],
  target: 'node18',
  platform: 'node',
  sourcemap: true,
  clean: true,
  dts: true,
  banner: {
    js: '#!/usr/bin/env node',
  },
});
