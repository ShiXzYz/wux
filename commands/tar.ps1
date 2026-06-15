function tar {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $tarExe = (Get-Command 'tar.exe' -ErrorAction SilentlyContinue)
    if (-not $tarExe) {
        Write-Error 'tar: tar.exe not found (requires Windows 10 build 17063+)'
        return
    }
    & $tarExe.Source @Arguments
}
