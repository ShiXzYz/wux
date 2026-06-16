function Wux_zip {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)][string]$ZipFile,
        [Parameter(Position = 1, Mandatory, ValueFromRemainingArguments)][string[]]$Files,
        [Alias('r')][switch]$Recurse,
        [Alias('u')][switch]$Update,
        [Alias('q')][switch]$Quiet
    )

    if (-not $ZipFile.EndsWith('.zip')) { $ZipFile += '.zip' }

    foreach ($f in $Files) {
        if (-not (Test-Path $f)) { Write-Error "zip: cannot find '$f'"; return }
    }

    Compress-Archive -Path $Files -DestinationPath $ZipFile -Force -ErrorAction Stop

    if (-not $Quiet) {
        Write-Output "  adding: $($Files -join ', ') -> $ZipFile"
    }
}
