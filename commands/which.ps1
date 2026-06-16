function Wux_which {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromRemainingArguments)]
        [string[]]$Commands,

        [Alias('a')][switch]$All
    )

    $failed = $false

    foreach ($cmd in $Commands) {
        $results = if ($All) {
            Get-Command $cmd -All -ErrorAction SilentlyContinue
        } else {
            @(Get-Command $cmd -ErrorAction SilentlyContinue | Select-Object -First 1)
        }

        if (-not $results) {
            Write-Error "which: no '$cmd' in PATH"
            $failed = $true
            continue
        }

        foreach ($r in $results) {
            switch ($r.CommandType) {
                'Application' { $r.Source }
                'Alias'       { "$($r.Name): aliased to $($r.Definition)" }
                'Function'    {
                    if ($r.ScriptBlock.File) { $r.ScriptBlock.File }
                    else { "$($r.Name): shell function" }
                }
                'Cmdlet'      { if ($r.Module.Path) { $r.Module.Path } else { $r.Name } }
                default       { if ($r.Source) { $r.Source } else { $r.Name } }
            }
        }
    }

    $global:LASTEXITCODE = if ($failed) { 1 } else { 0 }
}
