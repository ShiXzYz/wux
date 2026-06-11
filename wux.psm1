$commandDir   = Join-Path $PSScriptRoot 'commands'
$completerDir = Join-Path $PSScriptRoot 'completers'

foreach ($file in Get-ChildItem $commandDir -Filter '*.ps1') {
    . $file.FullName
}

foreach ($file in Get-ChildItem $completerDir -Filter '*.ps1') {
    . $file.FullName
}

Register-WuxCompleters

Export-ModuleMember -Function grep, head, tail, sed, awk, find, touch, chmod
