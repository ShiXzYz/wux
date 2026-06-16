function Wux_man {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)][string]$Command,
        [Alias('k')][switch]$Apropos
    )

    if ($Apropos) {
        Get-Help -Name "*$Command*" -ErrorAction SilentlyContinue |
            Select-Object Name, Synopsis |
            Format-Table -AutoSize
        return
    }

    $help = Get-Help $Command -Full -ErrorAction SilentlyContinue
    if ($help) {
        $help | Out-Host -Paging
    } else {
        Write-Error "man: no entry for $Command"
    }
}
