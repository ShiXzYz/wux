function nano {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$File,

        [Alias('R')][switch]$ReadOnly
    )

    # Prefer a real nano binary (Application), not this function
    $nanoBin = Get-Command -CommandType Application -Name nano -ErrorAction SilentlyContinue |
                   Select-Object -First 1
    if ($nanoBin) {
        $nanoArgs = @()
        if ($ReadOnly -and $File) { $nanoArgs += '--view' }
        if ($File) { $nanoArgs += $File }
        & $nanoBin.Source @nanoArgs
        return
    }

    # Fall back to VS Code (opens asynchronously)
    $codeBin = Get-Command -CommandType Application -Name code -ErrorAction SilentlyContinue |
                   Select-Object -First 1
    if ($codeBin) {
        if ($File) { & code $File } else { & code }
        return
    }

    # Last resort: notepad
    if ($File) { Start-Process notepad $File -Wait }
    else        { Start-Process notepad -Wait }
}
