function Wux_mv {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory)]
        [string]$Source,

        [Parameter(Position = 1, Mandatory)]
        [string]$Dest,

        [Alias('f')][switch]$Force,
        [Alias('n')][switch]$NoClobber,
        [Alias('b')][switch]$Backup
    )

    if (-not (Test-Path $Source)) {
        Write-Error "mv: cannot stat '${Source}': No such file or directory"; return
    }

    if ($NoClobber -and (Test-Path $Dest)) { return }

    if ($Backup -and (Test-Path $Dest)) {
        Copy-Item $Dest "$Dest~" -Force
    }

    if ($PSCmdlet.ShouldProcess("'$Source' -> '$Dest'", 'move')) {
        Move-Item -Path $Source -Destination $Dest -Force:$Force
        Write-Verbose "renamed '$Source' -> '$Dest'"
    }
}
