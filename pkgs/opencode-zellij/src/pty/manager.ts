import type { CreateSessionInput, PtySession, SessionStatus, SessionTerminalReason, SessionTombstone } from './session.js'
import { createSessionId } from '../utils/ids.js'

const tombstoneTailLimit = 200

export interface MarkTerminalInput {
  reason: SessionTerminalReason
  tail?: string[] | undefined
  exitCode?: number | undefined
}

export interface MarkTerminalResult {
  session: PtySession
  created: boolean
}

export class SessionManager {
  private readonly sessions = new Map<string, PtySession>()

  create(input: CreateSessionInput): PtySession {
    const now = new Date().toISOString()
    const session: PtySession = {
      id: createSessionId(),
      openCodeSessionId: input.openCodeSessionId ?? null,
      paneId: input.paneId,
      title: input.title,
      command: input.command,
      args: input.args ?? [],
      cwd: input.cwd,
      status: 'running',
      lineCount: 0,
      createdAt: now,
      updatedAt: now,
      allowAgentInput: input.allowAgentInput,
      humanInputOnly: input.humanInputOnly,
      exitCode: null,
      exitedAt: null,
      exitCodeToken: input.exitCodeToken ?? null,
      tombstone: null,
    }
    this.sessions.set(session.id, session)
    return session
  }

  get(id: string): PtySession {
    const session = this.sessions.get(id)
    if (!session)
      throw new Error(`Unknown zellij PTY session: ${id}`)
    return session
  }

  find(id: string): PtySession | undefined {
    return this.sessions.get(id)
  }

  list(): PtySession[] {
    return Array.from(this.sessions.values()).sort((a, b) => a.createdAt.localeCompare(b.createdAt))
  }

  updateLineCount(id: string, lineCount: number): PtySession {
    const session = this.get(id)
    session.lineCount = lineCount
    session.updatedAt = new Date().toISOString()
    return session
  }

  updateStatus(id: string, status: SessionStatus): PtySession {
    const session = this.get(id)
    if (session.status === 'terminal' && status !== 'terminal')
      return session
    session.status = status
    session.updatedAt = new Date().toISOString()
    return session
  }

  markExited(id: string, exitCode: number): PtySession {
    return this.markTerminal(id, { reason: 'exit_marker', exitCode }).session
  }

  markTerminal(id: string, input: MarkTerminalInput): MarkTerminalResult {
    const session = this.get(id)
    const now = new Date().toISOString()
    const created = session.status !== 'terminal' || !session.tombstone

    if (created) {
      const tombstone: SessionTombstone = {
        reason: input.reason,
        terminalAt: now,
        tail: (input.tail ?? []).slice(-tombstoneTailLimit),
        paneClosedAt: null,
      }

      session.status = 'terminal'
      session.tombstone = tombstone
      session.updatedAt = now
    }

    if (input.exitCode !== undefined && session.exitCode === null) {
      session.exitCode = input.exitCode
      session.exitedAt = now
      session.updatedAt = now
    }

    if (session.tombstone) {
      if (input.tail?.length && session.tombstone.tail.length === 0)
        session.tombstone.tail = input.tail.slice(-tombstoneTailLimit)
      if (!session.tombstone.reason)
        session.tombstone.reason = input.reason
    }

    return { session, created }
  }

  markTerminalPaneClosed(id: string): PtySession {
    const session = this.get(id)
    const now = new Date().toISOString()
    if (!session.tombstone)
      return session
    if (!session.tombstone.paneClosedAt) {
      session.tombstone.paneClosedAt = now
      session.updatedAt = now
    }
    return session
  }

  listByOpenCodeSession(openCodeSessionId: string): PtySession[] {
    return this.list().filter(session => session.openCodeSessionId === openCodeSessionId)
  }

  remove(id: string): void {
    if (!this.sessions.delete(id))
      throw new Error(`Unknown zellij PTY session: ${id}`)
  }
}

export const sessionManager = new SessionManager()
