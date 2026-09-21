<#
.SYNOPSIS
    Registers Windows Scheduled Tasks that run Equus's Set-Wallpaper.ps1
    every hour and (if permitted) at logon.

.DESCRIPTION
    Run this once (double-click Install.bat) to set up the wallpaper rotation.
    Safe to run again later - it replaces any existing Equus tasks.

    Uses schtasks.exe directly rather than the ScheduledTasks PowerShell module.
    That module's Register-ScheduledTask has a known bug: asking for an
    "indefinite" repeating trigger (RepetitionDuration = [TimeSpan]::MaxValue,
    or trying to blank it out afterwards) produces a duration value
    ("P99999999DT23H59M59S") that Task Scheduler's own XML schema rejects.
    schtasks' native HOURLY schedule type repeats forever with no duration
    value involved, so the bug can't occur.

    The hourly task is the one that matters and is treated as required.
    The logon task is a nice-to-have extra; some managed/corporate machines
    block non-admin accounts from creating logon-triggered tasks ("Access is
    denied"), so its failure is reported but does not stop the install.
#>

$hourlyTaskName = "Equus Wallpaper Changer"
$logonTaskName = "Equus Wallpaper Changer (Logon)"
$scriptPath = "C:\Equus\Set-Wallpaper.ps1"
$action = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

function Remove-IfExists {
    param([string]$Name)
    schtasks /Delete /TN $Name /F 2>$null | Out-Null
}

Remove-IfExists $hourlyTaskName
Remove-IfExists $logonTaskName

# Required: repeats every hour, indefinitely, starting now.
$hourlyResult = schtasks /Create /TN $hourlyTaskName /TR $action /SC HOURLY /MO 1 /RL LIMITED /F 2>&1
$hourlyExit = $LASTEXITCODE

if ($hourlyExit -ne 0) {
    Write-Host ""
    Write-Host "FAILED to create the hourly task:" -ForegroundColor Red
    Write-Host $hourlyResult
    exit 1
}

Write-Host "Task '$hourlyTaskName' installed. It will run every hour from now on."

# Optional: also fire once at logon. Not all accounts are permitted to create
# this trigger type (some managed PCs block it); that's fine, the hourly
# task above is what actually delivers "change every hour".
$logonResult = schtasks /Create /TN $logonTaskName /TR $action /SC ONLOGON /RL LIMITED /F 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Skipped the logon task (not permitted on this PC): $logonResult" -ForegroundColor Yellow
    Write-Host "This doesn't affect the hourly rotation."
}
else {
    Write-Host "Task '$logonTaskName' installed. It will also run once at each logon."
}

Write-Host "Running it once now to set a wallpaper immediately..."

$runResult = schtasks /Run /TN $hourlyTaskName 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Couldn't run it immediately:" -ForegroundColor Yellow
    Write-Host $runResult
    Write-Host "It will still run at the next scheduled hour."
}

Write-Host ""
Write-Host "Done. Check C:\Equus\wallpaper.log if the wallpaper doesn't change."
