function Wux_service {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory)][string]$ServiceName,
        [Parameter(Position = 1, Mandatory)]
        [ValidateSet('start','stop','restart','status','enable','disable','reload')]
        [string]$Action
    )

    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $svc) { Write-Error "service: ${ServiceName}: not found"; return }

    switch ($Action) {
        'start'   {
            if ($PSCmdlet.ShouldProcess($ServiceName, 'start')) { Start-Service -Name $ServiceName }
        }
        'stop'    {
            if ($PSCmdlet.ShouldProcess($ServiceName, 'stop'))  { Stop-Service  -Name $ServiceName }
        }
        'restart' {
            if ($PSCmdlet.ShouldProcess($ServiceName, 'restart')) { Restart-Service -Name $ServiceName }
        }
        'reload'  {
            if ($PSCmdlet.ShouldProcess($ServiceName, 'restart')) { Restart-Service -Name $ServiceName }
        }
        'status'  {
            Get-Service -Name $ServiceName | Select-Object Name, DisplayName, Status, StartType | Format-List
        }
        'enable'  {
            if ($PSCmdlet.ShouldProcess($ServiceName, 'enable (set Automatic)')) {
                Set-Service -Name $ServiceName -StartupType Automatic
            }
        }
        'disable' {
            if ($PSCmdlet.ShouldProcess($ServiceName, 'disable')) {
                Set-Service -Name $ServiceName -StartupType Disabled
            }
        }
    }
}
