<#
.SYNOPSIS
    Equus - picks a random image from a folder and sets it as the Windows desktop wallpaper.

.DESCRIPTION
    Part of the Equus project. Meant to be run on a schedule (see Install-Task.bat,
    which registers an hourly Windows Scheduled Task) to rotate the desktop wallpaper
    using a random image pulled from a chosen folder.

    - Picks the source folder based on today's date (see $SeasonalFolders below) -
      unless -ImageFolder is passed explicitly, which always wins.
    - Avoids repeating the same image twice in a row (when more than one image exists).
    - Sets the wallpaper style to "Fill" so images of any size/aspect ratio look right.
    - Logs each run to wallpaper.log next to this script for troubleshooting.

.NOTES
    To add or change seasonal folders, edit the $SeasonalFolders list below - each
    entry is a date range (month/day, year-independent) and the folder to use during
    it. Ranges are checked in order and the first match wins; nothing matching falls
    back to $DefaultImageFolder.
#>

param(
    [string]$ImageFolder = "",
    [bool]$IncludeSubfolders = $true,
    [string]$StateFile = "",
    [string]$LogFile = ""
)

# State and log files live next to this script, wherever it's installed
# (C:\Equus on the laptop, D:\Equus on the Main Desktop, ...).
if ([string]::IsNullOrWhiteSpace($StateFile)) { $StateFile = Join-Path $PSScriptRoot "last-wallpaper.txt" }
if ([string]::IsNullOrWhiteSpace($LogFile)) { $LogFile = Join-Path $PSScriptRoot "wallpaper.log" }

# OneDrive folder holding the Art* folders, per computer. The first one that
# exists on this machine is used - add a line here for any new computer.
$ArtRootCandidates = @(
    "C:\Users\ctouzel\OneDrive"        # Laptop
    "D:\OneDrivePersonal\OneDrive"      # Main Desktop
)
$ArtRoot = $ArtRootCandidates | Where-Object { Test-Path (Join-Path $_ "Art") } | Select-Object -First 1
if (-not $ArtRoot) { $ArtRoot = $ArtRootCandidates[0] }

# Used whenever today's date doesn't fall inside any range below.
$DefaultImageFolder = Join-Path $ArtRoot "Art"

# Date ranges are Month/Day only (the year is ignored) and are inclusive on
# both ends. A range may wrap the new year (e.g. StartMonth/Day = 12/26,
# EndMonth/Day = 1/31) and that's handled correctly below.
$SeasonalFolders = @(
    @{ Name = "Fall"; StartMonth = 9; StartDay = 15; EndMonth = 10; EndDay = 20; Folder = (Join-Path $ArtRoot "ArtFall") }
    @{ Name = "Halloween"; StartMonth = 10; StartDay = 28; EndMonth = 10; EndDay = 31; Folder = (Join-Path $ArtRoot "ArtHalloween") }
    @{ Name = "Christmas"; StartMonth = 11; StartDay = 25; EndMonth = 12; EndDay = 25; Folder = (Join-Path $ArtRoot "ArtChristmas") }
    @{ Name = "Winter"; StartMonth = 12; StartDay = 26; EndMonth = 1; EndDay = 31; Folder = (Join-Path $ArtRoot "ArtWinter") }
)

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp  $Message" | Out-File -FilePath $LogFile -Append -Encoding utf8
}

function Get-SeasonalFolder {
    param(
        [datetime]$Date,
        [array]$Rules,
        [string]$FallbackFolder
    )

    $todayKey = $Date.Month * 100 + $Date.Day

    foreach ($rule in $Rules) {
        $startKey = $rule.StartMonth * 100 + $rule.StartDay
        $endKey = $rule.EndMonth * 100 + $rule.EndDay

        $inRange = if ($startKey -le $endKey) {
            $todayKey -ge $startKey -and $todayKey -le $endKey
        }
        else {
            # Range wraps around the new year (e.g. Dec 26 -> Jan 31)
            $todayKey -ge $startKey -or $todayKey -le $endKey
        }

        if ($inRange) {
            return [pscustomobject]@{ Name = $rule.Name; Folder = $rule.Folder }
        }
    }

    return [pscustomobject]@{ Name = "Default"; Folder = $FallbackFolder }
}

$extensions = @("*.jpg", "*.jpeg", "*.png", "*.bmp")

try {
    $selection = $null
    if ([string]::IsNullOrWhiteSpace($ImageFolder)) {
        $selection = Get-SeasonalFolder -Date (Get-Date) -Rules $SeasonalFolders -FallbackFolder $DefaultImageFolder
        $ImageFolder = $selection.Folder
        Write-Log "Season: $($selection.Name) -> using folder $ImageFolder"
    }
    else {
        Write-Log "Using explicitly passed folder: $ImageFolder"
    }

    if (-not (Test-Path $ImageFolder)) {
        Write-Log "ERROR: Image folder not found: $ImageFolder"
        exit 1
    }

    if ($IncludeSubfolders) {
        $images = Get-ChildItem -Path $ImageFolder -Include $extensions -File -Recurse -ErrorAction SilentlyContinue
    }
    else {
        $images = Get-ChildItem -Path (Join-Path $ImageFolder '*') -Include $extensions -File -ErrorAction SilentlyContinue
    }

    if (-not $images -or $images.Count -eq 0) {
        Write-Log "ERROR: No images found in $ImageFolder"
        exit 1
    }

    # Avoid picking the same image twice in a row when there's more than one option
    $lastUsed = $null
    if (Test-Path $StateFile) {
        $lastUsed = Get-Content $StateFile -ErrorAction SilentlyContinue
    }

    $candidates = $images
    if ($lastUsed -and $images.Count -gt 1) {
        $filtered = $images | Where-Object { $_.FullName -ne $lastUsed }
        if ($filtered) { $candidates = $filtered }
    }

    $chosen = $candidates | Get-Random

    # Set wallpaper style to "Fill" (10) so it displays cleanly regardless of image size
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value 10
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value 0

    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class EquusWallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@ -ErrorAction SilentlyContinue

    $SPI_SETDESKWALLPAPER = 20
    $SPIF_UPDATEINIFILE = 0x01
    $SPIF_SENDWININICHANGE = 0x02

    [EquusWallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $chosen.FullName, $SPIF_UPDATEINIFILE -bor $SPIF_SENDWININICHANGE) | Out-Null

    $chosen.FullName | Out-File -FilePath $StateFile -Encoding utf8 -NoNewline

    Write-Log "Set wallpaper to: $($chosen.FullName)"
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
