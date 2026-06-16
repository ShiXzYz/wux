$commandDir   = Join-Path $PSScriptRoot 'commands'
$completerDir = Join-Path $PSScriptRoot 'completers'

$script:_exportedNames = @(
    'grep','head','tail','sed','awk','find','touch','chmod',
    'nano','ss','systemctl','df','du','ps','kill','which',
    'wc','tee','free','uptime','uniq','env',
    'cat','whoami','cp','mv','mkdir','chown','ls',
    'pwd','rm','ln','echo','less','man','uname','tar',
    'diff','cmp','comm','sort','export','zip','unzip',
    'service','killall','mount','ifconfig','traceroute',
    'wget','sudo','cal','alias','whereis','whatis','top',
    'useradd','usermod','passwd','apt'
)

foreach ($file in Get-ChildItem $commandDir -Filter '*.ps1') {
    . $file.FullName
}

foreach ($file in Get-ChildItem $completerDir -Filter '*.ps1') {
    . $file.FullName
}

Register-WuxCompleters

# Array splatting binds purely positionally in PowerShell -- it never re-parses
# "-a"-shaped strings as flags, so bundled switches (-la) can't just be expanded
# and re-splatted as an array. Instead, resolve tokens against the implementation
# function's own parameters/aliases (expanding bundles like -la -> -l -a along the
# way) and split them into a named hashtable (for switches/values) plus a leftover
# positional array, splatting both together.
function Resolve-WuxArguments {
    param(
        [string]$CommandName,
        [object[]]$Arguments
    )
    $empty = @{ Named = @{}; Positional = @() }
    if (-not $Arguments) { return $empty }
    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    if (-not $cmd) { return @{ Named = @{}; Positional = $Arguments } }

    $paramMap = [System.Collections.Generic.Dictionary[string,object]]::new([System.StringComparer]::Ordinal)
    foreach ($p in $cmd.Parameters.Values) {
        $paramMap[$p.Name] = $p
        foreach ($alias in $p.Aliases) { $paramMap[$alias] = $p }
    }

    $named      = @{}
    $positional = [System.Collections.Generic.List[object]]::new()
    $i = 0
    while ($i -lt $Arguments.Count) {
        $tok = $Arguments[$i]
        if ($tok -is [string] -and $tok -match '^-([A-Za-z0-9][A-Za-z0-9]*)$') {
            $pname = $Matches[1]
            if ($paramMap.ContainsKey($pname)) {
                $p = $paramMap[$pname]
                if ($p.ParameterType -eq [switch]) {
                    $named[$p.Name] = $true
                    $i++
                } else {
                    $i++
                    if ($i -lt $Arguments.Count) { $named[$p.Name] = $Arguments[$i]; $i++ }
                }
                continue
            } elseif ($pname.Length -gt 1) {
                $chars   = $pname.ToCharArray()
                $matched = [System.Collections.Generic.List[string]]::new()
                $allSwitch = $true
                foreach ($c in $chars) {
                    $key = [string]$c
                    if ($paramMap.ContainsKey($key) -and $paramMap[$key].ParameterType -eq [switch]) {
                        $matched.Add($paramMap[$key].Name)
                    } else { $allSwitch = $false; break }
                }
                if ($allSwitch) {
                    foreach ($n in $matched) { $named[$n] = $true }
                    $i++
                    continue
                }
            }
        }
        $positional.Add($tok)
        $i++
    }
    return @{ Named = $named; Positional = $positional.ToArray() }
}

# Thin wrappers: resolve bundled short flags against the real implementation's
# parameters, then forward to Wux_<name>. $input forwards pipeline objects through
# untouched for functions that bind ValueFromPipeline.
foreach ($name in $script:_exportedNames) {
    $implName = "Wux_$name"
    Invoke-Expression @"
function script:$name {
    `$resolved = Resolve-WuxArguments -CommandName '$implName' -Arguments `$args
    `$wuxPositional = `$resolved.Positional
    `$wuxNamed      = `$resolved.Named
    `$input | & $implName @wuxPositional @wuxNamed
}
"@
}

# Override built-in aliases that shadow our functions; restore originals on module unload
$script:_savedAliases = @{}
$script:_overrides = @('cat','cp','mv','ps','tee','rm','echo','diff','sort','alias','man','pwd','ls','kill','wget','mount')
foreach ($name in $script:_overrides) {
    $a = Get-Alias $name -Scope Global -ErrorAction SilentlyContinue
    if ($a) { $script:_savedAliases[$name] = $a.Definition }
    Set-Alias -Name $name -Value "wux\$name" -Scope Global -Force -Option AllScope
}

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    foreach ($name in $script:_savedAliases.Keys) {
        Set-Alias -Name $name -Value $script:_savedAliases[$name] -Scope Global -Force -ErrorAction SilentlyContinue
    }
    foreach ($name in $script:_overrides) {
        if (-not $script:_savedAliases.ContainsKey($name)) {
            Remove-Item "Alias:\$name" -Force -ErrorAction SilentlyContinue
        }
    }
}

Export-ModuleMember -Function $script:_exportedNames
