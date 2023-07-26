komorebic ensure-named-workspaces 0 main
komorebic ensure-named-workspaces 1 code ref other

# assign layouts to workspaces, possible values: bsp, columns, rows, vertical-stack, horizontal-stack, ultrawide-vertical-stack
komorebic named-workspace-layout main vertical-stack
komorebic named-workspace-layout code bsp
komorebic named-workspace-layout ref bsp
komorebic named-workspace-layout other bsp

# set the gaps around the edge of the screen for a workspace
komorebic named-workspace-padding main 10
komorebic named-workspace-padding code 10
komorebic named-workspace-padding ref 10
komorebic named-workspace-padding other 10

# set the gaps between the containers for a workspace
komorebic named-workspace-container-padding main 10
komorebic named-workspace-container-padding code 10
komorebic named-workspace-container-padding ref 10
komorebic named-workspace-container-padding other 10

komorebic focus-monitor-workspace 0 main
komorebic focus-monitor-workspace 1 code
komorebic focus-monitor-workspace 1 ref
komorebic focus-monitor-workspace 1 other

# you can assign specific apps to named workspaces
komorebic named-workspace-rule exe "WindowsTerminal.exe" main
komorebic named-workspace-rule exe "pwsh.exe" main
komorebic named-workspace-rule exe "bash.exe" main

komorebic named-workspace-rule exe "Code.exe" code
komorebic named-workspace-rule exe "PyCharm.exe" code
komorebic named-workspace-rule exe "VisualStudio.exe" code
komorebic named-workspace-rule exe "idea64.exe" code
komorebic named-workspace-rule exe "idea.exe" code

komorebic named-workspace-rule exe "Firefox.exe" ref
komorebic named-workspace-rule exe "firefox.exe" ref
komorebic named-workspace-rule exe "Chrome.exe" ref
komorebic named-workspace-rule exe "Microsoft Word.exe" ref
komorebic named-workspace-rule exe "Microsoft Excel.exe" ref
komorebic named-workspace-rule exe "Microsoft PowerPoint.exe" ref

komorebic named-workspace-rule exe "OUTLOOK.exe" other
komorebic named-workspace-rule exe "Slack.exe" other
komorebic named-workspace-rule exe "Discord.exe" other
