function Wux_whatis {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromRemainingArguments)]
        [string[]]$Commands
    )

    foreach ($cmd in $Commands) {
        $help = Get-Help $cmd -ErrorAction SilentlyContinue
        if ($help -and $help.Synopsis) {
            '{0} - {1}' -f $cmd, ($help.Synopsis -replace '\s+', ' ').Trim()
        } else {
            Write-Error "whatis: nothing appropriate for '$cmd'"
        }
    }
}
