import { sessionManager } from '../pty/manager.js'
import { errorMessage } from '../utils/errors.js'
import { subscriberManager } from '../zellij/subscribe.js'

export interface OutputSnapshot {
  text: string
  lineCount: number
  truncated: boolean
  /**
   * Number of matched lines included in `text`. Only present when the snapshot
   * was produced with a `grep` filter.
   */
  matched?: number
}

export function emptyOutputSnapshot(lineCount = 0): OutputSnapshot {
  return { text: '', lineCount, truncated: false }
}

export interface OutputOptions {
  maxLines?: number | undefined
  grep?: string | undefined
  ignoreCase?: boolean | undefined
}

export function validateGrep(grep: string | undefined): string | null {
  if (!grep)
    return null
  try {
    new RegExp(grep).test('')
    return null
  }
  catch (error) {
    return errorMessage(error)
  }
}

export function readOutputSnapshot(sessionId: string, options: OutputOptions = {}): OutputSnapshot {
  const grepError = validateGrep(options.grep)
  if (grepError)
    throw new Error(`Invalid grep regex: ${grepError}`)

  const buffered = subscriberManager.read(sessionId, {
    limit: options.maxLines,
    grep: options.grep,
    ignoreCase: options.ignoreCase,
  })
  sessionManager.updateLineCount(sessionId, buffered.lineCount)

  const snapshot: OutputSnapshot = {
    text: buffered.lines.join('\n'),
    lineCount: buffered.lineCount,
    truncated: buffered.offset > 0,
  }
  if (options.grep !== undefined)
    snapshot.matched = buffered.returned
  return snapshot
}

export function outputMatches(sessionId: string, grep: string, ignoreCase?: boolean | undefined): boolean {
  return (readOutputSnapshot(sessionId, { maxLines: 5_000, grep, ignoreCase }).matched ?? 0) > 0
}
