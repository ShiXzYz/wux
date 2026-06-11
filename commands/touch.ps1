function touch {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromRemainingArguments)]
        [string[]]$Files,

        [Alias('a')][switch]$AccessTime,
        [Alias('m')][switch]$ModifyTime,
        [Alias('c')][switch]$NoCrete,
        [Alias('t')][string]$Time,       # [[CC]YY]MMDDhhmm[.ss]
        [Alias('r')][string]$Reference,
        [Alias('d')][string]$Date
    )

    $stamp = if ($Reference) {
        (Get-Item $Reference).LastWriteTime
    } elseif ($Time) {
        # Parse [[CC]YY]MMDDhhmm[.ss]
        $t = $Time -replace '\.', ''
        $fmt = switch ($t.Length) {
            12 { 'yyyyMMddHHmm' }
            10 { 'MMddHHmm' }
             8 { 'MMddHHmm' }
            default { $null }
        }
        if ($fmt) { [datetime]::ParseExact($t.PadLeft(12,'0').Substring($t.Length - 10),'MMddHHmmss',$null) }
        else { Get-Date }
    } elseif ($Date) {
        [datetime]$Date
    } else {
        Get-Date
    }

    $setAccess = -not $ModifyTime -or $AccessTime
    $setModify = -not $AccessTime -or $ModifyTime

    foreach ($f in $Files) {
        if (-not (Test-Path $f)) {
            if (-not $NoCrete) { New-Item -ItemType File $f | Out-Null }
        }
        if (Test-Path $f) {
            $item = Get-Item $f
            if ($setModify) { $item.LastWriteTime   = $stamp }
            if ($setAccess) { $item.LastAccessTime  = $stamp }
        }
    }
}
