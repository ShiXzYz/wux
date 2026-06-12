function uniq {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$InputFile,

        [Parameter(Position = 1)]
        [string]$OutputFile,

        [Parameter(ValueFromPipeline = $true)]
        [string]$InputLine,

        [Alias('c')][switch]$Count,
        [Alias('d')][switch]$RepeatedOnly,
        [Alias('u')][switch]$UniqueOnly,
        [Alias('i')][switch]$IgnoreCase,
        [Alias('f')][int]$SkipFields = 0,
        [Alias('s')][int]$SkipChars  = 0
    )

    begin { $pipeLines = [System.Collections.Generic.List[string]]::new() }

    process {
        if ($PSBoundParameters.ContainsKey('InputLine')) { $pipeLines.Add($InputLine) }
    }

    end {
        function Get-Key([string]$line) {
            $k = $line
            if ($SkipFields -gt 0) {
                $parts = $k -split '\s+'
                $k = ($parts | Select-Object -Skip $SkipFields) -join ' '
            }
            if ($SkipChars -gt 0) {
                $k = if ($k.Length -gt $SkipChars) { $k.Substring($SkipChars) } else { '' }
            }
            if ($IgnoreCase) { return $k.ToLower() }
            return $k
        }

        $lines = if ($InputFile) {
            if (-not (Test-Path $InputFile)) { Write-Error "uniq: ${InputFile}: No such file or directory"; return }
            @(Get-Content $InputFile)
        } elseif ($pipeLines.Count -gt 0) {
            $pipeLines.ToArray()
        } else {
            @()
        }

        $prev      = $null
        $prevKey   = $null
        $runCount  = 0
        $output    = [System.Collections.Generic.List[string]]::new()

        foreach ($line in $lines) {
            $key = Get-Key $line
            if ($null -ne $prevKey -and $key -ceq $prevKey) {
                $runCount++
            } else {
                if ($null -ne $prev) {
                    $emit = (-not $RepeatedOnly -and -not $UniqueOnly) -or
                            ($RepeatedOnly -and $runCount -gt 1) -or
                            ($UniqueOnly   -and $runCount -eq 1)
                    if ($emit) {
                        $output.Add($(if ($Count) { '{0,7} {1}' -f $runCount, $prev } else { $prev }))
                    }
                }
                $prev = $line; $prevKey = $key; $runCount = 1
            }
        }

        if ($null -ne $prev) {
            $emit = (-not $RepeatedOnly -and -not $UniqueOnly) -or
                    ($RepeatedOnly -and $runCount -gt 1) -or
                    ($UniqueOnly   -and $runCount -eq 1)
            if ($emit) {
                $output.Add($(if ($Count) { '{0,7} {1}' -f $runCount, $prev } else { $prev }))
            }
        }

        if ($OutputFile) { $output | Set-Content $OutputFile }
        else             { $output | Write-Output }
    }
}
