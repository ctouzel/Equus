' Equus - launches Set-Wallpaper.ps1 with no visible window at all.
' powershell.exe's own -WindowStyle Hidden still flashes a console briefly;
' routing through wscript.exe (which has no console of its own) avoids that.
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""C:\Equus\Set-Wallpaper.ps1""", 0, False
