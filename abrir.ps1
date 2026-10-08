# Abre el Centro Multimedia a pantalla completa en un perfil de Edge propio.
# Si ya estaba abierto (por ejemplo, viendo Netflix), lo cierra BIEN (como al tocar la X)
# para que Edge guarde las sesiones de Netflix, Disney+, etc., y vuelve al menu.
$perfil = Join-Path $env:LOCALAPPDATA 'CentroMultimedia\EdgePerfil'
$menu   = 'file:///' + ((Join-Path $PSScriptRoot 'index.html') -replace '\\', '/')
$edge   = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edge)) { $edge = "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe" }

# 1) Ayudante de enlaces directos (oculto). Si ya esta funcionando, el nuevo se cierra solo.
Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
  '-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', "`"$(Join-Path $PSScriptRoot 'ayudante.ps1')`""
)

# 2) Cerrar con cuidado las ventanas del centro que esten abiertas
Add-Type @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class CentroVentanas {
  delegate bool EnumProc(IntPtr h, IntPtr p);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc f, IntPtr p);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  public static int Close(HashSet<uint> pids) {
    int n = 0;
    EnumWindows((h, p) => {
      uint pid; GetWindowThreadProcessId(h, out pid);
      if (pids.Contains(pid) && IsWindowVisible(h)) { PostMessage(h, 0x0010, IntPtr.Zero, IntPtr.Zero); n++; }
      return true;
    }, IntPtr.Zero);
    return n;
  }
}
'@

function Get-CentroProcs {
  Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" |
    Where-Object { $_.CommandLine -like "*CentroMultimedia\EdgePerfil*" }
}

$procs = @(Get-CentroProcs)
if ($procs.Count) {
  $set = New-Object 'System.Collections.Generic.HashSet[uint32]'
  $procs | ForEach-Object { [void]$set.Add([uint32]$_.ProcessId) }
  [void][CentroVentanas]::Close($set)
  # Esperar a que Edge termine de guardar y se cierre (hasta 10 segundos)
  for ($i = 0; $i -lt 40 -and @(Get-CentroProcs).Count; $i++) { Start-Sleep -Milliseconds 250 }
  # Solo si quedo colgado, se fuerza el cierre
  Get-CentroProcs | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Milliseconds 400
}

# 3) Abrir el menu
Start-Process $edge -ArgumentList @(
  "--user-data-dir=`"$perfil`"",
  "--app=$menu",
  '--start-fullscreen',
  '--no-first-run',
  '--no-default-browser-check',
  '--hide-crash-restore-bubble',
  '--autoplay-policy=no-user-gesture-required'
)
