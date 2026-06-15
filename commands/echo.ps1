function echo {
    [CmdletBinding()]
    param(
        [Alias('e')][switch]$InterpretEscapes,
        [Alias('n')][switch]$NoNewline,
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Text
    )

    $out = if ($Text) { $Text -join ' ' } else { '' }

    if ($InterpretEscapes) {
        $out = $out -replace '\\\\', "`x00BACKSLASH`x00" `
                    -replace '\\n',  "`n" `
                    -replace '\\t',  "`t" `
                    -replace '\\r',  "`r" `
                    -replace '\\a',  "`a" `
                    -replace '\\b',  "`b" `
                    -replace '\\f',  "`f" `
                    -replace '\\v',  "`v" `
                    -replace '\\0',  "`0" `
                    -replace "`x00BACKSLASH`x00", '\'
    }

    if ($NoNewline) {
        [Console]::Write($out)
    } else {
        Write-Output $out
    }
}
