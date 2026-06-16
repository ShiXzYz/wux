function Wux_uptime {
    [CmdletBinding()]
    param(
        [Alias('p')][switch]$Pretty,
        [Alias('s')][switch]$Since
    )

    $os       = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $bootTime = $os.LastBootUpTime
    $now      = Get-Date
    $span     = $now - $bootTime

    if ($Since) {
        Write-Output $bootTime.ToString('yyyy-MM-dd HH:mm:ss')
        return
    }

    if ($Pretty) {
        $parts = @()
        if ($span.Days    -gt 0) { $parts += "$($span.Days) day$(if($span.Days -ne 1){'s'})" }
        if ($span.Hours   -gt 0) { $parts += "$($span.Hours) hour$(if($span.Hours -ne 1){'s'})" }
        if ($span.Minutes -gt 0) { $parts += "$($span.Minutes) minute$(if($span.Minutes -ne 1){'s'})" }
        if ($parts.Count -eq 0)  { $parts += 'less than a minute' }
        Write-Output "up $($parts -join ', ')"
        return
    }

    $load  = [Math]::Round(((Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue |
                              Measure-Object -Property LoadPercentage -Average).Average) / 100, 2)
    $users = (query user 2>$null | Select-Object -Skip 1 | Measure-Object).Count

    ' {0}  up {1} days {2:D2}:{3:D2},  {4} user(s),  load: {5}' -f `
        $now.ToString('HH:mm:ss'), $span.Days, $span.Hours, $span.Minutes, $users, $load
}
