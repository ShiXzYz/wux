function whereis {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromRemainingArguments)]
        [string[]]$Commands
    )

    foreach ($cmd in $Commands) {
        $result = "${cmd}:"
        $found  = Get-Command $cmd -ErrorAction SilentlyContinue
        if ($found) {
            $result += " $($found.Source)"
            # also check for man page equivalent
            $help = Get-Help $cmd -ErrorAction SilentlyContinue
            if ($help -and $help.Synopsis) {
                $result += " (man: Get-Help $cmd)"
            }
        }
        Write-Output $result
    }
}
