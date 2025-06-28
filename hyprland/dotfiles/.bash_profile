# Lotrando Hyperland Minimal Desktop

[[ -f ~/.zshrc ]] && source ~/.bashrc
[[ -t 0 && $(tty) == /dev/tty1 && ! $DISPLAY ]] && exec dbus-run-session Hyprland > /dev/null 2>&1
