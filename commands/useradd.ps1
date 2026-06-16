function Wux_useradd {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory)][string]$Username,
        [Alias('c')][string]$Comment,
        [Alias('G')][string[]]$Groups,
        [Alias('p')][string]$Password
    )

    if ($PSCmdlet.ShouldProcess($Username, 'create local user')) {
        try {
            $params = @{ Name = $Username; ErrorAction = 'Stop' }
            if ($Password) {
                $params['Password'] = (ConvertTo-SecureString $Password -AsPlainText -Force)
            } else {
                $params['NoPassword'] = $true
            }
            if ($Comment) { $params['Description'] = $Comment }

            New-LocalUser @params | Out-Null
            Write-Verbose "useradd: user '$Username' created"

            foreach ($g in $Groups) {
                Add-LocalGroupMember -Group $g -Member $Username -ErrorAction SilentlyContinue
            }
        } catch {
            Write-Error "useradd: $($_.Exception.Message)"
        }
    }
}
