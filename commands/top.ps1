function top {
    [CmdletBinding()]
    param(
        [Alias('n')][int]$Iterations = 0,
        [Alias('d')][int]$Delay      = 2,
        [Alias('p')][int[]]$Pids
    )

    $i = 0
    try {
        while ($true) {
            $procs = if ($Pids) {
                $Pids | ForEach-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue }
            } else {
                Get-Process -ErrorAction SilentlyContinue | Sort-Object CPU -Descending | Select-Object -First 20
            }

            Clear-Host
            $now      = Get-Date -Format 'HH:mm:ss'
            $procCount = (Get-Process).Count
            $os        = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
            $memUsed   = if ($os) { [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 1) } else { '?' }
            $memTotal  = if ($os) { [math]::Round($os.TotalVisibleMemorySize / 1MB, 1) } else { '?' }

            Write-Host "top - $now  tasks: $procCount  mem: ${memUsed}/${memTotal} GiB  (Ctrl+C to quit)" -ForegroundColor Cyan
            Write-Host ('{0,-7} {1,-22} {2,6} {3,9} {4,6}' -f 'PID', 'COMMAND', '%CPU', 'MEM(MB)', 'THR') -ForegroundColor Yellow
            Write-Host ('-' * 55) -ForegroundColor DarkGray

            foreach ($p in $procs) {
                $cpu = if ($p.CPU) { [math]::Round($p.CPU, 1) } else { 0 }
                $mem = [math]::Round($p.WorkingSet64 / 1MB, 1)
                $thr = $p.Threads.Count
                '{0,-7} {1,-22} {2,6:F1} {3,9:F1} {4,6}' -f $p.Id, $p.ProcessName.Substring(0, [Math]::Min(22, $p.ProcessName.Length)), $cpu, $mem, $thr
            }

            $i++
            if ($Iterations -gt 0 -and $i -ge $Iterations) { break }
            Start-Sleep -Seconds $Delay
        }
    } catch [System.Management.Automation.PipelineStoppedException] {
        # Ctrl+C — exit cleanly
    }
}
