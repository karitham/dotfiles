import { mkdirSync } from 'node:fs'
import { homedir } from 'node:os'
import { dirname, join } from 'node:path'
import process from 'node:process'
import { LogFileRotationTransport } from '@loglayer/transport-log-file-rotation'
import { LogLayer } from 'loglayer'
import { serializeError } from 'serialize-error'

// Shared debug logger for the whole plugin. Submodules should NOT construct
// their own LogLayer; instead call `getChildLogger(name)` to get a child
// with a `[name]` prefix that inherits this root's transport.
//
// Logs are written under ~/.cache/opencode-zellij/ (overridable via
// OPENCODE_ZELLIJ_DEBUG_LOG or XDG_CACHE_HOME). They are rotated by
// LogFileRotationTransport — see `buildRootLogger` for the size-based
// rotation policy. Each entry is a JSON object with level, message,
// timestamp, and any structured metadata.
//
// If the transport fails to initialize (e.g. cache dir unwritable), the
// root logger is silently null and `getChildLogger` returns null too;
// callers should tolerate a null logger.
const defaultDebugLogPath = `${process.env.XDG_CACHE_HOME?.trim() || `${homedir()}/.cache`}/opencode-zellij/debug.log`

function buildRootLogger(): LogLayer | null {
  const filename = process.env.OPENCODE_ZELLIJ_DEBUG_LOG?.trim() || defaultDebugLogPath
  if (!filename)
    return null

  try {
    mkdirSync(dirname(filename), { recursive: true })
  }
  catch {
    return null
  }

  try {
    // The filename must contain `%DATE%` and the date format must be set
    // to a value file-stream-rotator accepts. Without `%DATE%` it auto-
    // appends one and logs to stderr; without an explicit `dateFormat`
    // it falls back to 'YMD' and logs a warning to stderr. Both are
    // unwanted at plugin startup.
    //
    // `auditFile` is colocated with the rotated log files: file-stream-
    // rotator otherwise writes its retention audit to the process CWD,
    // which would drop `audit.json` into whichever directory the plugin
    // is launched from (e.g. the repo root during local development).
    const transport = new LogFileRotationTransport({
      filename: filename.includes('%DATE%') ? filename : `${filename}-%DATE%`,
      dateFormat: 'YMD',
      size: '1M',
      maxLogs: '7d',
      frequency: 'daily',
      compressOnRotate: true,
      auditFile: join(dirname(filename), 'audit.json'),
    })
    return new LogLayer({
      errorSerializer: serializeError,
      transport,
    })
  }
  catch {
    return null
  }
}

const rootLogger = buildRootLogger()

/**
 * Returns a child logger that prefixes every message with `[name]`, or
 * null if the root logger failed to initialize.
 */
export function getChildLogger(name: string): LogLayer | null {
  return rootLogger?.withPrefix(`[${name}]`) ?? null
}
