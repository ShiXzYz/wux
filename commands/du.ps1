function Wux_du {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Paths = @('.'),

        [Alias('h')][switch]$HumanReadable,
        [Alias('s')][switch]$Summarize,
        [Alias('a')][switch]$All,
        [Alias('c')][switch]$Total,
        [Alias('d')][int]$MaxDepth = [int]::MaxValue,
        [Alias('m')][switch]$Megabytes
    )

    function Format-Size([long]$bytes) {
        if ($HumanReadable) {
            $u = 'B','K','M','G','T'; $i = 0; $v = [double]$bytes
            while ($v -ge 1024 -and $i -lt 4) { $v /= 1024; $i++ }
            return '{0:0.#}{1}' -f $v, $u[$i]
        }
        if ($Megabytes) { return [Math]::Ceiling($bytes / 1MB) }
        return [Math]::Ceiling($bytes / 1KB)
    }

    $grandTotal = [long]0

    foreach ($p in $Paths) {
        if (-not (Test-Path $p)) {
            Write-Error "du: cannot access '$p': No such file or directory"; continue
        }
        $resolved  = (Resolve-Path $p).Path
        $baseItem  = Get-Item $resolved

        if (-not $baseItem.PSIsContainer) {
            "$(Format-Size $baseItem.Length)`t$resolved"
            $grandTotal += $baseItem.Length
            continue
        }

        $resolvedNorm = $resolved.TrimEnd('\')
        $baseDepth    = $resolvedNorm.Split('\').Count

        # Single-pass: collect all file sizes and accumulate into each ancestor directory
        $dirSizes = @{ $resolvedNorm = 0L }
        $allFiles = Get-ChildItem $resolved -Recurse -Force -ErrorAction SilentlyContinue

        foreach ($item in $allFiles) {
            if ($item.PSIsContainer) {
                if (-not $dirSizes.ContainsKey($item.FullName)) { $dirSizes[$item.FullName] = 0L }
            } else {
                $dir = $item.DirectoryName
                while ($dir -and $dir.Length -ge $resolvedNorm.Length) {
                    if (-not $dirSizes.ContainsKey($dir)) { $dirSizes[$dir] = 0L }
                    $dirSizes[$dir] += $item.Length
                    $dir = Split-Path $dir -Parent
                }
                if ($All) {
                    $fileDepth = $item.FullName.Split('\').Count - $baseDepth - 1
                    if ($fileDepth -lt $MaxDepth) {
                        "$(Format-Size $item.Length)`t$($item.FullName)"
                    }
                }
            }
        }

        if (-not $Summarize) {
            foreach ($dir in ($dirSizes.Keys | Sort-Object)) {
                if ($dir -eq $resolvedNorm) { continue }
                $depth = $dir.Split('\').Count - $baseDepth
                if ($depth -le $MaxDepth) {
                    $sz = $dirSizes[$dir]
                    "$(Format-Size $sz)`t$dir"
                }
            }
        }

        $totalSize = $dirSizes[$resolvedNorm]
        "$(Format-Size $totalSize)`t$resolved"
        $grandTotal += $totalSize
    }

    if ($Total) { "$(Format-Size $grandTotal)`ttotal" }
}
