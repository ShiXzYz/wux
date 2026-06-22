function Wux_grep {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [string]$Pattern,

        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [string[]]$Files,

        [Parameter(ValueFromPipeline = $true)]
        [string]$InputLine,

        [Alias('i')][switch]$IgnoreCase,
        [Alias('r')][switch]$Recursive,
        [Alias('l')][switch]$FilesWithMatches,
        [switch]$FilesWithoutMatches,        # -L: no short alias (conflicts with -l in PS)
        [Alias('n')][switch]$LineNumber,
        [Alias('c')][switch]$Count,
        [Alias('v')][switch]$InvertMatch,
        [Alias('w')][switch]$WordRegex,
        [Alias('x')][switch]$LineRegex,
        [Alias('o')][switch]$OnlyMatching,
        [Alias('q')][switch]$Quiet,
        [Alias('H')][switch]$WithFilename,
        [switch]$NoFilename,             # -h: no short alias (conflicts with -H in PS)
        [Alias('e')][string]$Regexp,
        [Alias('f')][string]$PatternFile,
        [Alias('A')][int]$AfterContext  = 0,
        [Alias('B')][int]$BeforeContext = 0,
        [int]$Context       = 0,         # -C: no short alias (conflicts with -c in PS)
        [Alias('m')][int]$MaxCount      = [int]::MaxValue,
        [string]$Color   = 'auto',
        [switch]$NoColor
    )

    begin { $pipeLines = [System.Collections.Generic.List[string]]::new() }

    process {
        if ($PSBoundParameters.ContainsKey('InputLine')) { $pipeLines.Add($InputLine) }
    }

    end {
        if ($Regexp)      { $Pattern = $Regexp }
        if ($PatternFile) { $Pattern = Get-Content $PatternFile -Raw }
        if ($Context -gt 0) { $AfterContext = $Context; $BeforeContext = $Context }

        $regexOpts = [System.Text.RegularExpressions.RegexOptions]::None
        if ($IgnoreCase) { $regexOpts = $regexOpts -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }

        if ($WordRegex) { $Pattern = "\b$Pattern\b" }
        if ($LineRegex) { $Pattern = "^(?:$Pattern)$" }

        $re = [System.Text.RegularExpressions.Regex]::new($Pattern, $regexOpts)

        $esc      = [char]27
        $useColor = -not $NoColor -and ($Color -eq 'always' -or ($Color -eq 'auto' -and $Host.UI.SupportsVirtualTerminal))

        $inputFiles = [System.Collections.Generic.List[object]]::new()
        $useStdin   = $false

        if ($Files.Count -eq 0) {
            $useStdin = $true
        } elseif ($Recursive) {
            foreach ($f in $Files) {
                foreach ($item in (Get-ChildItem -Path $f -Recurse -File -ErrorAction SilentlyContinue)) {
                    $inputFiles.Add($item)
                }
            }
        } else {
            foreach ($f in $Files) {
                if (Test-Path $f -PathType Container) {
                    Write-Error "grep: ${f}: Is a directory"
                } else {
                    $item = Get-Item $f -ErrorAction SilentlyContinue
                    if ($item) { $inputFiles.Add($item) }
                    else { Write-Error "grep: ${f}: No such file or directory" }
                }
            }
        }

        $showFilename = $WithFilename -or ($inputFiles.Count -gt 1 -and -not $NoFilename)
        $exitCode     = 1

        function Process-Lines {
            param($lines, $sourceName)

            $matchCount   = 0
            $matchedLines = [System.Collections.Generic.List[int]]::new()

            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line    = $lines[$i]
                $isMatch = $re.IsMatch($line)
                if ($InvertMatch) { $isMatch = -not $isMatch }

                if ($isMatch) {
                    $matchCount++
                    $matchedLines.Add($i)
                    if ($matchCount -ge $MaxCount) { break }
                }
            }

            if ($matchCount -gt 0) { return @{ Matches = $matchedLines; Count = $matchCount; HasMatch = $true } }
            else                    { return @{ Matches = $matchedLines; Count = 0; HasMatch = $false } }
        }

        function Output-Lines {
            param($lines, $sourceName, $matchedLines, $matchCount)

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
                        $ms = $re.Matches($line)
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
                        $colored = $re.Replace($line, { param($m) "${esc}[1;31m$($m.Value)${esc}[0m" })
                        Write-Output ($out + $colored)
                    } else {
                        Write-Output ($out + $line)
                    }
                }
            }
        }

        if ($useStdin) {
            $result = Process-Lines -lines $pipeLines.ToArray() -sourceName '(standard input)'
            if ($result.HasMatch) { $exitCode = 0 }
            Output-Lines -lines $pipeLines.ToArray() -sourceName '(standard input)' -matchedLines $result.Matches -matchCount $result.Count
        } else {
            foreach ($f in $inputFiles) {
                $lines = @(Get-Content $f.FullName)
                $result = Process-Lines -lines $lines -sourceName $f.FullName
                if ($result.HasMatch) { $exitCode = 0 }
                Output-Lines -lines $lines -sourceName $f.FullName -matchedLines $result.Matches -matchCount $result.Count
            }
        }

        $global:LASTEXITCODE = $exitCode
    }
}
