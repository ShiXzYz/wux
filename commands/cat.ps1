function cat {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Files,

        [Parameter(ValueFromPipeline = $true)]
        [string]$InputLine,

        [Alias('n')][switch]$NumberLines,
        [Alias('b')][switch]$NumberNonBlank,
        [Alias('s')][switch]$SqueezeBlank,
        [Alias('A')][switch]$ShowAll,
        [Alias('E')][switch]$ShowEnds,
        [Alias('T')][switch]$ShowTabs
    )

    begin { $pipeLines = [System.Collections.Generic.List[string]]::new() }

    process {
        if ($PSBoundParameters.ContainsKey('InputLine')) { $pipeLines.Add($InputLine) }
    }

    end {
        function Write-Lines([string[]]$content) {
            $lineNum      = 0
            $prevBlank    = $false
            foreach ($line in $content) {
                $isBlank = $line.Trim() -eq ''
                if ($SqueezeBlank -and $isBlank -and $prevBlank) { continue }
                $prevBlank = $isBlank

                $out = $line
                if ($ShowTabs -or $ShowAll) { $out = $out -replace "`t", '^I' }

                $printNum = $NumberLines -or ($NumberNonBlank -and -not $isBlank)
                if ($printNum) { $lineNum++; $out = '{0,6}  {1}' -f $lineNum, $out }

                if ($ShowEnds -or $ShowAll) { $out += '$' }
                Write-Output $out
            }
        }

        if ($Files.Count -eq 0) {
            Write-Lines $pipeLines.ToArray()
        } else {
            foreach ($f in $Files) {
                if (-not (Test-Path $f)) { Write-Error "cat: ${f}: No such file or directory"; continue }
                Write-Lines @(Get-Content $f)
            }
        }
    }
}
