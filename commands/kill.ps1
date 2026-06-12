function kill {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromRemainingArguments)]
        [int[]]$Pids,

        [Alias('s')][string]$Signal = 'TERM',
        [switch]$Force   # equivalent to -s KILL / -9
    )

    # NOTE: kill -9 1234 (numeric signal flag) is not parseable in PowerShell.
    # Use: kill -Force 1234   or   kill -s KILL 1234

    $forceKill = $Force -or $Signal -match '^(9|KILL|SIGKILL)$'

    foreach ($id in $Pids) {
        $proc = Get-Process -Id $id -ErrorAction SilentlyContinue
        if (-not $proc) { Write-Error "kill: ($id) - No such process"; continue }

        if ($PSCmdlet.ShouldProcess("PID $id ($($proc.ProcessName))", 'terminate')) {
            if ($forceKill) {
                Stop-Process -Id $id -Force
            } else {
                Stop-Process -Id $id
            }
        }
    }
}
