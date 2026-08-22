# Customize XFCE desktop

Copies `files/Background.png` to `/usr/share/backgrounds/kali-custom/`, points Kali's default 16x9 wallpaper at it, and writes `xfce4-desktop.xml` for both the user and `/etc/xdg`. That does not need a live X/DBus session (unlike `xfconf-query`).

Also installs panel, window manager, shortcuts, notifyd, power-manager, and Thunar channel XML under `~/.config/xfce4/xfconf/xfce-perchannel-xml/`.

Override `desktop_wallpaper_filename` if you replace the PNG.
