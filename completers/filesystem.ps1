function Register-WuxCompleters {
    $wuxCommands = @('grep','head','tail','sed','awk','find','touch','chmod')

    foreach ($cmd in $wuxCommands) {
        Register-ArgumentCompleter -CommandName $cmd -ScriptBlock {
            param($wordToComplete, $commandAst, $cursorPosition)

            # Flags for each command
            $flagMap = @{
                grep  = @('-i','-r','-R','-l','-L','-n','-c','-v','-w','-x','-o','-q','-H','-h',
                           '-e','-f','-A','-B','-C','-m','--color','--no-color')
                head  = @('-n','-c','-q','-v')
                tail  = @('-n','-c','-f','-q','-v')
                sed   = @('-i','-n','-E','-r','-e','-f')
                awk   = @('-F','-f','-v','-W')
                find  = @('-name','-iname','-type','-newer','-maxdepth','-mindepth',
                           '-mtime','-size','-empty','-delete','-exec','-print','-L')
                touch = @('-a','-m','-c','-t','-r','-d')
                chmod = @('-R','-v','-c')
            }

            $cmdName = $commandAst.CommandElements[0].Value
            $tokens  = $commandAst.CommandElements | Select-Object -Skip 1 | ForEach-Object { "$_" }
            $prev    = if ($tokens.Count -ge 2) { $tokens[-2] } else { $null }

            # If completing a flag
            if ($wordToComplete.StartsWith('-')) {
                $flags = $flagMap[$cmdName]
                if ($flags) {
                    return $flags | Where-Object { $_ -like "$wordToComplete*" } |
                        ForEach-Object {
                            [System.Management.Automation.CompletionResult]::new(
                                $_, $_, 'ParameterValue', $_
                            )
                        }
                }
                return
            }

            # Flags that expect a non-file argument — skip file completion
            $nonFileFlags = @('-n','-c','-A','-B','-C','-m','-F','-v','-t','-d','-type',
                              '-maxdepth','-mindepth','-mtime','-size','-newer','-r','-exec')
            if ($prev -in $nonFileFlags) { return }

            # Complete file/folder paths
            $searchPath = if ($wordToComplete) { $wordToComplete } else { '.' }
            $dir  = Split-Path $searchPath -Parent
            $leaf = Split-Path $searchPath -Leaf

            if (-not $dir) { $dir = '.' }

            Get-ChildItem -Path $dir -Filter "$leaf*" -Force -ErrorAction SilentlyContinue |
                ForEach-Object {
                    $completion = if ($_.PSIsContainer) { "$($_.FullName)\" } else { $_.FullName }
                    $display    = if ($_.PSIsContainer) { "$($_.Name)/" } else { $_.Name }
                    $tooltip    = if ($_.PSIsContainer) { "[dir]  $($_.FullName)" } else {
                        "[file] $($_.FullName)  ($([Math]::Round($_.Length/1KB,1)) KB)"
                    }
                    [System.Management.Automation.CompletionResult]::new(
                        $completion, $display, 'ProviderItem', $tooltip
                    )
                }
        }
    }
}
