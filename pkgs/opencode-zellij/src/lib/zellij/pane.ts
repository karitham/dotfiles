import { execFile } from 'node:child_process'
import process from 'node:process'
import { promisify } from 'node:util'
import { zellij, zellijCommandArgs } from './cli.js'

const execFileAsync = promisify(execFile)

export interface ZellijPaneInfo {
  id?: number | string | undefined
  pane_id?: number | string | undefined
  tab_id?: number | string | undefined
  is_plugin?: boolean | undefined
}

// Coerce a Zellij pane/tab id field (number or numeric string) into a
// plain integer. Returns undefined when the value is missing or not
// integer-shaped so callers can use `??` to fall back across the
// alternate field names (`id` / `pane_id`, `tab_id` / `tabId`).
export function coercePaneId(value: number | string | undefined): number | undefined {
  if (value === undefined)
    return undefined
  const parsed = Number(value)
  return Number.isInteger(parsed) ? parsed : undefined
}

export interface PaneExistsWithRetryOptions {
  targetPaneId: string
  attempts?: number | undefined
  intervalMs?: number | undefined
}

export interface PaneExistsWithRetryResult {
  alive: boolean
  rawListPanes: string
}

// Match a Zellij terminal pane id (`terminal_<n>`) or a bare numeric id
// (`<n>`), anchored to a whole line. The `m` flag lets the id appear on
// any line of a multi-line payload so a future Zellij change that adds
// a leading debug prefix doesn't immediately break this. Crucially we
// no longer use `\b…\d+\b` with a global match: that would happily pick
// the FIRST number in stdout (e.g. a PID in a debug banner) and map the
// session to the wrong pane, which would then turn the next
// `close-pane` into a silent close-wrong-pane.
const paneIdPattern = /^(?:terminal_)?(\d+)\s*$/m

export function normalizePaneId(rawPaneId: string): string {
  const trimmed = rawPaneId.trim()
  if (/^terminal_\d+$/.test(trimmed))
    return trimmed
  if (/^\d+$/.test(trimmed))
    return `terminal_${trimmed}`
  throw new Error(`Invalid Zellij terminal pane id: ${rawPaneId}`)
}

export function parsePaneId(output: string): string {
  const match = output.match(paneIdPattern)
  if (!match?.[1]) {
    throw new Error(`Unable to parse Zellij pane id from output: ${output.trim() || '<empty>'}`)
  }
  return normalizePaneId(match[1])
}

export async function runZellij(actionArgs: string[], timeoutMs = 5_000): Promise<string> {
  const result = await execFileAsync('zellij', zellijCommandArgs(actionArgs), {
    encoding: 'utf8',
    timeout: timeoutMs,
  })
  return result.stdout ?? ''
}

export async function listPanes(): Promise<ZellijPaneInfo[]> {
  const output = await runZellij(['action', 'list-panes', '--json'])
  try {
    const parsed = JSON.parse(output)
    return Array.isArray(parsed) ? parsed as ZellijPaneInfo[] : []
  }
  catch {
    return []
  }
}

export async function dumpScreen(paneId: string): Promise<string> {
  return await runZellij(['action', 'dump-screen', '--pane-id', paneId, '--full'], 10_000)
}

export async function currentPaneTabId(): Promise<number | undefined> {
  const paneId = process.env.ZELLIJ_PANE_ID
  if (!paneId)
    return undefined

  const parsedPaneId = Number(paneId)
  if (!Number.isInteger(parsedPaneId))
    return undefined

  const panes = await listPanes()
  const pane = panes.find(p =>
    !p.is_plugin
    && (coercePaneId(p.id) === parsedPaneId || coercePaneId(p.pane_id) === parsedPaneId),
  )
  return coercePaneId(pane?.tab_id)
}

// Rename a specific tab by its numeric id. No-op when tabId is undefined so
// callers can pass through `await currentPaneTabId()` results without a
// guard. Throws inside an attached Zellij session whose current pane id
// can't be resolved, matching the underlying CLI's expectations.
export async function renameTabById(tabId: number | undefined, title: string): Promise<void> {
  if (tabId === undefined) {
    if (process.env.ZELLIJ)
      throw new Error(`Could not resolve Zellij tab id for pane ${process.env.ZELLIJ_PANE_ID ?? '<missing>'}`)
    return
  }
  await zellij.renameTabById(tabId, title)
}

// Probe `zellij action list-panes --json` up to `attempts` times before
// declaring the pane gone. Returns the raw stdout from the last attempt
// so the caller can include it in the failure dump and disambiguate
// "Zellij settled and the pane is really gone" from "RPC returned
// transient empty payload".
export async function paneExistsWithRetry({
  targetPaneId,
  attempts = 3,
  intervalMs = 200,
}: PaneExistsWithRetryOptions): Promise<PaneExistsWithRetryResult> {
  let lastOutput = ''
  for (let i = 0; i < attempts; i++) {
    let output = ''
    try {
      output = await runZellij(['action', 'list-panes', '--json'])
    }
    catch (error) {
      lastOutput = `<list-panes RPC failed: ${error instanceof Error ? error.message : String(error)}>`
      if (i < attempts - 1)
        await new Promise(r => setTimeout(r, intervalMs))
      continue
    }
    lastOutput = output

    let panes: ZellijPaneInfo[] = []
    try {
      const parsed = JSON.parse(output)
      panes = Array.isArray(parsed) ? parsed : []
    }
    catch {
      panes = []
    }

    const alive = panes.some((p) => {
      const id = normalizePaneIdOrUndefined(p.id)
      const paneIdAlt = normalizePaneIdOrUndefined(p.pane_id)
      return id === targetPaneId || paneIdAlt === targetPaneId
    })
    if (alive)
      return { alive: true, rawListPanes: output }
    if (i < attempts - 1)
      await new Promise(r => setTimeout(r, intervalMs))
  }
  return { alive: false, rawListPanes: lastOutput }
}

// ---------------------------------------------------------------------------
// Spawned pane identity verification
// ---------------------------------------------------------------------------

export interface SpawnedTerminalPaneIdentity {
  normalizedPaneId: string
  numericPaneId: number
}

export interface VerifySpawnedTerminalPaneIdentityOptions {
  spawnOutput: string
  currentPaneId?: string | undefined
  paneIdsBeforeSpawn?: ReadonlySet<number> | undefined
}

export function verifySpawnedTerminalPaneIdentity({
  spawnOutput,
  currentPaneId,
  paneIdsBeforeSpawn,
}: VerifySpawnedTerminalPaneIdentityOptions): SpawnedTerminalPaneIdentity {
  const trimmedCurrentPaneId = currentPaneId?.trim() || undefined

  let normalizedPaneId: string
  try {
    normalizedPaneId = parsePaneId(spawnOutput)
  }
  catch (error) {
    throw createSpawnedPaneIdentityError({
      spawnOutput,
      currentPaneId: trimmedCurrentPaneId,
      reason: error instanceof Error
        ? error.message
        : 'Unable to parse Zellij pane id from new-pane output',
    })
  }

  const numericPaneId = terminalPaneNumber(normalizedPaneId)
  if (numericPaneId === undefined) {
    throw createSpawnedPaneIdentityError({
      spawnOutput,
      currentPaneId: trimmedCurrentPaneId,
      parsedPaneId: normalizedPaneId,
      reason: 'Parsed pane id was not a terminal pane id',
    })
  }

  const currentPaneNumeric = terminalPaneNumber(trimmedCurrentPaneId)
  if (currentPaneNumeric !== undefined && numericPaneId === currentPaneNumeric) {
    throw createSpawnedPaneIdentityError({
      spawnOutput,
      currentPaneId: trimmedCurrentPaneId,
      parsedPaneId: normalizedPaneId,
      reason: 'Parsed pane id matches the current/outer pane id',
    })
  }

  if (paneIdsBeforeSpawn?.has(numericPaneId)) {
    throw createSpawnedPaneIdentityError({
      spawnOutput,
      currentPaneId: trimmedCurrentPaneId,
      parsedPaneId: normalizedPaneId,
      reason: 'Parsed pane id already existed before spawn, so the new terminal pane is not safely identifiable',
    })
  }

  return {
    normalizedPaneId,
    numericPaneId,
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

function normalizePaneIdOrUndefined(value: number | string | undefined): string | undefined {
  if (value === undefined)
    return undefined
  const normalized = String(value).trim()
  if (!normalized)
    return undefined
  if (/^terminal_\d+$/.test(normalized))
    return normalized
  if (/^\d+$/.test(normalized))
    return `terminal_${normalized}`
  return normalized
}

function terminalPaneNumber(rawPaneId: string | undefined): number | undefined {
  if (!rawPaneId)
    return undefined

  const trimmed = rawPaneId.trim()
  if (/^terminal_\d+$/.test(trimmed))
    return Number(trimmed.slice('terminal_'.length))
  if (/^\d+$/.test(trimmed))
    return Number(trimmed)
  return undefined
}

function createSpawnedPaneIdentityError({
  spawnOutput,
  currentPaneId,
  parsedPaneId,
  reason,
}: {
  spawnOutput: string
  currentPaneId?: string | undefined
  parsedPaneId?: string | undefined
  reason: string
}): Error {
  return new Error(
    'Spawn output could not be safely identified as a new terminal pane.\n'
    + `  reason: ${reason}\n`
    + `  raw new-pane output: ${JSON.stringify(spawnOutput)}\n`
    + `  current pane id: ${JSON.stringify(currentPaneId ?? '<missing>')}\n`
    + `  parsed pane id: ${JSON.stringify(parsedPaneId ?? '<unparsed>')}`,
  )
}
