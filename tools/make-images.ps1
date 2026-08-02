<#
.SYNOPSIS
    Regenerates every raster asset in static/ — favicons and the social card.

.DESCRIPTION
    LOCAL DEV TOOL. CI never runs this; the outputs are committed and the
    workflow only consumes them. Run it when the mark, the title or the tagline
    changes, then commit whatever it produces.

        pwsh tools\make-images.ps1
        pwsh tools\make-images.ps1 -Title "Nils" -Tagline "Something else"

    Outputs: favicon.ico (16+32), favicon-16x16.png, favicon-32x32.png,
    apple-touch-icon.png (180), og-card.png (1200x630).

    Windows only — uses System.Drawing and the Segoe UI font.
#>
param(
    [string]$OutDir  = (Join-Path $PSScriptRoot '..\static'),
    [string]$Title   = 'Nils',
    [string]$Tagline = 'Software test & automation engineer',
    [string]$Url     = 'noodle-.github.io/nils-homepage'
)

Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

# The mark's teal is the site's original accent. It is deliberately NOT the
# current --accent: keeping it means re-running this script reproduces the
# committed icons byte for byte. The card below uses live palette values.
$MarkTeal = [System.Drawing.ColorTranslator]::FromHtml('#0d9488')

# Card palette — mirrors assets/css/extended/custom.css.
$Paper    = [System.Drawing.ColorTranslator]::FromHtml('#faf9f7')  # --theme
$Ink      = [System.Drawing.ColorTranslator]::FromHtml('#2a2d31')  # --primary
$Muted    = [System.Drawing.ColorTranslator]::FromHtml('#666c72')  # --secondary
$AxisTeal = [System.Drawing.ColorTranslator]::FromHtml('#0e837a')  # --a3
$NodeDark = [System.Drawing.ColorTranslator]::FromHtml('#0b4f4a')  # --a1
$NodeLite = [System.Drawing.ColorTranslator]::FromHtml('#4fb3a6')  # --a4

$OutDir = (Resolve-Path $OutDir).Path

# ---------------------------------------------------------------- favicons --

function New-Mark {
    param([int]$Size, [bool]$Rounded = $true)

    $bmp = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::Transparent)

    $brush = New-Object System.Drawing.SolidBrush($MarkTeal)
    if ($Rounded) {
        $r = [int][Math]::Max(2, $Size * 0.18)
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $d = $r * 2
        $path.AddArc(0, 0, $d, $d, 180, 90)
        $path.AddArc($Size - $d, 0, $d, $d, 270, 90)
        $path.AddArc($Size - $d, $Size - $d, $d, $d, 0, 90)
        $path.AddArc(0, $Size - $d, $d, $d, 90, 90)
        $path.CloseFigure()
        $g.FillPath($brush, $path)
        $path.Dispose()
    } else {
        $g.FillRectangle($brush, 0, 0, $Size, $Size)
    }

    $font = New-Object System.Drawing.Font('Segoe UI', ($Size * 0.62), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = [System.Drawing.StringAlignment]::Center
    $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $rect = New-Object System.Drawing.RectangleF(0, ($Size * -0.04), $Size, $Size)
    $g.DrawString('N', $font, $white, $rect, $fmt)

    $g.Dispose(); $brush.Dispose(); $white.Dispose(); $font.Dispose(); $fmt.Dispose()
    return $bmp
}

function Get-PngBytes {
    param($Bitmap)
    $ms = New-Object System.IO.MemoryStream
    $Bitmap.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $bytes = $ms.ToArray()
    $ms.Dispose()
    return ,$bytes   # leading comma: stops PowerShell unrolling byte[] to object[]
}

$b16  = New-Mark -Size 16
$b32  = New-Mark -Size 32
$b180 = New-Mark -Size 180 -Rounded $false

$b16.Save((Join-Path $OutDir 'favicon-16x16.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$b32.Save((Join-Path $OutDir 'favicon-32x32.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$b180.Save((Join-Path $OutDir 'apple-touch-icon.png'), [System.Drawing.Imaging.ImageFormat]::Png)

# ICO container holding the 16 and 32 PNGs.
$entries = @(
    @{ Size = 16; Bytes = (Get-PngBytes $b16) },
    @{ Size = 32; Bytes = (Get-PngBytes $b32) }
)
$ms = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($ms)
$bw.Write([uint16]0)                    # reserved
$bw.Write([uint16]1)                    # type: icon
$bw.Write([uint16]$entries.Count)
$offset = 6 + (16 * $entries.Count)
foreach ($e in $entries) {
    $bw.Write([byte]$e.Size)            # width  (0 would mean 256)
    $bw.Write([byte]$e.Size)            # height
    $bw.Write([byte]0)                  # palette size
    $bw.Write([byte]0)                  # reserved
    $bw.Write([uint16]1)                # colour planes
    $bw.Write([uint16]32)               # bits per pixel
    $bw.Write([uint32]$e.Bytes.Length)
    $bw.Write([uint32]$offset)
    $offset += $e.Bytes.Length
}
# Explicit byte[] overload: without it the payload is skipped and the .ico
# writes as a valid-looking 40-byte header containing no image at all.
foreach ($e in $entries) { $bw.Write([byte[]]$e.Bytes, 0, $e.Bytes.Length) }
$bw.Flush()
[System.IO.File]::WriteAllBytes((Join-Path $OutDir 'favicon.ico'), $ms.ToArray())
$bw.Dispose(); $ms.Dispose()
$b16.Dispose(); $b32.Dispose(); $b180.Dispose()

# --------------------------------------------------------------- social card --
# 1200x630 is ~1.91:1, what LinkedIn and Facebook want. Twitter crops nearer
# 2:1, so everything stays well inside the middle band.

$W = 1200; $H = 630
$card = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($card)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.Clear($Paper)

# Timeline motif: the axis and its nodes, echoing the page itself.
$axisX = 120; $axisTop = 150; $axisBottom = 480
$axisPen = New-Object System.Drawing.Pen($AxisTeal, 3)
$g.DrawLine($axisPen, $axisX, $axisTop, $axisX, $axisBottom)
$axisPen.Dispose()

$nodes = @(
    @{ Y = 190; Color = $NodeDark; R = 13 },
    @{ Y = 315; Color = $AxisTeal; R = 11 },
    @{ Y = 440; Color = $NodeLite; R = 9  }
)
foreach ($n in $nodes) {
    $b = New-Object System.Drawing.SolidBrush($n.Color)
    $g.FillEllipse($b, ($axisX - $n.R), ($n.Y - $n.R), ($n.R * 2), ($n.R * 2))
    $b.Dispose()
}

# Shrink the type until it fits, so a longer title or tagline can't run off the
# edge of the card.
function Get-FittedFont {
    param($Graphics, [string]$Text, [single]$StartSize, $Style, [single]$MaxWidth)
    $size = $StartSize
    while ($size -gt 10) {
        $f = New-Object System.Drawing.Font('Segoe UI', $size, $Style, [System.Drawing.GraphicsUnit]::Pixel)
        if ($Graphics.MeasureString($Text, $f).Width -le $MaxWidth) { return $f }
        $f.Dispose()
        $size -= 2
    }
    return (New-Object System.Drawing.Font('Segoe UI', 10, $Style, [System.Drawing.GraphicsUnit]::Pixel))
}

$textX = 186
$maxW = $W - $textX - 90

$inkBrush   = New-Object System.Drawing.SolidBrush($Ink)
$mutedBrush = New-Object System.Drawing.SolidBrush($Muted)

$titleFont = Get-FittedFont $g $Title 104 ([System.Drawing.FontStyle]::Bold) $maxW
$g.DrawString($Title, $titleFont, $inkBrush, [single]($textX - 6), [single]205)

$tagFont = Get-FittedFont $g $Tagline 40 ([System.Drawing.FontStyle]::Regular) $maxW
$g.DrawString($Tagline, $tagFont, $mutedBrush, [single]$textX, [single]345)

$urlFont = New-Object System.Drawing.Font('Segoe UI', 26, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$g.DrawString($Url, $urlFont, $mutedBrush, [single]$textX, [single]445)

$g.Dispose(); $inkBrush.Dispose(); $mutedBrush.Dispose()
$titleFont.Dispose(); $tagFont.Dispose(); $urlFont.Dispose()

$card.Save((Join-Path $OutDir 'og-card.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$card.Dispose()

Get-ChildItem $OutDir -File | Select-Object Name, Length | Format-Table -AutoSize
