# Power off (or suspend) Windows (PowerShell/CMD); if powering off fails, it suspends instead. Usage: power-off.ps1 [-Sleep] [-DryRun]
param([switch]$Sleep, [switch]$DryRun)
$sleepCmd = 'rundll32.exe powrprof.dll,SetSuspendState 0,1,0'
$cmd = if ($Sleep) { $sleepCmd } else { 'shutdown /s /t 0' }
Write-Host "power-off: command: $cmd"
if (-not $Sleep) { Write-Host "power-off: if it fails twice, falls back to: $sleepCmd" }
if ($DryRun) { exit 0 }
Start-Sleep -Seconds 5  # lets the calling agent finish its reply; Ctrl+C cancels
Invoke-Expression $cmd
if (-not $Sleep -and $LASTEXITCODE -ne 0) {
  Write-Host "power-off: power off failed; retrying once"
  Start-Sleep -Seconds 2
  Invoke-Expression $cmd
}
if (-not $Sleep -and $LASTEXITCODE -ne 0) {
  Write-Host "power-off: power off failed again; sleeping instead: $sleepCmd"
  Invoke-Expression $sleepCmd
}
