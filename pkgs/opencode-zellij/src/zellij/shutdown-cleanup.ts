import type { SessionManager } from '../pty/manager.js'
import type { SubscriberManager } from './subscribe.js'
import process from 'node:process'
import { zellij } from '../lib/zellij/cli.js'
import { sessionManager } from '../pty/manager.js'
import { debug } from '../utils/debug.js'
import { errorMessage } from '../utils/errors.js'
import { subscriberManager } from './subscribe.js'

let registered = false
let cleanedUp = false

export function cleanupPanesOnShutdown(
  sessions: SessionManager = sessionManager,
  subscribers: SubscriberManager = subscriberManager,
): void {
  if (cleanedUp)
    return
  cleanedUp = true

  for (const session of sessions.list()) {
    try {
      zellij.closePaneSync(session.paneId)
    }
    catch (error) {
      // Shutdown cleanup is only a fast best-effort path; the watchdog registry remains as fallback.
      debug('cleanupPanesOnShutdown closePane failed', errorMessage(error))
    }

    subscribers.forget(session.id)
    try {
      sessions.remove(session.id)
    }
    catch (error) {
      // Another cleanup path may have already removed it.
      debug('cleanupPanesOnShutdown sessions.remove failed', errorMessage(error))
    }
  }
}

export function registerShutdownCleanup(): void {
  if (registered)
    return
  registered = true

  process.once('exit', () => cleanupPanesOnShutdown())
  process.once('SIGINT', () => exitAfterCleanup('SIGINT', 130))
  process.once('SIGTERM', () => exitAfterCleanup('SIGTERM', 143))
  process.once('SIGHUP', () => exitAfterCleanup('SIGHUP', 129))
}

function exitAfterCleanup(signal: NodeJS.Signals, code: number): void {
  cleanupPanesOnShutdown()
  process.removeAllListeners(signal)
  process.exit(code)
}
