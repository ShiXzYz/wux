function Wux_whoami {
    [CmdletBinding()]
    param(
        [switch]$Groups,
        [switch]$User,
        [Alias('a')][switch]$All
    )

    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()

    if ($Groups -or $All) {
        $identity.Groups | ForEach-Object {
            try { $_.Translate([System.Security.Principal.NTAccount]).Value } catch { $_.Value }
        }
        if (-not $All) { return }
    }

    if ($User -or $All -or (-not $Groups)) {
        Write-Output $identity.Name.ToLower()
    }
}
