import type { PaneExistsFn } from './pane-cleanup.js'
import type { ZellijToolInfo } from './tool.js'
import { z } from 'zod'
import { zellij } from '../lib/zellij/cli.js'
import { sessionManager } from '../pty/manager.js'
import { subscriberManager } from '../zellij/subscribe.js'
import { jsonResponse, publicSession } from './format.js'
import { readOutputSnapshot, validateGrep } from './output.js'
import { closePaneOrVerifyGone } from './pane-cleanup.js'

export interface ReadToolArgs {
  id: string
  maxLines?: number | undefined
  grep?: string | undefined
  ignoreCase?: boolean | undefined
  cleanupExitedPaneOnRead?: boolean | undefined
}

export interface ReadCleanupResult {
  requested: boolean
  performed: boolean
  alreadyClosed: boolean
  warning?: string | undefined
}

export interface ReadToolResult {
  session: ReturnType<typeof publicSession>
  output: ReturnType<typeof readOutputSnapshot>
  subscriberActive: boolean
  subscriberLastExitedAt: string | null
  subscriberErrors: string[]
  warnings: string[]
  cleanup: ReadCleanupResult
}

export interface ReadToolDependencies {
  sessionManager?: Pick<typeof sessionManager, 'get' | 'updateStatus' | 'markTerminalPaneClosed'> | undefined
  subscriberManager?: Pick<typeof subscriberManager, 'status' | 'start' | 'stderr' | 'closeSessionPane'> | undefined
  publicSession?: typeof publicSession | undefined
  readOutputSnapshot?: typeof readOutputSnapshot | undefined
  validateGrep?: typeof validateGrep | undefined
  paneExists?: PaneExistsFn | undefined
  defaultCleanupExitedPaneOnRead?: boolean | undefined
}

export async function executeZellijPtyRead(args: ReadToolArgs, dependencies: ReadToolDependencies = {}): Promise<ReadToolResult> {
  const sessionManagerApi = dependencies.sessionManager ?? sessionManager
  const subscriberManagerApi = dependencies.subscriberManager ?? subscriberManager
  const publicSessionApi = dependencies.publicSession ?? publicSession
  const readOutputSnapshotApi = dependencies.readOutputSnapshot ?? readOutputSnapshot
  const validateGrepApi = dependencies.validateGrep ?? validateGrep
  const paneExistsApi = dependencies.paneExists ?? (paneId => zellij.paneExists(paneId))

  const session = sessionManagerApi.get(args.id)
  const grepError = validateGrepApi(args.grep)
  if (grepError) {
    return {
      session: publicSessionApi(session, { includeTombstone: true }),
      output: { text: '', lineCount: session.lineCount, truncated: false },
      subscriberActive: false,
      subscriberLastExitedAt: null,
      subscriberErrors: [],
      warnings: [`Invalid grep regex: ${grepError}`],
      cleanup: { requested: false, performed: false, alreadyClosed: false },
    }
  }

  const subscriberStatus = subscriberManagerApi.status(session.id)
  if (!subscriberStatus.hasBuffer || (!subscriberStatus.active && (session.status === 'running' || session.status === 'unknown')))
    await subscriberManagerApi.start(session)

  const statusAfterStart = subscriberManagerApi.status(session.id)
  const warnings: string[] = []
  if (session.humanInputOnly)
    warnings.push('This pane is human-input-only: agent writes are forbidden, but rendered output is visible to the agent.')

  if (!statusAfterStart.active && session.status === 'running') {
    warnings.push('Subscriber is inactive; returned output may be stale.')
    sessionManagerApi.updateStatus(session.id, 'unknown')
  }

  const output = readOutputSnapshotApi(session.id, { maxLines: args.maxLines, grep: args.grep, ignoreCase: args.ignoreCase })
  const cleanup = await cleanupExitedPaneOnRead(session.id, session.status, args.cleanupExitedPaneOnRead ?? dependencies.defaultCleanupExitedPaneOnRead ?? true, {
    sessionManager: sessionManagerApi,
    subscriberManager: subscriberManagerApi,
    paneExists: paneExistsApi,
  })
  if (cleanup.warning)
    warnings.push(cleanup.warning)

  return {
    session: publicSessionApi(session, { includeTombstone: true }),
    output,
    subscriberActive: statusAfterStart.active,
    subscriberLastExitedAt: statusAfterStart.lastExitedAt,
    subscriberErrors: subscriberManagerApi.stderr(session.id),
    warnings,
    cleanup,
  }
}

async function cleanupExitedPaneOnRead(
  sessionId: string,
  status: string,
  enabled: boolean,
  dependencies: {
    sessionManager: Pick<typeof sessionManager, 'get' | 'markTerminalPaneClosed'>
    subscriberManager: Pick<typeof subscriberManager, 'closeSessionPane'>
    paneExists: PaneExistsFn
  },
): Promise<ReadCleanupResult> {
  const requested = enabled && isCompletedSession(status)
  if (!requested)
    return { requested: false, performed: false, alreadyClosed: false }

  const session = dependencies.sessionManager.get(sessionId)
  if (session.tombstone?.paneClosedAt)
    return { requested: true, performed: false, alreadyClosed: true }

  const closeResult = await closePaneOrVerifyGone({
    paneId: session.paneId,
    closePane: () => dependencies.subscriberManager.closeSessionPane(sessionId, { throwOnFailure: true }),
    paneExists: dependencies.paneExists,
  })

  if (closeResult.cleanupReady) {
    dependencies.sessionManager.markTerminalPaneClosed(sessionId)
    return { requested: true, performed: true, alreadyClosed: closeResult.alreadyGone }
  }
  return {
    requested: true,
    performed: false,
    alreadyClosed: false,
    warning: `Completed pane cleanup failed: ${closeResult.closeErrorMessage ?? 'unknown error'}`,
  }
}

export const zellijPtyReadInput = z.object({
  id: z.string().describe('zellij-pty session id.'),
  maxLines: z.number().int().positive().max(5_000).optional().describe('Maximum recent output lines to return. Defaults to 200.'),
  grep: z.string().optional().describe('Regex used to filter returned lines.'),
  ignoreCase: z.boolean().optional().describe('Use case-insensitive regex matching.'),
  cleanupExitedPaneOnRead: z.boolean().optional().describe('Close completed panes after returning the final output. Defaults to true.'),
})

export function createZellijPtyReadTool(options: { defaultCleanupExitedPaneOnRead?: boolean | undefined } = {}): ZellijToolInfo {
  return {
    name: 'zellij_pty_read',
    description: 'Read recent rendered output from a Zellij PTY session. Supports regex grep filtering.',
    input: zellijPtyReadInput,
    async execute(args) {
      return {
        content: jsonResponse(await executeZellijPtyRead(args, {
          defaultCleanupExitedPaneOnRead: options.defaultCleanupExitedPaneOnRead,
        })),
      }
    },
  }
}

export const zellijPtyReadTool = createZellijPtyReadTool()

function isCompletedSession(status: string): boolean {
  return status === 'terminal' || status === 'exited' || status === 'killed'
}
