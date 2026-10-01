import { randomUUID } from 'node:crypto'

export function createSessionId(): string {
  return `zpty_${randomUUID().replaceAll('-', '').slice(0, 10)}`
}
