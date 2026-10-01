import { defineConfig } from 'tsdown'

export default defineConfig({
  entry: { 'index': 'src/plugin.ts', 'pane-watchdog-runner': 'src/zellij/pane-watchdog-runner.ts' },
  format: ['esm'],
  dts: false,
  clean: true,
  sourcemap: false,
  minify: true,
  codeSplitting: false,
  target: 'node20',
  // OpenCode V2 loads a plugin directory without installing dependencies for
  // it, so bundle every runtime dependency into the two output files.
  noExternal: [/.*/],
})
