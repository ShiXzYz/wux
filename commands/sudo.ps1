function Wux_sudo {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromRemainingArguments)]
        [string[]]$Command
    )

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    if ($isAdmin) {
        $exe  = $Command[0]
        $rest = if ($Command.Count -gt 1) { $Command[1..($Command.Count - 1)] } else { @() }
        & $exe @rest
    } else {
        $cmdStr = $Command -join ' '
        Start-Process powershell -ArgumentList "-NoProfile -Command `"$cmdStr`"" -Verb RunAs -Wait
    }
}
