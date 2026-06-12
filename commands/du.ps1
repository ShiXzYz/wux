function du {
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

    function Get-RecursiveSize([string]$path) {
        $sum = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object { -not $_.PSIsContainer } |
                Measure-Object -Property Length -Sum).Sum
        return [long]$(if ($sum) { $sum } else { 0 })
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

        $baseDepth = ($resolved.TrimEnd('\').Split('\') | Where-Object { $_ }).Count

        if ($Summarize) {
            $size = Get-RecursiveSize $resolved
            "$(Format-Size $size)`t$resolved"
            $grandTotal += $size
        } else {
            if ($All) {
                Get-ChildItem $resolved -Recurse -Force -File -ErrorAction SilentlyContinue |
                    Where-Object {
                        $d = ($_.FullName.TrimEnd('\').Split('\') | Where-Object { $_ }).Count - $baseDepth - 1
                        $d -lt $MaxDepth
                    } | ForEach-Object {
                        "$(Format-Size $_.Length)`t$($_.FullName)"
                    }
            }

            Get-ChildItem $resolved -Recurse -Force -Directory -ErrorAction SilentlyContinue |
                Where-Object {
                    $d = ($_.FullName.TrimEnd('\').Split('\') | Where-Object { $_ }).Count - $baseDepth
                    $d -le $MaxDepth
                } | ForEach-Object {
                    "$(Format-Size (Get-RecursiveSize $_.FullName))`t$($_.FullName)"
                }

            $totalSize = Get-RecursiveSize $resolved
            "$(Format-Size $totalSize)`t$resolved"
            $grandTotal += $totalSize
        }
    }

    if ($Total) { "$(Format-Size $grandTotal)`ttotal" }
}
