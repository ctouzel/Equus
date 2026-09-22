Equus - Random Hourly Wallpaper Changer
========================================

What's here
------------
Set-Wallpaper.ps1      The script that picks a random image and sets it as your wallpaper.
Install-Task.ps1       Registers Scheduled Tasks: one that runs the script hourly (required),
                        one at logon (optional - some managed PCs block this, that's fine).
Install.bat            Double-click this to run the installer (no PowerShell fiddling needed).
Uninstall-Task.ps1 /
Uninstall.bat           Removes the scheduled task(s) if you ever want to stop the rotation.
wallpaper.log           Created automatically after the first run; shows what happened each time,
                        including which seasonal folder was chosen.
last-wallpaper.txt      Created automatically; remembers the last image used so it isn't repeated back-to-back.

Setup (one time)
----------------
1. Double-click Install.bat (a console window will open and prompt you to press a key when done).
2. That's it. It creates the hourly Scheduled Task (and the logon one, if permitted), and runs
   the script once immediately so your wallpaper changes right away.

Where it picks images from (seasonal folders)
-----------------------------------------------
The script checks today's date against a list of date ranges and picks the matching folder.
Right now:

    Sep 15 - Oct 20  ->  C:\Users\ctouzel\OneDrive\ArtFall
    Any other date   ->  C:\Users\ctouzel\OneDrive\Art   (the default)

Subfolders are included, and it picks .jpg, .jpeg, .png, and .bmp files.

To add more seasonal folders (e.g. a winter/holiday set, a summer set), open
Set-Wallpaper.ps1 in Notepad and add another line to the $SeasonalFolders list near the top,
following the same pattern as the Fall entry:

    @{ Name = "Winter"; StartMonth = 12; StartDay = 1; EndMonth = 1; EndDay = 15; Folder = "C:\Users\ctouzel\OneDrive\ArtWinter" }

Ranges can cross the new year (like the Winter example above, Dec 1 -> Jan 15) and that's
handled automatically. Ranges are checked top to bottom and the first match wins. No need to
reinstall the scheduled task after editing - it just picks up the new list on its next hourly run.

To change the year-round default folder, edit the $DefaultImageFolder line instead.

How the image is sized to your screen
---------------------------------------
The script sets Windows' wallpaper style to "Fill" before applying each image, so any
image - whatever its size or aspect ratio - is scaled to cover the whole screen with the
excess cropped off, never stretched/distorted and never leaving black bars. This is the
same as picking "Fill" under Settings > Personalization > Background.

Checking it's working / troubleshooting
----------------------------------------
- Open Task Scheduler (search for it in the Start menu) and look under the Task Scheduler
  Library for "Equus Wallpaper Changer" (and "Equus Wallpaper Changer (Logon)" if it exists)
  to see run history and next run time.
- Open C:\Equus\wallpaper.log to see a timestamped line for every run - it now also logs
  which seasonal folder was selected and why (e.g. "Season: Fall -> using folder ...").
- To test the script manually at any time, right-click Set-Wallpaper.ps1 and choose
  "Run with PowerShell".

Removing it
-----------
Double-click Uninstall.bat. This deletes the scheduled task(s) only - it does not touch your
images or the Equus folder itself.

Notes
-----
- The tasks run as your regular Windows user (not as Administrator), since setting your own
  wallpaper doesn't need admin rights.
