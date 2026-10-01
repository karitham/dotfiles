import type { ZellijToolInfo } from './tool.js'
import { setTimeout as delay } from 'node:timers/promises'
import { z } from 'zod'
import { zellij } from '../lib/zellij/cli.js'
import { sessionManager } from '../pty/manager.js'
import { unregisterPaneFromWatchdog } from '../zellij/pane-watchdog.js'
import { subscriberManager } from '../zellij/subscribe.js'
import { jsonResponse, publicSession } from './format.js'
import { readOutputSnapshot } from './output.js'
import { closePaneOrVerifyGone } from './pane-cleanup.js'

export interface KillToolDependencies {
  zellij?: Pick<typeof zellij, 'sendCtrlC' | 'closePane' | 'paneExists'> | undefined
}

export interface KillToolResult {
  killed: boolean
  cleanedUp: boolean
  id?: string | undefined
  paneId?: string | undefined
  session?: ReturnType<typeof publicSession> | undefined
  output?: ReturnType<typeof readOutputSnapshot> | undefined
  warnings: string[]
}

export async function executeZellijPtyKill(args: { id: string }, dependencies: KillToolDependencies = {}): Promise<KillToolResult> {
  const zellijApi = dependencies.zellij ?? zellij
  const session = sessionManager.get(args.id)
  const warnings: string[] = []
  const output = subscriberManager.has(session.id) ? readOutputSnapshot(session.id) : undefined

  try {
    await zellijApi.sendCtrlC(session.paneId)
    await delay(500)
  }
  catch (error) {
    warnings.push(`Ctrl-C failed or pane was already gone: ${error instanceof Error ? error.message : String(error)}`)
  }

  const closeResult = await closePaneOrVerifyGone({
    paneId: session.paneId,
    closePane: () => zellijApi.closePane(session.paneId),
    paneExists: zellijApi.paneExists,
  })

  if (!closeResult.cleanupReady) {
    warnings.push(`close-pane failed: ${closeResult.closeErrorMessage ?? 'unknown error'}`)
    const updated = sessionManager.updateStatus(session.id, 'unknown')
    return {
      killed: false,
      cleanedUp: false,
      session: publicSession(updated),
      output,
      warnings,
    }
  }

  return finalizeKilledSession(session.id, session.paneId, output, warnings)
}

export const zellijPtyKillInput = z.object({
  id: z.string().describe('zellij-pty session id.'),
})

export const zellijPtyKillTool: ZellijToolInfo = {
  name: 'zellij_pty_kill',
  description: 'Terminate a known Zellij PTY session by sending Ctrl-C, then closing its pane.',
  input: zellijPtyKillInput,
  async execute(args) {
    return { content: jsonResponse(await executeZellijPtyKill(args)) }
  },
}

async function finalizeKilledSession(
  sessionId: string,
  paneId: string,
  output: ReturnType<typeof readOutputSnapshot> | undefined,
  warnings: string[],
): Promise<KillToolResult> {
  subscriberManager.stop(sessionId)
  subscriberManager.forget(sessionId)
  unregisterPaneFromWatchdog(sessionId)
  sessionManager.remove(sessionId)
  return {
    killed: true,
    cleanedUp: true,
    id: sessionId,
    paneId,
    output,
    warnings,
  }
}
