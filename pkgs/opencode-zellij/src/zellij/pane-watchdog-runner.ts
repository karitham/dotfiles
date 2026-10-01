import { spawnSync } from 'node:child_process'
import { appendFileSync, existsSync, readFileSync, rmSync } from 'node:fs'
import process from 'node:process'

const registryPath = process.argv[2]
const pollIntervalMs = 1_000

function writeWatchdogDebug(message: string, error: unknown): void {
  if (!process.env.ZELLIJ_PTY_DEBUG)
    return

  try {
    appendFileSync(`${registryPath}.log`, `${new Date().toISOString()} ${message}: ${error instanceof Error ? error.message : String(error)}\n`)
  }
  catch (loggingError) {
    void loggingError
    // The watchdog has no stderr; if file logging fails, there is nowhere else to report diagnostics.
  }
}

interface WatchdogPane {
  paneId: string
}

interface WatchdogRegistry {
  ownerPid: number
  ownerStartTime?: string | null | undefined
  zellijSessionName?: string | null | undefined
  panes?: WatchdogPane[] | undefined
}

if (!registryPath)
  process.exit(1)

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms))
}

function linuxProcessStartTime(pid: number): string | null {
  try {
    const stat = readFileSync(`/proc/${pid}/stat`, 'utf8')
    const fieldsAfterCommand = stat.slice(stat.lastIndexOf(')') + 2).trim().split(/\s+/)
    return fieldsAfterCommand[19] || null
  }
  catch (error) {
    // Missing /proc data is expected when the owner has exited or on non-Linux systems.
    writeWatchdogDebug('linuxProcessStartTime failed', error)
    return null
  }
}

function readRegistry(): WatchdogRegistry | null {
  try {
    if (!existsSync(registryPath!))
      return null
    return JSON.parse(readFileSync(registryPath!, 'utf8')) as WatchdogRegistry
  }
  catch (error) {
    // A missing or corrupt registry cannot be used safely; let the watchdog exit.
    writeWatchdogDebug('readRegistry failed', error)
    return null
  }
}

function ownerAlive(registry: WatchdogRegistry): boolean {
  try {
    process.kill(registry.ownerPid, 0)
  }
  catch (error) {
    // process.kill(pid, 0) throws when the owner is gone or inaccessible.
    writeWatchdogDebug('ownerAlive kill check failed', error)
    return false
  }

  return !registry.ownerStartTime || linuxProcessStartTime(registry.ownerPid) === registry.ownerStartTime
}

function closePane(registry: WatchdogRegistry, paneId: string): void {
  const args: string[] = []
  if (registry.zellijSessionName)
    args.push('--session', registry.zellijSessionName)
  args.push('action', 'close-pane', '--pane-id', paneId)
  spawnSync('zellij', args, { stdio: 'ignore', timeout: 2_000 })
}

async function main(): Promise<void> {
  for (;;) {
    const registry = readRegistry()
    if (!registry)
      return

    if (!ownerAlive(registry)) {
      const finalRegistry = readRegistry() || registry
      for (const pane of finalRegistry.panes || []) {
        closePane(finalRegistry, pane.paneId)
      }
      rmSync(registryPath!, { force: true })
      return
    }

    await sleep(pollIntervalMs)
  }
}

function writeFatalError(error: unknown): void {
  try {
    appendFileSync(`${registryPath}.log`, `${new Date().toISOString()} ${error instanceof Error ? error.stack || error.message : String(error)}\n`)
  }
  catch (loggingError) {
    void loggingError
    // The watchdog has no stderr; if file logging also fails, exiting is the only safe fallback.
  }
}

main().catch((error: unknown) => {
  writeFatalError(error)
  process.exit(1)
})
