export interface ReadLinesInput {
  offset?: number | undefined
  limit?: number | undefined
  grep?: string | undefined
  ignoreCase?: boolean | undefined
}

export interface ReadLinesResult {
  offset: number
  returned: number
  lineCount: number
  lines: string[]
}

const escapeCharacter = String.fromCharCode(27)
const ansiPattern = new RegExp(`${escapeCharacter}\\[[0-9;?]*[a-z]`, 'gi')

function normalizeLines(input: string | string[]): string[] {
  const lines = Array.isArray(input) ? input : input.replace(/\r\n/g, '\n').split('\n')
  if (lines.at(-1) === '')
    return lines.slice(0, -1)
  return lines
}

function stripAnsi(line: string): string {
  return line.replace(ansiPattern, '')
}

function overlapSize(existing: string[], incoming: string[]): number {
  const max = Math.min(existing.length, incoming.length)
  for (let size = max; size > 0; size -= 1) {
    const existingStart = existing.length - size
    let matches = true
    for (let index = 0; index < size; index += 1) {
      if (existing[existingStart + index] !== incoming[index]) {
        matches = false
        break
      }
    }
    if (matches)
      return size
  }
  return 0
}

export class RingBuffer {
  private readonly maxLines: number
  private lines: string[] = []
  private totalAppended = 0

  constructor(maxLines = 50_000) {
    this.maxLines = Math.max(1, maxLines)
  }

  get lineCount(): number {
    return this.totalAppended
  }

  get startOffset(): number {
    return Math.max(0, this.totalAppended - this.lines.length)
  }

  append(input: string | string[]): number {
    const incoming = normalizeLines(input)
    if (incoming.length === 0)
      return 0
    this.lines.push(...incoming)
    this.totalAppended += incoming.length
    this.trim()
    return incoming.length
  }

  appendSnapshot(input: string | string[]): number {
    const incoming = normalizeLines(input)
    if (incoming.length === 0)
      return 0
    const overlap = overlapSize(this.lines, incoming)
    return this.append(incoming.slice(overlap))
  }

  read(input: ReadLinesInput = {}): ReadLinesResult {
    const limit = Math.max(1, Math.min(input.limit ?? 200, 5_000))
    const firstReadableOffset = this.startOffset
    const defaultOffset = Math.max(firstReadableOffset, this.lineCount - limit)
    const requestedOffset = input.offset ?? defaultOffset
    const offset = Math.max(firstReadableOffset, Math.min(requestedOffset, this.lineCount))
    const relativeOffset = offset - firstReadableOffset
    const unfiltered = this.lines.slice(relativeOffset, relativeOffset + limit)
    const pattern = input.grep ? new RegExp(input.grep, input.ignoreCase ? 'i' : '') : undefined
    const lines = unfiltered
      .map(stripAnsi)
      .filter(line => (pattern ? pattern.test(line) : true))

    return {
      offset,
      returned: lines.length,
      lineCount: this.lineCount,
      lines,
    }
  }

  clear(): void {
    this.lines = []
    this.totalAppended = 0
  }

  private trim(): void {
    if (this.lines.length <= this.maxLines)
      return
    this.lines = this.lines.slice(this.lines.length - this.maxLines)
  }
}
