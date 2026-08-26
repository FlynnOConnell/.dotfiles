' Invisible launcher for mount-lab.ps1 (window style 0 = hidden, no console flash).
Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\Users\loson\repos\.dotfiles\windows\mount-lab.ps1""", 0, False
