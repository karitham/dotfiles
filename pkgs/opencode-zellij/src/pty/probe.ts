import { setTimeout as delay } from 'node:timers/promises'

export type Probe
  = | { type: 'sleep', seconds?: number | undefined }
    | { type: 'http', url: string, expectStatus?: number | undefined, timeoutSeconds?: number | undefined }
    | { type: 'output', grep: string, ignoreCase?: boolean | undefined, timeoutSeconds?: number | undefined }

export interface ProbeResult {
  type: Probe['type']
  ok: boolean
  message: string
}

export type OutputProbeReader = (grep: string, ignoreCase: boolean | undefined) => boolean

const defaultSleepSeconds = 1
const defaultProbeTimeoutSeconds = 20
const pollIntervalMs = 250

export async function runProbe(probe: Probe | undefined, outputReader: OutputProbeReader): Promise<ProbeResult> {
  const effectiveProbe = probe ?? { type: 'sleep', seconds: defaultSleepSeconds }

  if (effectiveProbe.type === 'sleep') {
    const seconds = effectiveProbe.seconds ?? defaultSleepSeconds
    await delay(seconds * 1_000)
    return result(effectiveProbe.type, true, `Slept for ${seconds}s.`)
  }

  if (effectiveProbe.type === 'output') {
    const timeoutSeconds = effectiveProbe.timeoutSeconds ?? defaultProbeTimeoutSeconds
    const deadline = Date.now() + timeoutSeconds * 1_000
    while (Date.now() <= deadline) {
      if (outputReader(effectiveProbe.grep, effectiveProbe.ignoreCase)) {
        return result(effectiveProbe.type, true, `Observed output matching /${effectiveProbe.grep}/.`)
      }
      await delay(pollIntervalMs)
    }
    return result(effectiveProbe.type, false, `Timed out after ${timeoutSeconds}s waiting for output matching /${effectiveProbe.grep}/.`)
  }

  const timeoutSeconds = effectiveProbe.timeoutSeconds ?? defaultProbeTimeoutSeconds
  const deadline = Date.now() + timeoutSeconds * 1_000
  const expectStatus = effectiveProbe.expectStatus
  let lastError = 'no response'

  while (Date.now() <= deadline) {
    try {
      const remainingMs = Math.max(1, deadline - Date.now())
      const response = await fetch(effectiveProbe.url, { signal: AbortSignal.timeout(Math.min(remainingMs, 3_000)) })
      const ok = expectStatus === undefined ? response.status >= 200 && response.status < 400 : response.status === expectStatus
      if (ok) {
        const expected = expectStatus === undefined ? '2xx/3xx' : String(expectStatus)
        return result(effectiveProbe.type, true, `HTTP probe ${effectiveProbe.url} returned expected status ${expected}.`)
      }
      lastError = `HTTP ${response.status}`
    }
    catch (error) {
      lastError = error instanceof Error ? error.message : String(error)
    }
    await delay(pollIntervalMs)
  }

  return result(effectiveProbe.type, false, `Timed out after ${timeoutSeconds}s probing ${effectiveProbe.url}: ${lastError}.`)
}

function result(type: Probe['type'], ok: boolean, message: string): ProbeResult {
  return { type, ok, message }
}
