function Wux_chmod {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [string]$Mode,

        [Parameter(Position = 1, Mandatory, ValueFromRemainingArguments)]
        [string[]]$Paths,

        [Alias('R')][switch]$Recursive,
        [Alias('v')][switch]$ShowChanges,
        [Alias('c')][switch]$ReportChanges
    )

    function Apply-Mode {
        param($item)
        $path = $item.FullName

        if ($Mode -match '^[0-7]{3,4}$') {
            $octal    = $Mode.PadLeft(4, '0')
            $owner    = [int]::Parse($octal[1].ToString())
            $readOnly = ($owner -band 2) -eq 0
            $item.IsReadOnly = $readOnly
            if ($ShowChanges -or $ReportChanges) {
                $attr = if ($readOnly) { 'read-only' } else { 'writable' }
                Write-Output "chmod: changed '${path}' to ${attr}"
            }
            return
        }

        if ($Mode -match '^([ugoa]*)([+\-=])([rwxX]*)$') {
            $op    = $Matches[2]
            $perms = $Matches[3]

            if ($op -eq '-' -and $perms -match 'w') {
                $item.IsReadOnly = $true
                if ($ShowChanges) { Write-Output "chmod: removed write on '${path}'" }
            } elseif ($op -eq '+' -and $perms -match 'w') {
                $item.IsReadOnly = $false
                if ($ShowChanges) { Write-Output "chmod: added write on '${path}'" }
            } elseif ($op -eq '=' -and $perms -notmatch 'w') {
                $item.IsReadOnly = $true
            } elseif ($op -eq '=' -and $perms -match 'w') {
                $item.IsReadOnly = $false
            }
            return
        }

        Write-Warning "chmod: unrecognized mode '${Mode}' - only basic attribute changes supported on Windows"
    }

    foreach ($p in $Paths) {
        if (-not (Test-Path $p)) { Write-Error "chmod: cannot access '${p}': No such file or directory"; continue }
        if ($Recursive) {
            Get-ChildItem $p -Recurse -Force | ForEach-Object { Apply-Mode $_ }
        }
        Apply-Mode (Get-Item $p)
    }
}
