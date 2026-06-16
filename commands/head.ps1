function Wux_head {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Files,

        [Parameter(ValueFromPipeline = $true)]
        [string]$InputLine,

        [Alias('n')][int]$Lines = 10,
        [Alias('c')][int]$Bytes = 0,
        [Alias('q')][switch]$Quiet,
        [Alias('v')][switch]$ShowHeader
    )

    begin { $pipeLines = [System.Collections.Generic.List[string]]::new() }

    process {
        if ($PSBoundParameters.ContainsKey('InputLine')) { $pipeLines.Add($InputLine) }
    }

    end {
        $showHeader = $ShowHeader -or ($Files.Count -gt 1 -and -not $Quiet)

        function Process-Source {
            param($content, $name)
            if ($showHeader) { Write-Output "==> $name <==" }
            if ($Bytes -gt 0) {
                $str = [string]::Join("`n", $content)
                Write-Output $str.Substring(0, [Math]::Min($Bytes, $str.Length))
            } else {
                $content | Select-Object -First $Lines | Write-Output
            }
        }

        if ($Files.Count -eq 0) {
            Process-Source -content $pipeLines.ToArray() -name 'standard input'
        } else {
            foreach ($f in $Files) {
                if (-not (Test-Path $f)) { Write-Error "head: ${f}: No such file or directory"; continue }
                Process-Source -content (Get-Content $f) -name $f
            }
        }
    }
}
