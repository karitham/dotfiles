import type { PtySession, SessionTerminalReason } from '../pty/session.js'
import { errorMessage } from '../utils/errors.js'
import { getChildLogger } from '../utils/logger.js'

const logger = getChildLogger('completion-notifications')

export interface SubscriberTerminalEvent {
  sessionId: string
  reason: SessionTerminalReason
  session: PtySession
}

/** Delivers a synthetic prompt to the OpenCode session that owns a pane. */
export type CompletionPrompt = (sessionID: string, text: string) => Promise<unknown>

export interface CompletionNotificationContext {
  prompt: CompletionPrompt
}

export interface CompletionNotificationManager {
  handleSessionTerminal: (event: SubscriberTerminalEvent) => Promise<void>
  dispose: () => void
}

function formatExitCode(exitCode: number | null): string {
  return exitCode === null ? '?' : String(exitCode)
}

// Short, system-notification style. Contains the plugin name, pane id, and
// exit code so the agent can immediately call zellij_pty_read on the right
// pane without digging through session metadata.
export function buildCompletionPromptText(event: SubscriberTerminalEvent): string {
  const { paneId, exitCode } = event.session
  return `[zellij_pty] pane ${paneId} exit=${formatExitCode(exitCode)} — call zellij_pty_read to read, then zellij_pty_kill to close.`
}

export class SessionCompletionNotificationManager implements CompletionNotificationManager {
  private readonly seen = new Set<string>()

  constructor(
    private readonly context: CompletionNotificationContext,
  ) { }

  dispose(): void {
    this.seen.clear()
  }

  async handleSessionTerminal(event: SubscriberTerminalEvent): Promise<void> {
    logger?.withMetadata({
      session: event.sessionId,
      reason: event.reason,
      paneId: event.session.paneId,
      openCodeSessionId: event.session.openCodeSessionId ?? 'null',
    }).info('handleSessionTerminal')
    if (this.seen.has(event.sessionId))
      return
    this.seen.add(event.sessionId)

    const sessionID = event.session.openCodeSessionId
    if (!sessionID) {
      logger?.withMetadata({ session: event.sessionId }).info('skipped: no openCodeSessionId')
      return
    }

    try {
      await this.context.prompt(sessionID, buildCompletionPromptText(event))
      logger?.withMetadata({ sessionID }).info('prompt ok')
    }
    catch (error) {
      // A prompt can legitimately fail (aborted message, shut-down session);
      // the pane is already terminal, so log and move on.
      logger?.withMetadata({ sessionID, error: errorMessage(error) }).warn('prompt failed')
    }
  }
}
