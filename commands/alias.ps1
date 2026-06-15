function alias {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Definitions
    )

    if (-not $Definitions) {
        Get-Alias | Sort-Object Name | ForEach-Object {
            "alias $($_.Name)='$($_.Definition)'"
        }
        return
    }

    foreach ($def in $Definitions) {
        if ($def -match "^([^=]+)=(.+)$") {
            $name  = $Matches[1].Trim()
            $value = $Matches[2].Trim("'`"")
            Set-Alias -Name $name -Value $value -Scope Global -Force
        } else {
            $a = Get-Alias $def -ErrorAction SilentlyContinue
            if ($a) { "alias $($a.Name)='$($a.Definition)'" }
            else    { Write-Error "alias: $def: not found" }
        }
    }
}
