# Abre Windows Terminal con WSL, corre grabar_demo.sh y graba esa ventana a MP4 con ffmpeg.
$ErrorActionPreference = 'Stop'
$here   = $PSScriptRoot
$out    = Join-Path $here 'HandsOn3_CodingLexers.mp4'
$title  = 'HandsOn3-Lexers-Demo'
$ffmpeg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe |
          Select-Object -First 1 -ExpandProperty FullName

# Copiar el script a WSL (evita problemas con espacios en la ruta)
$wslSrc = (wsl -d Ubuntu-24.04 -- wslpath -a ($here -replace '\\','/')).Trim()
wsl -d Ubuntu-24.04 -- bash -c "cp '$wslSrc/grabar_demo.sh' /tmp/grabar_demo.sh && rm -f /tmp/demo_done"

Start-Process wt.exe -ArgumentList @('-w','new','--pos','60,40','--size','125,38','new-tab','--title',$title,
    '--suppressApplicationTitle','wsl.exe','-d','Ubuntu-24.04','--','bash','/tmp/grabar_demo.sh')
$w0 = Get-Date
while (-not (Get-Process WindowsTerminal -ErrorAction SilentlyContinue | Where-Object MainWindowTitle -eq $title)) {
    if (((Get-Date) - $w0).TotalSeconds -gt 20) { throw "No apareció la ventana $title" }
    Start-Sleep -Milliseconds 200
}
Start-Sleep -Milliseconds 800

# Rectángulo de la ventana en píxeles físicos (sin sombra) y traerla al frente
Add-Type @'
using System; using System.Runtime.InteropServices;
public struct RECT { public int L, T, R, B; }
public static class W {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h, int a, out RECT r, int s);
}
'@
[W]::SetProcessDPIAware() | Out-Null
$hwnd = (Get-Process WindowsTerminal | Where-Object MainWindowTitle -eq $title | Select-Object -First 1).MainWindowHandle
[W]::ShowWindow($hwnd, 9) | Out-Null; [W]::SetForegroundWindow($hwnd) | Out-Null
$r = New-Object RECT; [W]::DwmGetWindowAttribute($hwnd, 9, [ref]$r, 16) | Out-Null
$x = [math]::Max(0,$r.L); $y = [math]::Max(0,$r.T)
$wd = ($r.R - $x) - (($r.R - $x) % 2); $ht = ($r.B - $y) - (($r.B - $y) % 2)
"Capturando región $x,$y ${wd}x$ht"

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $ffmpeg
$psi.Arguments = "-y -loglevel error -f gdigrab -framerate 20 -draw_mouse 0 -offset_x $x -offset_y $y -video_size ${wd}x$ht -i desktop " +
                 "-vf ""pad=ceil(iw/2)*2:ceil(ih/2)*2"" -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p ""$out"""
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$ff = [System.Diagnostics.Process]::Start($psi)

# Esperar a que la demo termine (máx. 8 min)
$t0 = Get-Date
while (((Get-Date) - $t0).TotalSeconds -lt 480) {
    wsl -d Ubuntu-24.04 -- test -f /tmp/demo_done
    if ($LASTEXITCODE -eq 0) { break }
    Start-Sleep -Seconds 1
}
Start-Sleep -Seconds 4
$ff.StandardInput.Write('q'); $ff.StandardInput.Close()
$ff.WaitForExit(30000) | Out-Null
wsl -d Ubuntu-24.04 -- pkill -f grabar_demo.sh
"Video: $out  (" + [math]::Round(((Get-Date) - $t0).TotalSeconds) + " s)"
