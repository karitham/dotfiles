import type { SudoPaneFloatingSize, SudoPaneMode, SudoPaneModeKind } from '../config.js'
import type { ZellijToolInfo } from './tool.js'
import { zellijPtyKillTool } from './kill.js'
import { zellijPtyListTool } from './list.js'
import { createZellijPtyReadTool } from './read.js'
import { createRequestSudoTool } from './request-sudo.js'
import { createZellijPtySpawnTool } from './spawn.js'
import { zellijPtyWriteTool } from './write.js'

export interface ToolTableOptions {
  directory: string
  enabled: boolean
  cleanupExitedPaneOnRead: boolean
  sudoPane: SudoPaneMode
  sudoPaneMode: SudoPaneModeKind
  sudoPaneFloatingSize: SudoPaneFloatingSize
}

/** Builds the V2 tool definitions for this location. */
export function buildToolTable(options: ToolTableOptions): ZellijToolInfo[] {
  if (!options.enabled)
    return []

  const tools: ZellijToolInfo[] = [
    createZellijPtySpawnTool({ directory: options.directory }),
    zellijPtyListTool,
    zellijPtyWriteTool,
    createZellijPtyReadTool({ defaultCleanupExitedPaneOnRead: options.cleanupExitedPaneOnRead }),
    zellijPtyKillTool,
  ]

  if (options.sudoPane !== 'hide') {
    tools.push(createRequestSudoTool({
      mode: options.sudoPaneMode,
      floatingSize: options.sudoPaneFloatingSize,
      sudoAllowed: options.sudoPane === 'allow',
      directory: options.directory,
    }))
  }

  return tools
}
