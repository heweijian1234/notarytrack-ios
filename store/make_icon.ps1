Add-Type -AssemblyName System.Drawing
$S = 1024
$OUT = 'E:\AI-Projects\个人成长\10-项目\SaaS项目\notarytrack-ios\NotaryTrack\Assets.xcassets\AppIcon.appiconset\AppIcon1024.png'
if (-not (Test-Path (Split-Path $OUT))) { New-Item -ItemType Directory -Force (Split-Path $OUT) | Out-Null }

$bmp = New-Object System.Drawing.Bitmap($S, $S, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'

# 靛蓝渐变底（公证主题）
$rect = New-Object System.Drawing.Rectangle(0, 0, $S, $S)
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect,
    [System.Drawing.Color]::FromArgb(255, 70, 80, 180),
    [System.Drawing.Color]::FromArgb(255, 40, 50, 120), 60)
$g.FillRectangle($bg, $rect)

# 白色印章图形（圆环+方章）
$white = [System.Drawing.Brushes]::White
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 42)
$g.DrawEllipse($pen, 240, 240, 544, 544)
# 章内文字区横杠（模拟文书）
$pen2 = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 30)
$g.DrawLine($pen2, 360, 460, 664, 460)
$g.DrawLine($pen2, 360, 545, 664, 545)
# 右下角小对勾（完成感）
$pen3 = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 120, 230, 160), 36)
$g.DrawLine($pen3, 640, 760, 720, 840)
$g.DrawLine($pen3, 720, 840, 860, 700)

$bmp.Save($OUT, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
$img = [System.Drawing.Image]::FromFile($OUT)
Write-Output "icon saved: $($img.Width)x$($img.Height)"
$img.Dispose()
