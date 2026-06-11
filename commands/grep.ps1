function grep {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [string]$Pattern,

        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [string[]]$Files,

        [Alias('i')][switch]$IgnoreCase,
        [Alias('r')][switch]$Recursive,
        [Alias('l')][switch]$FilesWithMatches,
        [Alias('L')][switch]$FilesWithoutMatches,
        [Alias('n')][switch]$LineNumber,
        [Alias('c')][switch]$Count,
        [Alias('v')][switch]$InvertMatch,
        [Alias('w')][switch]$WordRegex,
        [Alias('x')][switch]$LineRegex,
        [Alias('o')][switch]$OnlyMatching,
        [Alias('q')][switch]$Quiet,
        [Alias('H')][switch]$WithFilename,
        [Alias('h')][switch]$NoFilename,
        [Alias('e')][string]$Regexp,
        [Alias('f')][string]$PatternFile,
        [Alias('A')][int]$AfterContext = 0,
        [Alias('B')][int]$BeforeContext = 0,
        [Alias('C')][int]$Context = 0,
        [Alias('m')][int]$MaxCount = [int]::MaxValue,
        [string]$Color = 'auto',
        [switch]$NoColor
    )

    if ($Regexp)      { $Pattern = $Regexp }
    if ($PatternFile) { $Pattern = Get-Content $PatternFile -Raw }
    if ($Context -gt 0) { $AfterContext = $Context; $BeforeContext = $Context }

    $regexOpts = [System.Text.RegularExpressions.RegexOptions]::None
    if ($IgnoreCase) { $regexOpts = $regexOpts -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }

    if ($WordRegex) { $Pattern = "\b$Pattern\b" }
    if ($LineRegex) { $Pattern = "^(?:$Pattern)$" }

    $useColor = -not $NoColor -and ($Color -eq 'always' -or ($Color -eq 'auto' -and $Host.UI.SupportsVirtualTerminal))

    $inputFiles = @()
    $useStdin   = $false

    if ($Files.Count -eq 0) {
        $useStdin = $true
    } elseif ($Recursive) {
        foreach ($f in $Files) {
            $inputFiles += Get-ChildItem -Path $f -Recurse -File -ErrorAction SilentlyContinue
        }
    } else {
        foreach ($f in $Files) {
            if (Test-Path $f -PathType Container) {
                Write-Error "grep: ${f}: Is a directory"
            } else {
                $item = Get-Item $f -ErrorAction SilentlyContinue
                if ($item) { $inputFiles += $item }
                else { Write-Error "grep: ${f}: No such file or directory" }
            }
        }
    }

    $showFilename = $WithFilename -or ($inputFiles.Count -gt 1 -and -not $NoFilename)
    $foundAny     = $false
    $exitCode     = 1

    function Process-Lines {
        param($lines, $sourceName)

        $matchCount   = 0
        $matchedLines = @()

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line    = $lines[$i]
            $isMatch = [System.Text.RegularExpressions.Regex]::IsMatch($line, $Pattern, $regexOpts)
            if ($InvertMatch) { $isMatch = -not $isMatch }

            if ($isMatch) {
                $matchCount++
                $matchedLines += $i
                $script:exitCode = 0
                $script:foundAny = $true
                if ($matchCount -ge $MaxCount) { break }
            }
        }

        if ($Count) {
            $prefix = if ($showFilename) { "${sourceName}:" } else { "" }
            Write-Output "${prefix}${matchCount}"
            return
        }

        if ($FilesWithMatches)    { if ($matchCount -gt 0) { Write-Output $sourceName }; return }
        if ($FilesWithoutMatches) { if ($matchCount -eq 0) { Write-Output $sourceName }; return }

        foreach ($idx in $matchedLines) {
            $start = [Math]::Max(0, $idx - $BeforeContext)
            $end   = [Math]::Min($lines.Count - 1, $idx + $AfterContext)

            for ($j = $start; $j -le $end; $j++) {
                $line = $lines[$j]
                $sep  = if ($j -eq $idx) { ':' } else { '-' }

                if ($Quiet) { return }

                if ($OnlyMatching -and $j -eq $idx) {
                    $ms = [System.Text.RegularExpressions.Regex]::Matches($line, $Pattern, $regexOpts)
                    foreach ($m in $ms) {
                        $out = ""
                        if ($showFilename) { $out += "${sourceName}:" }
                        if ($LineNumber)   { $out += "$($j+1):" }
                        Write-Output ($out + $m.Value)
                    }
                    continue
                }

                $out = ""
                if ($showFilename) { $out += "${sourceName}${sep}" }
                if ($LineNumber)   { $out += "$($j+1)${sep}" }

                if ($useColor -and $j -eq $idx -and -not $InvertMatch) {
                    $colored = [System.Text.RegularExpressions.Regex]::Replace(
                        $line, $Pattern,
                        { param($m) "`e[1;31m$($m.Value)`e[0m" },
                        $regexOpts
                    )
                    Write-Output ($out + $colored)
                } else {
                    Write-Output ($out + $line)
                }
            }
        }
    }

    if ($useStdin) {
        $lines = @($Input)
        Process-Lines -lines $lines -sourceName '(standard input)'
    } else {
        foreach ($f in $inputFiles) {
            $lines = @(Get-Content $f.FullName)
            Process-Lines -lines $lines -sourceName $f.FullName
        }
    }

    $global:LASTEXITCODE = $exitCode
}
