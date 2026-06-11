function tail {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Files,

        [Alias('n')][string]$Lines = '10',
        [Alias('c')][int]$Bytes = 0,
        [Alias('f')][switch]$Follow,
        [Alias('q')][switch]$Quiet,
        [Alias('v')][switch]$ShowHeader,
        [int]$RetryInterval = 1
    )

    $fromStart = $Lines.StartsWith('+')
    $lineCount  = [int]($Lines.TrimStart('+'))

    $showHeader = $ShowHeader -or ($Files.Count -gt 1 -and -not $Quiet)

    function Get-Tail {
        param($path)
        $content = Get-Content $path
        if ($fromStart) {
            return $content | Select-Object -Skip ($lineCount - 1)
        } else {
            return $content | Select-Object -Last $lineCount
        }
    }

    function Process-Source {
        param($content, $name)
        if ($showHeader) { Write-Output "==> $name <==" }
        if ($Bytes -gt 0) {
            $str   = [string]::Join("`n", $content)
            $start = [Math]::Max(0, $str.Length - $Bytes)
            Write-Output $str.Substring($start)
        } else {
            $content | Write-Output
        }
    }

    if ($Files.Count -eq 0) {
        $all    = @($Input)
        $sliced = if ($fromStart) { $all | Select-Object -Skip ($lineCount - 1) } else { $all | Select-Object -Last $lineCount }
        Process-Source -content $sliced -name 'standard input'
        return
    }

    foreach ($f in $Files) {
        if (-not (Test-Path $f)) { Write-Error "tail: ${f}: No such file or directory"; continue }
        Process-Source -content (Get-Tail $f) -name $f
    }

    if ($Follow) {
        $positions = @{}
        foreach ($f in $Files) {
            if (Test-Path $f) { $positions[$f] = (Get-Item $f).Length }
        }
        while ($true) {
            Start-Sleep -Seconds $RetryInterval
            foreach ($f in $Files) {
                if (-not (Test-Path $f)) { continue }
                $newLen = (Get-Item $f).Length
                if ($newLen -gt $positions[$f]) {
                    $stream = [System.IO.File]::Open($f, 'Open', 'Read', 'ReadWrite')
                    $stream.Seek($positions[$f], 'Begin') | Out-Null
                    $reader = New-Object System.IO.StreamReader($stream)
                    while (-not $reader.EndOfStream) { Write-Output $reader.ReadLine() }
                    $reader.Close()
                    $stream.Close()
                    $positions[$f] = $newLen
                }
            }
        }
    }
}
