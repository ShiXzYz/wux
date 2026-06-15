function rm {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromRemainingArguments)]
        [string[]]$Paths,

        [Alias('r','R')][switch]$Recursive,
        [Alias('f')][switch]$Force,
        [Alias('i')][switch]$Interactive,
        [Alias('v')][switch]$Verbose
    )

    foreach ($path in $Paths) {
        if (-not (Test-Path $path -ErrorAction SilentlyContinue)) {
            if (-not $Force) { Write-Error "rm: cannot remove '$path': No such file or directory" }
            continue
        }

        $item = Get-Item $path -Force -ErrorAction SilentlyContinue
        if ($item.PSIsContainer -and -not $Recursive) {
            Write-Error "rm: cannot remove '$path': Is a directory"
            continue
        }

        if ($Interactive -and -not $PSCmdlet.ShouldProcess($path, 'remove')) { continue }

        Remove-Item $path -Recurse:$Recursive -Force:$Force -ErrorAction (if ($Force) { 'SilentlyContinue' } else { 'Stop' })
        if ($Verbose) { Write-Output "removed '$path'" }
    }
}
