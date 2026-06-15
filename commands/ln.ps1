function ln {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Alias('s')][switch]$Symbolic,
        [Alias('f')][switch]$Force,
        [Alias('v')][switch]$Verbose,
        [Parameter(Position = 0, Mandatory)][string]$Target,
        [Parameter(Position = 1, Mandatory)][string]$LinkName
    )

    if ($Force -and (Test-Path $LinkName)) { Remove-Item $LinkName -Force }

    $type = if ($Symbolic) { 'SymbolicLink' } else { 'HardLink' }

    if ($PSCmdlet.ShouldProcess("$LinkName -> $Target", "create $type")) {
        try {
            New-Item -ItemType $type -Path $LinkName -Target $Target -ErrorAction Stop | Out-Null
            if ($Verbose) { Write-Output "'$LinkName' -> '$Target'" }
        } catch [UnauthorizedAccessException] {
            Write-Error "ln: failed to create $type '$LinkName': Permission denied (run as Administrator or enable Developer Mode)"
        } catch {
            Write-Error "ln: failed to create $type '$LinkName': $($_.Exception.Message)"
        }
    }
}
