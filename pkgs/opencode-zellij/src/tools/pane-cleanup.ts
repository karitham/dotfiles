export type PaneExistsFn = (paneId: string) => Promise<boolean | undefined> | boolean | undefined

export interface ClosePaneOrVerifyGoneInput {
  paneId: string
  closePane: () => Promise<void>
  paneExists?: PaneExistsFn | undefined
}

export interface ClosePaneOrVerifyGoneResult {
  cleanupReady: boolean
  alreadyGone: boolean
  closeErrorMessage?: string | undefined
}

export async function closePaneOrVerifyGone(input: ClosePaneOrVerifyGoneInput): Promise<ClosePaneOrVerifyGoneResult> {
  try {
    await input.closePane()
    return { cleanupReady: true, alreadyGone: false }
  }
  catch (error) {
    const closeErrorMessage = error instanceof Error ? error.message : String(error)
    const paneGone = await isPaneGone(input.paneId, input.paneExists)
    if (paneGone)
      return { cleanupReady: true, alreadyGone: true, closeErrorMessage }
    return { cleanupReady: false, alreadyGone: false, closeErrorMessage }
  }
}

async function isPaneGone(paneId: string, paneExists?: PaneExistsFn | undefined): Promise<boolean> {
  if (!paneExists)
    return false

  try {
    return (await paneExists(paneId)) === false
  }
  catch {
    return false
  }
}
