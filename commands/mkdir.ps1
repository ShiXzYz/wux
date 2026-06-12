function mkdir {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromRemainingArguments)]
        [string[]]$Dirs,

        [Alias('p')][switch]$Parents,
        [string]$Mode  # accepted for compat; no-op on Windows
    )

    foreach ($dir in $Dirs) {
        if (Test-Path $dir) {
            if ($Parents) { continue }
            Write-Error "mkdir: cannot create directory '${dir}': File exists"
            continue
        }

        if ($PSCmdlet.ShouldProcess($dir, 'create directory')) {
            New-Item -ItemType Directory -Path $dir -Force:$Parents | Out-Null
            Write-Verbose "mkdir: created directory '$dir'"
        }
    }
}
