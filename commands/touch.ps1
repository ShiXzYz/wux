function Wux_touch {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromRemainingArguments)]
        [string[]]$Files,

        [Alias('a')][switch]$AccessTime,
        [Alias('m')][switch]$ModifyTime,
        [Alias('c')][switch]$NoCreate,
        [Alias('t')][string]$Time,       # [[CC]YY]MMDDhhmm[.ss]
        [Alias('r')][string]$Reference,
        [Alias('d')][string]$Date
    )

    $stamp = if ($Reference) {
        (Get-Item $Reference).LastWriteTime
    } elseif ($Time) {
        # Parse [[CC]YY]MMDDhhmm[.ss]  (remove optional dot before seconds)
        $t = $Time -replace '\.', ''
        switch ($t.Length) {
            14 { [datetime]::ParseExact($t, 'yyyyMMddHHmmss', $null) }
            12 { [datetime]::ParseExact($t, 'yyyyMMddHHmm',   $null) }
            10 { [datetime]::ParseExact($t, 'yyMMddHHmm',     $null) }
             8 { [datetime]::ParseExact($t, 'MMddHHmm',       $null) }
            default { Get-Date }
        }
    } elseif ($Date) {
        [datetime]$Date
    } else {
        Get-Date
    }

    $setAccess = -not $ModifyTime -or $AccessTime
    $setModify = -not $AccessTime -or $ModifyTime

    foreach ($f in $Files) {
        if (-not (Test-Path $f)) {
            if (-not $NoCreate) { New-Item -ItemType File $f | Out-Null }
        }
        if (Test-Path $f) {
            $item = Get-Item $f
            if ($setModify) { $item.LastWriteTime   = $stamp }
            if ($setAccess) { $item.LastAccessTime  = $stamp }
        }
    }
}
