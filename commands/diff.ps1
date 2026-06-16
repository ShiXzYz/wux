function Wux_diff {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)][string]$File1,
        [Parameter(Position = 1, Mandatory)][string]$File2,
        [Alias('q')][switch]$Brief,
        [Alias('i')][switch]$IgnoreCase
    )

    foreach ($f in $File1, $File2) {
        if (-not (Test-Path $f)) { Write-Error "diff: ${f}: No such file or directory"; return }
    }

    $a = @(Get-Content $File1)
    $b = @(Get-Content $File2)

    $changes = Compare-Object $a $b -CaseSensitive:(-not $IgnoreCase)

    if (-not $changes) { return }

    if ($Brief) {
        Write-Output "Files $File1 and $File2 differ"
        return
    }

    foreach ($c in $changes) {
        switch ($c.SideIndicator) {
            '<=' { Write-Output "< $($c.InputObject)" }
            '=>' { Write-Output "> $($c.InputObject)" }
        }
    }
}
