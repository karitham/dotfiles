export interface CommandInput {
  command: string
  args?: string[] | undefined
}

export interface BuildCommandArgvOptions {
  exitCodeToken?: string | undefined
}

const directCommandExitWrapper = 'token="$1"; shift; set +e; "$@"; code=$?; printf "\\n[zellij-pty:%s] exit-code=%s\\n" "$token" "$code"; exit "$code"'
const shellCommandExitWrapper = 'token="$1"; command="$2"; set +e; bash -lc "$command"; code=$?; printf "\\n[zellij-pty:%s] exit-code=%s\\n" "$token" "$code"; exit "$code"'

export function buildCommandArgv(input: CommandInput, options: BuildCommandArgvOptions = {}): string[] {
  const command = input.command.trim()
  if (!command)
    throw new Error('command is required')

  if (options.exitCodeToken) {
    if (input.args && input.args.length > 0) {
      return ['bash', '-lc', directCommandExitWrapper, 'zellij-pty', options.exitCodeToken, command, ...input.args]
    }

    return ['bash', '-lc', shellCommandExitWrapper, 'zellij-pty', options.exitCodeToken, command]
  }

  if (input.args && input.args.length > 0) {
    return [command, ...input.args]
  }

  return ['bash', '-lc', command]
}
