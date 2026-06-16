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

# Override built-in aliases that shadow our functions.
#
# PowerShell associates any alias set via Set-Alias -Scope Global while code is
# executing inside a module's context with that module, and deletes it as part of
# Remove-Module's own teardown -- even if a Module.OnRemove handler already restored
# it to its original value first. Restoring the aliases therefore can't be done from
# inside the module at all; it has to happen in a separate step after Remove-Module
# has fully returned. Uninstall-Wux (below) is that step -- use it instead of plain
# Remove-Module wux to get the original ls/rm/cat/etc. aliases back.
$savedAliases = @{}
$overrides    = @('cat','cp','mv','ps','tee','rm','echo','diff','sort','alias','man','pwd','ls','kill','wget','mount')
foreach ($name in $overrides) {
    $a = Get-Alias $name -Scope Global -ErrorAction SilentlyContinue
    if ($a) { $savedAliases[$name] = $a.Definition }
    Set-Alias -Name $name -Value "wux\$name" -Scope Global -Force -Option AllScope
}

# Defined directly on the Function: provider (not via Export-ModuleMember), so it
# isn't tracked as belonging to the module and survives Remove-Module wux.
Set-Item -Path Function:Global:Uninstall-Wux -Value {
    Remove-Module wux -Force -ErrorAction SilentlyContinue
    foreach ($name in $overrides) {
        if ($savedAliases.ContainsKey($name)) {
            Set-Alias -Name $name -Value $savedAliases[$name] -Scope Global -Force -Option AllScope -ErrorAction SilentlyContinue
        } else {
            Remove-Item "Alias:\$name" -Force -ErrorAction SilentlyContinue
        }
    }
}.GetNewClosure()

Export-ModuleMember -Function $script:_exportedNames
