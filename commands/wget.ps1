function wget {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)][string]$Url,
        [Alias('O')][string]$Output,
        [Alias('P')][string]$Directory,
        [Alias('q')][switch]$Quiet,
        [Alias('c')][switch]$Continue,
        [string]$UserAgent = 'Wget/1.21 (wux)'
    )

    if (-not $Output) {
        $Output = Split-Path $Url -Leaf
        if (-not $Output -or $Output -eq '') { $Output = 'index.html' }
    }

    if ($Directory) {
        if (-not (Test-Path $Directory)) { New-Item -ItemType Directory -Path $Directory | Out-Null }
        $Output = Join-Path $Directory $Output
    }

    $prev = $ProgressPreference
    $ProgressPreference = if ($Quiet) { 'SilentlyContinue' } else { 'Continue' }

    try {
        $params = @{
            Uri         = $Url
            OutFile     = $Output
            UserAgent   = $UserAgent
            ErrorAction = 'Stop'
        }
        if ($Continue -and (Test-Path $Output)) {
            $params['Resume'] = $true
        }
        Invoke-WebRequest @params
        if (-not $Quiet) { Write-Output "Saved: '$Output'" }
    } catch {
        Write-Error "wget: $($_.Exception.Message)"
    } finally {
        $ProgressPreference = $prev
    }
}
