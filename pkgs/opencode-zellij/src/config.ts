import { existsSync } from 'node:fs'
import { readFile } from 'node:fs/promises'
import { homedir } from 'node:os'
import { join } from 'node:path'
import process from 'node:process'
import { parseJSON, parseJSONC } from 'confbox'
import { z } from 'zod'

const sudoPaneSchema = z.enum(['allow', 'deny', 'hide'])
const sudoPaneModeSchema = z.enum(['floating', 'fullscreen'])
const sudoPaneFloatingSizeSchema = z.object({
  width: z.string().default('80%'),
  height: z.string().default('60%'),
  pinned: z.boolean().default(true),
}).strict()

export interface TabTitleConfig {
  enabled: boolean
  emojiIdle: string
  emojiRunning: string
  emojiNeedsInput: string
  debounceMs: number
}

export interface SudoPaneFloatingSize {
  width: string
  height: string
  pinned: boolean
}

export interface PtyConfig {
  enabled: boolean
  cleanupExitedPaneOnRead: boolean
  sudoPane: SudoPaneMode
  sudoPaneMode: SudoPaneModeKind
  sudoPaneFloatingSize: SudoPaneFloatingSize
}

export type SudoPaneMode = z.infer<typeof sudoPaneSchema>
export type SudoPaneModeKind = z.infer<typeof sudoPaneModeSchema>

export interface ZellijPluginConfig {
  tabTitle: TabTitleConfig
  pty: PtyConfig
}

export interface LoadConfigInput {
  directory?: string | undefined
  worktree?: string | undefined
}

export interface LoadConfigResult {
  config: ZellijPluginConfig
  sources: {
    user?: string | undefined
    project?: string | undefined
  }
  warnings: string[]
}

const configFilenames = [
  'opencode-zellij.config.jsonc',
  'opencode-zellij.config.json',
] as const

const tabTitleLayerSchema = z.object({
  enabled: z.boolean().optional().describe('Enable dynamic Zellij tab title updates.'),
  emojiIdle: z.string().optional().describe('Prefix used when OpenCode is idle.'),
  emojiRunning: z.string().optional().describe('Prefix used while OpenCode is running work.'),
  emojiNeedsInput: z.string().optional().describe('Prefix used when OpenCode is waiting for human input.'),
  debounceMs: z.number().finite().min(0).optional().describe('Debounce time for tab title updates in milliseconds.'),
}).strict()

const ptyLayerSchema = z.object({
  enabled: z.boolean().optional().describe('Enable Zellij-backed PTY tools.'),
  cleanupExitedPaneOnRead: z.boolean().optional().describe('Remove exited PTY panes after they are read.'),
  sudoPane: sudoPaneSchema.optional().describe('Controls whether the sudo pane tool is available, denied, or hidden.'),
  sudoPaneMode: sudoPaneModeSchema.optional().describe('How the sudo request pane is presented to the user. `floating` (default) opens a large, pinned floating pane without stealing focus; `fullscreen` opens a non-floating pane that Zellij focuses automatically.'),
  sudoPaneFloatingSize: sudoPaneFloatingSizeSchema.optional().describe('Size of the floating sudo pane. `width`/`height` accept a percent string (e.g. `80%`) or a bare integer in cells. `pinned` keeps the pane on top of other floating panes.'),
}).strict()

export const sidecarConfigSchema = z.object({
  $schema: z.string().optional().describe('JSON Schema URI for editor completion.'),
  tabTitle: tabTitleLayerSchema.optional(),
  pty: ptyLayerSchema.optional(),
}).strict()

export const defaultConfig: ZellijPluginConfig = {
  tabTitle: {
    enabled: true,
    emojiIdle: '🟢',
    emojiRunning: '⚡',
    emojiNeedsInput: '💬',
    debounceMs: 300,
  },
  pty: {
    enabled: true,
    cleanupExitedPaneOnRead: true,
    sudoPane: 'allow',
    sudoPaneMode: 'floating',
    sudoPaneFloatingSize: { width: '80%', height: '60%', pinned: true },
  },
}

type ConfigLayer = Pick<z.infer<typeof sidecarConfigSchema>, 'tabTitle' | 'pty'>

const DEPRECATED_TAB_TITLE_KEYS = ['emojiBranch'] as const

function stripDeprecatedTabTitleFields(value: unknown): unknown {
  if (!value || typeof value !== 'object' || Array.isArray(value))
    return value
  const result = { ...(value as Record<string, unknown>) }
  for (const key of DEPRECATED_TAB_TITLE_KEYS)
    delete result[key]
  return result
}

function validConfigLayer(value: unknown): ConfigLayer | undefined {
  if (!value || typeof value !== 'object' || Array.isArray(value))
    return undefined
  const cloned = { ...(value as Record<string, unknown>) }
  cloned.tabTitle = stripDeprecatedTabTitleFields(cloned.tabTitle)
  const result = sidecarConfigSchema.safeParse(cloned)
  if (!result.success)
    return undefined

  return {
    tabTitle: result.data.tabTitle,
    pty: result.data.pty,
  }
}

function mergeConfig(user?: ConfigLayer | undefined, project?: ConfigLayer | undefined): ZellijPluginConfig {
  return {
    tabTitle: {
      enabled: project?.tabTitle?.enabled ?? user?.tabTitle?.enabled ?? defaultConfig.tabTitle.enabled,
      emojiIdle: project?.tabTitle?.emojiIdle ?? user?.tabTitle?.emojiIdle ?? defaultConfig.tabTitle.emojiIdle,
      emojiRunning: project?.tabTitle?.emojiRunning ?? user?.tabTitle?.emojiRunning ?? defaultConfig.tabTitle.emojiRunning,
      emojiNeedsInput: project?.tabTitle?.emojiNeedsInput ?? user?.tabTitle?.emojiNeedsInput ?? defaultConfig.tabTitle.emojiNeedsInput,
      debounceMs: project?.tabTitle?.debounceMs ?? user?.tabTitle?.debounceMs ?? defaultConfig.tabTitle.debounceMs,
    },
    pty: {
      enabled: project?.pty?.enabled ?? user?.pty?.enabled ?? defaultConfig.pty.enabled,
      cleanupExitedPaneOnRead: project?.pty?.cleanupExitedPaneOnRead ?? user?.pty?.cleanupExitedPaneOnRead ?? defaultConfig.pty.cleanupExitedPaneOnRead,
      sudoPane: project?.pty?.sudoPane ?? user?.pty?.sudoPane ?? defaultConfig.pty.sudoPane,
      sudoPaneMode: project?.pty?.sudoPaneMode ?? user?.pty?.sudoPaneMode ?? defaultConfig.pty.sudoPaneMode,
      sudoPaneFloatingSize: project?.pty?.sudoPaneFloatingSize ?? user?.pty?.sudoPaneFloatingSize ?? defaultConfig.pty.sudoPaneFloatingSize,
    },
  }
}

async function loadConfigLayer(directory: string, warnings: string[]): Promise<{ layer?: ConfigLayer | undefined, source?: string | undefined }> {
  const configFile = detectConfigFile(directory)
  if (!configFile)
    return {}

  try {
    const text = await readFile(configFile, 'utf8')
    const parsed = configFile.endsWith('.jsonc') ? parseJSONC(text) : parseJSON(text)
    const layer = validConfigLayer(parsed)
    if (!layer) {
      warnings.push(`Ignoring invalid config shape in ${configFile}.`)
      return { source: configFile }
    }
    return { layer, source: configFile }
  }
  catch (cause) {
    warnings.push(`Ignoring unreadable or invalid config file ${configFile}: ${cause instanceof Error ? cause.message : String(cause)}`)
    return {}
  }
}

function detectConfigFile(directory: string): string | undefined {
  return configFilenames
    .map(filename => join(directory, filename))
    .find(path => existsSync(path))
}

export function userConfigDir(): string {
  return process.env.XDG_CONFIG_HOME ? join(process.env.XDG_CONFIG_HOME, 'opencode') : join(homedir(), '.config', 'opencode')
}

export function projectConfigDirs(input: LoadConfigInput): string[] {
  const dirs: string[] = []
  if (input.worktree)
    dirs.push(join(input.worktree, '.opencode'))
  if (input.directory && input.directory !== input.worktree)
    dirs.push(join(input.directory, '.opencode'))
  return dirs
}

export async function loadConfig(input: LoadConfigInput): Promise<LoadConfigResult> {
  const warnings: string[] = []
  const sources: LoadConfigResult['sources'] = {}

  const userResult = await loadConfigLayer(userConfigDir(), warnings)
  const userLayer = userResult.layer
  if (userResult.source && userLayer)
    sources.user = userResult.source

  let projectLayer: ConfigLayer | undefined
  for (const projectDir of projectConfigDirs(input)) {
    const projectResult = await loadConfigLayer(projectDir, warnings)
    if (!projectResult.source)
      continue
    projectLayer = projectResult.layer
    if (projectLayer)
      sources.project = projectResult.source
    break
  }

  return {
    config: mergeConfig(userLayer, projectLayer),
    sources,
    warnings,
  }
}
