import type { TabTitleEvent } from './tab-title-events.js'
import process from 'node:process'
import { createZellijClient } from '../lib/zellij/cli.js'
import { debug } from '../utils/debug.js'
import { errorMessage } from '../utils/errors.js'

export interface TabTitleCli {
  renameTab: (title: string) => Promise<void>
  currentTabTitle: () => Promise<string | undefined>
}

export type TabTitleStatus = 'idle' | 'running' | 'needs-input'

export interface TabTitleEmojis {
  idle: string
  running: string
  needsInput: string
}

export const defaultTabTitleEmojis: TabTitleEmojis = {
  idle: '🟢',
  running: '⚡',
  needsInput: '💬',
}

export interface TitleContext {
  status: TabTitleStatus
  emojis: TabTitleEmojis
}

export function formatTabTitle(context: TitleContext): string {
  return context.emojis[context.status === 'needs-input' ? 'needsInput' : context.status]
}

export function sanitizeTitle(title: string, maxLength = 90): string {
  let cleaned = title
    .replace(/[\p{Cc}\p{Cf}\p{Co}\p{Cn}]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim()

  const chars = Array.from(cleaned)
  if (chars.length > maxLength) {
    cleaned = `${chars.slice(0, maxLength - 1).join('')}…`
  }

  return cleaned
}

interface SessionRecord {
  directory: string | undefined
  parentID: string | undefined
}

export class TabTitleActivityModel {
  status: 'idle' | 'running' | 'needs-input' = 'idle'
  private worktreeDirectory: string
  private sessions = new Map<string, SessionRecord>()
  private scopedSessions = new Set<string>()
  private runningSessions = new Set<string>()
  private pendingInputs = new Map<string, string>()

  constructor(options: { worktreeDirectory: string }) {
    this.worktreeDirectory = options.worktreeDirectory
  }

  getSession(sessionID: string): SessionRecord | undefined {
    return this.scopedSessions.has(sessionID) ? this.sessions.get(sessionID) : undefined
  }

  hasPendingInput(sessionID: string, requestID: string): boolean {
    return this.pendingInputs.has(`${sessionID}:${requestID}`)
  }

  handleEvent(event: TabTitleEvent): void {
    switch (event.type) {
      case 'session-created':
        this.storeSession(event.sessionID, event.directory, event.parentID)
        break
      case 'session-running':
        if (this.scopedSessions.has(event.sessionID)) {
          this.runningSessions.add(event.sessionID)
          this.updateStatus()
        }
        break
      case 'session-idle':
        if (this.runningSessions.delete(event.sessionID))
          this.updateStatus()
        break
      case 'input-asked':
        if (this.scopedSessions.has(event.sessionID)) {
          this.pendingInputs.set(`${event.sessionID}:${event.id}`, event.sessionID)
          this.runningSessions.add(event.sessionID)
          this.updateStatus()
        }
        break
      case 'input-resolved':
        this.pendingInputs.delete(`${event.sessionID}:${event.id}`)
        this.updateStatus()
        break
      case 'session-deleted':
        this.removeSessionAndDescendants(event.sessionID)
        this.updateStatus()
        break
    }
  }

  private storeSession(id: string, directory: string | undefined, parentID: string | undefined): void {
    this.sessions.set(id, { directory, parentID })

    const isDirectlyScoped = directory === this.worktreeDirectory
    const isDescendantScoped = parentID ? this.scopedSessions.has(parentID) : false
    const isKnown = this.scopedSessions.has(id)

    if (isKnown || isDirectlyScoped || isDescendantScoped)
      this.scopedSessions.add(id)
  }

  private removeSessionAndDescendants(rootID: string): void {
    const toRemove = new Set<string>()
    toRemove.add(rootID)

    let changed = true
    while (changed) {
      changed = false
      for (const [id, session] of this.sessions) {
        if (!toRemove.has(id) && session.parentID && toRemove.has(session.parentID)) {
          toRemove.add(id)
          changed = true
        }
      }
    }

    for (const id of toRemove) {
      this.sessions.delete(id)
      this.scopedSessions.delete(id)
      this.runningSessions.delete(id)
    }

    for (const [key, sessionID] of [...this.pendingInputs.entries()]) {
      if (toRemove.has(sessionID))
        this.pendingInputs.delete(key)
    }
  }

  private updateStatus(): void {
    if (this.pendingInputs.size > 0)
      this.status = 'needs-input'
    else if (this.runningSessions.size > 0)
      this.status = 'running'
    else
      this.status = 'idle'
  }
}

export class TabTitleActor {
  private activity: TabTitleActivityModel
  private emojis: TabTitleEmojis

  constructor(options: {
    activity: TabTitleActivityModel
    emojis?: Partial<TabTitleEmojis> | undefined
  }) {
    this.activity = options.activity
    this.emojis = { ...defaultTabTitleEmojis, ...options.emojis }
  }

  get context() {
    return {
      status: this.activity.status,
    }
  }

  get title(): string {
    return formatTabTitle({
      ...this.context,
      emojis: this.emojis,
    })
  }

  handleEvent(event: TabTitleEvent): void {
    this.activity.handleEvent(event)
  }
}

export interface TabTitleManagerOptions {
  cli?: TabTitleCli
  emojis?: Partial<TabTitleEmojis> | undefined
  debounceMs?: number
  retryInitialMs?: number
  retryMaxMs?: number
  actor: TabTitleActor
}

export class TabTitleManager {
  private lastDesiredStatus: TabTitleStatus | undefined
  private lastSyncedTitle: string | undefined
  private syncGeneration = 0
  private debounceTimer: ReturnType<typeof setTimeout> | undefined
  private retryTimer: ReturnType<typeof setTimeout> | undefined
  private retryAttempt = 0
  private syncInFlight = false
  private syncPromise: Promise<void> | undefined
  private readonly debounceMs: number
  private readonly retryInitialMs: number
  private readonly retryMaxMs: number
  private readonly cli: TabTitleCli
  private readonly emojis: TabTitleEmojis
  private readonly enabled: boolean
  private destroyed = false
  private destroyPromise: Promise<void> | undefined
  private readonly actor: TabTitleActor

  constructor(options: TabTitleManagerOptions) {
    this.cli = options.cli ?? createZellijClient()
    this.emojis = { ...defaultTabTitleEmojis, ...options.emojis }
    this.debounceMs = options.debounceMs ?? 300
    this.retryInitialMs = options.retryInitialMs ?? 250
    this.retryMaxMs = options.retryMaxMs ?? 5_000
    this.enabled = Boolean(process.env.ZELLIJ || process.env.ZELLIJ_SESSION_NAME)
    this.actor = options.actor
  }

  private buildTitle(): string {
    return sanitizeTitle(formatTabTitle({
      ...this.actor.context,
      emojis: this.emojis,
    }))
  }

  /**
   * Compose a full tab title by appending or replacing the status emoji
   * at the end of the current title.
   */
  private composeTitle(current: string | undefined, newEmoji: string, allEmojis: string[]): string {
    if (!current)
      return newEmoji
    // Whole title is exactly a known status emoji (e.g. from a previous version)
    if (allEmojis.includes(current))
      return newEmoji
    // Ends with " emoji" → replace the trailing emoji
    for (const emoji of allEmojis) {
      if (current.endsWith(` ${emoji}`))
        return `${current.slice(0, current.length - emoji.length - 1)} ${newEmoji}`
    }
    // No known emoji at the end → append
    return `${current} ${newEmoji}`
  }

  private get statusEmojis(): string[] {
    return [this.emojis.idle, this.emojis.running, this.emojis.needsInput]
  }

  getCurrentTitle(): string {
    return this.buildTitle()
  }

  private async readCurrentTitle(): Promise<string | undefined> {
    try {
      return await this.cli.currentTabTitle()
    }
    catch (error) {
      debug('Failed to read current tab title', errorMessage(error))
      return undefined
    }
  }

  async renderImmediate(): Promise<void> {
    if (!this.enabled || this.destroyed)
      return
    this.lastDesiredStatus = undefined
    this.clearDebounceTimer()
    await this.syncDesiredTitle()
  }

  scheduleUpdate(): void {
    if (!this.enabled || this.destroyed)
      return
    const status = this.actor.context.status
    if (status === this.lastDesiredStatus && this.lastSyncedTitle !== undefined)
      return
    this.lastDesiredStatus = status

    this.clearRetryTimer()
    this.clearDebounceTimer()
    this.debounceTimer = setTimeout(() => {
      this.debounceTimer = undefined
      this.syncDesiredTitle()
        .catch(error => debug('debounced tab title sync failed', errorMessage(error)))
    }, this.debounceMs)
    this.unrefTimer(this.debounceTimer)
  }

  private async syncDesiredTitle(): Promise<void> {
    if (!this.enabled || this.destroyed)
      return
    const generation = this.syncGeneration
    if (this.destroyed || generation !== this.syncGeneration)
      return
    if (this.syncInFlight)
      return this.syncPromise

    this.syncInFlight = true
    this.syncPromise = this.runTitleSync(generation)
    return this.syncPromise
  }

  private async runTitleSync(generation: number): Promise<void> {
    try {
      while (generation === this.syncGeneration) {
        const currentTitle = await this.readCurrentTitle()
        // Reading current title failed; skip this sync to avoid destructive overwrite
        if (currentTitle === undefined)
          break

        const newEmoji = this.buildTitle()
        const composed = sanitizeTitle(this.composeTitle(currentTitle, newEmoji, this.statusEmojis))

        if (composed === this.lastSyncedTitle)
          break

        try {
          await this.cli.renameTab(composed)
          if (generation !== this.syncGeneration || this.destroyed)
            return
          this.lastSyncedTitle = composed
          this.retryAttempt = 0
          this.clearRetryTimer()
        }
        catch (cause) {
          debug('Failed to rename Zellij tab.', cause)
          if (generation !== this.syncGeneration || this.destroyed)
            break
          this.scheduleRetry()
          break
        }
      }
    }
    finally {
      this.syncInFlight = false
      this.syncPromise = undefined
    }
  }

  private scheduleRetry(): void {
    if (!this.enabled || this.destroyed || this.retryTimer)
      return

    const delay = Math.min(this.retryMaxMs, this.retryInitialMs * 2 ** this.retryAttempt)
    this.retryAttempt += 1
    this.retryTimer = setTimeout(() => {
      this.retryTimer = undefined
      this.syncDesiredTitle()
        .catch(error => debug('retry tab title sync failed', errorMessage(error)))
    }, delay)
    this.unrefTimer(this.retryTimer)
  }

  private clearRetryTimer(): void {
    if (this.retryTimer)
      clearTimeout(this.retryTimer)
    this.retryTimer = undefined
  }

  private unrefTimer(timer: ReturnType<typeof setTimeout>): void {
    if (typeof timer === 'object' && timer && 'unref' in timer && typeof timer.unref === 'function')
      timer.unref()
  }

  private clearDebounceTimer(): void {
    if (this.debounceTimer)
      clearTimeout(this.debounceTimer)
    this.debounceTimer = undefined
  }

  // No-op. Previously this method captured the tab title and restored it
  // on destroy, but in practice the opencode plugin lifecycle never
  // dispatches a reliable "session ended" event in any mode (TUI
  // worker shutdown, `opencode run` headless, or `opencode run --interactive`
  // all exit without firing `server.instance.disposed` / `global.disposed`).
  // `process.once('exit')` only supports sync callbacks so it cannot drive
  // the async Zellij rename, and SIGKILL cannot be intercepted at all.
  // The remaining work is to clear timers so a straggler sync cannot race
  // the process exit; the tab title we set is simply left in place.
  destroy(): Promise<void> {
    if (this.destroyed)
      return this.destroyPromise ?? Promise.resolve()
    this.destroyed = true
    this.syncGeneration += 1
    this.clearDebounceTimer()
    this.clearRetryTimer()
    return Promise.resolve()
  }
}
