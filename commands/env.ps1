function Wux_env {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Args,

        [Alias('u')][string]$Unset,
        [Alias('i')][switch]$IgnoreEnvironment
    )

    # Unset a variable
    if ($Unset) {
        [System.Environment]::SetEnvironmentVariable($Unset, $null, 'Process')
        return
    }

    # Separate VAR=val assignments from the command to run
    $assignments = [ordered]@{}
    $cmdStart    = 0
    foreach ($a in $Args) {
        if ($a -match '^([^=]+)=(.*)$') {
            $assignments[$Matches[1]] = $Matches[2]
            $cmdStart++
        } else {
            break
        }
    }

    # Apply assignments (temporary for this session / permanent if running a command)
    foreach ($k in $assignments.Keys) {
        [System.Environment]::SetEnvironmentVariable($k, $assignments[$k], 'Process')
        Set-Item -Path "Env:\$k" -Value $assignments[$k]
    }

    if ($cmdStart -lt $Args.Count) {
        # Run the remaining args as a command
        $cmd     = $Args[$cmdStart]
        $cmdArgs = if ($Args.Count -gt $cmdStart + 1) { $Args[($cmdStart + 1)..($Args.Count - 1)] } else { @() }
        & $cmd @cmdArgs
    } elseif ($assignments.Count -eq 0) {
        # No command, no assignments — print all env vars
        Get-ChildItem Env: | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }
    }
}
