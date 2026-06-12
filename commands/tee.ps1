function tee {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [string]$File,

        [Alias('a')][switch]$Append,

        [Parameter(ValueFromPipeline = $true)]
        [object]$InputObject
    )

    begin {
        $mode   = if ($Append) { [System.IO.FileMode]::Append } else { [System.IO.FileMode]::Create }
        $stream = [System.IO.File]::Open($File, $mode, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
        $writer = [System.IO.StreamWriter]::new($stream)
    }

    process {
        Write-Output $InputObject
        $writer.WriteLine("$InputObject")
    }

    end {
        $writer.Close()
        $stream.Close()
    }
}
