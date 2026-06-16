function Wux_apt {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)][string]$Action,
        [Parameter(Position = 1, ValueFromRemainingArguments)][string[]]$Packages
    )

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error 'apt: winget not found. Install the Windows Package Manager from https://aka.ms/winget'
        return
    }

    switch ($Action) {
        { $_ -in 'install','i' }       { & winget install @Packages }
        { $_ -in 'remove','uninstall' }{ & winget uninstall @Packages }
        { $_ -in 'update','upgrade' }  {
            if ($Packages) { & winget upgrade @Packages }
            else           { & winget upgrade --all }
        }
        'search'                        { & winget search @Packages }
        'list'                          { & winget list }
        { $_ -in 'show','info' }       { & winget show @Packages }
        'autoremove'                    { Write-Output 'apt: autoremove has no winget equivalent' }
        default                         { Write-Error "apt: unknown action: $Action (try: install, remove, update, search, list, show)" }
    }
}
