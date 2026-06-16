function Wux_comm {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)][string]$File1,
        [Parameter(Position = 1, Mandatory)][string]$File2,
        [Parameter(ValueFromRemainingArguments)][string[]]$Flags
    )

    foreach ($f in $File1, $File2) {
        if (-not (Test-Path $f)) { Write-Error "comm: ${f}: No such file or directory"; return }
    }

    $suppress1 = $Flags -contains '-1'
    $suppress2 = $Flags -contains '-2'
    $suppress3 = $Flags -contains '-3'

    $a = @(Get-Content $File1 | Sort-Object)
    $b = @(Get-Content $File2 | Sort-Object)

    $ai = 0; $bi = 0
    while ($ai -lt $a.Count -or $bi -lt $b.Count) {
        $aLine = if ($ai -lt $a.Count) { $a[$ai] } else { $null }
        $bLine = if ($bi -lt $b.Count) { $b[$bi] } else { $null }

        if ($null -eq $bLine -or ($null -ne $aLine -and $aLine -lt $bLine)) {
            if (-not $suppress1) {
                $indent = ''
                Write-Output "$indent$aLine"
            }
            $ai++
        } elseif ($null -eq $aLine -or $aLine -gt $bLine) {
            if (-not $suppress2) {
                $indent = if (-not $suppress1) { "`t" } else { '' }
                Write-Output "$indent$bLine"
            }
            $bi++
        } else {
            if (-not $suppress3) {
                $indent = ''
                if (-not $suppress1) { $indent += "`t" }
                if (-not $suppress2) { $indent += "`t" }
                Write-Output "$indent$aLine"
            }
            $ai++; $bi++
        }
    }
}
