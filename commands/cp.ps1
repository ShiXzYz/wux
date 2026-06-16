function Wux_cp {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory)]
        [string]$Source,

        [Parameter(Position = 1, Mandatory)]
        [string]$Dest,

        [Alias('r')][switch]$Recursive,
        [Alias('f')][switch]$Force,
        [Alias('n')][switch]$NoClobber,
        [Alias('p')][switch]$PreserveTimestamps
    )

    if (-not (Test-Path $Source)) {
        Write-Error "cp: cannot stat '${Source}': No such file or directory"; return
    }

    $destIsDir = Test-Path $Dest -PathType Container

    if ((Test-Path $Source -PathType Container) -and -not $Recursive) {
        Write-Error "cp: -r not specified; omitting directory '${Source}'"; return
    }

    if ($NoClobber -and (Test-Path $Dest)) {
        return
    }

    $cpArgs = @{ Path = $Source; Destination = $Dest; Recurse = $Recursive; Force = $Force }

    if ($PSCmdlet.ShouldProcess("'$Source' -> '$Dest'", 'copy')) {
        Copy-Item @cpArgs
        Write-Verbose "'$Source' -> '$Dest'"

        if ($PreserveTimestamps -and (Test-Path $Dest)) {
            $src  = Get-Item $Source
            $dst  = Get-Item (Join-Path $Dest (Split-Path $Source -Leaf))
            if (Test-Path $dst) {
                $dst.LastWriteTime   = $src.LastWriteTime
                $dst.LastAccessTime  = $src.LastAccessTime
                $dst.CreationTime    = $src.CreationTime
            }
        }
    }
}
