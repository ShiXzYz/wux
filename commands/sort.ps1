function sort {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][string[]]$Files,
        [Parameter(ValueFromPipeline)][string]$InputObject,

        [Alias('r')][switch]$Reverse,
        [Alias('u')][switch]$Unique,
        [Alias('n')][switch]$Numeric,
        [Alias('i')][switch]$IgnoreCase,
        [Alias('k')][string]$Key,
        [Alias('t')][string]$FieldSeparator = ' '
    )

    begin { $pipeLines = [System.Collections.Generic.List[string]]::new() }

    process {
        if ($PSBoundParameters.ContainsKey('InputObject')) { $pipeLines.Add($InputObject) }
    }

    end {
        $allLines = if ($Files) {
            foreach ($f in $Files) {
                if (-not (Test-Path $f)) { Write-Error "sort: cannot read '$f': No such file or directory"; continue }
                Get-Content $f
            }
        } else {
            $pipeLines.ToArray()
        }

        $sorted = if ($Numeric) {
            $allLines | Sort-Object { [double]($_ -split "[$([regex]::Escape($FieldSeparator))]")[0] } -Descending:$Reverse
        } elseif ($Key) {
            $keyIdx = [int]$Key - 1
            $sep    = $FieldSeparator
            $allLines | Sort-Object { ($_ -split "[$([regex]::Escape($sep))]")[$keyIdx] } -CaseSensitive:(-not $IgnoreCase) -Descending:$Reverse
        } else {
            $allLines | Sort-Object -CaseSensitive:(-not $IgnoreCase) -Descending:$Reverse
        }

        if ($Unique) { $sorted = $sorted | Select-Object -Unique }
        $sorted
    }
}
