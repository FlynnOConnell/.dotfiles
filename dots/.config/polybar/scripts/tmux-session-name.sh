#!/bin/bash

session_name=$(tmux display-message -p '#S')
echo "${session_name}"

