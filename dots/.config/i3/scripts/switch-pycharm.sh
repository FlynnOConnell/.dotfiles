#!/bin/bash

# Fetch window IDs of PyCharm instances
window_ids=$(i3-msg -t get_tree | jq -r 'recurse(.nodes[]) | select(.window_properties? and .window_properties.class=="JetBrains") | .id')

# Convert to array
window_ids=($window_ids)

# If no instances are found, exit
if [ -z "$window_ids" ]; then
  exit 1
fi

# If only one instance is found, focus it
if [ ${#window_ids[@]} -eq 1 ]; then
  i3-msg [id="${window_ids[0]}"] focus
  exit 0
fi

# If multiple instances are found, switch to the next one
focused=$(i3-msg -t get_tree | jq -r 'recurse(.nodes[]) | select(.focused==true).id')

for index in "${!window_ids[@]}"; do
  if [ "${window_ids[$index]}" = "$focused" ]; then
    next_index=$(( (index + 1) % ${#window_ids[@]} ))
    i3-msg [id="${window_ids[$next_index]}"] focus
    exit 0
  fi
done

# If no focused window is found among the instances, focus the first one
i3-msg [id="${window_ids[0]}"] focus
