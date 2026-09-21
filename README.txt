Equus - Random Hourly Wallpaper Changer
========================================

What's here
------------
Set-Wallpaper.ps1      The script that picks a random image and sets it as your wallpaper.
Install-Task.ps1       Registers two Scheduled Tasks: one that runs the script hourly, one at logon.
Install.bat            Double-click this to run the installer (no PowerShell fiddling needed).
Uninstall-Task.ps1 /
Uninstall.bat           Removes both scheduled tasks if you ever want to stop the rotation.
wallpaper.log           Created automatically after the first run; shows what happened each time.
last-wallpaper.txt      Created automatically; remembers the last image used so it isn't repeated back-to-back.

Setup (one time)
----------------
1. Double-click Install.bat (a console window will open and prompt you to press a key when done).
2. That's it. It creates two Scheduled Tasks:
   - "Equus Wallpaper Changer" - runs every hour, indefinitely.
   - "Equus Wallpaper Changer (Logon)" - runs once whenever you log in.
   It also runs the script once immediately so your wallpaper changes right away.

Where it picks images from
---------------------------
By default the script uses:
    C:\Users\ctouzel\OneDrive\Art
including subfolders, and picks .jpg, .jpeg, .png, and .bmp files.

To point it at a different folder, open Set-Wallpaper.ps1 in Notepad and change the line:
    [string]$ImageFolder = "C:\Users\ctouzel\OneDrive\Art",
to the folder you want, then save. No need to reinstall the tasks.

How the image is sized to your screen
---------------------------------------
The script sets Windows' wallpaper style to "Fill" before applying each image, so any
image - whatever its size or aspect ratio - is scaled to cover the whole screen with the
excess cropped off, never stretched/distorted and never leaving black bars. This is the
same as picking "Fill" under Settings > Personalization > Background.

Checking it's working / troubleshooting
----------------------------------------
- Open Task Scheduler (search for it in the Start menu) and look under the Task Scheduler
  Library for "Equus Wallpaper Changer" and "Equus Wallpaper Changer (Logon)" to see run
  history and next run time.
- Open C:\Equus\wallpaper.log to see a timestamped line for every run, including any errors
  (e.g. if the image folder can't be found or is empty).
- To test the script manually at any time, right-click Set-Wallpaper.ps1 and choose
  "Run with PowerShell".

Removing it
-----------
Double-click Uninstall.bat. This deletes both scheduled tasks only - it does not touch your
images or the Equus folder itself.

Notes
-----
- This only randomizes wallpaper every hour (and at logon); it doesn't yet do anything based
  on season or special dates. That logic can be added later as a second phase of Equus (e.g.
  picking from a season-specific subfolder, or swapping in a themed image on specific dates)
  by extending Set-Wallpaper.ps1 - the random-pick and wallpaper-setting plumbing here will
  still be used.
- The tasks run as your regular Windows user (not as Administrator), since setting your own
  wallpaper doesn't need admin rights.
