export type SessionStatus = 'running' | 'exited' | 'killed' | 'unknown' | 'terminal'

export type SessionTerminalReason = 'pane_closed' | 'exit_marker' | 'read_cleanup' | 'subscriber_exit' | 'subscriber_error' | 'session_deleted'

export interface SessionTombstone {
  reason: SessionTerminalReason
  terminalAt: string
  tail: string[]
  paneClosedAt: string | null
}

export interface PtySession {
  id: string
  openCodeSessionId: string | null
  paneId: string
  title: string
  command: string
  args: string[]
  cwd: string
  status: SessionStatus
  lineCount: number
  createdAt: string
  updatedAt: string
  allowAgentInput: boolean
  humanInputOnly: boolean
  exitCode: number | null
  exitedAt: string | null
  exitCodeToken: string | null
  tombstone?: SessionTombstone | null
}

export interface CreateSessionInput {
  openCodeSessionId?: string | undefined
  paneId: string
  title: string
  command: string
  args?: string[] | undefined
  cwd: string
  allowAgentInput: boolean
  humanInputOnly: boolean
  exitCodeToken?: string | undefined
}
