Add-Type -AssemblyName System.Drawing

$srcPath = Join-Path (Get-Location) "assets\images\mascot\quixote_3d_render.png"
$bmp = [System.Drawing.Bitmap]::FromFile($srcPath)

$w = $bmp.Width
$h = $bmp.Height

# We know the background is a cream/off-white color around RGB (245..255, 235..250, 225..245)
# Let's inspect corner pixels
$sample1 = $bmp.GetPixel(2, 2)
$sample2 = $bmp.GetPixel($w - 3, 2)
$bgR = ($sample1.R + $sample2.R) / 2
$bgG = ($sample1.G + $sample2.G) / 2
$bgB = ($sample1.B + $sample2.B) / 2

Write-Output "Background color estimate: R=$bgR, G=$bgG, B=$bgB"

$outBmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
        $c = $bmp.GetPixel($x, $y)
        $dr = [Math]::Abs($c.R - $bgR)
        $dg = [Math]::Abs($c.G - $bgG)
        $db = [Math]::Abs($c.B - $bgB)
        $diff = [Math]::Sqrt($dr*$dr + $dg*$dg + $db*$db)
        
        # Also check brightness: if very bright neutral parchment
        $isParchment = ($c.R -gt 225 -and $c.G -gt 215 -and $c.B -gt 200 -and [Math]::Abs($c.R - $c.G) -lt 25 -and [Math]::Abs($c.G - $c.B) -lt 30)
        
        # Except the character's white beard and white hair which are inside the character silhouette
        # Hair/beard is roughly between y: 60 and y: 220, x: 50 and x: 190.
        $inBeardZone = ($x -gt 60 -and $x -lt 195 -and $y -gt 70 -and $y -lt 220)
        
        if ($isParchment -and -not $inBeardZone) {
            $outBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        } elseif ($diff -lt 28 -and -not $inBeardZone) {
            $alpha = [int](($diff / 28.0) * 255)
            $outBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $c.R, $c.G, $c.B))
        } else {
            $outBmp.SetPixel($x, $y, $c)
        }
    }
}

$bmp.Dispose()
$outPath = Join-Path (Get-Location) "assets\images\mascot\quixote_3d_render_transparent.png"
$outBmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$outBmp.Dispose()
Write-Output "Saved transparent render to $outPath"
