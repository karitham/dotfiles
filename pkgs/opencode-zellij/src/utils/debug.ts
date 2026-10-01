import process from 'node:process'

export function debug(message: string, ...details: unknown[]): void {
  if (!process.env.ZELLIJ_PTY_DEBUG)
    return

  console.warn(`[opencode-zellij] ${message}`, ...details)
}
