function ls {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = '.',

        [Alias('a')][switch]$All,       # include hidden/system (dot-files)
        [Alias('l')][switch]$Long,      # long listing format
        [Alias('h')][switch]$HumanReadable, # human-readable sizes (use with -l)
        [Alias('r')][switch]$Reverse,   # reverse sort order
        [Alias('t')][switch]$SortTime,  # sort by modification time
        [Alias('S')][switch]$SortSize,  # sort by file size
        [Alias('1')][switch]$OnePerLine, # one entry per line
        [Alias('d')][switch]$Directory, # list directory itself, not its contents
        [Alias('R')][switch]$Recurse    # list subdirectories recursively
    )

    $gciParams = @{ Path = $Path; ErrorAction = 'Stop' }
    if ($All)     { $gciParams['Force'] = $true }
    if ($Recurse) { $gciParams['Recurse'] = $true }

    if ($Directory) {
        $items = @(Get-Item $Path)
    } else {
        try {
            $items = @(Get-ChildItem @gciParams)
        } catch {
            Write-Error "ls: cannot access '$Path': $($_.Exception.Message)"
            return
        }
    }

    # Sort
    if ($SortTime) {
        $items = $items | Sort-Object LastWriteTime -Descending:(-not $Reverse)
    } elseif ($SortSize) {
        $items = $items | Sort-Object Length -Descending:(-not $Reverse)
    } else {
        $items = $items | Sort-Object Name -Descending:$Reverse
    }

    if ($Long) {
        foreach ($item in $items) {
            $mode = $item.Mode
            $size = if ($item.PSIsContainer) {
                '-'
            } elseif ($HumanReadable) {
                Format-HumanSize $item.Length
            } else {
                $item.Length.ToString()
            }
            $date = $item.LastWriteTime.ToString('MMM dd HH:mm')
            $name = if ($item.PSIsContainer) { "$($item.Name)/" } else { $item.Name }
            '{0}  {1,8}  {2}  {3}' -f $mode, $size, $date, $name
        }
    } elseif ($OnePerLine) {
        foreach ($item in $items) {
            $name = if ($item.PSIsContainer) { "$($item.Name)/" } else { $item.Name }
            Write-Output $name
        }
    } else {
        # Columnar output — colour directories blue, executables green
        $names = foreach ($item in $items) {
            if ($item.PSIsContainer) { "$($item.Name)/" } else { $item.Name }
        }
        if (-not $names) { return }

        $maxLen    = ($names | Measure-Object Length -Maximum).Maximum
        $colWidth  = $maxLen + 2
        $console   = $Host.UI.RawUI
        $termWidth = if ($console -and $console.WindowSize.Width -gt 0) { $console.WindowSize.Width } else { 80 }
        $cols      = [Math]::Max(1, [Math]::Floor($termWidth / $colWidth))
        $rows      = [Math]::Ceiling($names.Count / $cols)

        for ($row = 0; $row -lt $rows; $row++) {
            $line = ''
            for ($col = 0; $col -lt $cols; $col++) {
                $idx = $col * $rows + $row
                if ($idx -ge $names.Count) { break }
                $entry = $names[$idx]
                $item  = $items[$idx]
                $padded = $entry.PadRight($colWidth)
                if ($item.PSIsContainer) {
                    Write-Host $padded -NoNewline -ForegroundColor Blue
                } elseif ($item.Extension -in '.exe','.bat','.cmd','.ps1','.sh') {
                    Write-Host $padded -NoNewline -ForegroundColor Green
                } else {
                    Write-Host $padded -NoNewline
                }
            }
            Write-Host ''
        }
    }
}

function Format-HumanSize([long]$bytes) {
    if     ($bytes -ge 1GB) { '{0:0.#}G' -f ($bytes / 1GB) }
    elseif ($bytes -ge 1MB) { '{0:0.#}M' -f ($bytes / 1MB) }
    elseif ($bytes -ge 1KB) { '{0:0.#}K' -f ($bytes / 1KB) }
    else                    { "${bytes}B" }
}
