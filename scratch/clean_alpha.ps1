Add-Type -AssemblyName System.Drawing

$srcPath = Join-Path (Get-Location) "assets\images\mascot\quixote_3d_render.png"
$bmp = [System.Drawing.Bitmap]::FromFile($srcPath)
$w = $bmp.Width
$h = $bmp.Height

# We will do flood fill / edge color tolerance from border pixels
$outBmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

# Background color sampled at edges
$bg = $bmp.GetPixel(0, 0)
$bgR = [double]$bg.R
$bgG = [double]$bg.G
$bgB = [double]$bg.B

for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
        $c = $bmp.GetPixel($x, $y)
        
        $dr = [Math]::Abs($c.R - $bgR)
        $dg = [Math]::Abs($c.G - $bgG)
        $db = [Math]::Abs($c.B - $bgB)
        $diff = [Math]::Sqrt($dr*$dr + $dg*$dg + $db*$db)
        
        # Check if this pixel is background parchment
        # Background is very light warm parchment: R > 230, G > 220, B > 200, low saturation
        $maxC = [Math]::Max($c.R, [Math]::Max($c.G, $c.B))
        $minC = [Math]::Min($c.R, [Math]::Min($c.G, $c.B))
        $sat = if ($maxC -gt 0) { ($maxC - $minC) / [double]$maxC } else { 0 }
        
        # Character features:
        # Hat: brown (R~180..220, G~140..170, B~100..130) -> high saturation
        # Face skin: peach (R~255, G~215, B~190) -> G and B lower than background
        # Eyes: black
        # Beard: white (R~250, G~250, B~250, very low saturation, but centrally located)
        # Armor: steel blue/grey (R~120..180, G~130..190, B~150..200)
        # Cape: burgundy red (R~180..220, G~50..80, B~40..70)
        # Spear: grey/brown
        
        # Protected region: character body & head
        $isCenterHead = ($x -gt 65 -and $x -lt 190 -and $y -gt 60 -and $y -lt 210)
        
        if ($isCenterHead) {
            # Only remove if it strictly matches the flat background color within small diff
            if ($diff -lt 18) {
                $outBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            } else {
                $outBmp.SetPixel($x, $y, $c)
            }
        } else {
            # Outside center head, anything that is parchment background becomes fully transparent
            if ($c.R -gt 220 -and $c.G -gt 210 -and $c.B -gt 195 -and $sat -lt 0.15) {
                $outBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            } elseif ($diff -lt 35) {
                $outBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            } else {
                $outBmp.SetPixel($x, $y, $c)
            }
        }
    }
}

$bmp.Dispose()
$outPath = Join-Path (Get-Location) "assets\images\mascot\quixote_3d_render_clean.png"
$outBmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$outBmp.Dispose()

Copy-Item $outPath $srcPath -Force
Write-Output "Cleaned and saved $srcPath"
