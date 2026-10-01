import { Buffer } from 'node:buffer'
import process from 'node:process'

const defaultMaxWriteBytes = 64 * 1024
const defaultChunkBytes = 8 * 1024

export function maxWriteBytes(): number {
  const configured = Number(process.env.ZELLIJ_PTY_MAX_WRITE_BYTES ?? defaultMaxWriteBytes)
  return Number.isFinite(configured) && configured > 0 ? configured : defaultMaxWriteBytes
}

export function assertWriteSizeAllowed(data: string): void {
  const bytes = Buffer.byteLength(data, 'utf8')
  const maxBytes = maxWriteBytes()
  if (bytes > maxBytes) {
    throw new Error(`Write payload is too large: ${bytes} bytes exceeds ${maxBytes} bytes. Split the input into smaller writes.`)
  }
}

export function chunkWriteData(data: string, maxChunkBytes = defaultChunkBytes): string[] {
  const chunks: string[] = []
  let current = ''
  let currentBytes = 0

  for (const character of data) {
    const characterBytes = Buffer.byteLength(character, 'utf8')
    if (current && currentBytes + characterBytes > maxChunkBytes) {
      chunks.push(current)
      current = ''
      currentBytes = 0
    }
    current += character
    currentBytes += characterBytes
  }

  if (current)
    chunks.push(current)
  return chunks
}
