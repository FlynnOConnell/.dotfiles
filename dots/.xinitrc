#!/bin/sh

# Xmodmap (outdated)
[[ -f ~/.Xmodmap ]] && xmodmap ~/.Xmodmap


# No mouse acceleration
xset m 1/1 0 &

# Faster keyboard auto-repeat rate
xset r rate 250 50 &

# Start WM
exec awesome
