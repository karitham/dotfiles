import type { Context, Plugin as PluginDefinition } from '@opencode/plugin/promise/plugin'
import type { CompletionNotificationContext, CompletionNotificationManager } from './zellij/completion-notifications.js'
import type { OpenCodeEventLike } from './zellij/tab-title-events.js'
import { define } from '@opencode/plugin/promise/plugin'
import { loadConfig } from './config.js'
import { sessionManager } from './pty/manager.js'
import { buildToolTable } from './tools/registry.js'
import { debug } from './utils/debug.js'
import { errorMessage } from './utils/errors.js'
import { SessionCompletionNotificationManager } from './zellij/completion-notifications.js'
import { cleanupStaleWatchdogRegistries, unregisterPaneFromWatchdog } from './zellij/pane-watchdog.js'
import { registerShutdownCleanup } from './zellij/shutdown-cleanup.js'
import { subscriberManager } from './zellij/subscribe.js'
import { normalizeTabTitleEvent } from './zellij/tab-title-events.js'
import { TabTitleActivityModel, TabTitleActor, TabTitleManager } from './zellij/tab-title.js'

const PLUGIN_ID = 'opencode-zellij'

async function cleanupStep(stepName: string, sessionId: string, step: () => void | Promise<void>): Promise<void> {
  try {
    await step()
  }
  catch (error) {
    debug(`session.deleted cleanup failed: ${stepName} for ${sessionId}`, errorMessage(error))
  }
}

async function cleanupDeletedSession(sessionId: string): Promise<void> {
  await cleanupStep('close pane', sessionId, () => subscriberManager.closeSessionPane(sessionId))
  await cleanupStep('forget subscriber', sessionId, () => subscriberManager.forget(sessionId))
  await cleanupStep('unregister watchdog', sessionId, () => unregisterPaneFromWatchdog(sessionId))
  await cleanupStep('remove session', sessionId, () => sessionManager.remove(sessionId))
}

export interface ZellijPtyPluginDependencies {
  /** Test seam: build the completion notification manager. */
  createCompletionNotifications?: ((context: CompletionNotificationContext) => CompletionNotificationManager | undefined) | undefined
}

/**
 * Builds the V2 plugin definition. Exported as a factory so tests can supply
 * dependencies; the module default is the production instance.
 */
export function createZellijPtyPlugin(dependencies: ZellijPtyPluginDependencies = {}): PluginDefinition {
  return define({
    id: PLUGIN_ID,
    async setup(ctx: Context) {
      const directory = ctx.location.directory
      const worktree = ctx.location.project.canonical

      const { config, warnings } = await loadConfig({ directory, worktree })
      for (const warning of warnings)
        debug(warning)

      cleanupStaleWatchdogRegistries()
      registerShutdownCleanup()

      const activityModel = config.tabTitle.enabled
        ? new TabTitleActivityModel({ worktreeDirectory: worktree })
        : undefined
      const actor = activityModel
        ? new TabTitleActor({ activity: activityModel })
        : undefined
      const tabTitleManager = config.tabTitle.enabled && actor
        ? new TabTitleManager({
            actor,
            debounceMs: config.tabTitle.debounceMs,
            emojis: {
              idle: config.tabTitle.emojiIdle,
              running: config.tabTitle.emojiRunning,
              needsInput: config.tabTitle.emojiNeedsInput,
            },
          })
        : undefined

      const notificationContext: CompletionNotificationContext = {
        prompt: (sessionID, text) => ctx.session.prompt({ sessionID, text }),
      }
      const completionNotifications = dependencies.createCompletionNotifications?.(notificationContext)
        ?? new SessionCompletionNotificationManager(notificationContext)
      subscriberManager.setLifecycleHooks({
        onSessionTerminal: event => void completionNotifications.handleSessionTerminal(event)
          .catch(error => debug('completion notification lifecycle hook failed', errorMessage(error))),
      })

      // Best-effort initial render; no-op when not inside a real Zellij pane.
      tabTitleManager?.renderImmediate()
        .catch(error => debug('initial tab title render failed', errorMessage(error)))

      const tools = buildToolTable({
        directory,
        enabled: config.pty.enabled,
        cleanupExitedPaneOnRead: config.pty.cleanupExitedPaneOnRead,
        sudoPane: config.pty.sudoPane,
        sudoPaneMode: config.pty.sudoPaneMode,
        sudoPaneFloatingSize: config.pty.sudoPaneFloatingSize,
      })
      await ctx.tool.transform((editor) => {
        for (const tool of tools)
          editor.add(tool)
      })

      const controller = new AbortController()
      void (async () => {
        for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
          await handleEvent(event as OpenCodeEventLike)
        }
      })().catch((error) => {
        if (!controller.signal.aborted)
          debug('event subscription failed', errorMessage(error))
      })

      async function handleEvent(event: OpenCodeEventLike): Promise<void> {
        const normalized = normalizeTabTitleEvent(event)

        if (actor && tabTitleManager) {
          for (const tabEvent of normalized)
            actor.handleEvent(tabEvent)
          tabTitleManager.scheduleUpdate()
        }

        if (event.type === 'location.shutdown')
          dispose()

        for (const tabEvent of normalized) {
          if (tabEvent.type !== 'session-deleted')
            continue
          // The event carries the OpenCode session id; panes are keyed by
          // their own plugin session id, so map through the OpenCode id.
          const panes = sessionManager.listByOpenCodeSession(tabEvent.sessionID)
          await Promise.all(panes.map(session => cleanupDeletedSession(session.id)))
        }
      }

      function dispose(): void {
        completionNotifications.dispose()
        subscriberManager.setLifecycleHooks(undefined)
      }

      return () => {
        controller.abort()
        dispose()
        void tabTitleManager?.destroy()
      }
    },
  })
}

export default createZellijPtyPlugin()
