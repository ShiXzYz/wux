function Wux_nano {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$File,

        [Alias('R')][switch]$ReadOnly,
        [Alias('c')][switch]$ConstantShow,
        [Alias('l')][switch]$LineNumbers
    )

    $script:nanoLines     = [System.Collections.Generic.List[string]]::new()
    $script:nanoCurRow    = 0
    $script:nanoCurCol    = 0
    $script:nanoOffsetRow = 0
    $script:nanoOffsetCol = 0
    $script:nanoReadOnly  = [bool]$ReadOnly
    $script:nanoModified  = $false
    $script:nanoStatus    = ''
    $script:nanoStatusTTL = 0
    $script:nanoShowLines = [bool]$LineNumbers -or [bool]$ConstantShow
    $script:nanoRunning   = $true
    $script:nanoCutBuffer = ''
    $script:nanoSearchTerm = ''

    if ($File) {
        $script:nanoFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($File)
    } else {
        $script:nanoFile = ''
    }

    if ($script:nanoFile -and (Test-Path $script:nanoFile)) {
        $content = Get-Content $script:nanoFile -Raw
        if ($null -eq $content -or $content -eq '') {
            $script:nanoLines.Add('')
        } else {
            foreach ($ln in $content -split "`r?`n") {
                $script:nanoLines.Add($ln)
            }
        }
    } else {
        $script:nanoLines.Add('')
    }

    $script:nanoDisplayName = if ($script:nanoFile) { $script:nanoFile } else { 'New Buffer' }

    $origBg      = [Console]::BackgroundColor
    $origFg      = [Console]::ForegroundColor
    $origTitle   = [Console]::Title
    $origCurSize = [Console]::CursorSize
    [Console]::Title = "nano - $($script:nanoDisplayName)"
    [Console]::CursorVisible = $false
    [Console]::Clear()

    try {
        Nano-Render
        while ($script:nanoRunning) {
            $key = [Console]::ReadKey($true)
            Nano-HandleKey $key
            Nano-Render
        }
    } finally {
        [Console]::BackgroundColor = $origBg
        [Console]::ForegroundColor = $origFg
        [Console]::CursorVisible = $true
        [Console]::Title = $origTitle
        [Console]::Clear()
    }
}

function Nano-WriteInverted {
    param([string]$text)
    $saveBg = [Console]::BackgroundColor
    $saveFg = [Console]::ForegroundColor
    [Console]::BackgroundColor = $saveFg
    [Console]::ForegroundColor = $saveBg
    [Console]::Write($text)
    [Console]::BackgroundColor = $saveBg
    [Console]::ForegroundColor = $saveFg
}

function Nano-WriteDim {
    param([string]$text)
    $saveFg = [Console]::ForegroundColor
    [Console]::ForegroundColor = [ConsoleColor]::DarkGray
    [Console]::Write($text)
    [Console]::ForegroundColor = $saveFg
}

function Nano-Render {
    $w = [Console]::WindowWidth
    $h = [Console]::WindowHeight
    $editH = $h - 3

    [Console]::CursorVisible = $false
    [Console]::SetCursorPosition(0, 0)

    # Title bar
    $titleText = if ($script:nanoModified) { "  nano: $($script:nanoDisplayName) [Modified]" }
                 else { "  nano: $($script:nanoDisplayName)" }
    if ($titleText.Length -lt $w) { $titleText = $titleText.PadRight($w) }
    if ($titleText.Length -gt $w) { $titleText = $titleText.Substring(0, $w) }
    Nano-WriteInverted $titleText

    # Gutter width for line numbers
    $gutter = 0
    if ($script:nanoShowLines) {
        $maxLine = $script:nanoOffsetRow + $editH
        $gutter = ([string]$maxLine).Length + 1
    }

    # Text area
    for ($row = 0; $row -lt $editH; $row++) {
        [Console]::SetCursorPosition(0, $row + 1)
        $lineIdx = $script:nanoOffsetRow + $row
        $avail = $w - $gutter

        if ($script:nanoShowLines -and $lineIdx -lt $script:nanoLines.Count) {
            $num = ('{0,' + ($gutter - 1) + '}') -f ($lineIdx + 1)
            Nano-WriteDim "$num "
        } elseif ($script:nanoShowLines) {
            [Console]::Write((' ' * $gutter))
        }

        if ($lineIdx -lt $script:nanoLines.Count) {
            $line = $script:nanoLines[$lineIdx]
            if ($script:nanoOffsetCol -lt $line.Length) {
                $visible = $line.Substring($script:nanoOffsetCol, [Math]::Min($avail, $line.Length - $script:nanoOffsetCol))
            } else {
                $visible = ''
            }
            if ($visible.Length -lt $avail) { $visible = $visible.PadRight($avail) }
            if ($visible.Length -gt $avail) { $visible = $visible.Substring(0, $avail) }
            [Console]::Write($visible)
        } else {
            [Console]::Write((' ' * $avail))
        }
    }

    # Status line
    [Console]::SetCursorPosition(0, $h - 3)
    if ($script:nanoStatusTTL -gt 0) {
        $statusLine = "  $($script:nanoStatus)"
        $script:nanoStatusTTL--
    } else {
        $pos = "[ Ln $($script:nanoCurRow + 1), Col $($script:nanoCurCol + 1) ]"
        $statusLine = $pos.PadLeft($w)
    }
    if ($statusLine.Length -lt $w) { $statusLine = $statusLine.PadRight($w) }
    if ($statusLine.Length -gt $w) { $statusLine = $statusLine.Substring(0, $w) }
    Nano-WriteInverted $statusLine

    # Shortcut bars
    [Console]::SetCursorPosition(0, $h - 2)
    Nano-RenderShortcutBar @(
        @('^G','Help'), @('^O','Save'), @('^W','Search'),
        @('^K','Cut'),  @('^U','Paste'),@('^X','Exit')
    ) $w
    [Console]::SetCursorPosition(0, $h - 1)
    Nano-RenderShortcutBar @(
        @('^\ ','Replace'), @('^C','Pos'),  @('^J','Justify'),
        @('^T','Spell'),    @('^_','GoTo'), @('^R','Read')
    ) $w

    # Position real cursor
    $curScreenCol = ($script:nanoCurCol - $script:nanoOffsetCol) + $gutter
    $curScreenRow = ($script:nanoCurRow - $script:nanoOffsetRow) + 1
    if ($curScreenCol -ge $w) { $curScreenCol = $w - 1 }
    if ($curScreenCol -lt $gutter) { $curScreenCol = $gutter }
    [Console]::SetCursorPosition($curScreenCol, $curScreenRow)
    [Console]::CursorVisible = $true
}

function Nano-RenderShortcutBar {
    param([object[]]$items, [int]$width)
    $cellW = [Math]::Floor($width / $items.Count)
    $written = 0
    foreach ($pair in $items) {
        $keyText = $pair[0]
        $label   = $pair[1]
        Nano-WriteInverted $keyText
        $rest = " $label"
        $pad = $cellW - $keyText.Length - $rest.Length
        if ($pad -gt 0) { $rest += ' ' * $pad }
        [Console]::Write($rest)
        $written += $keyText.Length + $rest.Length
    }
    if ($written -lt $width) {
        [Console]::Write((' ' * ($width - $written)))
    }
}

function Nano-HandleKey {
    param([System.ConsoleKeyInfo]$key)

    $ctrl = $key.Modifiers -band [ConsoleModifiers]::Control
    $h = [Console]::WindowHeight
    $editH = $h - 3

    if ($ctrl) {
        switch ($key.Key) {
            'X' { Nano-Exit; return }
            'O' { Nano-Save; return }
            'W' { Nano-Search; return }
            'K' { Nano-CutLine; return }
            'U' { Nano-PasteLine; return }
            'G' { Nano-SetStatus 'Help: ^O Save | ^X Exit | ^W Search | ^K Cut | ^U Paste'; return }
            'C' { Nano-SetStatus "Line $($script:nanoCurRow + 1), Col $($script:nanoCurCol + 1), Lines $($script:nanoLines.Count)"; return }
        }
        return
    }

    switch ($key.Key) {
        'UpArrow'    { Nano-MoveUp; return }
        'DownArrow'  { Nano-MoveDown; return }
        'LeftArrow'  { Nano-MoveLeft; return }
        'RightArrow' { Nano-MoveRight; return }
        'Home'       { $script:nanoCurCol = 0; Nano-AdjustView; return }
        'End'        { $script:nanoCurCol = $script:nanoLines[$script:nanoCurRow].Length; Nano-AdjustView; return }
        'PageUp'     { $script:nanoCurRow = [Math]::Max(0, $script:nanoCurRow - $editH); Nano-AdjustView; return }
        'PageDown'   { $script:nanoCurRow = [Math]::Min($script:nanoLines.Count - 1, $script:nanoCurRow + $editH); Nano-AdjustView; return }
        'Backspace'  { Nano-Backspace; return }
        'Delete'     { Nano-Delete; return }
        'Enter'      { Nano-Enter; return }
        'Tab'        { Nano-InsertChar "`t"; return }
    }

    $ch = $key.KeyChar
    if ($ch -and [int]$ch -ge 32) {
        Nano-InsertChar ([string]$ch)
    }
}

function Nano-MoveUp {
    if ($script:nanoCurRow -gt 0) {
        $script:nanoCurRow--
        $lineLen = $script:nanoLines[$script:nanoCurRow].Length
        if ($script:nanoCurCol -gt $lineLen) { $script:nanoCurCol = $lineLen }
    }
    Nano-AdjustView
}

function Nano-MoveDown {
    if ($script:nanoCurRow -lt ($script:nanoLines.Count - 1)) {
        $script:nanoCurRow++
        $lineLen = $script:nanoLines[$script:nanoCurRow].Length
        if ($script:nanoCurCol -gt $lineLen) { $script:nanoCurCol = $lineLen }
    }
    Nano-AdjustView
}

function Nano-MoveLeft {
    if ($script:nanoCurCol -gt 0) {
        $script:nanoCurCol--
    } elseif ($script:nanoCurRow -gt 0) {
        $script:nanoCurRow--
        $script:nanoCurCol = $script:nanoLines[$script:nanoCurRow].Length
    }
    Nano-AdjustView
}

function Nano-MoveRight {
    $lineLen = $script:nanoLines[$script:nanoCurRow].Length
    if ($script:nanoCurCol -lt $lineLen) {
        $script:nanoCurCol++
    } elseif ($script:nanoCurRow -lt ($script:nanoLines.Count - 1)) {
        $script:nanoCurRow++
        $script:nanoCurCol = 0
    }
    Nano-AdjustView
}

function Nano-Backspace {
    if ($script:nanoReadOnly) { Nano-SetStatus '[ Read-Only Mode ]'; return }
    if ($script:nanoCurCol -gt 0) {
        $line = $script:nanoLines[$script:nanoCurRow]
        $script:nanoLines[$script:nanoCurRow] = $line.Substring(0, $script:nanoCurCol - 1) + $line.Substring($script:nanoCurCol)
        $script:nanoCurCol--
        $script:nanoModified = $true
    } elseif ($script:nanoCurRow -gt 0) {
        $prevLine = $script:nanoLines[$script:nanoCurRow - 1]
        $curLine  = $script:nanoLines[$script:nanoCurRow]
        $script:nanoCurCol = $prevLine.Length
        $script:nanoLines[$script:nanoCurRow - 1] = $prevLine + $curLine
        $script:nanoLines.RemoveAt($script:nanoCurRow)
        $script:nanoCurRow--
        $script:nanoModified = $true
    }
    Nano-AdjustView
}

function Nano-Delete {
    if ($script:nanoReadOnly) { Nano-SetStatus '[ Read-Only Mode ]'; return }
    $line = $script:nanoLines[$script:nanoCurRow]
    if ($script:nanoCurCol -lt $line.Length) {
        $script:nanoLines[$script:nanoCurRow] = $line.Substring(0, $script:nanoCurCol) + $line.Substring($script:nanoCurCol + 1)
        $script:nanoModified = $true
    } elseif ($script:nanoCurRow -lt ($script:nanoLines.Count - 1)) {
        $script:nanoLines[$script:nanoCurRow] = $line + $script:nanoLines[$script:nanoCurRow + 1]
        $script:nanoLines.RemoveAt($script:nanoCurRow + 1)
        $script:nanoModified = $true
    }
}

function Nano-Enter {
    if ($script:nanoReadOnly) { Nano-SetStatus '[ Read-Only Mode ]'; return }
    $line = $script:nanoLines[$script:nanoCurRow]
    $before = $line.Substring(0, $script:nanoCurCol)
    $after  = $line.Substring($script:nanoCurCol)
    $script:nanoLines[$script:nanoCurRow] = $before
    $script:nanoLines.Insert($script:nanoCurRow + 1, $after)
    $script:nanoCurRow++
    $script:nanoCurCol = 0
    $script:nanoModified = $true
    Nano-AdjustView
}

function Nano-InsertChar {
    param([string]$ch)
    if ($script:nanoReadOnly) { Nano-SetStatus '[ Read-Only Mode ]'; return }
    $line = $script:nanoLines[$script:nanoCurRow]
    $script:nanoLines[$script:nanoCurRow] = $line.Insert($script:nanoCurCol, $ch)
    $script:nanoCurCol += $ch.Length
    $script:nanoModified = $true
    Nano-AdjustView
}

function Nano-CutLine {
    if ($script:nanoReadOnly) { Nano-SetStatus '[ Read-Only Mode ]'; return }
    $script:nanoCutBuffer = $script:nanoLines[$script:nanoCurRow]
    if ($script:nanoLines.Count -gt 1) {
        $script:nanoLines.RemoveAt($script:nanoCurRow)
        if ($script:nanoCurRow -ge $script:nanoLines.Count) {
            $script:nanoCurRow = $script:nanoLines.Count - 1
        }
    } else {
        $script:nanoLines[0] = ''
    }
    $lineLen = $script:nanoLines[$script:nanoCurRow].Length
    if ($script:nanoCurCol -gt $lineLen) { $script:nanoCurCol = $lineLen }
    $script:nanoModified = $true
    Nano-SetStatus '[ Cut 1 line ]'
    Nano-AdjustView
}

function Nano-PasteLine {
    if ($script:nanoReadOnly) { Nano-SetStatus '[ Read-Only Mode ]'; return }
    if ($script:nanoCutBuffer -eq '') { return }
    $script:nanoLines.Insert($script:nanoCurRow, $script:nanoCutBuffer)
    $script:nanoCurRow++
    $script:nanoModified = $true
    Nano-SetStatus '[ Pasted 1 line ]'
    Nano-AdjustView
}

function Nano-Search {
    Nano-SetStatus 'Search: '
    Nano-Render
    [Console]::CursorVisible = $true

    $term = Nano-ReadMiniBuffer 'Search: '
    if ($null -eq $term -or $term -eq '') { Nano-SetStatus '[ Cancelled ]'; return }
    $script:nanoSearchTerm = $term

    Nano-DoSearch $term
}

function Nano-DoSearch {
    param([string]$term)
    for ($i = $script:nanoCurRow; $i -lt $script:nanoLines.Count; $i++) {
        $startCol = if ($i -eq $script:nanoCurRow) { $script:nanoCurCol + 1 } else { 0 }
        $idx = $script:nanoLines[$i].IndexOf($term, $startCol, [StringComparison]::OrdinalIgnoreCase)
        if ($idx -ge 0) {
            $script:nanoCurRow = $i
            $script:nanoCurCol = $idx
            Nano-AdjustView
            Nano-SetStatus "[ Found at Ln $($i + 1), Col $($idx + 1) ]"
            return
        }
    }
    for ($i = 0; $i -le $script:nanoCurRow; $i++) {
        $endCol = if ($i -eq $script:nanoCurRow) { $script:nanoCurCol } else { $script:nanoLines[$i].Length }
        $idx = $script:nanoLines[$i].IndexOf($term, 0, [Math]::Min($endCol, $script:nanoLines[$i].Length), [StringComparison]::OrdinalIgnoreCase)
        if ($idx -ge 0) {
            $script:nanoCurRow = $i
            $script:nanoCurCol = $idx
            Nano-AdjustView
            Nano-SetStatus "[ Found (wrapped) at Ln $($i + 1), Col $($idx + 1) ]"
            return
        }
    }
    Nano-SetStatus '[ Not found ]'
}

function Nano-ReadMiniBuffer {
    param([string]$prompt)
    $w = [Console]::WindowWidth
    $h = [Console]::WindowHeight
    $inputRow = $h - 3
    $input = ''

    while ($true) {
        $display = "$prompt$input"
        if ($display.Length -lt $w) { $display = $display.PadRight($w) }
        if ($display.Length -gt $w) { $display = $display.Substring(0, $w) }
        [Console]::SetCursorPosition(0, $inputRow)
        Nano-WriteInverted $display
        $curPos = [Math]::Min($prompt.Length + $input.Length, $w - 1)
        [Console]::SetCursorPosition($curPos, $inputRow)
        [Console]::CursorVisible = $true

        $k = [Console]::ReadKey($true)
        if ($k.Key -eq 'Enter') { return $input }
        if ($k.Key -eq 'Escape') { return $null }
        if ($k.Modifiers -band [ConsoleModifiers]::Control) {
            if ($k.Key -eq 'C' -or $k.Key -eq 'G') { return $null }
        }
        if ($k.Key -eq 'Backspace') {
            if ($input.Length -gt 0) { $input = $input.Substring(0, $input.Length - 1) }
            continue
        }
        $ch = $k.KeyChar
        if ($ch -and [int]$ch -ge 32) { $input += $ch }
    }
}

function Nano-Save {
    if ($script:nanoReadOnly) { Nano-SetStatus '[ Read-Only Mode ]'; return }

    $path = $script:nanoFile
    if (-not $path) {
        $path = Nano-ReadMiniBuffer 'File Name to Write: '
        if ($null -eq $path -or $path -eq '') { Nano-SetStatus '[ Cancelled ]'; return }
        $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
        $script:nanoFile = $path
        $script:nanoDisplayName = $path
    }

    try {
        $content = $script:nanoLines -join "`r`n"
        [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
        $script:nanoModified = $false
        Nano-SetStatus "[ Wrote $($script:nanoLines.Count) lines to $path ]"
    } catch {
        Nano-SetStatus "[ Error: $($_.Exception.Message) ]"
    }
}

function Nano-Exit {
    if ($script:nanoModified) {
        Nano-SetStatus 'Save modified buffer? (Y)es (N)o (C)ancel'
        Nano-Render
        while ($true) {
            $k = [Console]::ReadKey($true)
            switch -Regex ($k.KeyChar) {
                '[yY]' { Nano-Save; $script:nanoRunning = $false; return }
                '[nN]' { $script:nanoRunning = $false; return }
                '[cC]' { Nano-SetStatus '[ Cancelled ]'; return }
            }
            if ($k.Key -eq 'Escape') { Nano-SetStatus '[ Cancelled ]'; return }
        }
    } else {
        $script:nanoRunning = $false
    }
}

function Nano-SetStatus {
    param([string]$msg)
    $script:nanoStatus = $msg
    $script:nanoStatusTTL = 3
}

function Nano-AdjustView {
    $w = [Console]::WindowWidth
    $h = [Console]::WindowHeight
    $editH = $h - 3
    $gutter = 0
    if ($script:nanoShowLines) {
        $maxLine = $script:nanoOffsetRow + $editH
        $gutter = ([string]$maxLine).Length + 1
    }
    $avail = $w - $gutter

    if ($script:nanoCurRow -lt $script:nanoOffsetRow) {
        $script:nanoOffsetRow = $script:nanoCurRow
    }
    if ($script:nanoCurRow -ge ($script:nanoOffsetRow + $editH)) {
        $script:nanoOffsetRow = $script:nanoCurRow - $editH + 1
    }
    if ($script:nanoCurCol -lt $script:nanoOffsetCol) {
        $script:nanoOffsetCol = $script:nanoCurCol
    }
    if ($script:nanoCurCol -ge ($script:nanoOffsetCol + $avail)) {
        $script:nanoOffsetCol = $script:nanoCurCol - $avail + 1
    }
}
