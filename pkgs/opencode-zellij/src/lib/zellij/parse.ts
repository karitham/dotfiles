import { debug } from '../../utils/debug.js'
import { errorMessage } from '../../utils/errors.js'
import { normalizePaneId } from './pane.js'

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

function numericProperty(object: Record<string, unknown>, keys: string[]): number | undefined {
  for (const key of keys) {
    const value = object[key]
    if (typeof value === 'number' && Number.isFinite(value))
      return value
    if (typeof value === 'string') {
      const parsed = Number(value)
      if (Number.isInteger(parsed))
        return parsed
    }
  }
  return undefined
}

function stringProperty(object: Record<string, unknown>, keys: string[]): string | undefined {
  for (const key of keys) {
    const value = object[key]
    if (typeof value === 'string')
      return value
  }
  return undefined
}

// ---------------------------------------------------------------------------
// Pane → tab resolution
// ---------------------------------------------------------------------------

function paneMatches(object: Record<string, unknown>, paneId: number): boolean {
  const candidate = numericProperty(object, ['id', 'pane_id', 'paneId'])
  return candidate === paneId && object.is_plugin !== true
}

function findPaneRecord(value: unknown, paneId: number): Record<string, unknown> | undefined {
  if (Array.isArray(value)) {
    for (const item of value) {
      const found = findPaneRecord(item, paneId)
      if (found !== undefined)
        return found
    }
    return undefined
  }

  if (typeof value !== 'object' || value === null)
    return undefined

  const object = value as Record<string, unknown>
  if (paneMatches(object, paneId))
    return object

  for (const nested of Object.values(object)) {
    const found = findPaneRecord(nested, paneId)
    if (found !== undefined)
      return found
  }
  return undefined
}

export function parseCurrentPaneTabId(listPanesJson: string, paneId: string | undefined): number | undefined {
  if (!paneId)
    return undefined
  const parsedPaneId = Number(paneId)
  if (!Number.isInteger(parsedPaneId))
    return undefined

  try {
    const pane = findPaneRecord(JSON.parse(listPanesJson), parsedPaneId)
    return pane ? numericProperty(pane, ['tab_id', 'tabId']) : undefined
  }
  catch (error) {
    debug('parseCurrentPaneTabId failed', errorMessage(error))
    return undefined
  }
}

export function parsePaneExists(listPanesJson: string, paneId: string | undefined): boolean | undefined {
  if (!paneId)
    return undefined
  let parsedPaneId: number
  try {
    parsedPaneId = Number(normalizePaneId(paneId).slice('terminal_'.length))
  }
  catch {
    return undefined
  }

  try {
    return findPaneRecord(JSON.parse(listPanesJson), parsedPaneId) !== undefined
  }
  catch (error) {
    debug('parsePaneExists failed', errorMessage(error))
    return undefined
  }
}

// ---------------------------------------------------------------------------
// Tab name resolution
// ---------------------------------------------------------------------------

function tabNameProperty(object: Record<string, unknown>, tabId: number | undefined): string | undefined {
  if (tabId === undefined)
    return undefined
  const foundTabId = numericProperty(object, ['tab_id', 'tabId'])
  if (foundTabId !== tabId)
    return undefined
  const name = stringProperty(object, ['name', 'title'])
  return typeof name === 'string' ? name : undefined
}

function findTabName(value: unknown, tabId: number | undefined): string | undefined {
  if (Array.isArray(value)) {
    for (const item of value) {
      const found = findTabName(item, tabId)
      if (found !== undefined)
        return found
    }
    return undefined
  }

  if (typeof value !== 'object' || value === null)
    return undefined

  const object = value as Record<string, unknown>
  const name = tabNameProperty(object, tabId)
  if (name !== undefined)
    return name

  for (const nested of Object.values(object)) {
    const found = findTabName(nested, tabId)
    if (found !== undefined)
      return found
  }
  return undefined
}

function activeTabNameProperty(object: Record<string, unknown>): string | undefined {
  if (object.active !== true || object.is_plugin === true)
    return undefined
  const name = stringProperty(object, ['name', 'title'])
  return typeof name === 'string' ? name : undefined
}

function findActiveTabName(value: unknown): string | undefined {
  if (Array.isArray(value)) {
    for (const item of value) {
      const found = findActiveTabName(item)
      if (found !== undefined)
        return found
    }
    return undefined
  }

  if (typeof value !== 'object' || value === null)
    return undefined

  const object = value as Record<string, unknown>
  const name = activeTabNameProperty(object)
  if (name !== undefined)
    return name

  for (const nested of Object.values(object)) {
    const found = findActiveTabName(nested)
    if (found !== undefined)
      return found
  }
  return undefined
}

export function parseTabName(listTabsJson: string, tabId: number | undefined): string | undefined {
  try {
    return findTabName(JSON.parse(listTabsJson), tabId)
  }
  catch (error) {
    debug('parseTabName failed', errorMessage(error))
    return undefined
  }
}

export function parseActiveTabName(listTabsJson: string): string | undefined {
  try {
    return findActiveTabName(JSON.parse(listTabsJson))
  }
  catch (error) {
    debug('parseActiveTabName failed', errorMessage(error))
    return undefined
  }
}
