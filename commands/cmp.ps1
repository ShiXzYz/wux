function Wux_cmp {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)][string]$File1,
        [Parameter(Position = 1, Mandatory)][string]$File2,
        [Alias('s')][switch]$Silent,
        [Alias('l')][switch]$VerboseOutput
    )

    foreach ($f in $File1, $File2) {
        if (-not (Test-Path $f)) { Write-Error "cmp: ${f}: No such file or directory"; return }
    }

    $bytes1 = [System.IO.File]::ReadAllBytes((Resolve-Path $File1).Path)
    $bytes2 = [System.IO.File]::ReadAllBytes((Resolve-Path $File2).Path)
    $minLen = [Math]::Min($bytes1.Length, $bytes2.Length)

    $line = 1
    $differences = $false

    for ($i = 0; $i -lt $minLen; $i++) {
        if ($bytes1[$i] -ne $bytes2[$i]) {
            $differences = $true
            if ($VerboseOutput) {
                Write-Output ('{0,8} {1,3} {2,3}' -f ($i + 1), $bytes1[$i], $bytes2[$i])
            } elseif (-not $Silent) {
                Write-Output "$File1 $File2 differ: byte $($i + 1), line $line"
                return
            } else {
                return
            }
        }
        if ($bytes1[$i] -eq 10) { $line++ }
    }

    if ($bytes1.Length -ne $bytes2.Length) {
        $shorter = if ($bytes1.Length -lt $bytes2.Length) { $File1 } else { $File2 }
        if (-not $Silent) {
            Write-Output "cmp: EOF on $shorter after byte $minLen, line $line"
        }
        $LASTEXITCODE = 1
    }
}
