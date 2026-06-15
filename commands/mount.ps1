function mount {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)][string]$Source,
        [Parameter(Position = 1)][string]$Target,
        [Alias('t')][string]$Type,
        [Alias('o')][string]$Options
    )

    if (-not $Source) {
        # List mounted volumes
        '{0,-12} {1,-10} {2}' -f 'Filesystem', 'Type', 'Mount point'
        Get-PSDrive -PSProvider FileSystem | ForEach-Object {
            $fsType = if ($_.DisplayRoot) { 'cifs' } else { 'ntfs' }
            '{0,-12} {1,-10} {2}' -f ($_.Root.TrimEnd('\')), $fsType, $_.Root
        }
        return
    }

    if ($Source -match '\.(iso|vhd|vhdx)$') {
        $resolved = Resolve-Path $Source -ErrorAction SilentlyContinue
        if (-not $resolved) { Write-Error "mount: cannot find '$Source'"; return }
        if ($PSCmdlet.ShouldProcess($Source, 'mount disk image')) {
            Mount-DiskImage -ImagePath $resolved.Path
        }
        return
    }

    Write-Error "mount: on Windows, only .iso/.vhd/.vhdx files are directly mountable. Use Disk Management for other operations."
}
