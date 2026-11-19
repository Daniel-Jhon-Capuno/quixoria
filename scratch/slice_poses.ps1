Add-Type -AssemblyName System.Drawing

$srcPath = Join-Path (Get-Location) "assets\images\mascot\don_quixote_concept_sheet.jpg"
$src = [System.Drawing.Image]::FromFile($srcPath)

function Crop-Image($x, $y, $w, $h, $destName) {
    $rect = New-Object System.Drawing.Rectangle($x, $y, $w, $h)
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $destRect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $g.DrawImage($src, $destRect, $rect, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    
    $outPath = Join-Path (Get-Location) "assets\images\mascot\$destName.png"
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "Saved $outPath"
}

# 1. 3D Render Full Body: Left side, approx x: 25, y: 30, w: 220, h: 320
Crop-Image 20 25 240 330 "quixote_3d_render"

# 2. Key Animations (bottom row):
# Poses: Idle, Walking, Jump, Celebration, Reading, Thinking / Hint
# The row starts around y: 400 to 670
# Let's crop each pose cleanly:
Crop-Image 15 405 135 255 "pose_idle"
Crop-Image 140 405 130 255 "pose_walking"
Crop-Image 295 405 125 255 "pose_jump"
Crop-Image 430 405 140 255 "pose_celebration"
Crop-Image 565 440 120 220 "pose_reading"
Crop-Image 690 405 120 255 "pose_thinking"

# 3. Expressions (top right):
# Happy, Excited, Thinking, Sad, Surprised, Determined
Crop-Image 660 85 105 110 "expr_happy"
Crop-Image 770 85 105 110 "expr_excited"
Crop-Image 880 85 105 110 "expr_thinking"
Crop-Image 660 215 105 110 "expr_sad"
Crop-Image 770 215 105 110 "expr_surprised"
Crop-Image 880 215 105 110 "expr_determined"

# 4. Turnaround (top center):
Crop-Image 290 90 130 240 "turnaround_front"
Crop-Image 440 90 100 240 "turnaround_side"
Crop-Image 550 90 105 240 "turnaround_back"

# 5. UI Speech bubble idea (bottom right):
Crop-Image 830 540 140 130 "ui_thumbs_up"

$src.Dispose()
Write-Output "All slices extracted successfully!"
