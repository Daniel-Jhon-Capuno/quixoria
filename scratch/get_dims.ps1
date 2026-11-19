Add-Type -AssemblyName System.Drawing
$filePath = Join-Path (Get-Location) "assets\images\mascot\don_quixote_concept_sheet.jpg"
$img = [System.Drawing.Image]::FromFile($filePath)
Write-Output "Dimensions: $($img.Width) x $($img.Height)"
$img.Dispose()
