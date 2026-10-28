# gallant-llama starts and stops the local llama-server that answers Liquid d1
# questions. The gallant wrapper calls "ensure" before a run, so the first run
# pays the model load and later runs reuse the warm server.

def health [base: string] {
    try {
        let response = (http get -m 2sec -f -e $"($base)/health")
        ($response.status == 200)
    } catch {
        false
    }
}

# server_pids returns the llama-server processes that listen on port.
def server_pids [port: int] {
    let result = (^pgrep -x llama-server | complete)
    if $result.exit_code != 0 {
        return []
    }

    $result.stdout
    | lines
    | where {|line| $line != "" }
    | each {|line| $line | into int }
    | where {|pid|
      let args = (^ps -ww -o args= -p $pid | complete)
      ($args.exit_code == 0) and (($args.stdout | str contains $"--port ($port)"))
    }
}

def wait_ready [base: string, port: int, timeout: int] {
    for i in 0..$timeout {
        if (health $base) {
            return true
        }
        if ($i > 5) and ((server_pids $port) | is-empty) {
            return false
        }
        sleep 1sec
    }
    false
}

def start_server [
    base: string
    port: int
    model: string
    context: int
    threads: int
    gpu_layers: int
    timeout: int
    state_dir: string
] {
    if (health $base) {
        return
    }

    let log = $state_dir | path join "llama-server.log"
    let model_flag = if ($model | str starts-with "/") or ($model | str ends-with ".gguf") { "-m" } else { "-hf" }
    $"--- (date now) ---" | save --append $log
    ^setsid -f llama-server $model_flag $model -c $context -b $context -ub $context -t $threads -ngl $gpu_layers --host 127.0.0.1 --port $port --no-webui o+e>> $log

    if (wait_ready $base $port $timeout) {
        return
    }

    for pid in (server_pids $port) {
        try { kill $pid } catch { }
    }
    error make {msg: $"llama-server did not become ready; see ($log)"}
}

def lock_is_stale [lock_dir: string] {
    if not ($lock_dir | path exists) {
        return false
    }

    let pid_file = $lock_dir | path join "pid"
    if not ($pid_file | path exists) {
        try {
            let age = (date now) - (ls -D $lock_dir | get 0.modified)
            return ($age > 5sec)
        } catch {
            return false
        }
    }

    let owner = (
        try {
            open $pid_file | str trim | into int
        } catch {
            null
        }
    )
    if ($owner | is-empty) {
        return false
    }
    (ps | where pid == $owner | is-empty)
}

def start_with_lock [
    base: string
    port: int
    model: string
    context: int
    threads: int
    gpu_layers: int
    timeout: int
    state_dir: string
    runtime_dir: string
] {
    if (health $base) {
        if (server_matches $port $model $context $gpu_layers) {
            return
        }
        stop_server $port --quiet
    }

    let lock_dir = $runtime_dir | path join "llama-server.lock"
    mut acquired = false
    for _ in 0..($timeout + 60) {
        if (health $base) {
            return
        }
        if (try {
            mkdir --fail-if-exists $lock_dir
            true
        } catch {
            false
        }) {
            $acquired = true
            break
        }
        if (lock_is_stale $lock_dir) {
            rm -rf $lock_dir
            continue
        }
        sleep 1sec
    }

    if not $acquired {
        error make {msg: "timed out waiting for another gallant-llama start"}
    }

    try {
        $nu.pid | save --force ($lock_dir | path join "pid")
        (start_server
            $base
            $port
            $model
            $context
            $threads
            $gpu_layers
            $timeout
            $state_dir
        )
    } finally {
        rm -rf $lock_dir
    }
}

def server_matches [
    port: int
    model: string
    context: int
    gpu_layers: int
] {
    let pids = (server_pids $port)
    if ($pids | is-empty) {
        return true
    }

    $pids | all {|pid|
        let args = (^ps -ww -o args= -p $pid | complete)
        if $args.exit_code != 0 {
            false
        } else {
            let line = $args.stdout
            (($line | str contains $model) and ($line | str contains $"-c ($context)") and ($line | str contains $"-ngl ($gpu_layers)"))
        }
    }
}

def stop_server [port: int, --quiet] {
    let pids = (server_pids $port)
    if ($pids | is-empty) {
        if not $quiet {
            print "gallant-llama: not running"
        }
        return
    }

    for pid in $pids {
        try { kill $pid } catch { }
    }

    for _ in 0..10 {
        if ((server_pids $port) | is-empty) {
            if not $quiet {
                print "gallant-llama: stopped"
            }
            return
        }
        sleep 1sec
    }

    for pid in (server_pids $port) {
        try { kill --force $pid } catch { }
    }
    if not $quiet {
        print "gallant-llama: killed"
    }
}

def status_server [base: string] {
    if (health $base) {
        print $"gallant-llama: running at ($base)"
        return
    }

    print "gallant-llama: stopped"
    exit 1
}

def ensure_server [
    args: list<string>
    base: string
    port: int
    model: string
    context: int
    threads: int
    gpu_layers: int
    timeout: int
    state_dir: string
    runtime_dir: string
] {
    if not (($env.GALLANT_LLAMA_DISABLE? | default "") | is-empty) {
        return
    }
    if ($args | is-empty) {
        return
    }
    if ($args | any {|arg| $arg in ["-h" "--help" "-help" "--man"]}) {
        return
    }

    mut provider = $env.GALLANT_PROVIDER? | default "liquid"
    mut i = 0
    while $i < ($args | length) {
        let arg = $args | get $i
        if ($arg == "--provider") or ($arg == "-provider") {
            if ($i + 1) < ($args | length) {
                $provider = ($args | get ($i + 1))
                $i += 1
            }
        } else if ($arg | str starts-with "--provider=") {
            $provider = ($arg | str replace "--provider=" "")
        } else if ($arg | str starts-with "-provider=") {
            $provider = ($arg | str replace "-provider=" "")
        }
        $i += 1
    }

    if $provider != "liquid" {
        return
    }

    (start_with_lock
        $base
        $port
        $model
        $context
        $threads
        $gpu_layers
        $timeout
        $state_dir
        $runtime_dir
    )
}

def main [...args: string] {
    let command = $args | first | default "ensure"
    let rest = $args | skip 1

    let base = $env.LIQUID_BASE_URL? | default "http://127.0.0.1:18080"
    let parsed = $base | url parse
    if not (($parsed.host == "127.0.0.1") or ($parsed.host == "localhost")) {
        return
    }

    let port = if ($parsed.port | is-empty) {
        80
    } else {
        $parsed.port | into int
    }
    let model = $env.GALLANT_LLAMA_MODEL? | default "LiquidAI/d1-2B-GGUF:Q8_0"
    let context = $env.GALLANT_LLAMA_CONTEXT? | default 8192 | into int
    let threads = $env.GALLANT_LLAMA_THREADS? | default 8 | into int
    let gpu_layers = $env.GALLANT_LLAMA_GPU_LAYERS? | default 0 | into int
    let timeout = $env.GALLANT_LLAMA_START_TIMEOUT? | default 900 | into int
    let state_dir = (
        ($env.XDG_STATE_HOME? | default $"($env.HOME)/.local/state")
        | path join "gallant"
    )
    let runtime_base = if "XDG_RUNTIME_DIR" in $env { $env.XDG_RUNTIME_DIR } else { $"/tmp/gallant-(^id -u | str trim)" }
    let runtime_dir = $runtime_base | path join "gallant"

    mkdir $state_dir $runtime_dir
    ^chmod 700 $runtime_dir

    match $command {
        "ensure" => {
            (ensure_server
                $rest
                $base
                $port
                $model
                $context
                $threads
                $gpu_layers
                $timeout
                $state_dir
                $runtime_dir
            )
        }
        "start" => {
            (start_with_lock
                $base
                $port
                $model
                $context
                $threads
                $gpu_layers
                $timeout
                $state_dir
                $runtime_dir
            )
        }
        "stop" => { stop_server $port }
        "status" => { status_server $base }
        "restart" => {
            stop_server $port
            (start_with_lock
                $base
                $port
                $model
                $context
                $threads
                $gpu_layers
                $timeout
                $state_dir
                $runtime_dir
            )
        }
        _ => { error make {msg: "usage: gallant-llama {ensure|start|stop|status|restart}"} }
    }
}
