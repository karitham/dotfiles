#!/usr/bin/env bash

options=(
    # "swaylock"
    "systemctl poweroff"
    "systemctl reboot"
)

options_labels=(
    # " Lock"
    "  Shut down"
    "  Reboot"
)

set -e
set -x

options_string=$(printf '%s\n' "${options_labels[@]}")
selected_option=$(echo "$options_string" | rofi -dmenu)

if [[ -n $selected_option ]]; then
    # Find the index of the selected option in the options_labels array
    for i in "${!options_labels[@]}"; do
        if [[ "${options_labels[$i]}" == "$selected_option" ]]; then
            command_index=$i
            break
        fi
    done

    # If a valid index is found, run the corresponding command
    if [[ -n $command_index ]]; then
        eval "${options[$command_index]}"
    fi
fi
