function Wux_export {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Assignments,
        [Alias('p')][switch]$Print
    )

    if ($Print -or -not $Assignments) {
        Get-ChildItem env: | ForEach-Object { "export $($_.Name)=$($_.Value)" }
        return
    }

    foreach ($a in $Assignments) {
        if ($a -match '^([^=]+)=(.*)$') {
            Set-Item "env:$($Matches[1])" $Matches[2]
        } else {
            Write-Error "export: `'$a`': not a valid assignment (use NAME=VALUE)"
        }
    }
}
