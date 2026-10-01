import type { CommandInput } from '../../utils/shell-args.js'
import { execFile, spawnSync } from 'node:child_process'
import process from 'node:process'
import { promisify } from 'node:util'
import { buildCommandArgv } from '../../utils/shell-args.js'
import { parsePaneId } from './pane.js'
import { parseActiveTabName, parseCurrentPaneTabId, parsePaneExists, parseTabName } from './parse.js'

const execFileAsync = promisify(execFile)

export type NewPaneOptions = CommandInput & {
  cwd?: string | undefined
  title?: string | undefined
  floating?: boolean | undefined
  floatingWidth?: string | undefined
  floatingHeight?: string | undefined
  floatingPinned?: boolean | undefined
  closeOnExit?: boolean | undefined
  exitCodeToken?: string | undefined
}

export interface ZellijRunOptions {
  timeoutMs?: number | undefined
}

export interface ZellijRunResult {
  stdout: string
  stderr: string
}

export interface ZellijRunner {
  run: (actionArgs: string[], options?: ZellijRunOptions) => Promise<ZellijRunResult>
}

export interface ZellijClient {
  newPane: (options: NewPaneOptions) => Promise<string>
  writeChars: (paneId: string, data: string) => Promise<void>
  sendCtrlC: (paneId: string) => Promise<void>
  closePane: (paneId: string) => Promise<void>
  closePaneSync: (paneId: string) => void
  focusPane: (paneId: string) => Promise<void>
  dumpScreen: (paneId: string) => Promise<string>
  paneExists: (paneId: string) => Promise<boolean | undefined>
  currentPaneTabId: () => Promise<number | undefined>
  renameTab: (title: string) => Promise<void>
  renameTabById: (tabId: number, title: string) => Promise<void>
  currentTabTitle: () => Promise<string | undefined>
}

export interface CreateZellijClientOptions {
  runner?: ZellijRunner | undefined
}

export function zellijCommandArgs(actionArgs: string[]): string[] {
  const sessionName = process.env.ZELLIJ_SESSION_NAME?.trim()
  if (sessionName)
    return ['--session', sessionName, ...actionArgs]
  return actionArgs
}

export function zellijActionArgs(action: string, args: string[] = []): string[] {
  return ['action', action, ...args]
}

export function buildNewPaneActionArgs(options: NewPaneOptions): string[] {
  const args = ['action', 'new-pane']
  // `--near-current-pane` only applies to layout-bound (non-floating) panes.
  // Floating panes use their own positioning (`--x`/`--y`/centered defaults)
  // and anchoring via `--width`/`--height`/`--pinned`.
  if (process.env.ZELLIJ && !options.floating)
    args.push('--near-current-pane')

  if (options.title)
    args.push('--name', options.title)
  if (options.cwd)
    args.push('--cwd', options.cwd)
  if (options.floating) {
    args.push('--floating')
    if (options.floatingWidth)
      args.push('--width', options.floatingWidth)
    if (options.floatingHeight)
      args.push('--height', options.floatingHeight)
    if (options.floatingPinned)
      args.push('--pinned', 'true')
  }
  if (options.closeOnExit)
    args.push('--close-on-exit')

  args.push('--', ...buildCommandArgv(options, { exitCodeToken: options.exitCodeToken }))
  return args
}

export function buildRenameTabActionArgs(title: string, options: { tabId?: number } = {}): string[] {
  if (options.tabId !== undefined)
    return ['action', 'rename-tab', '--tab-id', String(options.tabId), title]
  return ['action', 'rename-tab', title]
}

export function ensureZellijTarget(): void {
  if (process.env.ZELLIJ || process.env.ZELLIJ_SESSION_NAME)
    return
  throw new Error('Zellij context not found. Run OpenCode inside Zellij or set ZELLIJ_SESSION_NAME to an existing session.')
}

async function defaultRunZellij(actionArgs: string[], options: ZellijRunOptions = {}): Promise<ZellijRunResult> {
  ensureZellijTarget()
  try {
    const result = await execFileAsync('zellij', zellijCommandArgs(actionArgs), {
      encoding: 'utf8',
      timeout: options.timeoutMs ?? 10_000,
      maxBuffer: 20 * 1024 * 1024,
    })

    return {
      stdout: result.stdout ?? '',
      stderr: result.stderr ?? '',
    }
  }
  catch (cause) {
    const error = cause as { message?: string, stdout?: string, stderr?: string }
    const stderr = error.stderr?.trim()
    const stdout = error.stdout?.trim()
    const detail = stderr || stdout || error.message || 'unknown error'
    throw new Error(`zellij ${actionArgs.join(' ')} failed: ${detail}`)
  }
}

const defaultRunner: ZellijRunner = { run: defaultRunZellij }

export function createZellijClient(options: CreateZellijClientOptions = {}): ZellijClient {
  const runner = options.runner ?? defaultRunner

  async function resolveCurrentPaneTabId(): Promise<number | undefined> {
    const paneId = process.env.ZELLIJ_PANE_ID
    if (!paneId)
      return undefined

    const result = await runner.run(zellijActionArgs('list-panes', ['--json']), { timeoutMs: 5_000 })
    return parseCurrentPaneTabId(result.stdout, paneId)
  }

  return {
    newPane: async (paneOptions) => {
      const result = await runner.run(buildNewPaneActionArgs(paneOptions))
      return parsePaneId(result.stdout)
    },

    writeChars: async (paneId, data) => {
      await runner.run(zellijActionArgs('write-chars', ['--pane-id', paneId, data]))
    },

    sendCtrlC: async (paneId) => {
      await runner.run(zellijActionArgs('send-keys', ['--pane-id', paneId, 'Ctrl c']))
    },

    closePane: async (paneId) => {
      await runner.run(zellijActionArgs('close-pane', ['--pane-id', paneId]))
    },

    closePaneSync: (paneId) => {
      ensureZellijTarget()
      spawnSync('zellij', zellijCommandArgs(zellijActionArgs('close-pane', ['--pane-id', paneId])), {
        encoding: 'utf8',
        stdio: 'ignore',
        timeout: 2_000,
      })
    },

    focusPane: async (paneId) => {
      await runner.run(zellijActionArgs('focus-pane-id', [paneId]))
    },

    dumpScreen: async (paneId) => {
      const result = await runner.run(
        zellijActionArgs('dump-screen', ['--pane-id', paneId, '--full']),
        { timeoutMs: 10_000 },
      )
      return result.stdout
    },

    paneExists: async (paneId) => {
      const result = await runner.run(zellijActionArgs('list-panes', ['--json']), { timeoutMs: 5_000 })
      return parsePaneExists(result.stdout, paneId)
    },

    currentPaneTabId: resolveCurrentPaneTabId,

    renameTab: async (title) => {
      const tabId = await resolveCurrentPaneTabId()
      if (tabId === undefined && process.env.ZELLIJ)
        throw new Error(`Could not resolve Zellij tab id for pane ${process.env.ZELLIJ_PANE_ID ?? '<missing>'}`)
      await runner.run(
        tabId === undefined
          ? buildRenameTabActionArgs(title)
          : buildRenameTabActionArgs(title, { tabId }),
      )
    },

    renameTabById: async (tabId, title) => {
      await runner.run(buildRenameTabActionArgs(title, { tabId }))
    },

    currentTabTitle: async () => {
      const paneId = process.env.ZELLIJ_PANE_ID
      if (!paneId) {
        if (!process.env.ZELLIJ_SESSION_NAME?.trim())
          return undefined

        const result = await runner.run(zellijActionArgs('list-tabs', ['--json']), { timeoutMs: 5_000 })
        return parseActiveTabName(result.stdout)
      }

      const tabId = await resolveCurrentPaneTabId()
      if (tabId === undefined)
        return undefined

      const result = await runner.run(zellijActionArgs('list-tabs', ['--json']), { timeoutMs: 5_000 })
      return parseTabName(result.stdout, tabId)
    },
  }
}

export const zellij: ZellijClient = createZellijClient()
