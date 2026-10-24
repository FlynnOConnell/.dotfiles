-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Keep work Outlook open so new-mail desktop notifications arrive.
o.exec_on_start(o.launch_webapp("https://outlook.office.com/mail/"))

-- Open Home Assistant (over Tailscale) as a web app at login.
o.exec_on_start(o.launch_webapp("http://100.85.105.1"))
