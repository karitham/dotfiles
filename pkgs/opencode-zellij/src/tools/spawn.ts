import type { Probe } from '../pty/probe.js'
import type { ZellijToolInfo } from './tool.js'
import process from 'node:process'
import { z } from 'zod'
import { zellij } from '../lib/zellij/cli.js'
import { sessionManager } from '../pty/manager.js'
import { runProbe } from '../pty/probe.js'
import { createExitCodeToken } from '../utils/exit-code.js'
import { createOpenCodePaneTitle } from '../utils/pane-title.js'
import { registerPaneForWatchdog } from '../zellij/pane-watchdog.js'
import { subscriberManager } from '../zellij/subscribe.js'
import { completedPanesFromSessions, jsonResponse, publicSession } from './format.js'
import { outputMatches, readOutputSnapshot, validateGrep } from './output.js'

export const zellijPtySpawnInput = z.object({
  command: z.string().describe('Command to run. Without args, it is executed through bash -lc.'),
  args: z.array(z.string()).optional().describe('Optional argv. When provided, command is executed directly without shell parsing.'),
  cwd: z.string().optional().describe('Working directory for the new pane.'),
  title: z.string().optional().describe('Pane title/name.'),
  probe: z.discriminatedUnion('type', [
    z.object({
      type: z.literal('sleep'),
      seconds: z.number().positive().max(300).optional().describe('Seconds to wait before returning initial output. Defaults to 1.'),
    }),
    z.object({
      type: z.literal('http'),
      url: z.string().url().describe('HTTP URL to poll until it returns the expected status.'),
      expectStatus: z.number().int().min(100).max(599).optional().describe('Expected HTTP status. Defaults to any 2xx/3xx response.'),
      timeoutSeconds: z.number().positive().max(300).optional().describe('How long to poll before returning a failed probe result. Defaults to 20.'),
    }),
    z.object({
      type: z.literal('output'),
      grep: z.string().describe('Regex to search for in observed pane output.'),
      ignoreCase: z.boolean().optional().describe('Use case-insensitive regex matching.'),
      timeoutSeconds: z.number().positive().max(300).optional().describe('How long to wait for matching output. Defaults to 20.'),
    }),
  ]).optional().describe('Optional readiness probe. Defaults to a short sleep before returning output.'),
  maxLines: z.number().int().positive().max(5_000).optional().describe('Maximum recent output lines to return. Defaults to 200.'),
})

export type ZellijPtySpawnArgs = z.infer<typeof zellijPtySpawnInput>

export interface SpawnContext {
  sessionID: string
}

export async function executeZellijPtySpawn(args: ZellijPtySpawnArgs, context: SpawnContext, directory: string): Promise<unknown> {
  const cwd = args.cwd ?? directory
  const exitCodeToken = createExitCodeToken()
  const grepError = args.probe?.type === 'output' ? validateGrep(args.probe.grep) : null
  if (grepError)
    throw new Error(`Invalid probe.grep regex: ${grepError}`)
  const title = createOpenCodePaneTitle(args.title ?? args.command)

  const paneId = await zellij.newPane({
    command: args.command,
    args: args.args,
    cwd,
    title,
    floating: false,
    exitCodeToken,
  })

  const session = sessionManager.create({
    openCodeSessionId: context.sessionID,
    paneId,
    title,
    command: args.command,
    args: args.args,
    cwd,
    allowAgentInput: true,
    humanInputOnly: false,
    exitCodeToken,
  })
  registerPaneForWatchdog(session)
  await subscriberManager.start(session)
  const probe = await runProbe(args.probe as Probe | undefined, (grep, ignoreCase) => outputMatches(session.id, grep, ignoreCase))
  const output = readOutputSnapshot(session.id, { maxLines: args.maxLines })
  const completedPanes = completedPanesFromSessions(
    sessionManager.listByOpenCodeSession(context.sessionID),
  )

  return {
    session: publicSession(session),
    output,
    probe,
    ...completedPanes,
  }
}

export function createZellijPtySpawnTool(options: { directory: string }): ZellijToolInfo {
  return {
    name: 'zellij_pty_spawn',
    description: 'Create a visible Zellij pane and run a command in it.',
    input: zellijPtySpawnInput,
    async execute(args, context) {
      return { content: jsonResponse(await executeZellijPtySpawn(args, context, options.directory)) }
    },
  }
}

export const zellijPtySpawnTool = createZellijPtySpawnTool({ directory: process.cwd() })
