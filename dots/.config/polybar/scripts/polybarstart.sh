#!/bin/bash

killall polybar

polybar --config=$HOME/.config/polybar/config.ini primary-top
