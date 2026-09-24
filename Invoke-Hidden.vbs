' Equus - launches Set-Wallpaper.ps1 with no visible window at all.
' powershell.exe's own -WindowStyle Hidden still flashes a console briefly;
' routing through wscript.exe (which has no console of its own) avoids that.
' Uses the folder this .vbs lives in, so it works from C:\Equus, D:\Equus, etc.
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")
scriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptDir & "\Set-Wallpaper.ps1""", 0, False
