#!/bin/bash

if xwininfo -name "Slack" | grep "Normal window"; then
    i3-msg "[title=\"Slack\"] floating enable"
else
    i3-msg "[title=\"Slack\"] floating disable"
fi

