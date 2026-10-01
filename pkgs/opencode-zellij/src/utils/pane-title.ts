import { randomUUID } from 'node:crypto'

const generatedInstanceId = randomUUID().replaceAll('-', '').slice(0, 8)
const existingOpenCodePrefixPattern = /^oc:[a-z0-9]{4,16}:/i

export function createOpenCodePaneTitle(title: string, instanceId = generatedInstanceId): string {
  const trimmedTitle = title.trim() || 'opencode'
  if (existingOpenCodePrefixPattern.test(trimmedTitle))
    return trimmedTitle

  const safeInstanceId = instanceId.replace(/[^a-z0-9]/gi, '').slice(0, 8) || generatedInstanceId
  return `oc:${safeInstanceId}:${trimmedTitle}`
}
