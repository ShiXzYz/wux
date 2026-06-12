function ps {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Names,

        [int[]]$Pid,
        [Alias('e','A')][switch]$All,
        [Alias('f')][switch]$Full,
        [Alias('u')][switch]$UserFormat,
        [Alias('x')][switch]$WithoutTTY  # accepted for compat; all processes shown anyway
    )

    $procs = if ($Pid) {
        Get-Process -Id $Pid -ErrorAction SilentlyContinue
    } elseif ($Names -and $Names.Count -gt 0) {
        Get-Process -Name $Names -ErrorAction SilentlyContinue
    } else {
        Get-Process -ErrorAction SilentlyContinue
    }

    if ($UserFormat -or $Full) {
        '{0,7} {1,7} {2,8} {3,7} {4}' -f 'PID','CPU(s)','MEM(MB)','Handles','COMMAND'
        foreach ($p in $procs | Sort-Object Id) {
            $cpu  = if ($p.CPU)             { '{0:0.0}' -f $p.CPU }               else { '0.0' }
            $mem  = [Math]::Round($p.WorkingSet64 / 1MB, 1)
            $cmd  = if ($p.Path)            { $p.Path }                            else { $p.ProcessName }
            '{0,7} {1,7} {2,8} {3,7} {4}' -f $p.Id,$cpu,$mem,$p.HandleCount,$cmd
        }
    } else {
        '{0,7} {1,-5} {2,-10} {3}' -f 'PID','TTY','TIME','CMD'
        foreach ($p in $procs | Sort-Object Id) {
            $time = if ($p.CPU) { [TimeSpan]::FromSeconds($p.CPU).ToString('hh\:mm\:ss') } else { '00:00:00' }
            '{0,7} {1,-5} {2,-10} {3}' -f $p.Id,'?',$time,$p.ProcessName
        }
    }
}
