function killall {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromRemainingArguments)]
        [string[]]$Names,

        [switch]$Force,
        [Alias('u')][string]$User
    )

    foreach ($name in $Names) {
        $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
        if (-not $procs) { Write-Error "killall: no process found: $name"; continue }

        foreach ($p in $procs) {
            if ($User -and $p.UserName -notlike "*$User*") { continue }
            if ($PSCmdlet.ShouldProcess("$($p.ProcessName) (PID $($p.Id))", 'terminate')) {
                Stop-Process -Id $p.Id -Force:$Force -ErrorAction SilentlyContinue
            }
        }
    }
}
