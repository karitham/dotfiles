/**
 * Normalizes OpenCode V2 events into the small internal vocabulary the tab
 * title activity model consumes. This is the only module that knows both
 * shapes, so V2 payload changes stop here.
 *
 * V2 payloads live under `event.data` (V1 used `event.properties`).
 */
export type TabTitleEvent
  = | { type: 'session-created', sessionID: string, directory: string | undefined, parentID: string | undefined }
    | { type: 'session-running', sessionID: string }
    | { type: 'session-idle', sessionID: string }
    | { type: 'input-asked', sessionID: string, id: string }
    | { type: 'input-resolved', sessionID: string, id: string }
    | { type: 'session-deleted', sessionID: string }

/** Structural subset of `V2Event`; avoids importing the generated client type. */
export interface OpenCodeEventLike {
  type: string
  data?: unknown
  location?: { directory?: string } | undefined
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
  return isRecord(value) ? value : undefined
}

function stringField(object: Record<string, unknown> | undefined, key: string): string | undefined {
  const value = object?.[key]
  return typeof value === 'string' ? value : undefined
}

function sessionIDOf(event: OpenCodeEventLike): string | undefined {
  return stringField(asRecord(event.data), 'sessionID')
}

export function normalizeTabTitleEvent(event: OpenCodeEventLike): TabTitleEvent[] {
  const data = asRecord(event.data)

  switch (event.type) {
    case 'session.created': {
      const sessionID = stringField(data, 'sessionID')
      if (!sessionID)
        return []
      const directory = stringField(asRecord(data?.location), 'directory')
        ?? stringField(asRecord(event.location), 'directory')
      return [{ type: 'session-created', sessionID, directory, parentID: stringField(data, 'parentID') }]
    }

    case 'session.status': {
      const sessionID = stringField(data, 'sessionID')
      const status = stringField(asRecord(data?.status), 'type')
      if (!sessionID)
        return []
      if (status === 'idle')
        return [{ type: 'session-idle', sessionID }]
      if (status === 'busy' || status === 'retry')
        return [{ type: 'session-running', sessionID }]
      return []
    }

    case 'session.idle':
    case 'session.execution.failed': {
      const sessionID = sessionIDOf(event)
      return sessionID ? [{ type: 'session-idle', sessionID }] : []
    }

    case 'session.deleted': {
      const sessionID = sessionIDOf(event)
      return sessionID ? [{ type: 'session-deleted', sessionID }] : []
    }

    case 'permission.asked': {
      const sessionID = stringField(data, 'sessionID')
      const id = stringField(data, 'id')
      return sessionID && id ? [{ type: 'input-asked', sessionID, id }] : []
    }

    case 'permission.replied': {
      const sessionID = stringField(data, 'sessionID')
      const id = stringField(data, 'requestID')
      return sessionID && id ? [{ type: 'input-resolved', sessionID, id }] : []
    }

    case 'form.created': {
      const form = asRecord(asRecord(data?.form))
      const sessionID = stringField(form, 'sessionID')
      const id = stringField(form, 'id')
      return sessionID && id ? [{ type: 'input-asked', sessionID, id }] : []
    }

    case 'form.replied':
    case 'form.cancelled': {
      const sessionID = stringField(data, 'sessionID')
      const id = stringField(data, 'id')
      return sessionID && id ? [{ type: 'input-resolved', sessionID, id }] : []
    }

    default:
      return []
  }
}
