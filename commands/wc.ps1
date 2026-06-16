function Wux_wc {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Files,

        [Parameter(ValueFromPipeline = $true)]
        [string]$InputLine,

        [Alias('l')][switch]$Lines,
        [Alias('w')][switch]$Words,
        [Alias('c')][switch]$Bytes,
        [Alias('m')][switch]$Chars
    )

    begin { $pipeLines = [System.Collections.Generic.List[string]]::new() }

    process {
        if ($PSBoundParameters.ContainsKey('InputLine')) { $pipeLines.Add($InputLine) }
    }

    end {
        $showAll = -not ($Lines -or $Words -or $Bytes -or $Chars)

        function Measure-Source([string[]]$content) {
            $lc = $content.Count
            $wc = ($content | ForEach-Object {
                       ($_ -split '\s+' | Where-Object { $_ }).Count
                   } | Measure-Object -Sum).Sum
            $bc = ($content | ForEach-Object {
                       [System.Text.Encoding]::UTF8.GetByteCount($_)
                   } | Measure-Object -Sum).Sum + $lc
            return [PSCustomObject]@{ Lines = $lc; Words = [long]$wc; Bytes = [long]$bc }
        }

        function Format-Row([PSCustomObject]$r, [string]$name) {
            $out = ''
            if ($showAll -or $Lines)           { $out += '{0,8}' -f $r.Lines }
            if ($showAll -or $Words)           { $out += '{0,8}' -f $r.Words }
            if ($showAll -or $Bytes -or $Chars){ $out += '{0,8}' -f $r.Bytes }
            if ($name)                         { $out += " $name" }
            Write-Output $out
        }

        if ($Files.Count -eq 0) {
            Format-Row (Measure-Source $pipeLines.ToArray()) ''
            return
        }

        $totals = [PSCustomObject]@{ Lines = 0; Words = 0L; Bytes = 0L }
        foreach ($f in $Files) {
            if (-not (Test-Path $f)) { Write-Error "wc: ${f}: No such file or directory"; continue }
            $r = Measure-Source @(Get-Content $f)
            Format-Row $r $f
            $totals.Lines += $r.Lines
            $totals.Words += $r.Words
            $totals.Bytes += $r.Bytes
        }

        if ($Files.Count -gt 1) { Format-Row $totals 'total' }
    }
}
