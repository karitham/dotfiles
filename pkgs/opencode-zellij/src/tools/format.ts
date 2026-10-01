import type { PtySession, SessionTombstone } from '../pty/session.js'

export interface PublicSessionOptions {
  /**
   * Include `tombstone` in the response. Only `read` and `list` need it, because agents
   * observe completed/cleaned-up sessions through those tools. `spawn` / `write` /
   * `request_sudo` should omit it.
   */
  includeTombstone?: boolean | undefined
  /**
   * `true` for agent-writable panes (the default; matches `zellij_pty_spawn`).
   * `false` for human-input-only sudo panes (`zellij_pty_request_sudo`). The
   * non-default value is surfaced to the agent via `humanInputOnly` so it can
   * tell apart "I cannot write here" sessions.
   */
  agentWritable?: boolean | undefined
}

export interface PublicTombstone {
  reason: SessionTombstone['reason']
  terminalAt: string
  tailLines: number
  paneClosedAt: string | null
}

export function publicSession(session: PtySession, options: PublicSessionOptions = {}): Record<string, unknown> {
  const status = session.status === 'terminal' ? 'exited' : session.status
  const summary: Record<string, unknown> = {
    id: session.id,
    paneId: session.paneId,
    title: session.title,
    command: session.command,
    status,
  }

  if (options.agentWritable === false)
    summary.humanInputOnly = true

  if (options.includeTombstone) {
    summary.tombstone = session.tombstone
      ? {
          reason: session.tombstone.reason,
          terminalAt: session.tombstone.terminalAt,
          tailLines: session.tombstone.tail.length,
          paneClosedAt: session.tombstone.paneClosedAt,
        }
      : null
  }

  return summary
}

export function jsonResponse(value: unknown): string {
  return JSON.stringify(value, null, 2)
}

/**
 * Lean summary of a session that already reached its terminal state. Returned
 * by `spawn` and `list` so agents can spot dead panes that still need to be
 * closed via `zellij_pty_read` (which triggers cleanup) or `zellij_pty_kill`.
 */
export interface PublicCompletedPane {
  id: string
  paneId: string
  status: 'exited' | 'killed' | 'unknown'
  exitCode: number | null
  reason: SessionTombstone['reason'] | null
}

export interface CompletedPanesSummary {
  completedPaneIds: string[]
  completedPanes: PublicCompletedPane[]
}

export function publicCompletedPane(session: PtySession): PublicCompletedPane {
  const status = session.status === 'terminal' ? 'exited' : session.status
  const safeStatus: PublicCompletedPane['status'] = status === 'exited' || status === 'killed' || status === 'unknown'
    ? status
    : 'unknown'
  return {
    id: session.id,
    paneId: session.paneId,
    status: safeStatus,
    exitCode: session.exitCode,
    reason: session.tombstone?.reason ?? null,
  }
}

export function completedPanesFromSessions(sessions: PtySession[]): CompletedPanesSummary {
  const completedPanes = sessions
    .filter(session => session.status === 'terminal')
    .map(publicCompletedPane)
  return {
    completedPaneIds: completedPanes.map(pane => pane.id),
    completedPanes,
  }
}
