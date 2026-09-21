<#
.SYNOPSIS
    Equus - picks a random image from a folder and sets it as the Windows desktop wallpaper.

.DESCRIPTION
    Part of the Equus project. Meant to be run on a schedule (see Install-Task.bat,
    which registers an hourly Windows Scheduled Task) to rotate the desktop wallpaper
    using a random image pulled from a chosen folder.

    - Avoids repeating the same image twice in a row (when more than one image exists).
    - Sets the wallpaper style to "Fill" so images of any size/aspect ratio look right.
    - Logs each run to wallpaper.log next to this script for troubleshooting.

.NOTES
    Edit the default value of -ImageFolder below to point at a different folder,
    or pass -ImageFolder "C:\some\other\path" when calling the script.
#>

param(
    [string]$ImageFolder = "C:\Users\ctouzel\OneDrive\Art",
    [bool]$IncludeSubfolders = $true,
    [string]$StateFile = "C:\Equus\last-wallpaper.txt",
    [string]$LogFile = "C:\Equus\wallpaper.log"
)

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp  $Message" | Out-File -FilePath $LogFile -Append -Encoding utf8
}

$extensions = @("*.jpg", "*.jpeg", "*.png", "*.bmp")

try {
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
