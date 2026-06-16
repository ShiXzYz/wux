function Wux_less {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][string]$File,
        [Parameter(ValueFromPipeline)][string]$InputObject
    )

    begin { $lines = [System.Collections.Generic.List[string]]::new() }

    process {
        if ($PSBoundParameters.ContainsKey('InputObject')) { $lines.Add($InputObject) }
    }

    end {
        if ($File) {
            if (-not (Test-Path $File)) { Write-Error "less: ${File}: No such file or directory"; return }
            $lines = [System.Collections.Generic.List[string]](Get-Content $File)
        }
        $lines | Out-Host -Paging
    }
}
