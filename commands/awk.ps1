function awk {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Program,

        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [string[]]$Files,

        [Parameter(ValueFromPipeline = $true)]
        [string]$InputLine,

        [Alias('F')][string]$FieldSeparator = ' ',
        [Alias('p')][string]$ProgramFile,       # use -p for file; -f conflicts with -F
        [Alias('v')][string[]]$Assign,
        [Alias('W')][string]$Compat
    )

    begin { $pipeLines = [System.Collections.Generic.List[string]]::new() }

    process {
        if ($PSBoundParameters.ContainsKey('InputLine')) { $pipeLines.Add($InputLine) }
    }

    end {
        if ($ProgramFile) { $Program = Get-Content $ProgramFile -Raw }

        $vars = @{ FS = $FieldSeparator; OFS = ' '; ORS = "`n"; NR = 0; NF = 0 }
        foreach ($a in $Assign) {
            $kv = $a -split '=', 2
            if ($kv.Count -eq 2) { $vars[$kv[0]] = $kv[1] }
        }

        $beginBlock = ''
        $endBlock   = ''
        $rules      = [System.Collections.Generic.List[hashtable]]::new()

        function Extract-Block {
            param([string]$src)
            $src = $src.TrimStart()
            if ($src.Length -eq 0 -or $src[0] -ne '{') { return '', $src }
            $depth = 0; $i = 0
            while ($i -lt $src.Length) {
                if ($src[$i] -eq '{') { $depth++ }
                elseif ($src[$i] -eq '}') { $depth--; if ($depth -eq 0) { break } }
                $i++
            }
            return $src.Substring(1, $i - 1), $src.Substring($i + 1)
        }

        $rest = $Program
        while ($rest -and $rest.Trim()) {
            $rest = $rest.Trim()
            if ($rest -match '^BEGIN\s*\{') {
                $result = Extract-Block ($rest -replace '^BEGIN\s*', '')
                $beginBlock = $result[0]; $rest = $result[1]
            } elseif ($rest -match '^END\s*\{') {
                $result = Extract-Block ($rest -replace '^END\s*', '')
                $endBlock = $result[0]; $rest = $result[1]
            } elseif ($rest[0] -eq '{') {
                $result = Extract-Block $rest
                $rules.Add(@{ Pattern = ''; Body = $result[0] })
                $rest = $result[1]
            } elseif ($rest -match '^/([^/]+)/\s*') {
                $pat  = $Matches[1]
                $tail = $rest.Substring($Matches[0].Length)
                $result = Extract-Block $tail
                $rules.Add(@{ Pattern = $pat; Body = $result[0] })
                $rest = $result[1]
            } else {
                break
            }
        }

        function Eval-Expr {
            param([string]$expr, [hashtable]$ctx)
            $expr = $expr.Trim()
            if ($expr -match '^\$(\d+)$') {
                $n      = [int]$Matches[1]
                $fields = $ctx['_fields']
                if ($n -eq 0) { return $ctx['$0'] }
                if ($n -le $fields.Count) { return $fields[$n - 1] } else { return '' }
            }
            if ($expr -eq '$NF') {
                $fields = $ctx['_fields']
                if ($fields.Count -gt 0) { return $fields[-1] } else { return '' }
            }
            if ($ctx.ContainsKey($expr)) { return $ctx[$expr] }
            if ($expr -match '^"(.*)"$') { return $Matches[1] }
            return $expr
        }

        function Invoke-AwkBody {
            param([string]$body, [hashtable]$ctx)
            foreach ($stmt in ($body -split ';|\n' | Where-Object { $_.Trim() })) {
                $stmt = $stmt.Trim()
                if ($stmt -match '^print\b(.*)') {
                    $argStr = $Matches[1].Trim()
                    if (-not $argStr) {
                        Write-Output $ctx['$0']
                    } else {
                        $parts = $argStr -split ','
                        $out   = ($parts | ForEach-Object { Eval-Expr $_.Trim() $ctx }) -join $ctx['OFS']
                        Write-Output $out
                    }
                }
            }
        }

        function Process-Record {
            param([string]$record, [hashtable]$ctx)
            $ctx['NR']++
            $ctx['$0'] = $record
            $fs        = $ctx['FS']
            $fields    = if ($fs -eq ' ') {
                @($record -split '\s+' | Where-Object { $_ })
            } else {
                @($record -split [regex]::Escape($fs))
            }
            $ctx['_fields'] = $fields
            $ctx['NF']      = $fields.Count

            foreach ($rule in $rules) {
                $run = $false
                if (-not $rule.Pattern) { $run = $true }
                else { $run = $record -match $rule.Pattern }
                if ($run) { Invoke-AwkBody $rule.Body $ctx }
            }
        }

        if ($beginBlock) { Invoke-AwkBody $beginBlock $vars }

        if ($Files.Count -eq 0) {
            foreach ($line in $pipeLines) { Process-Record $line $vars }
        } else {
            foreach ($f in $Files) {
                if (-not (Test-Path $f)) { Write-Error "awk: ${f}: No such file or directory"; continue }
                foreach ($line in (Get-Content $f)) { Process-Record $line $vars }
            }
        }

        if ($endBlock) { Invoke-AwkBody $endBlock $vars }
    }
}
