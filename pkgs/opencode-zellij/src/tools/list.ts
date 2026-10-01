import type { ZellijToolInfo } from './tool.js'
import { z } from 'zod'
import { sessionManager } from '../pty/manager.js'
import { subscriberManager } from '../zellij/subscribe.js'
import { completedPanesFromSessions, jsonResponse, publicSession } from './format.js'

export const zellijPtyListInput = z.object({})

export const zellijPtyListTool: ZellijToolInfo = {
  name: 'zellij_pty_list',
  description: 'List known Zellij pane-backed PTY sessions created by this plugin process for the current OpenCode session.',
  input: zellijPtyListInput,
  async execute(_args, context) {
    const sessionList = sessionManager.listByOpenCodeSession(context.sessionID)
    const sessions = sessionList.map(session => ({
      ...publicSession(session, { includeTombstone: true }),
      subscriber: subscriberManager.status(session.id),
    }))
    return {
      content: jsonResponse({
        sessions,
        ...completedPanesFromSessions(sessionList),
      }),
    }
  },
}
