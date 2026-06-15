function passwd {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)][string]$Username = $env:USERNAME
    )

    if ($PSCmdlet.ShouldProcess($Username, 'change password')) {
        $secure = Read-Host "New password for $Username" -AsSecureString
        try {
            Set-LocalUser -Name $Username -Password $secure -ErrorAction Stop
            Write-Output "passwd: password updated successfully for $Username"
        } catch {
            Write-Error "passwd: $($_.Exception.Message)"
        }
    }
}
