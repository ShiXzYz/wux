function Wux_cal {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][int]$Month = (Get-Date).Month,
        [Parameter(Position = 1)][int]$Year  = (Get-Date).Year,
        [Alias('3')][switch]$ThreeMonths
    )

    function Show-Month([int]$m, [int]$y) {
        $today    = Get-Date
        $first    = [datetime]::new($y, $m, 1)
        $days     = [datetime]::DaysInMonth($y, $m)
        $header   = $first.ToString('MMMM yyyy').PadLeft(17).PadRight(20)
        Write-Host $header -ForegroundColor Cyan
        Write-Host 'Su Mo Tu We Th Fr Sa'

        $startCol = [int]$first.DayOfWeek
        $line     = '   ' * $startCol
        $col      = $startCol

        for ($d = 1; $d -le $days; $d++) {
            $isToday = ($d -eq $today.Day -and $m -eq $today.Month -and $y -eq $today.Year)
            $cell    = '{0,2}' -f $d
            if ($col -gt 0) { $line += ' ' }
            if ($isToday) {
                # Flush what we have, highlight today, continue
                Write-Host $line -NoNewline
                Write-Host $cell -NoNewline -ForegroundColor Black -BackgroundColor White
                $line = ''
            } else {
                $line += $cell
            }
            $col++
            if ($col -eq 7) {
                Write-Host $line
                $line = ''; $col = 0
            }
        }
        if ($line -ne '') { Write-Host $line }
        Write-Host ''
    }

    if ($ThreeMonths) {
        $pm = $Month - 1; $py = $Year
        if ($pm -lt 1) { $pm = 12; $py-- }
        $nm = $Month + 1; $ny = $Year
        if ($nm -gt 12) { $nm = 1; $ny++ }

        Show-Month $pm $py
        Show-Month $Month $Year
        Show-Month $nm $ny
    } else {
        Show-Month $Month $Year
    }
}
