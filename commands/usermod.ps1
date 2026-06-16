function Wux_usermod {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory)][string]$Username,
        [Alias('c')][string]$Comment,
        [Alias('l')][string]$NewLogin,
        [Alias('G')][string[]]$Groups,
        [Alias('a')][switch]$Append   # append to groups (used with -G)
    )

    if ($PSCmdlet.ShouldProcess($Username, 'modify local user')) {
        try {
            if ($Comment)  { Set-LocalUser  -Name $Username -Description $Comment -ErrorAction Stop }
            if ($NewLogin) { Rename-LocalUser -Name $Username -NewName $NewLogin  -ErrorAction Stop }

            if ($Groups) {
                if (-not $Append) {
                    # Replace: remove from all local groups first
                    Get-LocalGroup | ForEach-Object {
                        Remove-LocalGroupMember -Group $_.Name -Member $Username -ErrorAction SilentlyContinue
                    }
                }
                foreach ($g in $Groups) {
                    Add-LocalGroupMember -Group $g -Member $Username -ErrorAction SilentlyContinue
                }
            }
        } catch {
            Write-Error "usermod: $($_.Exception.Message)"
        }
    }
}
