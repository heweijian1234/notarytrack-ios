Add-Type -AssemblyName System.Drawing
$W = 1290; $H = 2796
$OUT = 'E:\AI-Projects\个人成长\10-项目\SaaS项目\notarytrack-ios\store'
if (-not (Test-Path $OUT)) { New-Item -ItemType Directory -Force $OUT | Out-Null }

function New-Bg($w, $h, $c1, $c2, $c3, $c4) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::FromArgb($c1,$c2,$c3), [System.Drawing.Color]::FromArgb($c2,$c3,$c4), 60)
    $g.FillRectangle($bg, $rect)
    return @($bmp, $g)
}
function CardSolid($g, $x, $y, $w, $h, $a, $r_, $gr, $b) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $r = 44
    $path.AddArc($x, $y, $r, $r, 180, 90); $path.AddArc($x+$w-$r, $y, $r, $r, 270, 90)
    $path.AddArc($x+$w-$r, $y+$h-$r, $r, $r, 0, 90); $path.AddArc($x, $y+$h-$r, $r, $r, 90, 90)
    $path.CloseFigure()
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($a, $r_, $gr, $b))
    $g.FillPath($brush, $path)
}
function Txt($g, $t, $x, $y, $size, $bold, $r, $gr, $b) {
    $style = if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $font = New-Object System.Drawing.Font('Segoe UI', $size, $style)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($r, $gr, $b))
    $g.DrawString($t, $font, $brush, $x, $y)
}
function CenterTxt($g, $t, $y, $size, $bold, $r, $gr, $b) {
    $style = if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $font = New-Object System.Drawing.Font('Segoe UI', $size, $style)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($r, $gr, $b))
    $m = $g.MeasureString($t, $font)
    $x = ([single]($script:W) - $m.Width) / 2
    $g.DrawString($t, $font, $brush, $x, $y)
}

# ========== shot1 主张（靛蓝渐变：证到期提醒+客户档案+逾期追踪）==========
$c = New-Bg $W $H 70 80 180 40; $bmp = $c[0]; $g = $c[1]
CenterTxt $g 'NotaryTrack' 150 66 $true 255 255 255
CenterTxt $g "Your signing agent book — nothing missed" 260 40 $false 200 210 255

CardSolid $g 130 420 1030 340 235 255 255 255
Txt $g 'COMMISSION EXPIRY' 190 470 36 $true 70 80 180
Txt $g 'Expires in 82 days' 190 545 44 $true 220 90 30
Txt $g 'Start your renewal — keep taking signings' 190 615 34 $false 90 90 110

CardSolid $g 130 810 1030 340 230 255 255 255
Txt $g 'ABC Title - Sarah at Escrow' 190 860 40 $true 60 60 80
Txt $g 'Fee $150 · Trip fee $45 · 42 mi' 190 930 36 $false 90 90 110
Txt $g 'Avg days to pay: 38' 190 995 36 $true 70 80 180

CardSolid $g 130 1200 1030 340 244 120 60 255
Txt $g '3 OVERDUE - total $425' 190 1255 40 $true 255 240 220
Txt $g 'Flagged automatically from your history' 190 1320 34 $false 255 210 180

CenterTxt $g 'No account · No cloud · Offline' 1650 42 $true 200 210 255
$bmp.Save("$OUT\shot1.png", [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()

# ========== shot2 月结（报税视角：免税拆分）==========
$c = New-Bg $W $H 255 250 245 240; $bmp = $c[0]; $g = $c[1]
Txt $g 'This Month' 80 130 64 $true 70 80 180
Txt $g '18 signings · Ready for taxes' 82 230 36 $false 110 110 120

CardSolid $g 70 320 ($W-140) 400 255 255 255 255
Txt $g 'INCOME' 120 360 36 $true 70 80 180
Txt $g 'Notary fees (SE-exempt) $560' 120 430 40 $false 20 130 80
Txt $g 'Service fees (taxable) $2,140' 120 495 40 $false 60 60 80
Txt $g 'Trip fees $135' 120 560 40 $false 60 60 80
Txt $g 'Total income $2,835' 120 640 44 $true 60 60 80

CardSolid $g 70 770 ($W-140) 380 255 255 255 255
Txt $g 'MILEAGE & TAX' 120 810 36 $true 70 80 180
Txt $g '212 miles - IRS deduction $142' 120 880 40 $false 60 60 80
Txt $g 'Every signing logged as you go' 120 950 34 $false 110 110 120

CardSolid $g 70 1200 ($W-140) 300 255 255 255 255
Txt $g 'UNPAID' 120 1240 36 $true 70 80 180
Txt $g '3 signings - $425 aged 30+ days' 120 1310 40 $false 200 90 30
Txt $g 'Chase list built automatically' 120 1375 34 $false 110 110 120

CenterTxt $g 'Tax-ready records, automatically' 1580 44 $true 70 80 180
$bmp.Save("$OUT\shot2.png", [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()

# ========== shot3 签署单流水线（状态+收款处理）==========
$c = New-Bg $W $H 40 24 60 90; $bmp = $c[0]; $g = $c[1]
CenterTxt $g 'From booking to payment' 150 58 $true 255 255 255
CenterTxt $g 'Track every signing in one place' 250 36 $false 200 210 255

CardSolid $g 130 420 1030 300 235 255 255 255
Txt $g 'ABC Title' 190 470 44 $true 60 60 80
Txt $g 'Fee $150 · Mark Paid / No-show' 190 545 36 $false 90 90 110
Txt $g 'Notarial acts: 4 loan docs' 190 610 36 $false 90 90 110
Txt $g 'Reminder 2h before' 190 675 36 $true 60 110 220

CardSolid $g 130 770 1030 300 230 255 255 255
Txt $g 'Sarah Miller' 190 820 44 $true 60 60 80
Txt $g 'Fee $175 · Trip fee $45' 190 895 36 $false 90 90 110
Txt $g 'Avg days to pay: 38' 190 960 36 $true 70 80 180

CardSolid $g 130 1120 1030 300 244 120 60 255
Txt $g 'Overdue $425 total' 190 1170 40 $true 255 240 220
Txt $g 'Aged 30+ days - chase list ready' 190 1240 34 $false 255 210 180

CenterTxt $g 'Offline · Private · No account' 1520 42 $true 200 210 255
$bmp.Save("$OUT\shot3.png", [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
Write-Output 'DONE 3 shots (NotaryTrack EN)'
