import type { ZellijToolInfo } from './tool.js'
import process from 'node:process'
import { z } from 'zod'
import { zellij } from '../lib/zellij/cli.js'
import { sessionManager } from '../pty/manager.js'
import { createExitCodeToken } from '../utils/exit-code.js'
import { createOpenCodePaneTitle } from '../utils/pane-title.js'
import { registerPaneForWatchdog } from '../zellij/pane-watchdog.js'
import { subscriberManager } from '../zellij/subscribe.js'
import { jsonResponse, publicSession } from './format.js'
import { readOutputSnapshot } from './output.js'

export function shellQuote(value: string): string {
  return `'${value.replaceAll('\'', `'"'"'`)}'`
}

export function buildReviewScript(summary: string, scripts: Array<{ command: string, description: string }>): string {
  const lines = [
    'set +e',
    'printf \'%s\\n\' \'=== OpenCode sudo request ===\'',
    `printf '%s\\n' ${shellQuote(summary)}`,
    'printf \'\\n%s\\n\' \'Commands to review:\'',
  ]

  scripts.forEach((script, index) => {
    const number = index + 1
    lines.push(`printf '\\n[%s/%s] %s\\n' ${shellQuote(String(number))} ${shellQuote(String(scripts.length))} ${shellQuote(script.description)}`)
    lines.push(`printf '  $ %s\\n' ${shellQuote(script.command)}`)
  })

  // 3s countdown before the confirmation prompt. We use carriage return
  // (`\r`) to overwrite the same line so the number ticks down (3 → 2 → 1)
  // instead of stacking three separate lines. This gives the user time to
  // read the summary and focus the floating pane before they decide.
  lines.push(
    'printf \'\\n%s\\n\' \'This pane is human-input-only. The agent cannot type here.\'',
    'printf \'Waiting 3s to prevent accidental confirmation: 3\\r\'',
    'sleep 1',
    'printf \'Waiting 3s to prevent accidental confirmation: 2\\r\'',
    'sleep 1',
    'printf \'Waiting 3s to prevent accidental confirmation: 1\\r\'',
    'sleep 1',
    'while true; do',
    '  printf \'\\n%s\' \'[y/n]: \'',
    '  read -r answer',
    // [y/n] convention with strict input: only `y`/`Y` approves, only
    // `n`/`N` cancels. Anything else (empty Enter, stray key, gibberish)
    // loops back to the prompt with feedback. This forces the user to make
    // an explicit, deliberate choice — empty Enter from a fast double-tap
    // or an accidental keypress must not silently cancel the request.
    '  case "$answer" in',
    '    [Yy]) break ;;',
    '    [Nn]) printf \'%s\\n\' \'Cancelled by user.\'; exit 130 ;;',
    '    "") printf \'%s\\n\' \'Empty input. Please type y or n explicitly.\' ;;',
    '    *) printf \'%s\\n\' "Please type y or n (got: $answer)." ;;',
    '  esac',
    'done',
    'status=0',
  )

  scripts.forEach((script, index) => {
    const number = index + 1
    lines.push(`printf '\\n[%s/%s] %s\\n' ${shellQuote(String(number))} ${shellQuote(String(scripts.length))} ${shellQuote(script.description)}`)
    lines.push(`printf '$ %s\\n' ${shellQuote(script.command)}`)
    lines.push(`bash -lc ${shellQuote(script.command)}`)
    lines.push('code=$?')
    lines.push('if [ $code -ne 0 ]; then status=$code; printf \'Command failed with exit code %s\\n\' "$code"; break; fi')
  })

  lines.push('exit $status')
  return lines.join('\n')
}

export interface RequestSudoToolOptions {
  mode: 'floating' | 'fullscreen'
  floatingSize: { width: string, height: string, pinned: boolean }
  /**
   * Carried by the tool definition rather than a module-level flag so the
   * `deny` behavior travels with the tool the plugin registered.
   */
  sudoAllowed: boolean
  /** Working directory for the review pane; defaults to the plugin location. */
  directory: string
}

export const DEFAULT_REQUEST_SUDO_TOOL_OPTIONS: RequestSudoToolOptions = {
  mode: 'floating',
  floatingSize: { width: '80%', height: '60%', pinned: true },
  sudoAllowed: true,
  directory: process.cwd(),
}

export function buildPaneTitle(summary: string): string {
  const trimmed = summary.trim().replace(/\s+/g, ' ')
  const limited = trimmed.length > 60 ? `${trimmed.slice(0, 57)}...` : trimmed
  return `⚠ sudo: ${limited}`
}

export const requestSudoInput = z.object({
  summary: z.string().min(1).describe('TL;DR of why privileged or human-reviewed execution is needed.'),
  scripts: z
    .array(
      z.object({
        command: z.string().min(1).describe('Command or script to run after the user explicitly approves in the pane.'),
        description: z.string().min(1).describe('Why this command is needed and what it is expected to change.'),
      }),
    )
    .min(1)
    .describe('Commands shown to the user for review before execution.'),
})

export function createRequestSudoTool(options: RequestSudoToolOptions = DEFAULT_REQUEST_SUDO_TOOL_OPTIONS): ZellijToolInfo {
  const isFloating = options.mode === 'floating'
  return {
    name: 'zellij_pty_request_sudo',
    description: 'Open a human-reviewed, human-input-only Zellij pane for sudo or other privileged commands.',
    input: requestSudoInput,
    async execute(args, context) {
      if (!options.sudoAllowed)
        throw new Error('sudo pane is disabled by zellij-pty config.')

      const cwd = options.directory
      const exitCodeToken = createExitCodeToken()

      const command = buildReviewScript(args.summary, args.scripts)
      const title = createOpenCodePaneTitle(buildPaneTitle(args.summary))
      const paneId = await zellij.newPane({
        command: 'bash',
        args: ['-lc', command],
        cwd,
        title,
        floating: isFloating,
        floatingWidth: isFloating ? options.floatingSize.width : undefined,
        floatingHeight: isFloating ? options.floatingSize.height : undefined,
        floatingPinned: isFloating ? options.floatingSize.pinned : undefined,
        // The sudo request is single-shot: when bash exits (YES ran the
        // commands, or the user rejected), Zellij closes the pane so the
        // user isn't left looking at a dead terminal with stale output.
        closeOnExit: true,
        exitCodeToken,
      })

      const session = sessionManager.create({
        openCodeSessionId: context.sessionID,
        paneId,
        title,
        command: 'zellij_pty_request_sudo',
        args: [],
        cwd,
        allowAgentInput: false,
        humanInputOnly: true,
        exitCodeToken,
      })
      registerPaneForWatchdog(session)
      await subscriberManager.start(session)

      return {
        content: jsonResponse({
          session: publicSession(session, { agentWritable: false }),
          output: readOutputSnapshot(session.id),
        }),
      }
    },
  }
}

export const requestSudoTool = createRequestSudoTool()
