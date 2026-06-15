function unzip {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)][string]$ZipFile,
        [Parameter(Position = 1)][string]$Destination = '.',
        [Alias('l')][switch]$List,
        [Alias('q')][switch]$Quiet,
        [Alias('o')][switch]$Overwrite
    )

    if (-not (Test-Path $ZipFile)) { Write-Error "unzip: cannot find '$ZipFile'"; return }

    if ($List) {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $ZipFile).Path)
        try {
            '{0,10}  {1,-20}  {2}' -f 'Length', 'Date', 'Name'
            '{0,10}  {1,-20}  {2}' -f '------', '----', '----'
            foreach ($e in $zip.Entries) {
                '{0,10}  {1,-20}  {2}' -f $e.Length, $e.LastWriteTime.ToString('yyyy-MM-dd HH:mm'), $e.FullName
            }
        } finally { $zip.Dispose() }
        return
    }

    Expand-Archive -Path $ZipFile -DestinationPath $Destination -Force:$Overwrite -ErrorAction Stop

    if (-not $Quiet) {
        Write-Output "Archive: $ZipFile"
        Write-Output "  inflating: $Destination"
    }
}
