<#
.SYNOPSIS
    Removes the Equus wallpaper Scheduled Tasks.
#>

$hourlyTaskName = "Equus Wallpaper Changer"
$logonTaskName = "Equus Wallpaper Changer (Logon)"

schtasks /Delete /TN $hourlyTaskName /F 2>$null | Out-Null
schtasks /Delete /TN $logonTaskName /F 2>$null | Out-Null

Write-Host "Equus wallpaper tasks removed (if they existed)."
