$commandDir   = Join-Path $PSScriptRoot 'commands'
$completerDir = Join-Path $PSScriptRoot 'completers'

foreach ($file in Get-ChildItem $commandDir -Filter '*.ps1') {
    . $file.FullName
}

foreach ($file in Get-ChildItem $completerDir -Filter '*.ps1') {
    . $file.FullName
}

Register-WuxCompleters

# Override built-in aliases that shadow our functions; restore originals on module unload
$script:_savedAliases = @{}
$script:_overrides = @('cat','cp','mv','ps','tee','rm','echo','diff','sort','alias','man','pwd')
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

Export-ModuleMember -Function grep, head, tail, sed, awk, find, touch, chmod,
                               nano, ss, systemctl, df, du, ps, kill, which,
                               wc, tee, free, uptime, uniq, env,
                               cat, whoami, cp, mv, mkdir, chown, ls,
                               pwd, rm, ln, echo, less, man, uname, tar,
                               diff, cmp, comm, sort, export, zip, unzip,
                               service, killall, mount, ifconfig, traceroute,
                               wget, sudo, cal, alias, whereis, whatis, top,
                               useradd, usermod, passwd, apt
