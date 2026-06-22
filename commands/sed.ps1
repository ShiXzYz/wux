function Wux_sed {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [string]$Script,

        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [string[]]$Files,

        [Parameter(ValueFromPipeline = $true)]
        [string]$InputLine,

        [Alias('i')][string]$InPlace,
        [Alias('n')][switch]$Silent,
        [Alias('r')][switch]$ExtendedRegex,
        [Alias('e')][string[]]$Expression,
        [Alias('f')][string]$ScriptFile
    )

    begin { $pipeLines = [System.Collections.Generic.List[string]]::new() }

    process {
        if ($PSBoundParameters.ContainsKey('InputLine')) { $pipeLines.Add($InputLine) }
    }

    end {
        $scripts = @()
        if ($Expression)  { $scripts += $Expression }
        if ($ScriptFile)  { $scripts += Get-Content $ScriptFile }
        if ($Script -and $Script -notmatch '^-') { $scripts += $Script }

        function Apply-Script {
            param([string[]]$lines)

            $bufA = [System.Collections.Generic.List[string]]::new([string[]]$lines)
            $bufB = [System.Collections.Generic.List[string]]::new($bufA.Count)

            foreach ($s in $scripts) {
                if ($s -match '^s(.)(.+)\1(.*)\1([gip]*)$') {
                    $old        = $Matches[2]
                    $new        = $Matches[3]
                    $flags      = $Matches[4]

                    $regexOpts = if ($flags -match 'i') {
                        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
                    } else {
                        [System.Text.RegularExpressions.RegexOptions]::None
                    }
                    $re = [System.Text.RegularExpressions.Regex]::new($old, $regexOpts)

                    $printMatch = $flags -match 'p'
                    $global     = $flags -match 'g'

                    foreach ($line in $bufA) {
                        $replaced = if ($global) {
                            $re.Replace($line, $new)
                        } else {
                            $m = $re.Match($line)
                            if ($m.Success) {
                                $line.Substring(0, $m.Index) + $new + $line.Substring($m.Index + $m.Length)
                            } else { $line }
                        }
                        if (-not $Silent) { $bufB.Add($replaced) }
                        if ($printMatch -and $replaced -ne $line) { $bufB.Add($replaced) }
                    }
                } elseif ($s -match '^(\d*),?(\d*)d$') {
                    $a1 = if ($Matches[1]) { [int]$Matches[1] } else { 0 }
                    $a2 = if ($Matches[2]) { [int]$Matches[2] } else { $a1 }
                    $n  = 1
                    foreach ($line in $bufA) {
                        if ($n -lt $a1 -or $n -gt $a2) { $bufB.Add($line) }
                        $n++
                    }
                } elseif ($s -match '^(\d*)p$') {
                    $addr = if ($Matches[1]) { [int]$Matches[1] } else { 0 }
                    $n = 1
                    foreach ($line in $bufA) {
                        if (-not $Silent) { $bufB.Add($line) }
                        if ($addr -eq 0 -or $n -eq $addr) { $bufB.Add($line) }
                        $n++
                    }
                } elseif ($s -match '^q$') {
                    if ($bufA.Count -gt 0) { $bufB.Add($bufA[0]) }
                    break
                } else {
                    if (-not $Silent) { $bufB.AddRange($bufA) }
                }

                $bufA.Clear()
                $temp = $bufA; $bufA = $bufB; $bufB = $temp
            }

            return $bufA.ToArray()
        }

        if ($Files.Count -eq 0) {
            Apply-Script $pipeLines.ToArray() | Write-Output
        } else {
            foreach ($f in $Files) {
                if (-not (Test-Path $f)) { Write-Error "sed: ${f}: No such file or directory"; continue }
                $lines  = @(Get-Content $f)
                $result = Apply-Script $lines

                if ($PSBoundParameters.ContainsKey('InPlace')) {
                    if ($InPlace) { Copy-Item $f "$f$InPlace" }
                    $result | Set-Content $f
                } else {
                    $result | Write-Output
                }
            }
        }
    }
}
