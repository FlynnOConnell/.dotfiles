#!/usr/bin/env bash

#######################################################
# To Install or Update:
# wget -O ~/.bashrc https://sourceforge.net/projects/ultimate-bashrc/files/_bashrc/download
# wget -O ~/.bashrc_help https://sourceforge.net/projects/ultimate-bashrc/files/_bashrc_help/download
# -or-
# curl -L --output ~/.bashrc https://sourceforge.net/projects/ultimate-bashrc/files/_bashrc/download
# curl -L --output ~/.bashrc_help https://sourceforge.net/projects/ultimate-bashrc/files/_bashrc_help/download
#######################################################
# Supported Optional Applications/Dependencies:
# 7z aria2 baca bash-completion bashmarks bashtop bat bc blesh bottom bpytop broot
# btop btrfs bzip2 ccat cmatrix cod colordiff commacd curl delta doas dua dust dym
# elinks enhancd exa exiftool eza fasd fd ffmpeg figlet fx fzf fzf-tab-completion
# fzy gawk gcal gdu gio git git-commander git-completion git-delta gitalias gitui
# glances glow grc grv gtop gzip hBlock hstr htop icdiff ifconfig iotop jless jp2a
# jq lazygit links links2 lnav lolcat lscolors lsd lsof lsx lynx mc mcfly micro
# mlocate moar multitail mysql-colorize nano ncdu neovim nmon nnn paru qfc rar rem
# resh ripgrep rsync shellcheck shred silver_searcher skim source-highlight tar
# terminology thefuck tig tmux toilet trash-cli tree tuifi ugit vivid vlock w3m
# wget xsel youtube-dl yt-dlp ytfzf ytop zellij zf zip zoxide
#
# Supported Optional Huds:
# neofetch, fastfetch, screenFetch, linux_logo, archey, pfetch
#
# Supported Optional Prompts:
# Trueline, Powerline, Powerline-Go, Powerline-Shell,
# Pureline, Starship, Bash Git Prompt, Liquid Prompt
#
# To Install Packages:
# pkginstall [package names separated by spaces]
#######################################################
# set -o errexit  # Exit when a command fails
# set -o pipefail # Catch mysqldump fails
# set -o nounset  # Exit when using undeclared variables
# set -o xtrace   # Trace what gets executed (useful for debugging)

### ERROR TRAPPING
# alias debug="set -o nounset; set -o xtrace"
# error() { echo 'Error in ${1} on line ${2}: ${3}' }
# trap 'error "${BASH_SOURCE}" "${LINENO}"' ERR

### TEST FOR AN INTERACTIVE SHELL
# This file is sourced by all "interactive" bash shells on startup
# including shells such as scp and rcp that can't tolerate any output.
# There is no need to set anything past this point for scp and rcp,
# and it's important to refrain from outputting anything in those cases.
[[ $- != *i* ]] && return
[[ -z "$PS1" ]] && return

# Bash version check
if [ -n "$BASH_VERSION" ] && ((BASH_VERSINFO[0] < 4)); then
	echo "This .bashrc file requires at least Bash 4.0"
	exit 1
fi

# Source global definitions from the available bashrc files
if [[ -f /etc/bashrc ]]; then
	source /etc/bashrc
elif [[ -f /etc/bash.bashrc ]]; then
	source /etc/bash.bashrc
fi

# Grant permission to the local root user to access the X server
# This is NOT recommended for regular use due to the security implications:
# https://stackoverflow.com/questions/63884968/why-is-xhost-considered-dangerous
#if [[ -x "$(command -v xhost)" ]]; then
#	# 'xhost +local:root' allows the root user to connect to the X server
#	# This might be needed for some X applications to work
#	xhost +local:root > /dev/null 2>&1
#fi

#######################################################
# Default Bash Escape ANSI Color Codes
#######################################################

# Foreground Colors
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"

# Bright Foreground Colors
BRIGHT_BLACK="\033[1;30m"
BRIGHT_RED="\033[1;31m"
BRIGHT_GREEN="\033[1;32m"
BRIGHT_YELLOW="\033[1;33m"
BRIGHT_BLUE="\033[1;34m"
BRIGHT_MAGENTA="\033[1;35m"
BRIGHT_CYAN="\033[1;36m"
BRIGHT_WHITE="\033[1;37m"

# Background Colors
BG_BLACK="\033[0;40m"
BG_RED="\033[0;41m"
BG_GREEN="\033[0;42m"
BG_YELLOW="\033[0;43m"
BG_BLUE="\033[0;44m"
BG_MAGENTA="\033[0;45m"
BG_CYAN="\033[0;46m"
BG_WHITE="\033[0;47m"

# Bright Background Colors
BG_BRIGHT_BLACK="\033[1;40m"
BG_BRIGHT_RED="\033[1;41m"
BG_BRIGHT_GREEN="\033[1;42m"
BG_BRIGHT_YELLOW="\033[1;43m"
BG_BRIGHT_BLUE="\033[1;44m"
BG_BRIGHT_MAGENTA="\033[1;45m"
BG_BRIGHT_CYAN="\033[1;46m"
BG_BRIGHT_WHITE="\033[1;47m"

# Reset Color
RESET="\033[0m"

#######################################################
# Set the default editor
# Examples: vim, nvim, emacs, nano, micro, helix, pico,
# or gui apps like kate, gedit, notepadqq, or vscodium
# NOTE: In Git Bash, you can use something like "/c/Program\ Files/Notepad++/notepad++.exe"
# To change these without modifying this file, simply
# add these with your changes to one of these files:
# ~/.env
# ~/.envrc
# ~/.config/bashrc/config
# See section "Configuration and Extras" in the README:
# Link: https://sourceforge.net/projects/ultimate-bashrc/files/
#######################################################

# Check if a command or alias exists
function cmd-exists() {
	# If no arguments or just '--strict' is provided, show help message
	if [[ -z "${1}" || (${#} -eq 1 && "${1}" == "--strict") ]]; then
		echo -e "${BRIGHT_WHITE}cmd-exists:${RESET} Checks if a command or alias exists"
		echo -e "${BRIGHT_WHITE}Options:${RESET}"
		echo -e "  ${BRIGHT_YELLOW}--strict${RESET} or ${BRIGHT_YELLOW}-s${RESET} checks for executable commands only ${BRIGHT_RED}excluding aliases${RESET}"
		echo -e "${BRIGHT_WHITE}Usage examples:${RESET}"
		echo -e "  Check any command or alias:"
		echo -e "    ${BRIGHT_GREEN}cmd-exists ${BRIGHT_YELLOW}ls${RESET}"
		echo -e "  Check executable only ${BRIGHT_RED}(strict mode)${RESET}:"
		echo -e "    ${BRIGHT_GREEN}cmd-exists ${BRIGHT_YELLOW}--strict ${BRIGHT_YELLOW}grep${RESET}"
		echo -e "  Display this help message:"
		echo -e "    ${BRIGHT_GREEN}cmd-exists${RESET}"
		return 2  # Return code 2 to indicate incorrect usage
	fi

	# Check for the '--strict' option
	if [[ "${1}" == "--strict" ]] || [[ "${1}" == "-s" ]]; then
		# Look for executable command
		if [[ -x "$(\command -v ${2})" ]]; then
			return 0  # Command exists
		else
			return 1  # Command doesn't exist
		fi
	else
		# Look for command or alias
		if [[ -n "$(\command -v ${1})" ]]; then
			return 0  # Command or alias exists
		else
			return 1  # Command or alias doesn't exist
		fi
	fi
}

# Loop a list of common editors and check if installed
_EDITORS=("nvim" "vim")
for EDITOR in "${_EDITORS[@]}"; do
	if cmd-exists $EDITOR &>/dev/null; then

		# Default text editor for various command-line utilities
		# (fallback if VISUAL is not set)
		export EDITOR

		# Default text editor for visual (full-screen) utilities
		# (takes precedence over EDITOR)
		export VISUAL=$EDITOR

		# Specifies the editor to use with 'sudo -e' or 'sudoedit'
		# (overrides VISUAL and EDITOR)
		export SUDO_EDITOR=$EDITOR

		# Specifies the editor for 'fc' command to edit and re-run
		# commands from history (falls back to EDITOR)
		export FCEDIT=$EDITOR

		# Specifies a fallback editor for Emacs and its derivatives
		# (Used when Emacs cannot start the primary editor defined by EDITOR)
		export ALTERNATE_EDITOR=$EDITOR

		# nnn default action for opening a file
		# https://github.com/jarun/nnn
		export NNN_OPENER=$EDITOR

		# Exit the loop when the first installed editor is found
		break
	fi
done
unset _EDITORS

# We will default to use either Neovim https://neovim.io or vim instead of vi
# NOTE: vi is POSIX compliant but vim has more features and Neovim is more extensible
# http://www.viemu.com/a-why-vi-vim.html
# https://www.linuxfordevices.com/tutorials/linux/vim-vs-neovim
if cmd-exists --strict nvim; then
	alias {v,vi,vim}='nvim'
	alias svi='sudo nvim'
	alias vis='nvim "+set si"'
elif cmd-exists --strict vim; then
	alias {v,vi}='vim'
	alias svi='sudo vim'
	alias vis='vim "+set si"'
elif cmd-exists --strict vi; then
	alias v='vi'
	alias svi='sudo vi'
fi

# Set some defaults for nano
# NOTE: Depending on the version of nano you have, --linenumbers and --suspend is helpful
if cmd-exists --strict nano; then
	alias {n,nano}='nano --smarthome --multibuffer --const --autoindent'
fi

# Set Micro editor true color support
# Link: https://micro-editor.github.io/
# Install: curl https://getmic.ro | bash
export MICRO_TRUECOLOR=1

# Create an alias for the Helix editor
# See hx --tutor or :tutor for a vimtutor-like introduction
# Link: https://github.com/helix-editor/helix
# Link: https://docs.helix-editor.com/title-page.html
if cmd-exists --strict helix; then
	alias hx='helix'
fi

# Smart File Editor with Auto Privilege Management
# Uses the default editor or sudoedit for security based on file permissions
# It also provides visual feedback in color and even integrates with Tmux
# Syntax: edit [optional_filename]
alias e="edit"
function edit() {

	# Local variable to track if the immutable attribute was modified
	local IMMUTABLE_SET=""

	# Post-edit action function to handle specific file edits and reapply the immutable attribute if it was removed
	function post_edit_action() {
		# Convert the provided path to an absolute path
		local ABSOLUTE_PATH=$(realpath "${1}" 2>/dev/null)

		# Exit the function if the file does not exist
		[[ -z "${ABSOLUTE_PATH}" ]] && return

		# Use a case statement to match the filename with specific actions
		case "${ABSOLUTE_PATH}" in

			/etc/default/grub)
				# Check if grub-mkconfig exists before updating grub configuration
				if cmd-exists grub-mkconfig; then
					if ask "${BRIGHT_YELLOW}Update grub configuration?${RESET}" Y; then
						sudo grub-mkconfig -o /boot/grub/grub.cfg
						echo -e "${BRIGHT_GREEN}Grub configuration updated${RESET}"
					fi
				fi
			;;

			# Apache Configuration
			/etc/httpd/conf/httpd.conf|/etc/apache2/apache2.conf)
				# Validate Apache Configuration
				if cmd-exists apachectl; then
					if apachectl configtest; then
						if ask "${BRIGHT_YELLOW}Restart Apache to apply changes?${RESET}" Y; then
							apacherestart
						fi
					else
						echo -e "${BRIGHT_RED}Apache configuration test failed${RESET}"
					fi
				fi
			;;

			# Nginx Configuration
			/etc/nginx/nginx.conf)
				# Validate Nginx Configuration
				if cmd-exists nginx; then
					if nginx -t; then
						if ask "${BRIGHT_YELLOW}Restart Nginx to apply changes?${RESET}" Y; then
							ngrestart
						fi
					else
						echo -e "${BRIGHT_RED}Nginx configuration test failed${RESET}"
					fi
				fi
			;;

			$(php -r 'echo php_ini_loaded_file();'))
				if ask "${BRIGHT_YELLOW}Restart web servers to apply PHP changes?${RESET}" Y; then
					# Try to restart Apache and suppress errors
					if cmd-exists --strict apachectl || cmd-exists --strict httpd || cmd-exists --strict apache2; then
						apacherestart
					fi

					# Try to restart Nginx and suppress errors
					if cmd-exists --strict nginx; then
						ngrestart
					fi

					echo -e "${BRIGHT_GREEN}Attempted to restart web servers for PHP.ini changes${RESET}"
				fi
			;;

			/etc/ssh/sshd_config)
				# Check if systemd is installed and systemctl is available
				if cmd-exists --strict systemctl; then
					if ask "${BRIGHT_YELLOW}Restart SSH service to apply changes?${RESET}" Y; then
						# Directly execute the commands to restart and enable the SSH service
						sudo systemctl restart sshd.service && sudo systemctl enable sshd.service
						echo -e "${BRIGHT_GREEN}SSH service restarted${RESET}"
					fi
				fi
			;;

			/etc/vconsole.conf)
				# Check if mkinitcpio exists before rebuilding the initial ramdisk environment
				if cmd-exists mkinitcpio; then
					if ask "${BRIGHT_YELLOW}Rebuild initial ramdisk environment for vconsole?${RESET}" Y; then
						sudo mkinitcpio -P
						echo -e "${BRIGHT_GREEN}Initial ramdisk environment rebuilt${RESET}"
					fi
				fi
			;;

			"${HOME}/.bash_profile")
				# If editing the .bash_profile file, reload it
				if ask "${BRIGHT_YELLOW}Reload the new .bash_profile file?${RESET}" N; then
					\clear
					\source ~/.bash_profile
				fi
			;;

			"${HOME}/.bashrc")
				# If editing the .bashrc file, reload it
				if ask "${BRIGHT_YELLOW}Reload the new .bashrc file?${RESET}" N; then
					\clear
					\source ~/.bashrc
				fi
			;;

			"${HOME}/.tmux.conf"|"${HOME}/.config/tmux/tmux.conf"|/etc/tmux.conf)
				# If editing .tmux.conf, refresh tmux configuration
				# Check if tmux is installed and running
				if cmd-exists tmux && tmux info &> /dev/null; then
					tmux source-file "${1}"
					echo -e "${BRIGHT_GREEN}Reloaded Tmux configuration from ${BRIGHT_MAGENTA}${1}${RESET}"
				fi
			;;

			"${HOME}/.Xresources"|/etc/X11/Xresources)
				# Check if xrdb exists and we are in X11 before merging .Xresources
				if [[ $DISPLAY ]] && [[ $XDG_SESSION_TYPE == "x11" ]] && cmd-exists --strict xrdb; then
					if ask "${BRIGHT_YELLOW}Merge X resources from ${ABSOLUTE_PATH}?${RESET}" Y; then
						xrdb -merge "${1}"
						echo -e "${BRIGHT_GREEN}Merged X resources from ${BRIGHT_MAGENTA}${1}${RESET}"
					fi
				fi
			;;
		esac
	}

	# Helper function to use the more secure sudoedit only if it's possible
	# since sudoedit cannot edit a file in a directory with write permissions
	function sudo_edit() {

		# Determine the directory containing the file
		local DIRNAME=$(dirname "${1}")
		[[ "${DIRNAME}" == "." ]] && DIRNAME="${PWD}"

		# If inside a Tmux session, rename the tab temporarily
		rename_tab ${1}

		# Check if the directory is writable...
		if [[ -w "${DIRNAME}" ]] || ! cmd-exists sudoedit; then
			# Edit as root keeping environment variables (like default editor)
			sudo --preserve-env "${EDITOR}" "${1}" && post_edit_action "${1}"
		else
			# Securely edit as root via temporary copy minimizing editor risks
			sudoedit "${1}" && post_edit_action "${1}"
		fi

		# Restore the Tmux tab name
		restore_tab
	}

	# Function to check and modify the immutable attribute of a file
	# Parameters:
	#   $1 - The filename to check and potentially modify the immutable attribute
	function immutable_remove() {
		# Check if required commands exist
		if ! cmd-exists chattr || ! cmd-exists lsattr; then
			return
		fi

		# Check if the file and commands exists
		if [[ -f "${1}" ]] && cmd-exists chattr && cmd-exists lsattr; then

			# Extract file attributes using lsattr
			local ATTRIBUTES=$(lsattr "${1}" 2>/dev/null | cut -d' ' -f1)

			# Check if the immutable attribute is set (indicated by 'i')
			if [[ "${ATTRIBUTES}" =~ i ]]; then

				# Ask user if they want to temporarily remove the immutable attribute to allow editing
				if ask "${BRIGHT_YELLOW}This file is immutable. Temporarily remove immutable attribute to edit?${RESET}" Y; then

					# Try to remove the immutable attribute without using sudo first
					if ! chattr -i "${1}" > /dev/null 2>&1; then
						# If the command fails, inform the user and retry with sudo
						sudo chattr -i "${1}" > /dev/null 2>&1
					fi

					# Set a flag to indicate the attribute was modified
					IMMUTABLE_SET="true"
				else

					# If the user chooses not to edit the file, exit and show a message
					echo -e "${BRIGHT_RED}Cannot edit the file without removing the immutable attribute.${RESET}"

					# Exit the function with status 1 indicating an error
					return 1
				fi
			fi
		fi
	}

	# Reapply the immutable attribute if it was previously removed
	function immutable_restore() {
		# Check if the file and commands exists
		if [[ -f "${1}" ]] && cmd-exists chattr; then

			# If we changed the immutable attribute
			if [[ "${IMMUTABLE_SET}" == "true" ]]; then

					# Try to restore the immutable attribute without using sudo first
					if ! chattr +i "${1}" > /dev/null 2>&1; then
						# If the command fails, inform the user and retry with sudo
						sudo chattr +i "${1}" > /dev/null 2>&1
					fi

				echo -e "${BRIGHT_GREEN}Immutable attribute reapplied to ${BRIGHT_MAGENTA}${1}${RESET}"
			fi
		fi
	}

	# Helper function to rename the current Tmux or console tab if supported
	function rename_tab() {
		# Get the simple editor name
		local _EDITOR_SHORT_NAME=$(basename "${EDITOR%% *}")

		# Get the filename (drop the path) for the new tab name
		local _EDITING_FILENAME=$(basename "${1}")

		# If in a Tmux session...
		if [[ -n "${TMUX}" ]] && cmd-exists tmux; then
			# Save the current tab text
			_CURRENT_TAB_NAME=$(tmux display-message -p '#W')

			# Rename the current tab
			#tmux rename-window "✒️${_EDITING_FILENAME}"
			tmux rename-window "${_EDITOR_SHORT_NAME}→${_EDITING_FILENAME}"

		# Check if we are in WezTerm
		elif [[ "${TERM_PROGRAM}" == "WezTerm" ]]; then
			# Rename the WezTerm tab
			wezterm cli set-tab-title "${_EDITOR_SHORT_NAME} → ${_EDITING_FILENAME}"

		# We are not in Tmux...
		else
			# Change the tab title if the terminal supports it
			echo -ne "\033]2;${_EDITOR_SHORT_NAME}→${_EDITING_FILENAME}\007"
			echo -ne "\033]30;${_EDITOR_SHORT_NAME}→${_EDITING_FILENAME}\007"
		fi
	}

	# Helper function to restore the Tmux or Konsole tab name
	function restore_tab() {
		# If we are inside a Tmux session...
		if [[ -n "${TMUX}" ]] && [[ -n "${_CURRENT_TAB_NAME}" ]] && cmd-exists tmux; then
			# Restore Tmux tab name
			tmux rename-window "${_CURRENT_TAB_NAME}"
			unset _CURRENT_TAB_NAME

		elif [[ "${TERM_PROGRAM}" == "WezTerm" ]]; then
			# Restore WezTerm tab name
			wezterm cli set-tab-title ""

		# If we are in Konsole...
		elif [[ -n "$KONSOLE_DBUS_SERVICE" ]]; then
			# Reset the tab title to the default
			echo -ne "\033]30;%d : %n\007"

		# We are not in Tmux...
		else
			# This will reset the tab
			echo -ne "\033]0;\007"
		fi
	}

	# Check if the file is a symlink
	if [[ -L "${1}" ]]; then
		# Resolve the symlink to the actual file
		local ACTUAL_FILE=$(readlink -f "${1}")

		# Inform the user about the switch
		echo -e "${BRIGHT_YELLOW}Editing actual file instead of symlink:${RESET} ${BRIGHT_CYAN}${ACTUAL_FILE}${RESET}"
	else
		# If not a symlink, proceed with the original file
		local ACTUAL_FILE="${1}"
	fi

	# If the it does not contain a path and is not a file
	if [[ "$ACTUAL_FILE" != */* && ! -f "$ACTUAL_FILE" ]]; then
		# Try to locate the full path using `which`
		local FOUND_PATH=$(command which "$ACTUAL_FILE" 2>/dev/null)

		# Update ACTUAL_FILE if a path was found
		if [[ -n "$FOUND_PATH" ]]; then
			ACTUAL_FILE="$FOUND_PATH"
		fi
	fi

	# Check for special case of editing /etc/sudoers...
	if [[ "${ACTUAL_FILE}" == "/etc/sudoers" ]] && cmd-exists visudo; then
		echo -ne "${BRIGHT_RED}Security alert:"
		echo -e "${BRIGHT_YELLOW} Using visudo to edit ${BRIGHT_CYAN}${ACTUAL_FILE}${RESET}"
		immutable_remove "${1}"
		rename_tab ${ACTUAL_FILE}
		sudo visudo
		restore_tab
		immutable_restore "${1}"
		return

	# Check if EDITOR is set...
	elif [ -z "${EDITOR}" ]; then
		echo -ne "${BRIGHT_RED}Error: ${BRIGHT_CYAN}EDITOR environment variable is not set.${RESET}"
		return 1

	# No parameters passed, load the default editor...
	elif [[ $# -eq 0 ]]; then
		rename_tab 'New File'
		"${EDITOR}"
		restore_tab
		return

	# Check if file exists and has read/write permissions...
	elif [[ -r "${ACTUAL_FILE}" ]] && [[ -w "${ACTUAL_FILE}" ]]; then
		immutable_remove "${1}"
		rename_tab ${ACTUAL_FILE}
		"${EDITOR}" "${ACTUAL_FILE}" && post_edit_action "${ACTUAL_FILE}"
		restore_tab
		immutable_restore "${1}"
		return

	# Check if the file exists but doesn't have write permission...
	elif [[ -f "${ACTUAL_FILE}" ]]; then
		echo -ne "${BRIGHT_RED}Insufficient permissions:"
		echo -e "${BRIGHT_YELLOW} Using super user to edit ${BRIGHT_CYAN}${ACTUAL_FILE}${RESET}"
		immutable_remove "${1}"
		sudo_edit "${ACTUAL_FILE}"
		immutable_restore "${1}"
		return

	# File doesn't exist, check if we can create it...
	elif [[ -w "$(dirname "${ACTUAL_FILE}")" ]]; then
		# Attempt to edit the file
		rename_tab ${ACTUAL_FILE}
		if "${EDITOR}" "${ACTUAL_FILE}"; then
			return
		else # There was an error...
			# Retry with sudo_edit
			restore_tab
			echo -ne "${BRIGHT_RED}Insufficient permissions:"
			echo -e "${BRIGHT_YELLOW} Retrying with super user to edit ${BRIGHT_CYAN}${ACTUAL_FILE}${RESET}"
			immutable_remove "${1}"
			sudo_edit "${ACTUAL_FILE}"
			immutable_restore "${1}"
			return
		fi

	# We need super user access to create the new file
	else
		echo -ne "${BRIGHT_RED}Insufficient permissions:"
		echo -e "${BRIGHT_YELLOW} Using super user to create ${BRIGHT_CYAN}${ACTUAL_FILE}${RESET}"
		sudo_edit "${ACTUAL_FILE}"
		return
	fi
}

# Shortcut for edit using root permissions
alias se="sudoedit"

#######################################################
# Set default variable values
# These variables can be overridden in one of these environment variable files:
# ~/.env
# ~/.envrc
# ~/.config/bashrc/config
#######################################################

# Determines if CTRL+h will show help
# Ctrl+h (for help) and Ctrl+Backspace share the same key binding
# in some terminal emulators so we default to skip this keybind
_SKIP_HELP_KEYBIND=true

# Show an installed information HUD on initial Bash load (if not skipped)
# Link: https://github.com/LinusDierheimer/fastfetch
# Link: https://ostechnix.com/neofetch-display-linux-systems-information/
# Link: https://github.com/KittyKatt/screenFetch
# Link: https://github.com/deater/linux_logo
# Link: https://github.com/dylanaraps/pfetch
_SKIP_SYSTEM_INFO=false

# If not skipped, shows pending updates (only in Arch, Manjaro, and Ubuntu)
# WARNING: This check for updates takes several seconds so the default is true
_SKIP_UPGRADE_NOTIFY=true

# Automatically launch TMUX terminal multiplexer in local, TTY, or SSH sessions
# https://github.com/tmux/tmux/wiki
# Since TMUX is pre-installed on so many systems, the default is to skip TMUX
_TMUX_LOAD_TTY=false
_TMUX_LOAD_SSH=false
_TMUX_LOAD_LOCAL=false

# OPTIONAL: Set and force the default TMUX session name for this script and tm
# If not specified, an active TMUX session is used and attached to
# If no active TMUX session exists, the current logged in user name is used
#_TMUX_LOAD_SESSION_NAME=""

# Terminology is a graphical EFL terminal emulator that can run in TTY sessions
# If installed, it can automatically be launched when starting a TTY session
# To split the window horizontally press Ctrl+Shift+PgUp
# To split the window vertically press Ctrl+Shift+PgDn
# To create Tabs press Ctrl+Shift+T and cycle through using Ctrl+1-9
# Link: https://github.com/borisfaure/terminology
# Link: https://linoxide.com/terminology-terminal/
_SKIP_TERMINOLOGY_TTY=false

# Blesh: Bash Line Editor replaces default GNU Readline
# Link: https://github.com/akinomyoga/ble.sh
# Link for configuration: https://github.com/akinomyoga/ble.sh/blob/master/blerc
# WARNING: Can be buggy with certain prompts (like Trueline)
_SKIP_BLESH=false

# Make sure the default file and directory permissions for newly created files
# in the home directory is umask 026 to improve security.
# (user=read/write/execute, group=read/execute, others=execute for directories)
# The default is to skip this security setting and not modify home permissions
_SKIP_UMASK_HOME=true

# Replaces Sudo with one of the two alternatives (if installed):
# RootDO (rdo) - A very slim alternative to both sudo and doas
# Link: https://codeberg.org/sw1tchbl4d3/rdo
# - OR -
# A port of OpenBSD's doas offers two benefits over sudo:
# 1) Its configuration file has a simple syntax and
# 2) It is smaller, requiring less effort to audit the code
# Link: https://github.com/Duncaen/OpenDoas or https://github.com/slicer69/doas
# Default value is skip and must be set to false manually for security reasons
_SKIP_SUDO_ALTERNATIVE=true

# If set to true, cd will not output the current absolute path under certain
# circumstances like when using the command cd - or using cdable_vars bookmarks
# Link: https://www.gnu.org/software/bash/manual/bash.html#index-cd
_SILENCE_CD_OUTPUT=false

# If set to true, will not load anything that modifies the ls command or colors
_SKIP_LS_COLORIZED=false

# LSD (LSDeluxe) is a rewrite of GNU ls with lots of added features like
# colors, icons, tree-view, more formatting options, git support, etc.
# Fonts: Install the patched fonts of powerline, nerd-font, and/or font-awesome
# Link: https://github.com/Peltoche/lsd
_SKIP_LSD=false

# eza/exa is a modern color replacement for ls that also has some Git support
# Link: https://github.com/eza-community/eza
# Link: https://github.com/ogham/exa
_SKIP_EXA=false

# grc Generic Colouriser
# Link: https://github.com/garabik/grc
_SKIP_GRC=false

# Choose your preferred picker to use with menus
# You can choose any picker like fzy, sk, fzf, peco, percol, pick, icepick,
# selecta, sentaku, zf, or even dmenu, rofi, or wofi UI pickers
_PREFERRED_PICKER=

# If set to true, will not source bash completion scripts
_SCRIPT_BASH_COMPLETION=false

# If set to true, will show a calendar when Bash is started
_SHOW_BASH_CALENDAR=false

# If GNU gcal is installed, use this local for holidays
# To show the possible options type: gcal -hh | grep 'Holidays in'
# Link: https://www.gnu.org/software/gcal/manual/gcal.html
# Link: https://unix.stackexchange.com/questions/164555/how-to-emphasize-holidays-by-color-in-cal-command
_GCAL_COUNTRY_CODE=US_AK

# Skip the birthday/anniversary reminder that shows a message in your teminal?
# Reads the birthday CSV file: ~/.config/birthdays.csv
# The first line is ignored (header) and the format is (year is optional):
# Month,Day,Year,"Message"
# Jan,1,1985,"This is a message!"
#
# Toilet application is an optional dependency
# Install Arch/Manjaro:  sudo pacman -S toilet
# Install Ubuntu/Debian: sudo apt-get install toilet
_SKIP_BDAY_REMINDER=false

# Set the location for the birthday/anniversary reminder CSV file
# The default location is "~/.config/birthdays.csv"
_BDAY_FILE="${HOME}/.config/birthdays.csv"

# Set the preferred birthday reminder font here (default is "future"):
_BDAY_FONT=future

# Set to have the built in prompt use a faster but less precise Git method
# This might be necessary on slow connections or networked directories
# Also if set to true, will remove eza/exa's --git flag (use lsg for Git info)
_GIT_IS_SLOW=false

# Recognize the depreciated _PROMPT_BUILTIN_FASTER_GIT option
if [[ ${_PROMPT_BUILTIN_FASTER_GIT} = true ]]; then
	_GIT_IS_SLOW=true
fi

# Optional original prompt from 2014 version now with newly added Git support
# download the optional .bashrc_prompt script file and place it in either your
# home directory or as the file ~/.config/bashrc/prompt
# You will also need to make sure this setting is set to false
_SKIP_PROMPT_ORIGINAL=false

# If false, the built-in prompt will be one single line with an abbreviated path
# If true, the built-in prompt will split into two lines with a full path
_PROMPT_BUILTIN_FULL_PATH=false

# Trueline Bash (true 24-bit color and glyph support)
# This is the prefered prompt since it looks amazing,
# has so many features, is easily extended using functions,
# and is a single Bash script file that is easy to install.
# Link: https://github.com/petobens/trueline
# Install: wget https://raw.githubusercontent.com/petobens/trueline/master/trueline.sh -P ~/
# Fonts: https://github.com/powerline/fonts
_SKIP_PROMPT_TRUELINE=false

# Powerline-Go (this prompt uses no special glyphs)
# Link: https://github.com/justjanne/powerline-go
_SKIP_PROMPT_POWERLINE_GO=false

# Powerline-Shell (details about git/svn/hg/fossil branch and Python virtualenv environment)
# Link: https://github.com/b-ryan/powerline-shell
_SKIP_PROMPT_POWERLINE_SHELL=false

# Pureline (256 color written in bash script)
# Link: https://github.com/chris-marsh/pureline
# Install:
# git clone https://github.com/chris-marsh/pureline.git
# cp pureline/configs/powerline_full_256col.conf ~/.pureline.conf
_SKIP_PROMPT_PURELINE=false

# Starship Cross Shell Prompt (focus on compatibility and written in Rust)
# Link: https://starship.rs
# Install: sh -c "$(curl -fsSL https://starship.rs/install.sh)"
_SKIP_PROMPT_STARSHIP=false

# Oh-My-Git (only used for Git but has huge support for it, requires font)
# Link: https://github.com/arialdomartini/oh-my-git
# Install: git clone https://github.com/arialdomartini/oh-my-git.git ~/.oh-my-git
_SKIP_PROMPT_OH_MY_GIT=false

# Bash Git Prompt (shows git repository, branch name, difference with remote branch, number of files staged, changed, etc)
# Link: https://github.com/magicmonty/bash-git-prompt
# Install: git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt --depth=1
_SKIP_PROMPT_BASH_GIT_PROMPT=false

# Bash Powerline (no need for patched fonts, supports git, previous command execution status, platform-dependent prompt symbols)
# Link: https://github.com/riobard/bash-powerline
# Install: curl https://raw.githubusercontent.com/riobard/bash-powerline/master/bash-powerline.sh > ~/.bash-powerline.sh
_SKIP_PROMPT_BASH_POWERLINE=false

# Sexy Bash Prompt (supports git, 256 color)
# Link: https://github.com/twolfson/sexy-bash-prompt
# Install: (cd /tmp && ([[ -d sexy-bash-prompt ]] || git clone --depth 1 --config core.autocrlf=false https://github.com/twolfson/sexy-bash-prompt) && cd sexy-bash-prompt && make install)
_SKIP_PROMPT_SEXY_BASH_PROMPT=false

# Liquid Prompt (adaptive prompt with low color and no glyphs)
# Link: https://github.com/nojhan/liquidprompt
# Install: git clone --branch stable https://github.com/nojhan/liquidprompt.git ~/liquidprompt
_SKIP_PROMPT_LIQUIDPROMPT=false

# Original Powerline Status Line for Vim Bash Zsh fish tmux IPython Awesome i3 Qtile
# Link: https://github.com/powerline/powerline
# Install: https://medium.com/earlybyte/powerline-for-bash-6d3dd004f6fc
# NOTE: Requires Python and can be used with Trueline in Bash
# WARNING: This path may change or break in the future with new Python versions
_SKIP_PROMPT_POWERLINE=false

# Determine our kernel name
_KERNEL_NAME="$(expr substr $(uname -s) 1 5)"

#######################################################
# Add Common Binary Directories to Path
#######################################################

# Add directories to the end of the path if they exists and are not already in the path
# Link: https://superuser.com/questions/39751/add-directory-to-path-if-its-not-already-there
function pathappend() {
	for ARG in "$@"
	do
		if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
			PATH="${PATH:+"$PATH:"}$ARG"
		fi
	done
}

# Add directories to the beginning of the path if they exist and are not already in the path
function pathprepend() {
	for ((i=$#; i>0; i--));
	do
		ARG=${!i}
		if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
			PATH="$ARG${PATH:+":$PATH"}"
		fi
	done
}

# Add the most common personal binary paths located inside the home folder
# (these directories are only added if they exist)
pathprepend "$HOME/bin" "$HOME/sbin" "$HOME/.local/bin" "$HOME/local/bin" "$HOME/.bin"

# Check for the Rust package manager binary install location
# Link: https://doc.rust-lang.org/cargo/index.html
pathappend "$HOME/.cargo/bin" "/root/.cargo/bin"

# If the GOPATH environment variable is not set, set it to the default
if cmd-exists --strict go && [[ -z ${GOPATH+x} ]] && [[ -d $HOME/go ]]; then
	export GOPATH="$HOME/go"
fi

#######################################################
# User Specific Environment Variables
#######################################################

if [[ -f "$HOME/.envrc" ]]; then
	source "$HOME/.envrc"
fi

if [[ -f "$HOME/.env" ]]; then
	source "$HOME/.env"
fi

if [[ -f "$HOME/.config/bashrc/config" ]]; then
	source "$HOME/.config/bashrc/config"
fi

#######################################################
# Bashrc Support
#######################################################

# Alias to edit and reload  this .bashrc file
alias {ebrc,editbashrc}='edit ~/.bashrc'
alias {rbrc,reloadbashrc}='\clear; \source ~/.bashrc'

# Find the help file for this .bashrc file (type hlp or press CONTROL-H)
if [[ -f "$HOME/.config/bashrc/help" ]]; then
	_BASHRC_HELP="$HOME/.config/bashrc/help"
	if [[ $_SKIP_HELP_KEYBIND = false ]]; then
		bind -x '"\C-h":"less -f -r -n -S ~/.config/bashrc/help"'
	fi
elif [[ -f "$HOME/.bashrc_help" ]]; then
	_BASHRC_HELP="$HOME/.bashrc_help"
	if [[ $_SKIP_HELP_KEYBIND = false ]]; then
		bind -x '"\C-h":"less -f -r -n -S ~/.bashrc_help"'
	fi
fi

# Alias to edit the global bashrc if it exists using the same aliases upper case
if [[ -f "/etc/bash.bashrc" ]]; then
	alias {EBRC,EDITBASHRC}='sudoedit /etc/bash.bashrc'
fi

# Alias to show the help file
alias hlp='\less -f -r -n -S "$_BASHRC_HELP"'

#######################################################
# Use these commands to keep the .bashrc immutable and write protected
# even from root so that other scripts and applications can't change it
#######################################################

alias bashrcprotect="sudo chattr +i $HOME/.bashrc"
alias bashrcunprotect="sudo chattr -i $HOME/.bashrc"
alias bashrccheckprotect='if [[ $(lsattr -R -l ~/.bashrc | grep " Immutable") ]]; then echo "Protected"; else echo "Not Protected"; fi;'

#######################################################
# Alias for Bashrc Updates
#######################################################

# Update this .bashrc and .bashrc_help files
if cmd-exists aria2c; then
	if [[ -f "$HOME/.config/bashrc/help" ]]; then
		alias bashrcupdate='if [[ $(lsattr -R -l ~/.bashrc | grep " Immutable") ]]; then sudo chattr -i ~/.bashrc; fi && aria2c --continue=true --async-dns=false --dir="${HOME}" --out=".bashrc" https://sourceforge.net/projects/ultimate-bashrc/files/_bashrc/download && aria2c --continue=true --async-dns=false --dir="${HOME}/.config/bashrc" --out="help" https://sourceforge.net/projects/ultimate-bashrc/files/_bashrc_help/download && echo "Restart your terminal to see the changes."'
	else
		alias bashrcupdate='if [[ $(lsattr -R -l ~/.bashrc | grep " Immutable") ]]; then sudo chattr -i ~/.bashrc; fi && aria2c --continue=true --async-dns=false --dir="${HOME}" --out=".bashrc" https://sourceforge.net/projects/ultimate-bashrc/files/_bashrc/download && aria2c --continue=true --async-dns=false --dir="${HOME}" --out=".bashrc_help" https://sourceforge.net/projects/ultimate-bashrc/files/_bashrc_help/download && echo "Restart your terminal to see the changes."'
	fi
elif cmd-exists curl; then
	if [[ -f "$HOME/.config/bashrc/help" ]]; then
		alias bashrcupdate='if [[ $(lsattr -R -l ~/.bashrc | grep " Immutable") ]]; then sudo chattr -i ~/.bashrc; fi && curl -L https://sourceforge.net/projects/ultimate-bashrc/files/_bashrc/download --output ~/.bashrc && curl -L https://sourceforge.net/projects/ultimate-bashrc/files/_bashrc_help/download --output ~/.config/bashrc/help && echo "Restart your terminal to see the changes."'
	else
		alias bashrcupdate='if [[ $(lsattr -R -l ~/.bashrc | grep " Immutable") ]]; then sudo chattr -i ~/.bashrc; fi && curl -L https://sourceforge.net/projects/ultimate-bashrc/files/_bashrc/download --output ~/.bashrc && curl -L https://sourceforge.net/projects/ultimate-bashrc/files/_bashrc_help/download --output ~/.bashrc_help && echo "Restart your terminal to see the changes."'
	fi
elif cmd-exists wget; then
	if [[ -f "$HOME/.config/bashrc/help" ]]; then
		alias bashrcupdate='if [[ $(lsattr -R -l ~/.bashrc | grep " Immutable") ]]; then sudo chattr -i ~/.bashrc; fi && wget -c -O ~/.bashrc https://sourceforge.net/projects/ultimate-bashrc/files/_bashrc/download && wget -c -O ~/.config/bashrc/help https://sourceforge.net/projects/ultimate-bashrc/files/_bashrc_help/download && echo "Restart your terminal to see the changes."'
	else
		alias bashrcupdate='if [[ $(lsattr -R -l ~/.bashrc | grep " Immutable") ]]; then sudo chattr -i ~/.bashrc; fi && wget -c -O ~/.bashrc https://sourceforge.net/projects/ultimate-bashrc/files/_bashrc/download && wget -c -O ~/.bashrc_help https://sourceforge.net/projects/ultimate-bashrc/files/_bashrc_help/download && echo "Restart your terminal to see the changes."'
	fi
else
	if cmd-exists --strict xdg-open; then
		alias bashrcupdate='open https://sourceforge.net/projects/ultimate-bashrc/files/'
	else
		alias bashrcupdate='echo "Please install either wget, curl, aria2, or visit https://sourceforge.net/projects/ultimate-bashrc/ to update.'
	fi
fi

#######################################################
# Change the default file and directory permissions for newly created files
# in the home directory
# The default is usually 022 blocking writes for non-users
# umask 022 # u=rwX,g=rX,o=rX
#######################################################

# Only if we are not the root user...
if [[ $_SKIP_UMASK_HOME = false ]] && [[ $EUID -ne 0 ]]; then
	# Grant full access to the user, block write for group, and
	# block read write for others. Leave execute for directories.
	# (Also see fixuserhome function)
	umask u=rwx,g=rx,o=x # umask 026
fi

#######################################################
# General Aliases
# NOTE: To temporarily bypass an alias, we proceed the command with a \
# EG: if the ls command is aliased, to use the normal command you would type \ls
#######################################################

# Show a list of available aliases and functions with optional filtering
function a() {
	# Store the first argument as a filter.
	local FILTER="${1}"

	# Function to list aliases.
	function list_aliases() {
		# Print the heading for aliases in bright red.
		echo -e "${BRIGHT_RED}Aliases:${RESET}"

		# If filter is provided, list aliases and apply the filter.
		alias | awk -F'[ =]' '{print "\033[33m"$2"\033[0m\t\033[34m"$0"\033[0m";}' | grep -E "${FILTER}"
	}

	# Function to list functions.
	function list_functions() {
		# Print the heading for functions in bright red.
		echo -e "${BRIGHT_RED}Functions:${RESET}"

		# If filter is provided, list functions and apply the filter.
		compgen -A function | grep -v '^_.*' | grep -E "${FILTER}"
	}

	# Combine the output of list_aliases and list_functions and pass to less.
	# The output is piped into less with several options for improved viewing.
	{ list_aliases; echo; list_functions; } | less --line-numbers --no-init
}

#######################################################
### DIRECTORY ALIASES
#######################################################

declare -A ALIASES=(
	["bashrc"]="$HOME"
	["bashrc"]="$HOME/.config/bashrc"
	["bin"]="$HOME/.local/bin"
	["BIN"]="/usr/bin"
	["config"]="$HOME/.config"
	["CONFIG"]="/etc"
	["desktop"]="$HOME/Desktop"
	["docs"]="$HOME/Documents"
	["DOCS"]="/usr/local/man"
	["DOCS"]="/usr/local/share/man"
	["DOCS"]="/usr/share/man"
	["downloads"]="$HOME/Downloads"
	["fonts"]="$HOME/.local/share/fonts"
	["fonts"]="$HOME/.fonts"
	["FONTS"]="/usr/share/fonts"
	["icons"]="$HOME/.local/share/icons"
	["icons"]="$HOME/.icons"
	["ICONS"]="/usr/share/icons"
	["music"]="$HOME/Music"
	["pics"]="$HOME/Pictures"
	["share"]="$HOME/.local/share"
	["SHARE"]="/usr/share"
	["themes"]="$HOME/.local/share/themes"
	["THEMES"]="/usr/share/themes"
	["tmp"]="~/tmp"
	["tmp"]="~/.cache/tmp"
	["tmp"]="~/.cache"
	["TMP"]="${TMPDIR:-/tmp}"
	["videos"]="$HOME/Videos"
	["wallpaper"]="$HOME/.local/share/wallpapers"
	["WALLPAPER"]="/usr/share/backgrounds"
	["WALLPAPER"]="/usr/share/wallpapers"
)

# Loop through the associative array and create aliases for existing directories
for ALIAS in "${!ALIASES[@]}"; do
	[ -d "${ALIASES[$ALIAS]}" ] && alias "$ALIAS"="cd \"${ALIASES[$ALIAS]}\""
done

# Clean up
unset ALIAS
unset ALIASES

#######################################################
### GIT ALIASES
#######################################################

# If git is installed...
if cmd-exists git; then

	# Git Alias: Provides many useful Git alias commands
	# This alias will install/update the Git alias commands file
	# Link: https://github.com/GitAlias/gitalias
	# Edit ~/.gitconfig and then include the path to this file like this:
	# [include]
	# path = gitalias.txt
	alias gitalias='curl -L --output "$HOME/gitalias.txt" https://raw.githubusercontent.com/GitAlias/gitalias/main/gitalias.txt && git config --global include.path "gitalias.txt"'

	# When invoked without arguments gg will do a short Git status,
	# otherwise it will just pass on the given arguments to the Git command.
	# Status is likely to be the Git command one will execute the most,
	# hence this simple enhancement does prove very useful in practice.
	# - `??`: Untracked file (not in the repository)
	# - `A`: Added to the index (staged for commit)
	# - `M`: Modified (changes not staged for commit)
	# - `D`: Deleted (deleted but not staged for commit)
	# - `R`: Renamed (file has been renamed, not staged for commit)
	# - `C`: Copied (file has been copied, not staged for commit)
	# - `U`: Unmerged (conflict in merging changes)
	# - `!!`: Ignored (file is ignored by Git)
	# - `1`: Index and working tree match (status for submodules)
	# - `2`: Working tree changed but index not updated (status for submodules)
	# - `?`: Unknown (an error occurred while trying to obtain the status)
	# git status --short --branch
	alias gg='_f() { if [[ $# == 0 ]]; then gitls; else git "$@"; fi }; _f'

	# All Git aliases start with gg for speed
	alias ggg='git status'
	alias ggs='git status --short --branch'
	alias ggp='git pull' # Fetch and merge
	alias ggf='git fetch'
	alias ggm='git merge'
	alias ggpu='git push'
	alias ggr='git reset' # Specify a file to un-add or no file to unstage all
	alias gga='git add'
	alias ggap='git add -p' # Interactively choose hunks
	alias ggac='git add --all && git commit --verbose -m' # Add "commit message"
	alias ggc='git commit --verbose -m' # Add "commit message"
	alias ggm='git commit --amend --verbose'
	alias ggl='git log --pretty=format:"%C(yellow)%h\\ %ad%Cred%d\\ %Creset%s%Cblue\\ [%cn]" --decorate --date=short'
	alias ggls='_f() { git ls-files "$@" | sort; }; _f'
	alias ggd='git diff'
	alias ggds='git diff --stat'
	alias ggdc='git diff --cached'
	alias ggb='gitbranch' # Change branch
	alias ggcb='git checkout -b' # Create new branch
	alias ggst='git stash'
	alias ggpop='git stash pop'

	# Vacuum the local Git repository database, reduce it's size, and clean out logs
	# Link: https://stackoverflow.com/questions/2116778/reduce-git-repository-size
	alias gitclean='git reflog expire --all --expire=now && git gc --prune=now --aggressive'

	# Find all Git repos in the current directory recursively
	# Note: Excludes hidden and temp directories
	# You can find all git repos on the entire system using: locate .git | grep "/.git$"
	alias gitrepos="find . -type d -not -path '*/.git/*' -not -path '*/tmp/*' -not -path '*/temp/*' -not -path '*/.*' -exec test -e '{}/.git' ';' -print -prune"

	# Git Auto-Completion
	# Link: https://github.com/git/git/tree/master/contrib/completion
	# Install: wget -O ~/git-completion.bash https://github.com/git/git/raw/master/contrib/completion/git-completion.bash
	if [[ -f "$HOME/git-completion.bash" ]]; then
		source "$HOME/git-completion.bash"
	fi

	# If exa (with Git support) is installed...
	# Link: https://github.com/ogham/exa
	if cmd-exists exa; then
		# Add icons if unicode and the icon paramter is supported
		if [[ ! $_SKIP_EXA = false ]] && [[ $(locale charmap) == 'UTF-8' ]] && [[ -n $(\exa --help | grep -e '--icons' 2> /dev/null) ]]; then
			alias exa='exa --icons'
		fi
		alias lsg='exa --long --all --links --group --modified --classify --git --group-directories-first --color=auto --color-scale'
	fi

	# If lsd (with Git support) is installed...
	# Link: https://github.com/Peltoche/lsd
	if cmd-exists lsd; then
		# Add icons if unicode and the icon paramter is supported
		if [[ -n $(\lsd --help | grep -e '\-\-git\s' 2> /dev/null) ]]; then
			alias lsd='lsd --git'
		fi
	fi

	# Nearly everything you can do in Git but in a terminal UI
	# Link: https://github.com/Extrawurst/gitui
	if cmd-exists gitui; then
		alias ggu='gitui'
	fi

	# Tig ncurses-based text-mode interface for git
	# Link: https://jonas.github.io/tig/
	if cmd-exists tig; then
		alias gitt='tig'
	fi

	# Git Commander
	# Link: https://github.com/golbin/git-commander
	# Install: npm install -g git-commander
	if cmd-exists git-commander; then
		alias gitc='git-commander'
	fi

	# GRV - Git Repository Viewer
	# Link: https://github.com/rgburke/grv
	if cmd-exists grv; then
		alias gitrv='grv'
	fi

	# LazyGit - Terminal UI for git commands
	# Link: https://github.com/jesseduffield/lazygit
	if cmd-exists lazygit; then
		alias lg='lazygit'
	fi

	# Ugit - Git Undo
	# Link: https://github.com/Bhupesh-V/ugit
	# Install: sh -c "$(curl -fsSL https://raw.githubusercontent.com/Bhupesh-V/ugit/master/install)"
	if cmd-exists ugit; then
		alias {gitundo,ggundo}='ugit'
	fi

	# List Git files by last modified date
	# Link: https://stackoverflow.com/questions/14141344/git-status-list-last-modified-date
	alias gitmodifieddate='IFS=""; git status -s | while read -n2 mode; read -n1; read file; do echo $mode $(stat -c %y "$file") $file; done | sort -k1,4'

	# Returns you to the Git project's top level
	alias cg='cd `git rev-parse --show-toplevel`'

	# Displays git status with human-readable descriptions aligned in columns
	function gitls() {
		count=0  # Will keep the file count
		toggle=0 # Toggle variable for alternating row colors

		# Getting the current branch name
		current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
		if [ $? -ne 0 ]; then
			echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}Not a git repository ${BRIGHT_MAGENTA}(or any parent up to mount point /)${RESET}"
			return 1  # Return with an error status code
		fi
		echo -e "${BRIGHT_RED}Current branch: ${BRIGHT_WHITE}${current_branch}${RESET}"

		# Storing the output of git status --porcelain in a variable
		git_status=$(git status --porcelain | sort -k1,1 -k2 | awk '{$1=$1};1')
		if [ -z "$git_status" ]; then
			echo -e "${BRIGHT_CYAN}No changes found in the repository${RESET}"
			return 0  # Return with a success status code
		fi

		# Find the maximum length of the filenames
		max_filename_length=0
		while IFS= read -r line; do
			filename="${line:2}"
			filename_length=${#filename}
			# Compare the current filename length with the current max
			max_filename_length=$(($max_filename_length < $filename_length ? $filename_length : $max_filename_length))
		done <<< "$git_status"

		# Cap the max_filename_length at 80 if it exceeds it
		if [ $max_filename_length -gt 80 ]; then
			max_filename_length=80
		fi

		# Running git status with the porcelain flag
		#git status --porcelain | sort | while read -r line; do
		while IFS= read -r line; do
			# Count the files
			((count++))

			# Extracting the status code and the file name
			code="${line:0:2}"
			filename="${line:2}"; filename="${filename# }"

			# Matching the status code with the corresponding description
			description=""
			case "$code" in
				"??") description="Untracked file (not in the repository)";;
				"A ") description="Added to the index (staged for commit)";;
				"M ") description="Modified (changes not staged for commit)";;
				"D ") description="Deleted (deleted but not staged for commit)";;
				"R ") description="Renamed (file has been renamed, not staged for commit)";;
				"C ") description="Copied (file has been copied, not staged for commit)";;
				"T ") description="Type changed (e.g., a file becomes executable)";;
				"U ") description="Unmerged (conflict in merging changes)";;
				"!!") description="Ignored (file is ignored by Git)";;
				"1 ") description="Index and working tree match (status for submodules)";;
				"2 ") description="Working tree changed but index not updated (status for submodules)";;
				"? ") description="Unknown (an error occurred while trying to obtain the status)";;
				*)    description="Unknown Status Code";;
			esac

			# Determine if the file is a directory
			if [ -d "$filename" ]; then
				color="${BRIGHT_BLUE}"
			else
				color="${BRIGHT_YELLOW}"
			fi

			# Applying alternating background colors
			if [ $toggle -eq 0 ]; then
				background="\033[100m" # Dark grey background
				toggle=1
			else
				background="\033[49m"  # Default background
				toggle=0
			fi

			# Printing the filename and description with the chosen colors
			printf "$background$color%-*s${BRIGHT_CYAN}%s${RESET}\n" "$max_filename_length" "$filename" " $description"

		# Loop through the next git status line
		done <<< "$git_status"

		# Printing the total count in purple and green
		echo -e "${MAGENTA}Total files:${RESET} ${count}"
	}

	# Change the Git branch - If no branch is specified as an argument, then
	# the user is prompted to select from a list the available branches
	# Syntax: gitbranch [optional_branch_name]
	function gitbranch() {
		# Check if the current directory is a Git repository
		if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
			# No arguments passed
			if [[ -z "${@}" ]]; then
				# Check if there is a remote server
				if git remote -v | grep -q 'origin'; then
					# Prompt the user for action
					if ask "${BRIGHT_WHITE}Download ${BRIGHT_YELLOW}remote${BRIGHT_WHITE} branch names?${BRIGHT_RED} Could be slow for large repos.${RESET}" N; then
						# Fetch latest remote branches; handle errors
						git fetch origin 2>&1
						REMOTE_BRANCHES=$(git ls-remote --refs --sort=-committerdate origin 2>&1 | awk '{sub("refs/heads/", ""); print $2}')
						if [[ $? -ne 0 ]]; then
							echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}$REMOTE_BRANCHES${RESET}"
							return 1
						fi
						# Use createmenu for selection
						git checkout $(echo "$REMOTE_BRANCHES" | createmenu)
					else
						# Use local branches for selection via createmenu
						git checkout $(git branch --sort=-committerdate | cut -c 3- | createmenu)
					fi
				else
					# No remote server, use local branches only
					git checkout $(git branch --sort=-committerdate | cut -c 3- | createmenu)
				fi
			else
				# Argument passed, just switch to that branch
				git checkout ${@}
			fi
		else
			# Not a Git repo
			echo -e "${BRIGHT_RED}ERROR: ${BRIGHT_CYAN}Current directory is not a Git repository${RESET}"
		fi
	}

	# Forces Git to overwrite local files and resets the branch (or master)
	# Important: If you have any local changes, they will be lost (if they're tracked)!
	function gitresetbranch() {
		# Initialize local branch variable
		local branch="${@}"

		# Check if a branch name was provided
		if [ -z "${branch}" ]; then
			# If not, ask if 'master' should be used
			if ask "No branch was specified. Do you wish to use master?" 'Y'; then
				branch="master"
			else
				echo "Please specify a branch."
				return 1
			fi
		fi

		# Confirm action, as local changes will be lost
		if ask "WARNING: If you have any local changes, they will be lost! Are you sure?" 'N'; then
			git checkout ${branch} && git fetch --all && git reset --hard origin/${branch}

		else
			return 0
		fi
	}

	# Function to retrieve a specific version of a file from Git history
	function gitfileversion() {
		# Constants
		local NO_ARGS=0
		local NO_GIT_REPO_ERROR=1
		local NO_FILE_PATH_ERROR=2
		local FILE_NOT_IN_GIT_ERROR=3
		local NO_SELECTION_MADE=4

		# Function to display help
		function display_help() {
			echo -e "${BRIGHT_BLUE}Usage:${RESET} git_file_version ${BRIGHT_GREEN}<file path>${RESET} [${BRIGHT_YELLOW}output file${RESET}]"
			echo -e "${BRIGHT_BLUE}Description:${RESET} Retrieves a specific version of a file from Git history"
			echo -e "   ${BRIGHT_GREEN}<file path>${RESET}   - Path of the file in the Git repository"
			echo -e "   ${BRIGHT_YELLOW}<output file>${RESET} - Optional. Path to save the older version of the file. If not provided, copies to clipboard"
		}

		# Check for no arguments
		if [[ $# -eq $NO_ARGS ]]; then
			display_help
			return $NO_ARGS
		fi

		# Check if inside a Git repository
		if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
			echo -e "${BRIGHT_RED}ERROR: ${BRIGHT_CYAN}Not inside a Git repository${RESET}"
			return $NO_GIT_REPO_ERROR
		fi

		# Check for missing file path
		if [[ -z "$1" ]]; then
			echo -e "${BRIGHT_RED}ERROR: ${BRIGHT_CYAN}File path not provided${RESET}"
			display_help
			return $NO_FILE_PATH_ERROR
		fi

		# Check if the file exists in the Git repo
		if ! git ls-files --error-unmatch "$1" > /dev/null 2>&1; then
			echo -e "${BRIGHT_RED}ERROR: ${BRIGHT_CYAN}File '${BRIGHT_YELLOW}$1${BRIGHT_CYAN}' not found in Git repository${RESET}"
			return $FILE_NOT_IN_GIT_ERROR
		fi

		# Display the commit menu and get selection
		local commit_hash
		commit_hash=$(git log --pretty=format:"%h - %s (%cr)" -- "$1" | createmenu)
		if [[ -z "$commit_hash" ]]; then
			echo -e "${BRIGHT_RED}No selection made. Exiting.${RESET}"
			return $NO_SELECTION_MADE
		fi

		# Extract the hash from the selection
		commit_hash=${commit_hash%% *}

		# Retrieve the file for the selected commit
		local git_show_cmd="git show ${commit_hash}:$1"
		if [[ -n "$2" ]]; then
			# Save to file if second parameter is provided
			$git_show_cmd > "$2"
		else
			$git_show_cmd | clipboard
		fi
	}

	# Set defaults for Git (~/.gitconfig)
	function gitfixsettings() {
		local checkmark="\r${BRIGHT_GREEN}✓${RESET}"

		# If GitAlias (see gitalias alias) is installed...
		if [[ -f "$HOME/gitalias.txt" ]]; then
			# Tell Git to include this file
			git config --global include.path "gitalias.txt"
			echo -e "${checkmark} Found gitalias.txt"
		fi

		# Set the user name
		local GIT_USER_NAME
		read -e -i "$(git config --get user.name)" -p "Enter your user name (ENTER to skip): " GIT_USER_NAME
		if [ -z "${GIT_USER_NAME}" ]; then
			GIT_USER_NAME="User"
		fi
		git config --global user.name "${GIT_USER_NAME}"

		# Set the email address
		local GIT_USER_EMAIL
		read -e -i "$(git config --get user.email)" -p "Enter your email (ENTER to skip): " GIT_USER_EMAIL
		if [ -z "${GIT_USER_EMAIL}" ]; then
			GIT_USER_EMAIL="user@example.com"
		fi
		git config --global user.email "${GIT_USER_EMAIL}"

		# You should add this manually with your own information
		# git config --global user.signingkey <gpg-key-id>

		# Set the default Git editor to your default Bash editor
		git config --global core.editor "${EDITOR}"
		echo -e "${checkmark} Default editor set to ${EDITOR}"

		# Set the dafault pager
		git config --global core.pager "less --ignore-case --LONG-PROMPT --LINE-NUMBERS"

		# Set defaults for diff and merge
		git config --global merge.conflictstyle "diff3"
		git config --global diff.colorMoved "default"

		# Set this if icdiff is installed
		if cmd-exists --strict icdiff; then
			git config --global icdiff.options '--highlight --line-numbers --strip-trailing-cr'
			echo -e "${checkmark} Found icdiff"
		fi

		# If delta is installed...
		if cmd-exists --strict delta; then
			# delta - Beautiful side by side colored diff with Git support and syntax highlighting
			# Link: https://github.com/dandavison/delta
			# Info: Add listed settings to your ~/.gitconfig
			# NOTE: use n and N to move between diff sections
			git config --global core.pager "delta"
			git config --global interactive.diffFilter "delta --color-only --features=interactive"
			git config --global delta.features "decorations"
			git config --global delta.side-by-side "true"
			git config --global delta.line-numbers "true"
			git config --global delta.interactive.keep-plus-minus-markers "false"
			git config --global delta.decorations.commit-decoration-style "blue ol"
			git config --global delta.decorations.commit-style "raw"
			git config --global delta.decorations.file-style "omit"
			git config --global delta.decorations.hunk-header-decoration-style "blue box"
			git config --global delta.decorations.hunk-header-file-style "red"
			git config --global delta.decorations.hunk-header-line-number-style "#067a00"
			git config --global delta.decorations.hunk-header-style "file line-number syntax"
			echo -e "${checkmark} Found delta"
		fi

		# If we are in a desktop environment and Ultracompare is not installed...
		# You will be prompted when you launch Ultracompare to automatically set up
		# Git, so just skip the other diff configurations since this app is paid
		# Link: https://www.ultraedit.com/products/ultracompare-linux/
		if [[ -n "${XDG_CURRENT_DESKTOP}" ]]; then
			echo -e "${checkmark} User is in desktop environment ${XDG_CURRENT_DESKTOP}"

			# If UltraCompare is installed...
			# You will be prompted when you launch UltraCompare to automatically set up
			# Git, so just skip the other diff configurations since this app is paid
			# Link: https://www.ultraedit.com/products/ultracompare-linux/
			if cmd-exists --strict ucx; then
				echo -e "${checkmark} Found UltraCompare"

			# If Meld is installed...
			# Link: https://meldmerge.org/
			elif cmd-exists --strict meld; then
				# These settings will not alter the behaviour of "git diff"
				# Link: https://stackoverflow.com/questions/34119866/setting-up-and-using-meld-as-your-git-difftool-and-mergetool
				# You use "git difftool" in exactly the same way as you use git diff
				# Example: git difftool <COMMIT_HASH> file_name
				# Example: git difftool <BRANCH_NAME> file_name
				# Example: git difftool <COMMIT_HASH_1> <COMMIT_HASH_2> file_name
				git config --global diff.tool meld
				git config --global difftool.meld.path "$(\which meld)"
				git config --global difftool.meld.cmd 'meld "$LOCAL" "$REMOTE"'
				git config --global difftool.prompt false

				# "git mergetool" allows you to use a GUI merge program to resolve merge conflicts
				# Before using git mergetool you perform a merge in the usual way with git
				# then Mergetool can now be used to resolve the merge conflicts
				git config --global merge.tool meld
				git config --global mergetool.meld.path "$(\which meld)"
				git config --global mergetool.prompt false

				# Choose which starting edit position you'd prefer; $MERGED for the file
				# which contains the partially merged file with the merge conflict info
				# or $BASE for the shared commit ancestor of $LOCAL and $REMOTE
				git config --global mergetool.meld.cmd 'meld "$LOCAL" "$MERGED" "$REMOTE" --output "$MERGED"'
				#git config --global mergetool.meld.cmd 'meld "$LOCAL" "$BASE" "$REMOTE" --output "$MERGED"'

				# Also set up the alias "git meld" which works on Cygwin
				git config --global alias.meld '!git difftool -t meld --dir-diff'
				echo -e "${checkmark} Found meld"

			# If KDiff3 is installed...
			# Link: https://kdiff3.sourceforge.net/
			elif cmd-exists --strict kdiff3; then
				git config --global diff.guitool kdiff3
				git config --global difftool.kdiff3.path "$(\which kdiff3)"
				git config --global difftool.kdiff3.trustExitCode false
				git config --global merge.tool kdiff3
				git config --global mergetool.kdiff3.path "$(\which kdiff3)"
				git config --global mergetool.kdiff3.trustExitCode false
				echo -e "${checkmark} Found KDiff3"
			fi
		fi
	}
fi

#######################################################
### SYSTEMD ALIASES
#######################################################

if cmd-exists --strict systemctl; then
	# Get a list of all services
	alias services='systemctl list-units --type=service --state=running,failed'
	alias servicesall='systemctl list-units --type=service'

	# Find what systemd services have failed
	alias {failed,servicefailed}='systemctl --failed'

	# Get the status of a services
	alias servicestatus='sudo systemctl status'

	# Start a service and enable automatic startup at boot
	alias serviceenable='sudo systemctl enable --now'

	# Start a service
	alias servicestart='sudo systemctl start'

	# Stop a service
	alias servicestop='sudo systemctl stop'

	# Forcefully terminate a service
	alias servicekill='sudo systemctl kill'

	# Stop and restart a service
	alias servicerestart='sudo systemctl restart'

	# Reload a service's configuration (soft restart)
	alias servicereload='sudo systemctl reload'

	# Clear system log entries from the systemd journal
	alias clearsystemlogs='echo -ne "${BRIGHT_BLUE}Before${RESET}: "; journalctl --disk-usage; sudo journalctl --rotate; sudo journalctl --vacuum-time=1s; echo -ne "${BRIGHT_BLUE}After${RESET}: "; journalctl --disk-usage'

	# If SSH is installed...
	if cmd-exists --strict ssh; then
		# Create aliases to start/enable and stop/disable the SSH server
		alias sshstatus='systemctl status sshd.service'
		alias sshstart='sudo systemctl start sshd.service && sudo systemctl enable sshd.service'
		alias sshstop='sudo systemctl stop sshd.service && sudo systemctl disable sshd.service'
		alias sshrestart='sudo systemctl restart sshd.service && sudo systemctl enable sshd.service'
	fi

	# If gpm is installed...
	# Link: https://github.com/telmich/gpm
	if cmd-exists --strict gpm; then
		alias ttymouseon='sudo systemctl enable --now gpm'
		alias ttymouseoff='sudo systemctl stop gpm && sudo systemctl disable gpm'
		alias ttymousestatus='sudo systemctl status gpm'
	fi

	# Flushing and restart the DNS cache if installed and running
	function flushdns() {
		# Check if systemd-resolved is available
		if cmd-exists --strict systemd-resolve; then
			# Check if systemd-resolved service is active
			if systemctl is-active systemd-resolved >/dev/null; then
				# Flush DNS cache and restart systemd-resolved
				sudo systemd-resolve --flush-caches
				sudo systemctl restart systemd-resolved
				echo "DNS cache flushed and systemd-resolved restarted"
			else
				echo "systemd-resolved is not active, unable to flush DNS cache"
			fi
		# Check if dnsmasq is available
		elif cmd-exists --strict dnsmasq; then
			# Check if dnsmasq process is running
			if pgrep -x "dnsmasq" >/dev/null; then
				# Restart dnsmasq to flush DNS cache
				sudo systemctl restart dnsmasq
				echo "DNS cache flushed and dnsmasq restarted"
			else
				echo "dnsmasq is not running, unable to flush DNS cache"
			fi
		else
			echo "No supported DNS caching service found"
		fi
	}
fi

#######################################################
### CHANGING AND LISTING DIRECTORIES
#######################################################

# Aliases for faster pushd and popd: type "p" for pushd and "p-" for popd
# Link: https://opensource.com/article/19/8/navigating-bash-shell-pushd-popd
alias p='pushd'
alias p-='popd'
# Allow us to clear the directory stack
alias dirsclear='dirs -c'
# If you want to see the numeric position of each directory in the stack,
# you can use the -v (vertical) option - as DT suggests, use this by default
alias dirs='dirs -v'

# Alias and bookmark the web folder (try to guess it's location)
# This will NOT overwrite a "web" alias previously definded in .bash_aliases
if [[ "$(type -t web)" != 'alias' ]]; then
	if [[ -d /var/www/html ]]; then
		alias web='cd /var/www/html'
		export web="/var/www/html"
	elif [[ -d /srv/http ]]; then
		alias web='cd /srv/http'
		export web="/srv/http"
	fi
fi

# If lsx enhanced directory navigation is found, source it
# Link: https://github.com/souvikinator/lsx
if [[ -f "$HOME/.config/lsx/lsx.sh" ]]; then
	source ~/.config/lsx/lsx.sh
fi
# If lsx is installed, alias it to see hidden directories
if cmd-exists lsx; then
	alias lsx='lsx -a'
fi

# If nnn is installed, add an alias for a directory listing
# Link: https://github.com/jarun/nnn/
# The following command installs or updates all plugins:
# Install: curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | sh
# Plugins are installed to ${XDG_CONFIG_HOME:-$HOME/.config}/nnn/plugins
if cmd-exists --strict nnn; then
	if [[ -f "$HOME/.config/nnn/plugins/finder" ]]; then
		export NNN_PLUG='f:finder;o:fzopen;p:mocplay;d:diffs;t:nmount;v:imgview'
		alias nnnplugins='curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | sh'
	fi
	#alias nnn='nnn -e'
	alias nnn='nnn -Headr'
fi

# TUIFI Manager
# Link: https://github.com/GiorgosXou/TUIFIManager
# Install: pip3 install tuifimanager --upgrade
if cmd-exists tuifi; then
	alias ff="tuifi"
fi

# List folders recursively in a tree
if cmd-exists --strict tree; then
	alias treed='\tree -CAFd'
fi

# List files recursively in a tree
if cmd-exists broot; then
	# If broot is installed...
	# Link: https://github.com/Canop/broot
	# Link: https://computingforgeeks.com/broot-easy-directory-trees-navigation-in-linux/

	# To generate this source file, type: broot --install
	if [[ -f "$HOME/.config/broot/launcher/bash/br" ]]; then
		# Source the br function
		source "$HOME/.config/broot/launcher/bash/br"

		# If Git is installed, enable the Git functionality
		if cmd-exists git; then
			alias {lb,tree}='br --sizes --dates --show-root-fs --hidden --show-git-info'
		else
			alias {lb,tree}='br --sizes --dates --show-root-fs --hidden'
		fi
	else
		# If Git is installed, enable the Git functionality
		if cmd-exists git; then
			alias {lb,tree}='broot --sizes --dates --show-root-fs --hidden --show-git-info'
		else
			alias {lb,tree}='broot --sizes --dates --show-root-fs --hidden'
		fi
	fi

elif [[ $_SKIP_LSD = false ]] && cmd-exists lsd; then
	# If lsd is installed...
	# Link: https://github.com/Peltoche/lsd
	alias tree='\lsd --all --blocks permission,user,size,date,name --group-dirs first --header --long --tree'
elif [[ $_SKIP_EXA = false ]] && cmd-exists exa; then
	# If exa is installed...
	# Link: https://github.com/ogham/exa
	alias tree='\exa --all --git --group-directories-first --header --long --tree'
elif cmd-exists tree; then
	# If tree is installed...
	# Link: https://www.tecmint.com/linux-tree-command-examples/
	alias tree='\tree -CAhF --dirsfirst'
fi

# Common aliases for directory listing commands
alias lw='ls -xAh'                   # wide listing format
alias lm='ll -alh | \less -S'        # pipe through less
alias lr='ls -lRh'                   # recursive ls
alias l.='ll -d .*'                  # show hidden files
alias lfile="ls -l | grep -v '^d'"   # files only
alias ldir="ls -la | grep '^d'"      # directories only

# Conditional aliases based on the availability of specific directory tools
if [[ $_SKIP_LS_COLORIZED = false ]]; then

	# If lsd is installed, use it instead
	# Link: https://github.com/Peltoche/lsd
	if [[ $_SKIP_LSD = false ]] && cmd-exists lsd; then
		alias ls='lsd -AF --group-dirs first'
		alias ll='lsd --almost-all --header --long --group-dirs first'
		alias labc='lsd -lAv --header'
		alias lx='lsd -lAXh --header'
		alias lk='lsd -lASrh --header'
		alias lt='lsd -lAtrh --header'
		alias lc='\ls -lAcrh --color=always --header'
		alias lu='\ls -lAurh --color=always --header'
		alias new='lsd -lAtr --almost-all | tail -10 | tac'
		alias ltree='\lsd --almost-all --blocks permission,user,size,date,name --group-dirs first --header --long --tree'

	# If exa (with Git support) is installed...
	# Link: https://github.com/ogham/exa
	elif [[ $_SKIP_EXA = false ]] && cmd-exists exa; then

		# Add icons to exa if unicode and the icon paramter is supported
		if [[ $(locale charmap) == 'UTF-8' ]]; then
			(\exa --help | grep -q -e "--icons" &> /dev/null) && alias exa='exa --icons'
		fi

		# If Git is not slow, use the exa Git feature
		if [[ $_GIT_IS_SLOW = false ]]; then
			_EXA_GIT_FLAG="--git "
		fi

		alias ls="exa --all --classify --group-directories-first --color=auto --color-scale"
		alias ll="exa --long --all --links --group --modified --classify ${_EXA_GIT_FLAG}--group-directories-first --color=auto --color-scale"
		alias labc="exa --grid --all --classify --color=auto --color-scale --sort name"
		alias lx="exa --long --all --links --group --modified --classify ${_EXA_GIT_FLAG}--group-directories-first --color=auto --color-scale --sort extension"
		alias lk="exa --long --all --links --group --modified --classify ${_EXA_GIT_FLAG}--group-directories-first --color=auto --color-scale --sort size"
		alias lt="exa --long --all --links --group --modified --classify ${_EXA_GIT_FLAG}--group-directories-first --color=auto --color-scale --sort modified"
		alias lc="exa --long --all --links --group --modified --changed --classify ${_EXA_GIT_FLAG}--group-directories-first --color=auto --color-scale --sort changed"
		alias lu="exa --long --all --links --group --modified --accessed --classify ${_EXA_GIT_FLAG}--group-directories-first --color=auto --color-scale --sort accessed"
		alias new="exa --long --all --links --group --modified --classify ${_EXA_GIT_FLAG}--group-directories-first --color=auto --color-scale --sort modified | tail -10 | tac"
		alias lr="exa --grid --all --classify --group-directories-first --color=auto --color-scale --recurse"
		alias ltree="\exa --all ${_EXA_GIT_FLAG}--group-directories-first --header --long --tree"

	# If Natls is installed, use it instead
	# Link: https://github.com/willdoescode/nat
	# Install: cargo install natls
	elif cmd-exists natls; then
		alias ls='natls --gdf --name'
		alias ll='natls --gdf --name --long'
		alias labc='natls --name'
		alias lx='\ls -FlsaXBh --color=auto'
		alias lk='natls --gdf --long --size'
		alias lt='natls --gdf --long --modified'
		alias lc='\ls -Flsacrh --color=auto'
		alias lu='\ls -Flsaurh --color=auto'
		alias new='\ls -latr | tail -10 | tac'
		alias l.='\ls -Flsd .* --color=auto'
		alias lr='\ls -lRh --color=auto'
	else
		# Use ls with command line options
		alias ls='ls -aFh --color=always --group-directories-first'
		alias labc='ls -lap'                  # sort alphabetically
		alias lx='ll -laXBh'                  # sort by extension
		alias lk='ll -laSrh'                  # sort by size
		alias lt='ll -latrh'                  # sort by date
		alias lc='ll -lacrh'                  # sort by change time
		alias lu='ll -laurh'                  # sort by access time
		alias new='ls -latr | tail -10 | tac' # list recently created/updated files
		alias ltree='\tree -CAhF --dirsfirst' # tree view

		if [[ $_SKIP_GRC = false ]] && cmd-exists grc; then
			# If grc Generic Colouriser is installed
			# Link: https://github.com/garabik/grc
			alias ll='grc ls -l --all --classify --group-directories-first --human-readable --color=always'
		else
			# Use standard long listing format
			alias ll='llcolor'
		fi
	fi
else
	alias ls='ls -aFh --color=always'     # do add built-in colors to file types
	alias ll='ls -Fals'                   # long listing
	alias labc='ls -lap'                  # sort alphabetically
	alias lx='ll -laXBh'                  # sort by extension
	alias lk='ll -laSrh'                  # sort by size
	alias lt='ll -latrh'                  # sort by date
	alias lc='ll -lacrh'                  # sort by change time
	alias lu='ll -laurh'                  # sort by access time
	alias new='ls -latr | tail -10 | tac' # list recently created/updated files
fi

# List all files larger than a given size
# llfs +10k will find and display all files larger than 10 kilobytes in the currect directory
alias llfs='_f(){ find . -type f -size "$1" -exec ls --color --classify --human-readable -l {} \; ; }; _f'

# Show colors with the dir command
if cmd-exists --strict dir; then
	alias dir='dir --color=auto  --almost-all --human-readable --group-directories-first -F'
	alias vdir='vdir --color=auto'
fi

# Show the previous path
alias pwd-='echo ${OLDPWD}'

# Show full path of file or wildcard
alias fullpath='find "`pwd`" -name'

# List the PATH environment variable directories
alias path='echo -e ${PATH//:/\\n}'

# When changing a directory, don't show an extra line with the directory
# Link: https://askubuntu.com/questions/1316485/how-do-i-stop-cd-command-from-printing-absolute-path-everytime
if [[ $_SILENCE_CD_OUTPUT = true ]]; then
	alias cd='>/dev/null cd'
fi

# Change to the home directory
alias home='cd ~'

# Allow changing directory when missing a space
alias cd..='cd ..'

# Allow changing directory back when missing a space
alias cd-='cd -'

# Go back directories using dot style
alias ..='up 1'
alias ...='up 2'
alias ....='up 3'
alias .....='up 4'
alias ......='up 5'

# Go back directories using dot dot number style
alias ..1='up 1'
alias ..2='up 2'
alias ..3='up 3'
alias ..4='up 4'
alias ..5='up 5'

#######################################################
### FIND FILES OR FILE INFORMATION
#######################################################

# Searches for directories (can use wildcards)
# Example: finddir config
# Example: finddir "This has spaces"
alias finddir='find . -type d -iname'

# Recursively find all files modified in the last 24 hours (current directory)
alias find24='find . -mtime -1 -ls'

# Find all the symlinks containing search text (i.e. "/backup")
alias findlinks="find . -type l -printf '%p -> ' -exec readlink -f {} ';' | grep -E"

# To count how many files are in your current file system location:
alias countfiles='find . -type f | wc -l'

# To see if a command is aliased, a file, or a built-in command
alias check="type -t"

# If the mlocate package is installed
if cmd-exists locate; then
	# Case insensitive search and display only files present in your system
	alias locate='locate -i -e'

	# Update the locate database before locating a file
	# --require-visibility 0 ensures only accessible files are indexed
	alias ulocate='sudo updatedb --require-visibility 0 && locate'

	# Always update the locate (mlocate) database as root
	alias updatedb='sudo updatedb --require-visibility 0'

	# Display the number of matching entries
	alias locount='locate -c'
fi

#######################################################
### FILE MANAGEMENT
#######################################################

# Safety net for changing permisions on /
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# Alias to make a file executable
# A combination of the letters ugoa controls which users' access to the
# file will be changed: the user who owns it (u), other users in the
# file's group (g), other users not in the file's group (o), or all users
# (a). If none of these are given, the effect is as if (a) were given,
# but bits that are set in the umask are not affected.
alias mx='chmod a+x'

# Make parent directories as needed
alias mkdir='mkdir -p'

# When copying files, prompt before overwriting a file
alias cp='cp -i'

# When moving files, prompt for confirmation if the destination path exists
# Use -f if you want to skip all prompts (-i option is ignored)
alias mv='mv -i'

# Prompt whether to remove destinations
alias ln='ln -i'

# Prompt before every removal
alias rm='rm -I --preserve-root'

# Remove a directory and all files
alias rmd='\rm --recursive --force --verbose'

# When shredding files, shred no matter permissions and remove the file(s)
alias shred='shred --force --remove --verbose'

# Type any text into a file
alias typefile='echo "Press CTRL+d when done:" && echo "$(</dev/stdin)" >'

# ExifTool removes embedded Exif data (like location) from images, videos, and docs
# https://exiftool.org/
# https://linuxhandbook.com/remove-exif-data/
if cmd-exists --strict exiftool; then
	alias cleanmeta='exiftool -overwrite_original -all='
fi

# Make mount command output pretty and human readable format
alias mount='mount | column -t'
alias m='mount'
alias um='umount'

# Your Linux system's filesystem table (or fstab) is a configuration table
# designed to automate mounting and unmounting file systems to a machine
# WARNING: Modifications to this file can make your system unbootable!
alias fstab='sudo cp /etc/fstab /etc/fstab.backup; edit /etc/fstab'

# Display disk space available and show file system type
alias df='df --human-readable --print-type --exclude-type=squashfs'
alias ds='df --human-readable --print-type --exclude-type=squashfs --exclude-type=tmpfs --exclude-type=devtmpfs'

# Get the block size for a partition
# Example: blocksize /dev/sda
alias blocksize='sudo blockdev --getbsz'

# dua parallel disk space analyzer in interactive mode TUI/GUI (in color)
# Link: https://github.com/Byron/dua-cli
# Install: curl -LSfs https://raw.githubusercontent.com/byron/dua-cli/master/ci/install.sh | \sh -s -- --git byron/dua-cli --target x86_64-unknown-linux-musl --crate dua
if [[ -f "$HOME/.cargo/bin/dua" ]]; then
	alias diskspace="$HOME/.cargo/bin/dua i"
elif cmd-exists dua; then
	alias diskspace='dua i'
# gdu fast parallel disk usage analyzer written in Go
# Link: https://github.com/dundee/gdu
# Install: go install github.com/dundee/gdu/v5/cmd/gdu@latest
elif cmd-exists gdu; then
	alias diskspace='gdu'
# Ncdu is a disk usage analyzer with an ncurses interface
# Link: https://dev.yorhel.nl/ncdu
elif cmd-exists ncdu; then
	alias diskspace='ncdu'
# Dust is like du written in Rust and more intuitive
# Link: https://github.com/bootandy/dust
elif cmd-exists dust; then
	alias diskspace='dust -xd1'
# List all folders disk space sorted by largest space
else
	alias diskspace='du -S | sort -n -r | more'
fi

# Just show the size of the current folder or a specified folder
alias totalsize='du -sh'

# List disk space of immediate folders one level deep
alias folders='du -kh --max-depth=1'

# f3 - test and check real capacity for USB devices (backup your drive first)
# Link: https://github.com/AltraMayor/f3
# Link: https://www.linuxbabe.com/command-line/f3-usb-capacity-fake-usb-test-linux
if cmd-exists --strict f3probe; then
	alias usbtest='sudo f3probe --destructive --time-ops'
fi

# Alias to show MySQL's data directory location
if cmd-exists --strict mysqld; then
	alias mysqldatadir='mysqld --verbose --help 2>/dev/null | grep ^datadir | column --table'
fi

# Aliases to compressed or uncompressed archives
alias mkbz2='tar -cvjf' # [filename.tar.bz2] [files_or_directories_to_compress]
alias unbz2='tar -xvjf'
alias mkgz='tar -cvzf' # [filename.tar.gz] [files_or_directories_to_compress]
alias ungz='tar -xvzf'
alias mktar='tar -cvf' # [filename.tar] [files_or_directories_to_compress]
alias untar='tar -xvf'

# Alias to use zip recursively with maximum compression
if cmd-exists --strict zip; then
	alias mkzip='zip -r9' # [filename.zip] [files_or_directories_to_compress]
fi

# Alias to launch a document, file, or URL in it's default X application
if cmd-exists --strict xdg-open; then
	alias open='runfree xdg-open'
fi

# Alias to fuzzy find files in the current folder(s), preview them, and launch in an editor
[ -f ~/.fzf.bash ] && source ~/.fzf.bash # Source if installed via Git
if cmd-exists --strict fzf; then
	# Preview text files in a directory
	if cmd-exists --strict xdg-open; then
		alias preview='open $(fzf --info=inline --query="${@}" --preview="$PAGER {}")'
	else
		alias preview='edit $(fzf --info=inline --query="${@}" --preview="$PAGER {}")'
	fi

	# Find log files using file previews
	if cmd-exists bat && [ -d /var/log ]; then
		# Use bat for preview if available for better syntax highlighting
		alias findlog='(cd /var/log && sudo realpath $(sudo find . -maxdepth 10 -iname "*.log" | sort -f | sudo fzf --layout=reverse-list --info=inline --query="${@}" --preview="sudo bat --color=always {}") 2>/dev/null)'
	else
		# Fall back to the default PAGER
		alias findlog='(cd /var/log && sudo realpath $(sudo find . -maxdepth 10 -iname "*.log" | sort -f | sudo -E fzf --layout=reverse-list --info=inline --query="${@}" --preview="sudo $PAGER {}") 2>/dev/null)'
	fi
fi

# Alias for Midnight Commander (mc) to exit into current directory
# https://stackoverflow.com/questions/39017391/how-to-make-midnight-commander-exit-to-its-current-directory
if [[ -f "/usr/lib/mc/mc-wrapper.sh" ]]; then
	alias mc='source /usr/lib/mc/mc-wrapper.sh'
fi

# Check shell script syntax
if cmd-exists --strict shellcheck; then
	alias schk='shellcheck'
fi

# Alias to view log files in real time (usually in /var/log)
# Check for lnav (The Log File Navigator)
if cmd-exists --strict lnav; then
	alias logview='sudo \lnav -r -t'
	alias logs='sudo \lnav -r -t /var/log/*.log' # All logs in /var/log

# Check for multitail (Multiple Tail)
elif cmd-exists --strict multitail; then
	alias logview='sudo \multitail -c -s 2'
	alias logs='sudo \multitail -c -s 2 /var/log/*.log'

# Check for tail
elif cmd-exists --strict tail; then
	alias logview='sudo tail -f'
	alias logs="find /var/log -type f -exec file {} \; | grep 'text' | cut -d' ' -f1 | sed -e's/:$//g' | grep -v '[0-9]$' | xargs tail -f"

# If no log viewer is installed, use less as a fallback
else
	alias logview='sudo \less +F'
fi

# Show logs in color
if cmd-exists --strict multitail; then
	alias multitail='\multitail -c'
fi

#######################################################
### DATE AND TIME
#######################################################

# Show the time
alias now='date +"%T"'

# Show the short date
alias today='date +"%Y-%m-%d"'

# Stop watch
alias stopwatch='date && echo "Press CTRL+D to stop" && time read'

# Countdown timer and stop watch
# Link: https://github.com/trehn/termdown
# Fonts: banner3, big, computer, doh, letters, roman, small, standard, univers
# Link: http://www.figlet.org/examples.html
if cmd-exists --strict termdown; then
	alias termdown='termdown --blink --end --critical 10 --font doh'
	alias countdown="termdown --help | sed -n '/Options\:/q;p'"
	alias timer='termdown'
	alias clock='termdown --time'
fi

# Change a file's (or files using a wildcard) accessed and modified time to now
# NOTE: There is no file creation date in Unix, only access, modify, and change
alias filetimenow='touch -a -m'

#######################################################
### CPU, MEMORY, AND PROCESSES
#######################################################

# Display amount of free and used memory
alias free='free -h'

# When reporting a snapshot of the current processes:
# a = all users
# u = user-oriented format providing detailed information
# x = list the processes without a controlling terminal
# f = display a tree view of parent to child processes
alias ps='ps auxf'

# Show top ten processes
alias cpu='ps aux | sort -r -nk +4 | head | $PAGER'

# Show CPU information
alias cpuinfo='lscpu | $PAGER'

# Show the USB device tree
if cmd-exists --strict lsusb; then
	alias usb='lsusb -t'
fi

# Show the PCI device tree
if cmd-exists --strict lspci; then
	alias pci='lspci -tv'
fi

# Alias top
# Link: https://ostechnix.com/some-alternatives-to-top-command-line-utility-you-might-want-to-know/
# Link: https://www.linuxlinks.com/alternativestotop/
# List of preferred top commands in order of preference

# Iterate over a list of preferred top commands in order of preference/features
_TOP_COMMANDS=("btop" "bpytop" "bashtop" "nmon" "glances" "ytop" "gtop" "htop")
for _TOP_COMMAND in "${_TOP_COMMANDS[@]}"; do
	# Check if the command exists and is executable
	if cmd-exists --strict $_TOP_COMMAND; then
		# Create an alias for the 'top' command using the found command
		alias top="$_TOP_COMMAND"
		# Exit the loop once the first matching command is found
		break
	fi
done
# Clean up and don't leave the extra variables in the environment
unset _TOP_COMMANDS
unset _TOP_COMMAND

# Alias bottom
# Link: https://github.com/ClementTsang/bottom
if cmd-exists --strict btm; then
	alias bottom='btm'
fi

# nvtop is a task monitor for NVIDIA, AMD and Intel GPUs
# Link: https://github.com/Syllo/nvtop
if cmd-exists --strict nvtop; then
	alias gpu='nvtop'
fi

# Show jobs
alias j='jobs -l'

# Change the cursor to a crosshair to select a window (requires xprop)
if cmd-exists --strict xprop; then
	alias windowinfo='xprop'
fi

# Get active X-window process ID after a 3 second delay (requires xdotool)
if cmd-exists --strict xdotool; then
	alias activewinpid='sleep 3 && xdotool getactivewindow getwindowpid'
fi

# Alias to clear RAM memory cache, buffer and swap space
# Link: https://www.tecmint.com/clear-ram-memory-cache-buffer-and-swap-space-on-linux/
alias flushcache="sudo free -h && \\
	sudo su -c \"echo 3 >'/proc/sys/vm/drop_caches' && \\
	swapoff -a && \\
	swapon -a && \\
	printf '\n${BRIGHT_YELLOW}%s${RESET}\n\n' 'Ram-cache and Swap Cleared'\" root && \\
	free -h"

#######################################################
### NETWORKING
#######################################################

# yt-dlp fork of youtube-dl - Set the default download folder
# Link: https://github.com/yt-dlp/yt-dlp
if cmd-exists --strict yt-dlp; then
	alias yt-dlp='yt-dlp'
	alias ytd='yt-dlp'
# Youtube-dl - Use best settings
# Link: https://github.com/ytdl-org/youtube-dl
elif cmd-exists --strict youtube-dl; then
	alias youtube-dl="youtube-dl --format 'best[vcodec*=avc]'"
	alias ytd='youtube-dl'
fi

# Checking for the presence of download utilities to create a download alias
# and an optional alias for downloading the LS_COLORS file to ~/.dircolors
# that requires the dircolors command used by ls to set color directory output
if cmd-exists aria2c; then
	# aria2c is a lightweight multi-protocol & multi-source command-line
	# download utility that supports HTTP/HTTPS, FTP, SFTP, BitTorrent, and
	# Metalink with multiple connections and enhanced control over connections
	# Link: https://aria2.github.io/
	alias {aria2c,download}='aria2c --max-connection-per-server=5 --continue=true --async-dns=false'

	if cmd-exists --strict dircolors; then
		alias download-dircolors='aria2c --max-connection-per-server=5 --continue=true --async-dns=false -d ${HOME} -o .dircolors https://raw.githubusercontent.com/ahmadassaf/dircolors/master/LS_COLORS'
	fi
elif cmd-exists --strict wget; then
	# wget is a non-interactive command-line file downloader for HTTP, HTTPS,
	# and FTP that supports resuming downloads on more unstable connections
	# Link: https://www.gnu.org/software/wget/
	alias download='wget --continue'

	if cmd-exists --strict dircolors; then
		alias download-dircolors='wget --continue -O ${HOME}/.dircolors https://raw.githubusercontent.com/ahmadassaf/dircolors/master/LS_COLORS'
	fi
elif cmd-exists --strict curl; then
	# curl supports data transfer from or to a server using multiple protocols
	# like HTTP, HTTPS, and FTP, and features resuming and redirect following
	# Link: https://curl.se/
	alias download='curl -C - -L -O'

	if cmd-exists --strict dircolors; then
		alias download-dircolors='curl -C - -L -o ${HOME}/.dircolors https://raw.githubusercontent.com/ahmadassaf/dircolors/master/LS_COLORS'
	fi
fi

# Resume wget by default
if cmd-exists --strict wget; then
	alias wget='wget -c'
fi

# Stop pinging after sending 5 ECHO_REQUEST packets
alias ping='ping -c 5'

# Do not wait for ping interval 1 second, go fast
alias fastping='ping -c 100 -i.2'

# Show open ports
alias ports='netstat -tulanp'

# Display and monitor the disk IO usage
# Link: https://www.geeksforgeeks.org/iotop-command-in-linux-with-examples/
if cmd-exists iotop; then
	alias iotop='sudo iotop -o -a'
fi

# If nmap is installed, set an alias for a network scan of a host (takes a while)
# Scan delay slows things down but reduces throttling, anti-ddos, auto-block
# Link: https://nmap.org/
# Example: netscan localhost
if cmd-exists nmap; then
	alias netscan='sudo nmap --scan-delay 1.1s -v --resolve-all -A -sTUV'
fi

# Get local IP addresses
if cmd-exists --strict ip; then
	alias iplocal="ip -br -c a"
else
	alias iplocal="ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"
fi

# Get public IP address (several options below)
alias ipexternal='wget -O - -q icanhazip.com && echo'
# alias ipexternal='wget -qO- ifconfig.me/ip && echo'
# alias ipexternal='curl ipinfo.io/ip && echo'

# Make it easy to disable and reenable the Teamviewer service
# so that it's not constantly running and only when you need it
if cmd-exists --strict teamviewer; then
	alias teamviewerstart='sudo teamviewer --daemon start'
	alias teamviewerstop='sudo teamviewer --daemon stop'
fi

# Automatically downloads based on URL by dynamically choosing the appropriate command
# Detects the domain from the URL and chooses the appropriate download command
# ---
# IMPORTANT: Always ensure that you have the legal right and ethical justification
# to download media from various services. Respect copyright laws and terms of service
# agreements. Use of this script should comply with all applicable regulations.
function d() {
	local URL="$1"
	local DOWNLOAD_PATH="."

	# Check if we are in a graphical environment and Desktop exists
	if [[ (-n "$DISPLAY" || -n "$WAYLAND_DISPLAY") && -d "${HOME}/Desktop" ]]; then
		DOWNLOAD_PATH="${HOME}/Desktop"
	fi

	# Display help if no URL provided
	if [[ -z "${URL}" ]]; then
		echo -e "Automatically downloads based on URL by dynamically choosing the appropriate command"
		echo -en "Supports ${BRIGHT_CYAN}axel${RESET}, ${BRIGHT_CYAN}aria2c${RESET}, ${BRIGHT_CYAN}wget${RESET}, ${BRIGHT_CYAN}curl${RESET},"
		echo -e " and common tools for ${BRIGHT_BLUE}Youtube${RESET}, ${BRIGHT_BLUE}Spotify${RESET}, ${BRIGHT_BLUE}Tidal${RESET}, and ${BRIGHT_BLUE}SoundCloud${RESET}"
		echo -e "${BRIGHT_WHITE}Usage: ${BRIGHT_CYAN}d ${BRIGHT_YELLOW}[URL]${RESET}"
		echo -e "${BRIGHT_WHITE}Options:${RESET} ${BRIGHT_YELLOW}-h, --help${RESET} Show this help message"
		return 1

	# YouTube URLs
	elif [[ "${URL}" =~ ^https?://(www\.)?(youtube\.com|youtu\.be)/ ]]; then
		if cmd-exists yt-dlp; then
			echo -e "${BRIGHT_GREEN}Using yt-dlp for YouTube URL...${RESET}"
			(cd "${DOWNLOAD_PATH}" && yt-dlp "${URL}") || echo -e "${BRIGHT_RED}Download failed.${RESET}"
		elif cmd-exists youtube-dl; then
			echo -e "${BRIGHT_GREEN}Using youtube-dl for YouTube URL...${RESET}"
			(cd "${DOWNLOAD_PATH}" && youtube-dl --format 'best[vcodec*=avc]' "${URL}") || echo -e "${BRIGHT_RED}Download failed.${RESET}"
		else
			echo -e "${BRIGHT_RED}ERROR: ${BRIGHT_CYAN}No suitable YouTube download tool found${RESET}"
			return 1
		fi

	# Spotify URLs
	elif [[ "${URL}" =~ ^https://open.spotify.com/ ]]; then
		if cmd-exists spotdl; then
			echo -e "${BRIGHT_GREEN}Using spotdl for Spotify URL...${RESET}"
			(cd "${DOWNLOAD_PATH}" && spotdl --bitrate 320k "${URL}") || echo -e "${BRIGHT_RED}Download failed.${RESET}"
		else
			echo -e "${BRIGHT_RED}ERROR: ${BRIGHT_CYAN}No suitable Spotify download tool found${RESET}"
			return 1
		fi

	# Tidal URLs
	elif [[ "${URL}" =~ ^https://tidal.com/ ]]; then
		if cmd-exists tidal-dl-ng; then
			echo -e "${BRIGHT_GREEN}Using tidal-dl-ng for Tidal URL...${RESET}"
			(cd "${DOWNLOAD_PATH}" && tidal-dl-ng dl "${URL}") || echo -e "${BRIGHT_RED}Download failed.${RESET}"
		elif cmd-exists tidal-dl; then
			echo -e "${BRIGHT_GREEN}Using tidal-dl for Tidal URL (ensure logged in)...${RESET}"
			(cd "${DOWNLOAD_PATH}" && tidal-dl "${URL}") || echo -e "${BRIGHT_RED}Download failed.${RESET}"
		else
			echo -e "${BRIGHT_RED}ERROR: ${BRIGHT_CYAN}No suitable Tidal download tool found${RESET}"
			return 1
		fi

	# SoundCloud URLs
	elif [[ "${URL}" =~ ^https?://(www\.)?soundcloud.com/ ]]; then
		if cmd-exists scdl; then
			echo -e "${BRIGHT_GREEN}Using scdl for SoundCloud URL...${RESET}"
			(scdl -l "${URL}" --path "${DOWNLOAD_PATH}" --onlymp3) || echo -e "${BRIGHT_RED}Download failed.${RESET}"
		else
			echo -e "${BRIGHT_RED}ERROR: ${BRIGHT_CYAN}No suitable SoundCloud download tool found${RESET}"
			return 1
		fi

	# Download using the detected tool
	else
		echo -e "${BRIGHT_GREEN}Downloading...${RESET}"
		(cd "${DOWNLOAD_PATH}" && download "${URL}") || echo -e "${BRIGHT_RED}Download failed.${RESET}"
	fi
}

#######################################################
### VISUAL
#######################################################

# Colorize the grep command output for ease of use (good for log files)
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Colorize messages for the kernel ring buffer
alias dmesg='dmesg --color'

# Clear the screen with both clear and cls shorthand
alias cls='clear'

# Search and play YouTube videos in the terminal
if cmd-exists --strict ytfzf; then
	alias yt='ytfzf -l -t'
fi

# Convert images to ASCII in color
if cmd-exists --strict jp2a; then
	alias jp2a='jp2a --color'
fi

# List fonts for toilet
if cmd-exists --strict toilet; then
	alias toiletfont='ls /usr/share/figlet'
	alias toiletfontlist='for file in /usr/share/figlet/*.?lf; do toilet -f $(basename "$file") $(basename "$file"); done'
fi

# Launch the cmatrix screen saver (if installed)
if cmd-exists --strict cmatrix; then
	alias matrix='cmatrix -b'
fi

#######################################################
### FILE SYSTEMS
#######################################################

# Aliases for BtrFS file systems
if cmd-exists --strict btrfs; then
	alias btrcheck='sudo btrfs fi show'                        # Check status of raid drives
	alias btrstats='sudo btrfs device stats'                   # Show device statistics
	alias btrscrub='sudo btrfs scrub start'                    # Start a scrub
	alias btrpause='sudo btrfs scrub cancel'                   # Cancel or pause a scrub
	alias btrresume='sudo btrfs scrub resume'                  # Resume a paused scrub
	alias btrstatus='sudo btrfs scrub status'                  # Show status of a scrub
	alias btrdefragfile='sudo btrfs filesystem defragment -vf' # Defrag a file
	alias btrdefragdir='sudo btrfs filesystem defragment -rvf' # Defrag a directory
fi

# Aliases for Ext3 file systems
if cmd-exists --strict mkfs.ext3; then
	alias ext3check='sudo fsck.ext3'   # Check and repair Ext3 filesystem
	alias ext3stats='sudo dumpe2fs -h' # Show statistics for Ext3 filesystem
	alias ext3trim='sudo fstrim -v'    # Trim unused blocks on Ext3 filesystem
fi

# Aliases for EXT4 file systems
if cmd-exists --strict mkfs.ext4; then
	alias ext4check='sudo fsck.ext4'   # Check and repair EXT4 filesystem
	alias ext4stats='sudo dumpe2fs -h' # Show statistics for EXT4 filesystem
	alias ext4trim='sudo fstrim -v'    # Trim unused blocks on EXT4 filesystem
fi

# Aliases for F2FS file systems
if cmd-exists --strict mkfs.f2fs; then
	alias f2fscheck='sudo fsck.f2fs'   # Check and repair F2FS filesystem
	alias f2fsstats='sudo f2fsck'      # Show statistics for F2FS filesystem
	alias f2fstrim='sudo fstrim -v'    # Trim unused blocks on F2FS filesystem
fi

# Aliases for XFS file systems
if cmd-exists --strict mkfs.xfs; then
	alias xfscheck='sudo xfs_repair'   # Check and repair XFS filesystem
	alias xfsstats='sudo xfs_info'     # Show information about XFS filesystem
	alias xfstrim='sudo fstrim -v'     # Trim unused blocks on XFS filesystem
fi

# Aliases for ZFS file systems
if cmd-exists --strict zpool; then
	alias zfscheck='sudo zpool scrub'           # Check and repair ZFS pool
	alias zfsstats='sudo zpool iostat'          # Show ZFS pool statistics
	alias zfstrim='sudo zpool trim'             # Trim unused blocks on ZFS pool
	alias zfsstatus='sudo zpool status'         # Check status of ZFS pool
	alias zfsscrub='sudo zpool scrub'           # Start a scrub on ZFS pool
	alias zfspause='sudo zpool scrub -s'        # Pause a scrub on ZFS pool
	alias zfsresume='sudo zpool scrub -r'       # Resume a paused scrub on ZFS pool
	alias zfsscrubstatus='sudo zpool status -v' # Show status of ZFS pool scrub
	alias zfsdefragfile='sudo zfs send -R'      # Defrag a file (snapshot-based)
	alias zfsdefragdir='sudo zfs send -R'       # Defrag a directory (snapshot-based)
fi

# Aliases for NTFS filesystems
if cmd-exists --strict ntfsfix; then
	alias ntfscheck='sudo ntfsfix'  # Check and repair NTFS filesystem
	alias ntfsstats='sudo ntfsinfo' # Show information about NTFS filesystem
fi

# Aliases for exFAT, FAT12, FAT16, and FAT32 filesystems
# I'm on a diet, so no jokes please. This whole section. lol
if cmd-exists --strict dosfsck; then
	alias fatcheck='sudo dosfsck'     # Check and repair FAT filesystem
	alias fatstats='sudo fsck.fat -i' # Show information about FAT filesystem
fi

#######################################################
### DISTROBOX
#######################################################

# If Distrobox is installed...
# Link: https://github.com/89luca89/distrobox
# Link: https://github.com/89luca89/distrobox/blob/main/docs/usage/usage.md
if cmd-exists --strict distrobox; then
	# Create aliases for the most common commands
	alias db='distrobox'
	alias {dbe,distrobox-enter}='_distrobox-enter'
	alias dbl='distrobox list'
	alias dbls='distrobox-list-simple'
	alias dbs='distrobox stop'
	alias dbsa='distrobox-stop-all'
	alias dbhe='distrobox-host-exec'
	alias {dbup,distrobox-upgrade}='_distrobox-upgrade'
	alias {dbc,distrobox-check}='docker system df -v'

	# List only the names of each container
	# This takes no arguments and will mostly be used in scripts
	function distrobox-list-simple() {
		distrobox-list | awk -F '|' '{print $2}' | tail -n +2 | sed 's/^[ \t]*//;s/[ \t]*$//'
	}

	# Choose an installed container
	# This takes no arguments and will mostly be used in scripts
	function distrobox-pick() {
		distrobox-list-simple | createmenu
	}

	# Loop through and stop all containers
	function distrobox-stop-all() {
		local _BOX_LIST="$(distrobox-list-simple)"
		for _BOX in $_BOX_LIST; do
			\distrobox stop --yes $_BOX
		done
	}

	function _distrobox-enter() {
		if [ $# -eq 0 ]; then
			\distrobox enter "$(distrobox-pick)"
		else
			\distrobox enter "$@"
		fi
	}

	function _distrobox-upgrade() {
		if [ $# -eq 0 ]; then
			\distrobox upgrade --all
		else
			\distrobox upgrade "$@"
		fi
	}
fi

#######################################################
### MISCELLANEOUS
#######################################################

# Alias to show the current TTY (CTRL+ALT+1 through 7)
alias whichtty='tty | sed -e "s:/dev/::"'

# Spell check a word with DidYouMean
# Link: https://github.com/hisbaan/didyoumean
if cmd-exists --strict dym; then
	alias spell='dym -n 10 -y'
fi

# Alias's for safe and forced reboots
alias rebootsafe='sudo shutdown -r now'
alias rebootforce='sudo shutdown -r -n now'

# If OpenSSL is installed...
if cmd-exists --strict openssl; then
	# If base64 isn't available, use openssl's version to do the same thing
	if ! cmd-exists --strict base64; then
		alias base64='openssl base64'
	fi

	# If base64 isn't available, use openssl's version to do the same thing
	if ! cmd-exists --strict md5sum; then
		alias md5sum='openssl md5'
	fi

	# SHA1
	alias sha1='openssl sha1'
fi

# Update the fireware on Linux automatically and safely using fwupdmgr
# (used by companies like Corsair, Dell, HP, Intel, Logitech, etc.)
# Install: pkginstall fwupdmgr
# Link: https://fwupd.org
if cmd-exists --strict fwupdmgr; then
	alias firmwareupdate='fwupdmgr get-devices && fwupdmgr refresh && fwupdmgr get-updates && fwupdmgr update'
fi

# When updating virus definitions, do it as root
if cmd-exists --strict freshclam; then
	alias freshclam='sudo freshclam'
fi

# Check passwords with cracklib
# Link: https://www.cyberciti.biz/security/linux-password-strength-checker/
if cmd-exists --strict cracklib-check; then
	alias pwcheck='cracklib-check<<<'
fi

# Check for the availability of web browsers
# Link: https://www.geeksforgeeks.org/using-lynx-to-browse-the-web-from-the-linux-terminal/
# Link: https://wiki.archlinux.org/title/ELinks
# Link: https://w3m.sourceforge.net/
# Link: http://www.aboutlinux.info/2007/02/links2-cross-platform-console-based-web.html
# Link: https://www.tecmint.com/command-line-web-browsers/
for TERMINAL_BROWSER in "lynx" "elinks" "w3m" "links2" "links"; do
	if cmd-exists "${TERMINAL_BROWSER}"; then
		# Show the Extreme Ultimate .bashrc README file in the available browser
		if [[ -f "${HOME}/.config/bashrc/README.html" ]]; then
			alias readme="${TERMINAL_BROWSER} ~/.config/bashrc/README.html"
			break  # Exit the loop once the first available browser is found
		elif [[ -f "${HOME}/README.html" ]]; then
			alias readme="${TERMINAL_BROWSER} ~/README.html"
			break  # Exit the loop once the first available browser is found
		fi
	fi
done

# Glow is one of the best CLI markdown viewers with pager support
# Add pager support and a local-only option for security
# Link: https://github.com/charmbracelet/glow
# If 'readme' alias is still empty, try glow
if cmd-exists glow; then
	# Use glow's pager option
	alias glow='glow --all --pager'

	# Local only version for security
	alias glowsafe='glow --all --pager --local'

	# If the readme alias is not set
	if [[ $(type -t readme) != 'alias' ]]; then
		# If README.md exists in .config/bashrc, set 'readme' alias
		if [[ -f "${HOME}/.config/bashrc/README.md" ]]; then
			alias readme='glow ~/.config/bashrc/README.md'
		# If README.md exists in home, set 'readme' alias
		elif [[ -f "${HOME}/README.md" ]]; then
			alias readme='glow ~/README.md'
		fi
	fi
fi

# fx is a JavaScript Object Notation (JSON) viewer
# Link: https://github.com/antonmedv/fx
if cmd-exists --strict fx; then
	alias json='fx'

# jless is a command-line JSON viewer
# Link: https://jless.io/
elif cmd-exists --strict jless; then
	alias json='jless'

# jq - Pretty Print JSON Files in the terminal
# Link: https://itsfoss.com/pretty-print-json-linux/
elif cmd-exists --strict jq; then
	alias json='jq'
fi

# baca TUI ebook reader
# Link: https://github.com/wustho/baca
# Install: pip install baca
if cmd-exists --strict baca; then
	alias ebook=baca
fi

# Speak with female voice
# Link: https://thomashunter.name/posts/2012-05-21-female-voice-using-espeak
if cmd-exists --strict espeak; then
	alias say='espeak -ven-us+f4 -s170'
fi

# Aliases to modify GRUB
# https://www.howtogeek.com/196655/how-to-configure-the-grub2-boot-loaders-settings/
alias grubedit='edit /etc/default/grub'
alias grubsave='sudo update-grub'

# Shows all the script files in a directory and which shell they require
alias scanscripts='for FILE in *; do [[ -f "$FILE" ]] && echo -n "$FILE - " && head -n 1 $FILE; done | grep "\#\!" 2> /dev/null'

# Vlock - lock all terminals
# Install: sudo apt install vlock
# Install: sudo pacman -S kbd
# https://odysee.com/@DistroTube:2/lock-your-terminal-sessions-with-vlock:0
if cmd-exists --strict vlock; then
	# Alias Vlock to lock all terminals and can be typed with one hand
	alias lok='vlock --all'
fi

# Alias thefuck that corrects errors in previous console commands
# Link: https://github.com/nvbn/thefuck
if cmd-exists --strict thefuck; then
	eval $(thefuck --alias fix)
fi

# Alias to restart KDE Plasma desktop without rebooting or logging out
if cmd-exists --strict kstart5 && cmd-exists --strict kquitapp5; then
	alias {plasmarestart,kderestart}='kquitapp5 plasmashell && runfree kstart5 plasmashell'
fi

#######################################################
# Tmux Terminal Multiplexor Support
# Link: https://github.com/tmux/tmux/wiki
#######################################################

# Aliases for tmux terminal multiplexer if installed
if cmd-exists tmux; then

	# Enhance clear to also clear the TMUX scrollback buffer
	if  [[ -n "${TMUX}" ]]; then
		alias clear='clear && tmux clear-history'
	fi

	# If you connect to a session with a different resolution terminal
	# this will freeze the size of the Tmux session window and not auto-resize
	#tmux resize-window -A &> /dev/null

	# Function to load TMUX with default session defined by _TMUX_LOAD_SESSION_NAME
	# If TMUX is already running, switch to a session name passed in as a parameter
	# TIP: Use CTRL+d to detach your session which closes but leaves the session
	# running. CTRL+d will also exit bash once outside of TMUX.
	# alias tm='tmux a -t main || tmux new -s main'
	function tm() {

		# Get the passed in or default session name
		if [[ -n "${@}" ]]; then
			local SESSION_NAME="${@}"
		elif [[ -n "${_TMUX_LOAD_SESSION_NAME}" ]]; then
			local SESSION_NAME="${_TMUX_LOAD_SESSION_NAME}"
		elif [[ "$(tmux list-sessions 2> /dev/null | wc -l)" -gt 0 ]]; then
			local SESSION_NAME="$(tmux ls -F "#{session_name}" | createmenu)"
		else
			local SESSION_NAME="$(whoami)"
		fi

		# Create the session if it doesn't exist
		TMUX='' tmux -u new-session -d -s "${SESSION_NAME}" 2> /dev/null

		# Attach if outside of TMUX
		if [[ -z "$TMUX" ]]; then
			tmux -u attach -t "${SESSION_NAME}" 2> /dev/null && exit

		# Switch if we are already inside of TMUX
		else
			tmux -u switch-client -t "${SESSION_NAME}" 2> /dev/null
		fi
	}

	function tmsessiongroup() {
		# Tmux allows you to create "session groups" - multiple sessions that can all attach to the same set of windows
		# (Allow multiple monitors to attach to the same session but independently view separate panes)
		# Link: https://unix.stackexchange.com/questions/282365/using-multiple-terminal-x-windows-with-one-tmux-session
		# To switch from one to the other using xdotool:
		# xdotool search --name 'session1:0:' windowactivate
		# xdotool search --name 'session2:1:' windowactivate

		# Get a list of sessions
		local _TMUX_OPEN_SESSIONS="$(tmux ls -F "#{session_name}" 2> /dev/null)"

		# If the chosen session is blank
		if [ -z "${_TMUX_OPEN_SESSIONS}" ]; then
			# Show an error and exit
			echo -e "${BRIGHT_RED}ERROR: ${BRIGHT_CYAN}No session found${RESET}"
			return 1
		fi

		# If a new session name was not passed in...
		if [ $# -eq 0 ]; then
			# Get the name of the last session
			local _TMUX_LAST_SESSION=$(echo "${_TMUX_OPEN_SESSIONS}" | head -n 1)

			# Generate a new session name based on the last session
			local _COUNTER=2
			local _TMUX_RANDOM_NAME
			while [ -z "${_TMUX_RANDOM_NAME}" ]; do
				if [[ "${_TMUX_OPEN_SESSIONS}" =~ "${_TMUX_LAST_SESSION}${_COUNTER}" ]]; then
					let _COUNTER=_COUNTER+1
				else
					_TMUX_RANDOM_NAME="${_TMUX_LAST_SESSION}${_COUNTER}"
				fi
			done

			# Ask for the new session name from a menu
			read -e -i "${_TMUX_RANDOM_NAME}" -p "New Session Name: " _TMUX_NEW_SESSION
		else
			# Use the passed in session name
			local _TMUX_NEW_SESSION="${@}"
		fi

		# Make sure the new session name doesn't already exist
		if [[ "${_TMUX_OPEN_SESSIONS}" =~ "${_TMUX_NEW_SESSION}" ]]; then
			# Show an error and exit
			echo -e "${BRIGHT_RED}ERROR: ${BRIGHT_CYAN}Session ${BRIGHT_YELLOW}${_TMUX_NEW_SESSION}${BRIGHT_CYAN} already exists${RESET}"
			return 1
		fi

		# If the chosen session is blank
		if [ -z ${_TMUX_NEW_SESSION} ]; then
			# Show an error and exit
			echo -e "${BRIGHT_RED}ERROR: ${BRIGHT_CYAN}You must specify a new session name${RESET}"
			return 1
		fi

		# Change the prompt
		_PS3_OLD="${PS3}"
		PS3="Choose an existing session to connect to: "

		# Ask for the session to connect to
		local _TMUX_EXISTING_SESSION=$(echo "${_TMUX_OPEN_SESSIONS}" | sort | createmenu)

		# Put the settings back to their original values
		PS3="${_PS3_OLD}"
		IFS="${_IFS_OLD}"

		# If the chosen session is blank
		if [ -z ${_TMUX_EXISTING_SESSION} ]; then
			# Show an error and exit
			echo -e "${BRIGHT_RED}ERROR: ${BRIGHT_CYAN}You must specify an existing session${RESET}"
			return 1
		fi

		# Create a session group
		if ($(tmux -u new-session -t "${_TMUX_EXISTING_SESSION}" -s "${_TMUX_NEW_SESSION}")); then
			return 0
		else
			# Show an error and exit
			echo -e "${BRIGHT_RED}ERROR: ${BRIGHT_CYAN}Could not connect to session ${BRIGHT_YELLOW}${_TMUX_EXISTING_SESSION}${RESET}"
			return 1
		fi
	}

	# Detach from Tmux - and optionally run a command if specified
	# For example, detach and log into an SSH server already running Tmux
	# so you don't run a Tmux session inside of your local Tmux session
	# Example: tmd ssh username@server.net
	function tmd() {
		# If Tmux is running...
		if [[ -n "$TMUX" ]]; then
			# If no parameters were pass in...
			if [ $# -eq 0 ]; then
				# Detach from the session
				tmux detach
			else
				# Detach and then execute the parameters
				eval "tmux detach -E '${@}'"
			fi

		# Tmux is NOT running so no need to detach...
		else
			# Only do something if a command is passed in...
			if [ $# -gt 0 ]; then
				# Run the command
				eval "${@}"
			fi
		fi
	}

	# List and choose a buffer (clipboard history)
	alias {tmb,tmc}='tmux choose-buffer'

	# List all the sessions
	alias tmlist='tmux ls'

	# List all the connected clients
	alias tmclients='tmux lsc'

	# Create a new session
	alias {tmnew,tmjoin}='tm'

	# Attach to an existing session
	#alias tmattach='tmux -u new-session -A -s'
	alias tmattach='tmux -u attach-session -t "$(tmux ls -F "#{session_name}" | createmenu)"'

	# Rename a session: tmrename [session] [new_name]
	alias tmrename='tmux rename -t'

	# Kill a session
	alias tmkill='tmux kill-session -t'

	# Kill all sessions
	alias tmreset='tmux kill-server'

	# List all the bound keys
	alias tmlistkeys='grep -E "^(bind-key|bind)\s+" ~/.tmux.conf | sort'

# Tmux is not installed, but Zellij is and is very user friendly
elif cmd-exists zellij; then
	# Redirect these Tmux aliases to Zellij instead
	alias {tm,tmnew,tmjoin}='znew'
	alias tmlist='zlist'
	alias tmattach='zattach'
	alias tmkill='zkill'
	alias tmreset='zreset'

# Tmux is not installed, but Screen is
# Link: https://linuxize.com/post/how-to-use-linux-screen/
elif cmd-exists screen; then
	alias tm="echo 'Tmux is not installed, but screen is installed on this system.'"

fi

#######################################################
# Zellij Terminal Multiplexor Support
# Link: https://zellij.dev/documentation/introduction.html
#######################################################

# Aliases for Zellij terminal multiplexer if installed
if cmd-exists zellij; then

	# Function to load Zellij with a default session named the logged in user
	# You can also pass in a specific session name as a parameter
	function znew() {
		# Get the passed in or default session name
		if [[ -n "${@}" ]]; then
			local SESSION_NAME="${@}"
		elif [[ "$(zellij list-sessions 2> /dev/null | wc -l)" -gt 0 ]]; then
			local SESSION_NAME=""
		else
			local SESSION_NAME="$(whoami)"
		fi

		# Create the session if it doesn't exist
		zellij --session "${SESSION_NAME}" 2> /dev/null || zellij attach "${SESSION_NAME}"
	}

	# Aliases for Zellij
	alias {zj,zjoin}='znew'
	alias zlist='zellij list-sessions'
	alias zattach='zellij attach "$(zellij list-sessions | createmenu)"'
	alias zkill='zellij kill-session'
	alias zreset='zellij kill-all-sessions'

	# Include the bash completion and aliases from Zellij (i.e. zr, zrf, ze, zef)
	source <(zellij setup --generate-completion bash) >/dev/null 2>&1
fi

#######################################################
# Abduco lets programs run independently of the controlling terminal
# Note: CTRL+\ will detach the session
# Link: https://www.brain-dump.org/projects/abduco/
#######################################################

if cmd-exists abduco; then

	# Start or connect to an abduco session
	function aa() {
		if [[ ${#} -eq 0 ]]; then
			if [[ $(abduco | wc -l) -gt 1 ]]; then
				abduco -a "$(abduco | tail -n +2 | sed 's:\s\+:\t:g' | cut -f 5 | createmenu)" bash
			else
				abduco -c "${USER}" bash
			fi
		else
			abduco -A "${@}" bash
		fi
	}

	# Connect to an abduco session read-only
	function aaro() {
		abduco -Ar "${@}" bash
	}

	# List any abduco sessions
	alias aals='abduco'

	# Kill all abduco sessions
	alias aareset='pkill abduco'
fi

#######################################################
# Easy Cross-Platform Package Management Aliases
#######################################################

# Depending on the installed package managers, set up some package aliases
if cmd-exists --strict paru; then # Arch
	# Link: https://github.com/Morganamilo/paru
	# Link: https://itsfoss.com/paru-aur-helper/
	# NOTE: To get search results to start at the bottom and go upwards, enable BottomUp in paru.conf
	alias has='paru -Si'
	alias pkgupdateall='paru -Syyu --sudoloop --noconfirm --newsonupgrade && if type flatpak >/dev/null 2>&1; then sudo flatpak update --assumeyes --noninteractive; fi && if type snap >/dev/null 2>&1; then sudo snap refresh; fi && if type tldr >/dev/null 2>&1; then tldr --update; fi'
	alias pkgupdate='paru --sync --sudoloop --noconfirm'
	alias pkginstall='paru --sync --sudoloop --noconfirm'
	alias pkgremove='paru --remove'
	alias pkgclean='paru --clean'
	alias pkgsearch='paru --bottomup'
	alias pkglist='paru -Qe'
	alias pkglistmore='paru -Q' # Also includes dependencies
elif cmd-exists --strict yay; then # Arch
	# Link: https://github.com/Jguer/yay
	alias has='yay -Si'
	alias pkgupdateall='yay -Syyu --sudoloop && if type flatpak >/dev/null 2>&1; then sudo flatpak update; fi && if type snap >/dev/null 2>&1; then sudo snap refresh; fi && if type tldr >/dev/null 2>&1; then tldr --update; fi'
	alias pkgupdate='yay -S'
	alias pkginstall='yay -S'
	alias pkgremove='yay -Rns'
	alias pkgclean='yay -Yc'
	alias pkgsearch='yay'
	alias pkglist='yay -Qe'
	alias pkglistmore='yay -Q' # Also includes dependencies
elif cmd-exists --strict pamac; then    # Manjaro
	# Link: https://wiki.manjaro.org/index.php/Pamac
	alias has='sudo pamac info'
	alias pkgupdateall='sudo pamac upgrade -a && if type tldr >/dev/null 2>&1; then tldr --update; fi'
	alias pkgupdate='sudo pamac update'
	alias pkginstall='sudo pamac install'
	alias pkgremove='sudo pamac remove'
	alias pkgclean='sudo pamac remove --orphans'
	alias pkgsearch='sudo pamac search -a'
	alias pkglist='pacman -Qe'
	alias pkglistmore='pacman -Q' # Also includes dependencies
elif cmd-exists --strict pacman && [[ -n $(uname -r | grep arch) ]]; then # Arch (No AUR)
	# Link: https://archlinux.org/pacman/
	alias has='pacman -Q --info'
	alias pkgupdateall='sudo pacman -Syyu && if type flatpak >/dev/null 2>&1; then sudo flatpak update; fi && if type snap >/dev/null 2>&1; then sudo snap refresh; fi && if type tldr >/dev/null 2>&1; then tldr --update; fi'
	alias pkgupdate='sudo pacman -S'
	alias pkginstall='sudo pacman -S'
	alias pkgremove='sudo pacman -Rns'
	alias pkgclean='pacman -Qtdq | sudo pacman -Rns -'
	alias pkgsearch='pacman -Ss'
	alias pkglist='pacman -Qe'
	alias pkglistmore='pacman -Q' # Also includes dependencies
elif cmd-exists --strict dnf; then # RedHat/Fedora
	# Link: https://fedoraproject.org/wiki/DNF
	alias has='dnf info'
	alias pkgupdateall='sudo dnf upgrade --refresh'
	alias pkgupdate='sudo dnf upgrade'
	alias pkginstall='sudo dnf install'
	alias pkgremove='sudo dnf remove'
	alias pkgclean='sudo dnf autoremove'
	alias pkgsearch='sudo dnf search'
	alias pkglist='dnf list installed'
	alias pkgdependencies='yum whatprovides'
elif cmd-exists --strict yum; then # RedHat/Fedora
	# Link: https://access.redhat.com/articles/yum-cheat-sheet
	alias has='yum info'
	alias pkgupdateall='sudo yum clean all && yum -y update'
	alias pkgupdate='sudo yum update'
	alias pkginstall='sudo yum install'
	alias pkgremove='sudo yum remove'
	alias pkgclean='sudo yum autoremove'
	alias pkgsearch='sudo yum search'
	alias pkglist='yum list installed'
	alias pkgdependencies='yum whatprovides'
elif cmd-exists --strict nala; then # Debian/Ubuntu/Raspbian
	# Link: https://gitlab.com/volian/nala
	# Link: https://itsfoss.com/nala/
	alias has='nala show'
	alias pkgupdateall='sudo nala update && sudo nala upgrade && if type pacstall >/dev/null 2>&1; then pacstall --upgrade; fi'
	alias pkgupdate='sudo nala update'
	alias pkginstall='sudo nala install --install-suggests'
	alias pkgremove='sudo nala remove'
	alias pkgclean='sudo nala clean --fix-broken'
	alias pkgsearch='sudo nala search'
	alias pkglist='sudo nala list --installed'
	alias pkgmirrors='sudo nala fetch'
elif cmd-exists --strict apt; then # Debian/Ubuntu/Raspbian
	# Link: https://itsfoss.com/apt-command-guide/
	alias has='apt show'
	alias pkgupdateall='sudo apt update --assume-yes && sudo apt upgrade --assume-yes && if type pacstall >/dev/null 2>&1; then pacstall --upgrade; fi && if type tldr >/dev/null 2>&1; then tldr --update; fi'
	alias pkgupdate='sudo apt-get install --only-upgrade'
	alias pkginstall='sudo apt install'
	alias pkgremove='sudo apt remove'
	alias pkgclean='sudo apt autoremove'
	alias pkgsearch='sudo apt search'
	alias pkglist='sudo apt list --installed'
	alias pkgcheck='sudo apt update --assume-yes && apt list --upgradable'
elif cmd-exists --strict apt-get; then # Debian/Ubuntu
	# Link: https://help.ubuntu.com/community/AptGet/Howto
	alias has='apt-cache show'
	alias pkgupdateall='sudo apt-get update && sudo apt-get upgrade && if type pacstall >/dev/null 2>&1; then pacstall --upgrade; fi && if type tldr >/dev/null 2>&1; then tldr --update; fi'
	alias pkgupdate='sudo apt-get install --only-upgrade'
	alias pkginstall='sudo apt-get install'
	alias pkgremove='sudo apt-get remove'
	alias pkgclean='sudo apt-get autoremove'
	alias pkgsearch='sudo apt-cache search'
	alias pkglist='sudo dpkg -l'
elif cmd-exists --strict zypper; then # SUSE
	# Link: https://en.opensuse.org/SDB:Zypper_usage
	alias has='zypper info'
	alias pkgupdateall='sudo zypper patch'
	alias pkgupdate='sudo zypper up'
	alias pkginstall='sudo zypper in'
	alias pkgremove='sudo zypper rm'
	alias pkgclean='sudo zypper packages --orphaned'
	alias pkgsearch='sudo zypper se'
	alias pkglist='zypper se --installed-only'
elif cmd-exists --strict eopkg; then # Solus
	# Link: https://getsol.us/articles/package-management/basics/en/
	alias has='sudo eopkg info'
	alias pkgupdateall='sudo eopkg upgrade'
	alias pkgupdate='sudo eopkg upgrade'
	alias pkginstall='sudo eopkg install'
	alias pkgremove='sudo eopkg remove'
	alias pkgsearch='sudo eopkg search'
	alias pkglist='eopkg li -l'
elif cmd-exists --strict emerge; then # Gentoo (Portage)
	# Link: https://www.linode.com/docs/guides/portage-package-manager/
	alias has='equery files'
	alias pkgupdateall='sudo emerge --sync && sudo emerge --update --deep --with-bdeps=y --newuse @world && sudo emerge --depclean && sudo revdep-rebuild'
	alias pkgupdate='sudo emerge -u'
	alias pkginstall='sudo emerge'
	alias pkgremove='sudo emerge --depclean'
	alias pkgsearch='sudo emerge --search'
	alias pkglist='equery list "*"'
elif cmd-exists --strict slackpkg; then # Slackware
	# Link: https://www.linux.com/training-tutorials/intro-slackware-package-management/
	alias has='slackpkg info'
	alias pkgupdateall='slackpkg update && slackpkg install-new && slackpkg upgrade-all'
	alias pkgupdate='upgradepkg'
	alias pkginstall='installpkg'
	alias pkgremove='removepkg'
	alias pkglist='pkgtool'
elif cmd-exists --strict urpmi; then # Mandrake
	# Link: https://wiki.mageia.org/en/URPMI
	alias has='urpmq --summary -Y'
	alias pkgupdateall='urpmi --auto-update'
	alias pkgupdate='urpmi'
	alias pkginstall='urpmi'
	alias pkgremove='urpme'
	alias pkgsearch='urpmq --summary -Y'
	alias pkglist='rpm -qa'
elif cmd-exists --strict apt-cyg; then # Cygwin
	# Link: http://stephenjungels.com/jungels.net/projects/apt-cyg/
	alias has='apt-cyg show'
	alias pkgupdateall='apt-cyg update'
	alias pkgupdate='apt-cyg update'
	alias pkginstall='apt-cyg install'
	alias pkgremove='apt-cyg remove'
	alias pkgsearch='apt-cyg find'
	alias pkglist='cygcheck --check-setup'
elif cmd-exists --strict brew; then # macOS
	# Link: https://brew.sh/
	alias has='brew info'
	alias pkgupdateall='brew update'
	alias pkgupdate='brew update'
	alias pkginstall='brew install'
	alias pkgremove='brew uninstall'
	alias pkgclean='brew cleanup'
	alias pkgsearch='brew search'
	alias pkglist='brew list'
fi

# If this is an Arch based distrobution with pacman...
if cmd-exists --strict pacman && [[ -d /etc/pacman.d/ ]]; then

	# Install a list of packages with regex
	# https://wiki.archlinux.org/title/pacman#Installing_specific_packages
	function pkginstallregex() {
		if [ $# -eq 0 ]; then
			echo "No regex provided"
			exit 1
		else
			sudo pacman -S $(pacman -Ssq "${@}")
		fi
	}

	# Clean the pacman and helper package caches
	alias pacman-clean-cache='yes | sudo pacman -Scc && command -v yay &> /dev/null && yes | yay -Sc || true && command -v paru &> /dev/null && yes | paru -Sc || true && echo'

	# To mark a package as explicitly installed or only a dependency
	alias pkgmarkasexplicit='sudo pacman -D --asexplicit'
	alias pkgmarkasdependency='sudo pacman -D --asdeps'

	# Show all packages and their install reason
	alias pkgreasons="pacman -Qi | awk -F': ' '/^Name/ { name = \$2; } /^Install Reason/ { reason = \$2; } /^$/ { printf \"%s: %s\\n\", name, reason; }'"

	# Check for default configuration file default backups
	alias pacnew='sudo true && echo "Pacman backup configuration files found:"; sudo find /etc -type f \( -iname \*.pacnew -o -iname \*.pacsave \) | sort -t"/" -k2.2r -k2.1'

	# Force remove a package ignoring required dependencies
	# NOTE: Also can be typed as sudo pacman -Rdd for short
	alias pkgforceremove='sudo pacman -Rd --nodeps'

	# Force remove a package ignoring required dependencies and then reinstall
	alias pkgforcereinstall='_PACKAGE_NAME=$1 && sudo pacman -Rd --nodeps $_PACKAGE_NAME && sudo pacman -S $_PACKAGE_NAME'

	# Search for a package containing a file
	alias pkgsearchcontainingfile='sudo pacman -Fy'

	# List all the local files in an installed package
	alias pkglocalpackagefiles='pacman -Ql'

	# Verify the presence of the files installed by a package
	alias pkgverifylocalpackage='sudo pacman -Qkk'

	# Verify all packages
	# Link: https://unix.stackexchange.com/questions/659756/arch-linux-reinstall-all-broken-packages-after-poweroff-during-system-upgrade
	alias pkgverifyall="pacman -Qk 2>/dev/null | grep -v ' 0 missing files'"

	# Show the latest Arch linux update news
	alias archnews='w3m https://www.archlinux.org/ | sed -n "/Latest News/,/Older News/p" | "${PAGER}"'

	# Pacseek - browse and search through the Arch Linux package databases and AUR
	# Link: https://github.com/moson-mo/pacseek
	if cmd-exists --strict pacseek; then
		alias pkg='pacseek'
	fi

	# If perl is installed (preset on most systems)...
	# Link: https://wiki.archlinux.org/title/Perl
	# Install: sudo pacman -S perl
	if cmd-exists --strict perl; then

		# Use a much more detailed package listing with descriptions (AUR separated)
		# pkglist [search] will search for all installed packages instead
		unalias pkglist &>/dev/null
		function pkglist() {
			if [ $# -eq 0 ]; then
				# In order to make this accurate, lets get a basic list of all the main repositories (minus the AUR) to check against
				repo="$(pacman -Sl core | awk '/\[.*[[:alpha:]]+]$/ {print $2}')\n$(pacman -Sl extra | awk '/\[.*[[:alpha:]]+]$/ {print $2}')\n$(pacman -Sl community | awk '/\[.*[[:alpha:]]+]$/ {print $2}')\n$(pacman -Sl multilib | awk '/\[.*[[:alpha:]]+]$/ {print $2}')\n"

				# If it's in the repo list, it's not the AUR
				echo -e "${BRIGHT_BLUE}=============== ${BRIGHT_YELLOW}Native Arch Packages${BRIGHT_BLUE} ===============${RESET}"
				for line in "$(pacman -Qqe | while read line; do if [[ $repo =~ $line ]]; then echo "$line"; fi; done)"; do \pacman -Qi $(echo "$line") ; done | perl -pe 's/ +/ /gm' | perl -pe 's/^(Groups +: )(.*)/$1($2)/gm' | perl -0777 -pe 's/^Name : (.*)\nVersion :(.*)\nDescription : ((?!None).*)?(?:.|\n)*?Groups :((?! \(None\)$)( )?.*)?(?:.|\n(?!Name))+/$1$4 - $3/gm' | grep -A1 --color -P "^[^\s]+"

				# If it's not in the repo list, it is from the AUR or Chaotic-AUR (or a custom repository)
				echo -e "\n${BRIGHT_BLUE}=============== ${BRIGHT_YELLOW}Arch User Repository (AUR)${BRIGHT_BLUE} ===============${RESET}"
				for line in "$(pacman -Qqe | while read line; do if [[ ! $repo =~ $line ]]; then echo "$line"; fi; done)"; do \pacman -Qi $(echo "$line") ; done | perl -pe 's/ +/ /gm' | perl -pe 's/^(Groups +: )(.*)/$1($2)/gm' | perl -0777 -pe 's/^Name : (.*)\nVersion :(.*)\nDescription : ((?!None).*)?(?:.|\n)*?Groups :((?! \(None\)$)( )?.*)?(?:.|\n(?!Name))+/$1$4 - $3/gm' | grep -A1 --color -P "^[^\s]+"
			else
				# If a search parameter was specified, just grep the parameter and ignore which repo
				for line in "$(\pacman -Qqe)"; do \pacman -Qi $(echo "$line") ; done | perl -pe 's/ +/ /gm' | perl -pe 's/^(Groups +: )(.*)/$1($2)/gm' | perl -0777 -pe 's/^Name : (.*)\nVersion :(.*)\nDescription : ((?!None).*)?(?:.|\n)*?Groups :((?! \(None\)$)( )?.*)?(?:.|\n(?!Name))+/$1$4 - $3/gm' | grep -A1 --color -P "^[^\s]+" | grep "${@}"
			fi
		}
	fi

	# If pacman-contrib (contributed scripts and tools for pacman) is installed...
	# Install: sudo pacman -S pacman-contrib
	if cmd-exists --strict paccache; then

		# Add aliases to find dependencies
		alias pkgdependencies='pactree --color' # --unique --depth 1
		alias pkgwhatuses='pactree --reverse --color'

		# The checkupdates script (also from Arch pacman-contrib)
		# NOTE: The benefit to this is it does NOT need SUDO/ROOT access
		alias pkgcheck='checkupdates | sort | \less --no-init --ignore-case --LONG-PROMPT --LINE-NUMBERS'

		# Alias to fix Arch Pacman install error "invalid or corrupted package" with a
		# new PGP key, clear anything older than the last 3 installs, and remove locks
		# Link: https://odysee.com/@DistroTube:2/solved-pacman-wouldn't-let-me-run-an:0
		alias pacmanfix='sudo rm -f /var/lib/pacman/db.lck && sudo paccache -r && sudo pacman -Sy archlinux-keyring'
		alias pacmanfixkeys='sudo rm -f /var/lib/pacman/db.lck; sudo rm -R /etc/pacman.d/gnupg/; sudo rm -R /root/.gnupg/; sudo gpg --refresh-keys && sudo pacman-key --init && sudo pacman-key --populate && sudo pacman -Sy archlinux-keyring'
	fi
fi

# If apt package manager is installed, add aliases to find dependencies in Ubuntu/Debian
if cmd-exists --strict apt-cache; then
	alias pkgdependencies='apt-cache depends'
	# If apt-rdepends is installed (sudo apt install apt-rdepends)
	if cmd-exists --strict apt-rdepends; then
		alias pkgwhatuses='apt-rdepends'
	fi
fi

# Aliases for flatpak packages if installed
if cmd-exists --strict flatpak; then
	alias flatpakhas='flatpak info'
	alias flatpakupdateall='sudo flatpak update'
	alias flatpakupdate='sudo flatpak update'
	alias flatpakinstall='sudo flatpak install'
	alias flatpakremove='sudo flatpak uninstall'
	alias flatpakwipe='sudo flatpak uninstall --delete-data'
	alias flatpakclean='sudo flatpak repair && sudo flatpak uninstall --unused'
	alias flatpaksearch='flatpak search'
	alias flatpaklist='flatpak list --columns=name,app:f,version:e,description:e --app'
	alias flatpaksize='flatpak list --columns=app:f,name,size:f,installation:e'
	alias flatpakremotes='flatpak remotes --show-details'

	# Create missing or recreate broken Flatpak icons (might require restart)
	if [ -d "/var/lib/flatpak/exports/share/applications/" ]; then
		alias flatpakmakeicons='\cp /var/lib/flatpak/exports/share/applications/*.desktop ~/.local/share/applications/'
	else
		alias flatpakmakeicons='find /var/lib/flatpak/app/ -type f -iname "*.desktop" -exec cp {} ~/.local/share/applications \;'
	fi

	# Make sure the Flatpak environment variable (for icons) is correct
	XDG_DATA_DIRS=$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share
fi

# Aliases for snap packages if installed
if cmd-exists --strict snap; then
	alias snaphas='snap info'
	alias snapupdateall='sudo snap refresh --list'
	alias snapupdate='sudo snap refresh'
	alias snapinstall='sudo snap install'
	alias snapremove='sudo snap remove'
	alias snapclean='LANG=C snap list --all | while read snapname ver rev trk pub notes; do if [[ $notes = *disabled* ]]; then sudo snap remove "$snapname" --revision="$rev"; fi; done'
	alias snapsearch='snap find'
	alias snaplist='snap list'
	alias snapsize='du -hcs /var/lib/snapd/snaps/*'
fi

#######################################################
# Alias for sudo replacements on machines with one user
#######################################################

if [[ $_SKIP_SUDO_ALTERNATIVE = false ]]; then

	# A very slim alternative to both sudo and doas
	# Link: https://codeberg.org/sw1tchbl4d3/rdo
	# Config: sudoedit /etc/rdo.conf
	# username=yourusername
	# wrong_pw_sleep=1000
	# session_ttl=5
	if cmd-exists --strict rdo; then
		alias sudo='rdo'

		# If sudoedit is not avaliable, alias it
		if ! cmd-exists --strict sudoedit; then
			# The edit alias might not exist in root but the
			# edit function handles sudo editing when needed
			alias sudoedit='edit'
		fi

	# A port of OpenBSD's doas offers two benefits over sudo:
	# 1) Its configuration file has a simple syntax and
	# 2) It is smaller, requiring less effort to audit the code
	# This makes it harder for both admins and coders to make mistakes that potentially open security holes in the system
	# Link: https://github.com/Duncaen/OpenDoas or https://github.com/slicer69/doas
	# Link: https://youtu.be/eamEZCj-CuQ
	# Config: Add "permit <user> as root" in /etc/doas.conf or /usr/local/etc/doas.conf
	elif cmd-exists --strict doas; then
		alias sudo='doas'

		# Replace sudoedit only if doasedit exists
		# Link: https://github.com/AN3223/scripts/blob/master/doasedit
		if cmd-exists --strict doasedit; then
			alias sudoedit='doasedit'
		fi
	fi
fi

#######################################################
# General Function "Aliases"
#######################################################

# Function to run upon exit of shell
function _exit() {
	# Show who logged out
	local COLOR="${BRIGHT_RED}"     # Light Red
	local HIGHLIGHT="${BRIGHT_BLUE}" # Light Blue
	local NOCOLOR="${RESET}"
	echo -e "${COLOR}User ${HIGHLIGHT}$(echo $USER)${COLOR} has logged out of ${HIGHLIGHT}$(echo $HOSTNAME)${COLOR}.${NOCOLOR}"
}
trap _exit EXIT

# Calculator that uses bc or Bash's built-in arithmetic
# Example: = 5*5+2
if cmd-exists bc; then
	# Start calculator with math support
	# echo 'if (scale == 0) scale=4' > ~/.config/bcrc
	# Link: https://www.gnu.org/software/bc/manual/html_mono/bc.html
	alias bc='bc --mathlib'
	if [[ -f ~/.bcrc ]]; then
		export BC_ENV_ARGS=~/.bcrc
	elif [[ -f ~/.config/bcrc ]]; then
		export BC_ENV_ARGS=~/.config/bcrc
	fi
	export BC_LINE_LENGTH=0

	function =() {
		bc <<< ${@}
	}
else
	function =() {
		local IFS=' '
		local _CALC="${*//p/+}"
		_CALC="${_CALC//x/*}"
		echo "$(($_CALC))"
	}
fi

# Confirm/Ask a question - See 'killps' for example of use
# General-purpose function to ask Yes/No questions in Bash,
# either with or without a default answer.
# It keeps repeating the question until it gets a valid answer.
# Link: https://gist.github.com/davejamesmiller/1965569
# Example Usage:
#   if ask "Do you want to do such-and-such?"; then
# Default to Yes if the user presses enter without giving an answer:
#   if ask "Do you want to do such-and-such?" Y; then
# Default to No if the user presses enter without giving an answer:
#   if ask "Do you want to do such-and-such?" N; then
# Or if you prefer the shorter version:
#   ask "Do you want to do such-and-such?" && said_yes
#   ask "Do you want to do such-and-such?" || said_no
function ask() {
	# Initialize local variables
	local prompt default reply

	# Determine the prompt and default based on the second parameter
	if [[ ${2:-} = 'Y' ]]; then
		prompt='Y/n'
		default='Y'
	elif [[ ${2:-} = 'N' ]]; then
		prompt='y/N'
		default='N'
	else
		prompt='y/n'
		default=''
	fi

	# Loop until a valid answer is given
	while true; do
		# Ask the question (not using "read -p" as it uses stderr not stdout)
		echo -ne "$1 [$prompt] "

		# Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
		read -r reply </dev/tty

		# Set reply to default if it is empty
		[[ -z $reply ]] && reply=$default

		# Check if the reply is valid
		case "$reply" in
			Y*|y*) return 0 ;;
			N*|n*) return 1 ;;
		esac
	done
}

# Creates a menu for selecting an item from a list from either piped in
# multi-line text or command line arguments. Use --picker=app to force a picker
# Example: ls -1 ~ | createmenu
# Example: echo -e "Jen\nTom\nJoe Bob\nAmy\nPat" | sort | createmenu
# Example: cat "menuitems.txt" | createmenu
# Example: _TMUX_SESSION="$(tmux ls -F "#{session_name}" 2> /dev/null | createmenu)"
# Example: createmenu 'Option 1' 'Option 2' 'Option 3'
function createmenu() {
	# Valid pickers to detect and automatically used in order
	local _VALID_PICKERS="${_PREFERRED_PICKER} fzy sk fzf peco percol pick icepick selecta sentaku zf dmenu rofi wofi"

	# Check if command line arguments are provided and if input is piped in
	if [ "$#" -eq 0 ] && [ -t 0 ]; then
		echo -e "${BRIGHT_WHITE}createmenu:${RESET} Creates a menu for selecting an item from a list"
		echo -e "${BRIGHT_WHITE}It takes input from either piped in multi-line text or command line arguments${RESET}"
		echo -e "${BRIGHT_WHITE}Supported optional pickers are:${RESET}"
		echo -e "  ${BRIGHT_GREEN}fzy, sk (skim), fzf, peco, percol, pick, icepick, selecta, sentaku, zf, dmenu, rofi, wofi${RESET}"
		echo -e "${BRIGHT_WHITE}Usage examples:${RESET}"
		echo -e "  With piped input:"
		echo -e "    ${BRIGHT_YELLOW}ls${BRIGHT_CYAN} -1 ~ | ${BRIGHT_MAGENTA}createmenu${RESET}"
		echo -e "    ${BRIGHT_CYAN}echo -e ${BRIGHT_YELLOW}\"Jen\\\\nTom\\\\nJoe Bob\\\\nAmy\\\\nPat\"${BRIGHT_CYAN} | sort | ${BRIGHT_MAGENTA}createmenu${RESET}"
		echo -e "    ${BRIGHT_CYAN}cat ${BRIGHT_YELLOW}'menuitems.txt'${BRIGHT_CYAN} | ${BRIGHT_MAGENTA}createmenu${RESET}"
		echo -e "    ${BRIGHT_CYAN}_TMUX_SESSION=\"\$(${BRIGHT_YELLOW}tmux ls -F '#{session_name}' 2> /dev/null${BRIGHT_CYAN} | ${BRIGHT_MAGENTA}createmenu${BRIGHT_CYAN})\"${RESET}"
		echo -e "  With command line arguments:"
		echo -e "    ${BRIGHT_MAGENTA}createmenu ${BRIGHT_YELLOW}'Option 1' 'Option 2' 'Option 3'${RESET}"
		echo -e "  With a specified picker:"
		echo -e "    ${BRIGHT_MAGENTA}createmenu ${BRIGHT_CYAN}--picker=${BRIGHT_GREEN}rofi ${BRIGHT_YELLOW}\"Option 1\" \"Option 2\" \"Option 3\"${RESET}"
		echo -e "    ${BRIGHT_CYAN}echo -e ${BRIGHT_YELLOW}\"Red\\\\nGreen\\\\nBlue\"${BRIGHT_CYAN} | ${BRIGHT_MAGENTA}createmenu${BRIGHT_CYAN} --picker=${BRIGHT_GREEN}dmenu${RESET}"
		return 1
	fi

	# Check for --picker parameter and remove it from arguments
	local _PICKER
	local _FOUND_PICKER=false
	local NEW_ARGS=()
	for ARG in "$@"; do
		if [[ "$ARG" == --picker=* ]]; then
			_PICKER="${ARG#*=}"
			if cmd-exists "${_PICKER}"; then
				_FOUND_PICKER=true
			else
				echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}The picker ${BRIGHT_YELLOW}${_PICKER}${BRIGHT_CYAN} is not available or installed${RESET}"
				return 1
			fi
		else
			NEW_ARGS+=("$ARG")
		fi
	done
	set -- "${NEW_ARGS[@]}"

	# If no specific picker is provided or the picker is not valid...
	if [ "$_FOUND_PICKER" == false ]; then
		# Loop through the list and see if one of them is installed
		for _PICKER in $_VALID_PICKERS; do
			if cmd-exists $_PICKER; then
				_FOUND_PICKER=true
				break
			fi
		done
	fi

	# Check if command line arguments are provided
	if [ "$#" -gt 0 ]; then
		local _INPUT=""
		local _COUNT=0
		for arg in "$@"; do
			# Increase count for each argument
			((_COUNT++))

			# Add newline after each argument except the last
			if [ $_COUNT -lt $# ]; then
				_INPUT+="${arg}"$'\n'
			else
				_INPUT+="${arg}"
			fi
		done
	else
		# Get the piped in multiple lines of text
		local _INPUT="$(</dev/stdin)"
		# Count the lines of text
		local _COUNT=$(echo "${_INPUT}" | wc -l)
	fi

	# If there is no input, just exit with an error
	if [ -z "${_INPUT}" ]; then
		return 1

	# If there is only one line (or one argument), no choice is needed
	elif [ ${_COUNT} -eq 1 ]; then
		echo "${_INPUT}"
		return 0
	fi

	# If we found a picker, use it
	if [ "$_FOUND_PICKER" == true ]; then
		# echo -e "${BRIGHT_MAGENTA}The picker is: ${BRIGHT_GREEN}$_PICKER${RESET}"
		case $_PICKER in
			dmenu)
				echo "${_INPUT}" | dmenu -l 10
				;;
			rofi)
				echo "${_INPUT}" | rofi -dmenu -i -no-custom -no-fixed-num-lines -p "Choose:"
				;;
			wofi)
				echo "${_INPUT}" | wofi --show dmenu --insensitive --prompt "Choose:"
				;;
			*)
				echo "${_INPUT}" | $_PICKER
				;;
		esac

	# Use Bash's built in select option
	else
		# Parse only on new lines
		local _IFS_OLD="${IFS}"
		IFS=$'\n'

		# Turn off globbing filename generation
		set -f

		# Show a list to pick an item from
		select RESULT in ${_INPUT}; do
			if [ -n "${RESULT}" ]; then
				echo "${RESULT}"
				break
			fi
		done < /dev/tty

		# Restore settings
		IFS="${_IFS_OLD}"
		set +f
	fi
}

# This function automates the process of executing a command and providing visual feedback
# It displays an hourglass symbol next to the provided description while the command is running
# Upon successful execution, the hourglass is replaced with a green checkmark
# If the command fails, a red cross symbol is displayed instead
# Parameters:
# 	$1: Text description to display while the command is running
# 	$2: The command to execute
function run-with-feedback() {
	# Check if both parameters are provided
	if [ -z "${1}" ] || [ -z "${2}" ]; then
		echo -e "${BRIGHT_WHITE}Usage: ${BRIGHT_CYAN}run-with-feedback${RESET} ${BRIGHT_GREEN}[description] [command]${RESET}"
		return 1
	fi

	# Local variables for special characters with color codes
	local hourglass="${BRIGHT_YELLOW}⌛${RESET}"   # Yellow Hourglass
	local checkmark="\r${BRIGHT_GREEN}✓${RESET}"  # Green Checkmark
	local cross="\r${BRIGHT_RED}X${RESET}"      # Red Error Cross

	# Display the hourglass and message
	echo -ne "${hourglass} ${1}"

	# Execute the command
	if eval "${2}"; then
		# If successful, display a green checkmark
		echo -e "${checkmark} ${1} "
	else
		# If failed, display a red cross
		echo -e "${cross} ${1} "
	fi
}

# Finds the current Linux distribution, name, version, and kernel version
function ver() {
	if cmd-exists --strict uname; then
		# Get information about the system kernel, release, and machine hardware
		uname --kernel-name --kernel-release --machine
		echo
	fi
	if [[ -e /proc/version ]]; then
		# File that contains version information about the operating kernel
		cat /proc/version
		echo
	fi
	if cmd-exists --strict lsb_release; then
		# Provides LSB (Linux Standard Base) and distribution-specific information
		lsb_release -a
		echo
	fi
	if cmd-exists --strict hostnamectl; then
		# Control the Linux system hostname, also shows various system details
		hostnamectl
		echo
	else
		# Various files that contain text relating to the system identification
		cat /etc/*-release 2> /dev/null
	fi
}

# Aliases crontab with safety warning for -r option, confirming removal
alias crontab='_crontab_safe'
function _crontab_safe() {
	# Check if the parameters contain the "-r" option
	if [[ "$*" == *"-r"* ]]; then
		# Display a warning message in bright red with a warning icon
		echo -e "${BRIGHT_RED}WARNING: ${RESET}${BRIGHT_CYAN}You are attempting to remove your crontab. This action cannot be undone! ${BRIGHT_YELLOW}⚠️${RESET}"

		# Ask for user confirmation before proceeding
		read -p "Are you sure you want to continue? (y/N) " confirm

		# Check if the user confirmed the operation
		if [[ "$confirm" == [yY] || "$confirm" == [yY][eE][sS] ]]; then
			# If confirmed, execute the actual crontab command with the provided parameters
			command crontab "$@"
		else
			# If not confirmed, display a cancellation message
			echo "Operation canceled."
		fi
	else
		# If the "-r" option is not present, execute the regular crontab command with the provided parameters
		command crontab "$@"
	fi
}

# Search process names to kill
# https://unix.stackexchange.com/questions/443472/alias-for-killing-all-processes-of-a-grep-hit
function smash() {
	# Check if a process name is specified; if not, show help text
	if [[ -z "$1" ]]; then
		echo -e "${BRIGHT_WHITE}smash:${RESET} Finds and optionally kills processes by name"
		echo -e "${BRIGHT_WHITE}Usage:${RESET} ${BRIGHT_CYAN}smash${RESET} ${BRIGHT_YELLOW}[process_name]${RESET}"
		echo -e "${BRIGHT_WHITE}Examples:${RESET}"
		echo -e "  ${BRIGHT_CYAN}smash${RESET} ${BRIGHT_YELLOW}vim${RESET}"
		return 1
	fi

	local T_PROC=$1
	local T_PIDS=($(pgrep -i "$T_PROC"))
	if [[ "${#T_PIDS[@]}" -ge 1 ]]; then
		echo "Found the following processes:"
		for pid in "${T_PIDS[@]}"; do
			echo "$pid" "$(\ps -p "$pid" -o comm= | awk -F'/' '{print $NF}')" | column -t
		done
		if ask "Kill them?" N; then
			for pid in "${T_PIDS[@]}"; do
				echo "Killing ${pid}..."
				( kill -15 "$pid" ) && continue
				sleep 2
				( kill -2 "$pid" ) && continue
				sleep 2
				( kill -1 "$pid" ) && continue
				echo "Cannot terminate" >&2 && return 1
			done
		else
			echo "Exiting..."
			return 0
		fi
	else
		echo "No processes found for: $1" >&2 && return 1
	fi
}

# Extracts any archive(s)
function extract() {
	# If no archive is specified or --help or -h is passed, show help text
	if [ -z "$1" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
		echo -e "${BRIGHT_WHITE}extract:${RESET} Extracts one or multiple archive files"
		echo -e "${BRIGHT_WHITE}Usage: ${BRIGHT_CYAN}extract${RESET} ${BRIGHT_YELLOW}[archive_file1] [archive_file2] ...${RESET}"
		echo -e "${BRIGHT_WHITE}Examples:${RESET}"
		echo -e "  ${BRIGHT_CYAN}extract${RESET} ${BRIGHT_YELLOW}'/path/to/file/example.tar.gz'${RESET}"
		echo -e "  ${BRIGHT_CYAN}extract${RESET} ${BRIGHT_YELLOW}example1.tar.gz example2.zip${RESET} ${BRIGHT_BLUE}(${BRIGHT_MAGENTA}multiple files${BRIGHT_BLUE})${RESET}"
		return 1
	fi

	# Loop through each archive provided as an argument
	for archive in "$@"; do
		# Check if the file exists
		if [ -f "${archive}" ] ; then
			# Switch case to handle various archive types
			case "${archive}" in
				*.tar.bz2)  tar xvjf "${archive}"    ;;
				*.tar.gz)   tar xvzf "${archive}"    ;;
				*.bz2)      bunzip2 "${archive}"     ;;
				*.rar)      rar x "${archive}"       ;;
				*.gz)       gunzip "${archive}"      ;;
				*.tar)      tar xvf "${archive}"     ;;
				*.tbz2)     tar xvjf "${archive}"    ;;
				*.tgz)      tar xvzf "${archive}"    ;;
				*.zip)      unzip "${archive}"       ;;
				*.Z)        uncompress "${archive}"  ;;
				*.7z)       7z x "${archive}"        ;;
				*)          echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}Unknown archive type ${BRIGHT_YELLOW}${archive##*.}${RESET}" ;;
			esac
		else
			echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}The file ${BRIGHT_YELLOW}${archive}${BRIGHT_CYAN} is not valid or does not exist${RESET}"
		fi
	done
}

# Generate a random password
# Pass the number of characters for the password on the command line
# Add the parameter +s to include symbols and -s to exclude them
# Example: genpw
# Example: genpw +s 24
# Example: genpw 8
# Example: genpw 12 -s
# HINT: Check passwords with cracklib: echo "1234abc" | cracklib-check
# Link: https://www.cyberciti.biz/security/linux-password-strength-checker/
function genpw() {
	local _PASSWORD_LENGTH
	local _PASSWORD_SYMBOLS

	if [[ ${1} -gt 0 ]]; then
		_PASSWORD_LENGTH=${1}
	elif [[ ${2} -gt 0 ]]; then
		_PASSWORD_LENGTH=${2}
	else
		read -e -i "16" -p "How many characters? " _PASSWORD_LENGTH
		if [[ ! ${_PASSWORD_LENGTH} -gt 0 ]]; then
			_PASSWORD_LENGTH=16
		fi
	fi

	if [[ ${1} == '-s' ]] || [[ ${2} == '-s' ]]; then
		_PASSWORD_SYMBOLS=false
	elif [[ ${1} == '+s' ]] || [[ ${2} == '+s' ]]; then
		_PASSWORD_SYMBOLS=true
	else
		if ask "Do you want to include symbols?" Y; then
			_PASSWORD_SYMBOLS=true
		fi
	fi

	if cmd-exists --strict apg; then
		if [[ ${_PASSWORD_SYMBOLS} == true ]]; then
			apg -a 1 -n 10 -m ${_PASSWORD_LENGTH} -l
		else
			apg -a 0 -n 10 -m ${_PASSWORD_LENGTH} -l
		fi
	elif cmd-exists --strict pwgen; then
		if [[ ${_PASSWORD_SYMBOLS} == true ]]; then
			pwgen --capitalize --numerals --symbols --secure -C ${_PASSWORD_LENGTH} 40
		else
			pwgen --capitalize --numerals --secure -C ${_PASSWORD_LENGTH} 40
		fi
	elif cmd-exists --strict gpg; then
		for ((n=0;n<10;n++)); do
			if [[ ${_PASSWORD_SYMBOLS} == true ]]; then
				gpg --gen-random 1 1024 | tr -dc a-zA-Z0-9'`~!@#$%^&*-_=+()[]{}|;:",.?<>/\\'"'" | head -c${_PASSWORD_LENGTH}; echo
			else
				gpg --gen-random 1 1024 | tr -dc a-zA-Z0-9 | head -c${_PASSWORD_LENGTH}; echo
			fi
		done
	elif cmd-exists --strict openssl; then
		for ((n=0;n<10;n++)); do
			if [[ ${_PASSWORD_SYMBOLS} == true ]]; then
				openssl rand 1024 | tr -dc a-zA-Z0-9'`~!@#$%^&*-_=+()[]{}|;:",.?<>/\\'"'" | head -c${_PASSWORD_LENGTH}; echo
			else
				openssl rand 1024 | tr -dc a-zA-Z0-9 | head -c${_PASSWORD_LENGTH}; echo
			fi
		done
	else
		for ((n=0;n<10;n++)); do
			if [[ ${_PASSWORD_SYMBOLS} == true ]]; then
				cat /dev/urandom | tr -dc a-zA-Z0-9'`~!@#$%^&*-_=+()[]{}|;:",.?<>/\\'"'" | head -c${_PASSWORD_LENGTH}; echo
			else
				cat /dev/urandom | tr -dc a-zA-Z0-9 | head -c${_PASSWORD_LENGTH}; echo
			fi
		done
	fi
}

# Schedule the computer to auto reboot (defaults to 4:00 AM)
function reboottonight() {
	# If no time is specified or --help or -h is passed, show help text
	if [ -z "$1" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
		echo -e "${BRIGHT_WHITE}reboottonight:${RESET} Schedule the computer to auto reboot (defaults to 4:00 AM)"
		echo -e "${BRIGHT_WHITE}Usage: ${BRIGHT_CYAN}reboottonight${RESET} ${BRIGHT_YELLOW}[OPTIONAL_TIME]${RESET}"
		echo -e "${BRIGHT_WHITE}Examples:${RESET}"
		echo -e "  ${BRIGHT_CYAN}reboottonight${RESET}          # Reboot at 4:00 AM"
		echo -e "  ${BRIGHT_CYAN}reboottonight${RESET} ${BRIGHT_YELLOW}'02:30'${RESET}  # Reboot at 2:30 AM"
		return 1
	fi

	# Check if 'at' command exists directly in the if statement
	if ! cmd-exists at; then
		echo -e "${BRIGHT_RED}Error:${RESET} Required 'at' command is not installed"
		return 1
	fi

	sudo bash -c '$(which shutdown) -r ${1:-"04:00"} | at now'
}

# See what command you are using the most (this parses the history command)
# Usage: mostused [num_items]
function mostused() {
	local num_items="${1:-10}"  # Default to 10 if num_items is not specified
	history \
	| awk ' { a[$4]++ } END { for ( i in a ) print a[i], i | "sort -rn | head -n'"$num_items"'"}' \
	| awk '$1 > max{ max=$1} { bar=""; i=s=10*$1/max;while(i-->0)bar=bar"#"; printf "%25s %15d %s %s", $2, $1,bar, "\n"; }'
}

# Start a program but immediately disown it and detach it from the terminal
function runfree() {
	"$@" > /dev/null 2>&1 & disown
}

# Sends a desktop notification when a command finishes its execution
# Examples: sleep 1; alert  # Notifies when the sleep command completes
#           make && alert 'Success' || alert 'Error'  # Notify result status
#           tar -czvf file.tar.gz && alert  # Notifies if the command succeeds
#           false || alert "There was an error"  # Notifies if the command fails
# Link: https://askubuntu.com/questions/423646/use-of-default-alias-alert
function alert() {
	# Determine the icon based on the exit status of the last command
	# If exit status is zero (success), use 'terminal' as icon; otherwise use 'error'
	icon="$([ $? == 0 ] && echo terminal || echo error)"

	# Extract the last executed command from the history
	# Remove leading numbers and trailing 'alert' command if exists
	last_command="$(history | tail -n1 | sed -e 's/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//')"

	# Send the desktop notification with highest urgency level ("critical")
	notify-send --urgency=critical -i "${icon}" "${last_command}"
}

# Format a string that is safe to be used in regular expressions
function regexformat() {
	echo -n "$(printf '%s' "${1}" | sed 's/[.[\(\)\ *^$+?{|]/\\&/g')"
}

# Trim leading and trailing characters on the clipboard
function trimcb() {
	# Fetch the current clipboard content and declare it as a local variable
	local content_to_trim=$(clipboard)

	# If clipboard content is not empty, trim it and send it back to the clipboard
	if [[ -n "$content_to_trim" ]]; then
		echo -e "$content_to_trim" | sed 's/^[ \t]*//;s/[ \t]*$//' | clipboard
	fi
}

# Long format directory listing with color columns (only requires gawk)
function llcolor {
	if cmd-exists --strict gawk; then
		# Show long directory listings with color columns
		\ls -l --all --classify --group-directories-first --human-readable --color=always "$@" | awk '
			BEGIN {
				FPAT = "([[:space:]]*[^[:space:]]+)";
				OFS = "";
			}
			{
				$1 = "\033[0;37m" $1 "\033[0m";
				$2 = "\033[0;34m" $2 "\033[0m";
				$3 = "\033[0;35m" $3 "\033[0m";
				$4 = "\033[0;31m" $4 "\033[0m";
				$5 = "\033[0;33m" $5 "\033[0m";
				$6 = "\033[0;32m" $6 "\033[0m";
				$7 = "\033[0;32m" $7 "\033[0m";
				$8 = "\033[0;36m" $8 "\033[0m";
				print
			}
		'
	else # Gawk not installed...
		# Show long directory listings with highest compatibility
		\ls -Fls "$@"
	fi
}

# Commands pushd and popd now output the directory stack after modification
# and also prevents duplicate directories being added to the directory stack
function pushd() {
	builtin pushd "${@}" > /dev/null
	dirsdedup
	echo "Directory Stack:"
	dirs -v
}

function popd() {
	builtin popd "${@}" > /dev/null
	echo "Directory Stack:"
	dirs -v
}

# Function to remove duplicate directories in the directory stack for pushd
function dirsdedup() {
	# Declare an array to hold the new directory stack without duplicates
	declare -a NEW_STACK=()
	# Declare a copy of the current directory stack, excluding the first element
	declare -a CURRENT_STACK_COPY=("${DIRSTACK[@]:1}")
	# Declare an associative array to keep track of directories seen
	declare -A SEEN_DIRECTORIES
	# Local variables for loop iteration
	local DIRECTORY INDEX
	# Mark the current working directory as seen
	SEEN_DIRECTORIES[$PWD]=1

	# Iterate through the copied directory stack
	for DIRECTORY in "${CURRENT_STACK_COPY[@]}"
	do
		# If the directory has not been seen before, add it to the new stack
		if [ -z "${SEEN_DIRECTORIES[$DIRECTORY]}" ]; then
			NEW_STACK+=("$DIRECTORY")
			SEEN_DIRECTORIES[$DIRECTORY]=1
		fi
	done

	# Rebuild the directory stack from the new stack, in reverse order
	builtin dirs -c
	for ((INDEX=${#NEW_STACK[@]}-1; INDEX>=0; INDEX--))
	do
		builtin pushd -n "${NEW_STACK[INDEX]}" >/dev/null
	done
}

# View a comma delimited (.CSV) file
function csvview() {
	# Check for the presence of arguments
	if [[ $# -eq 0 ]]; then
		echo -e "${BRIGHT_WHITE}csvview:${RESET} View comma-delimited (.CSV) files"
		echo -e "${BRIGHT_WHITE}Usage:${BRIGHT_CYAN} csvview${RESET} ${BRIGHT_YELLOW}<file1.csv> [file2.csv] ...${RESET}"
		return 1
	fi

	# Loop through all the arguments
	for FILE in "${@}"; do
		# Check if file exists
		if [[ ! -f "${FILE}" ]]; then
			echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}The file ${BRIGHT_YELLOW}${FILE}${BRIGHT_CYAN} does not exist${RESET}"
			continue
		# Check if file is readable
		elif [[ ! -r "${FILE}" ]]; then
			echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}The file ${BRIGHT_YELLOW}${FILE}${BRIGHT_CYAN} is not readable${RESET}"
			continue
		fi

		# Display the formatted CSV file
		\cat "${FILE}" | \sed 's/,/ ,/g' | column -t -s, | \less -S
	done
}

# Send file(s) to the trash
# Link: https://www.tecmint.com/trash-cli-manage-linux-trash-from-command-line/
function trash() {
	# Check for the presence of arguments
	if [[ $# -eq 0 ]]; then
		echo -e "${BRIGHT_WHITE}trash:${RESET} Send files to the trash"
		echo -e "${BRIGHT_WHITE}Usage:${BRIGHT_CYAN} trash${RESET} ${BRIGHT_YELLOW}<filename1> [filename2] ...${RESET}"
		return 1
	fi

	# Check if trash-cli exists...
	# https://github.com/andreafrancia/trash-cli
	if cmd-exists --strict trash-put; then
		trash-put "${@}"
	# Check if rem exists...
	# Link: https://github.com/quackduck/rem
	elif cmd-exists --strict rem; then
		rem "${@}"
	# Check if gio trash exists (glib2)...
	# Link: https://wiki.archlinux.org/title/Trash-cli#gio_trash
	elif cmd-exists --strict gio; then
		gio trash "${@}"
	# Check if kioclient5 exists (kde-cli-tools)...
	# Link: https://wiki.archlinux.org/title/Trash-cli#kioclient5
	elif cmd-exists --strict kioclient5; then
		kioclient5 move "${@}" trash:/
	elif [[ -d $HOME/.local/share/Trash/files ]]; then
		mv "${@}" $HOME/.local/share/Trash/files/
	elif [[ -d $HOME/.local/share/trash/files ]]; then
		mv "${@}" $HOME/.local/share/trash/files/
	elif [[ -d $HOME/.Trash ]]; then
		mv "${@}" $HOME/.Trash/
	elif [[ -d $HOME/.trash ]]; then
		mv "${@}" $HOME/.trash/
	else
		mkdir $HOME/.trash
		mv "${@}" $HOME/.trash/
	fi
}

# Display the contents of the trash
function trashlist() {
	# Check if trash-cli exists...
	# https://github.com/andreafrancia/trash-cli
	if cmd-exists --strict trash-list; then
		trash-list
	# Check if rem exists...
	# Link: https://github.com/quackduck/rem
	elif cmd-exists --strict rem; then
		rem -l
	# Check if gio trash exists (glib2)...
	# Link: https://wiki.archlinux.org/title/Trash-cli#gio_trash
	elif cmd-exists --strict gio; then
		gio list trash:///
	# Check if kioclient5 exists (kde-cli-tools)...
	# Link: https://wiki.archlinux.org/title/Trash-cli#kioclient5
	elif cmd-exists --strict kioclient5; then
		kioclient5 ls trash:/
	# Check for alternative trash directories and list files
	elif [[ -d ${HOME}/.local/share/Trash/files ]]; then
		ls -l ${HOME}/.local/share/Trash/files/
	elif [[ -d ${HOME}/.local/share/trash/files ]]; then
		ls -l ${HOME}/.local/share/trash/files/
	elif [[ -d ${HOME}/.Trash ]]; then
		ls -l ${HOME}/.Trash/
	elif [[ -d ${HOME}/.trash ]]; then
		ls -l ${HOME}/.trash/
	else
		echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}No trash directory found${RESET}"
	fi
}

# Empty and permanently delete all the files in the trash
function trashempty() {
	# Ask for user confirmation before deleting trash
	if ask "${BRIGHT_WHITE}Are you sure you want to ${BRIGHT_MAGENTA}permanently delete${BRIGHT_WHITE} all the files in the trash? ${BRIGHT_RED}This action cannot be undone.${RESET}" "N"; then
		# Check if trash-cli exists...
		# https://github.com/andreafrancia/trash-cli
		if cmd-exists --strict trash-empty; then
			trash-empty
		# Check if rem exists...
		# Link: https://github.com/quackduck/rem
		elif cmd-exists --strict rem; then
			rem --empty
		# Check if gio trash exists (glib2)...
		# Link: https://wiki.archlinux.org/title/Trash-cli#gio_trash
		elif cmd-exists --strict gio; then
			gio trash --empty
		# Check if kioclient5 exists (kde-cli-tools)...
		# Link: https://wiki.archlinux.org/title/Trash-cli#kioclient5
		elif cmd-exists --strict kioclient5; then
			kioclient5 empty trash:/
		# Check for alternative trash directories and delete files
		elif [[ -d ${HOME}/.local/share/Trash/files ]]; then
			rm -rf ${HOME}/.local/share/Trash/files/{..?*,.[!.]*,*} 2>/dev/null
		elif [[ -d ${HOME}/.local/share/trash/files ]]; then
			rm -rf ${HOME}/.local/share/trash/files/{..?*,.[!.]*,*} 2>/dev/null
		elif [[ -d ${HOME}/.Trash ]]; then
			rm -rf ${HOME}/.Trash/{..?*,.[!.]*,*} 2>/dev/null
		elif [[ -d ${HOME}/.trash ]]; then
			rm -rf ${HOME}/.trash/{..?*,.[!.]*,*} 2>/dev/null
		else
			# No supported method found for emptying trash
			echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}No trash directory or supported application found${RESET}"
		fi
	else
		# Operation was cancelled by the user
		echo -e "${BRIGHT_RED}Operation cancelled.${RESET}"
	fi
}

# Restore the trash only is trash-cli is installed
# trash-cli - Command Line Interface to FreeDesktop.org Trash
# Link: https://github.com/andreafrancia/trash-cli
if cmd-exists --strict restore-trash; then
	alias trashrestore='restore-trash'
elif cmd-exists --strict trash-restore; then
	alias trashrestore='trash-restore'
fi

# Check the sha256 checksum of a file using a checksum file parameter like sha256sum.txt
function checksha256() {
	if [[ "$#" -lt 2 ]] || [[ $1 = "--help" ]] || [[ $1 = "-h" ]]; then
		echo -e "${BRIGHT_WHITE}Usage: ${BRIGHT_CYAN}checksha256${RESET} ${BRIGHT_GREEN}[downloaded_filename] [checksum_filename]${RESET}"
		return 1
	fi
	if cmd-exists --strict sha256sum; then
		if [[ $(sha256sum "${1}" | cut -d' ' -f 1) == $(grep -Po '\b[a-zA-Z0-9]{64}\b' "${2}") ]]; then
			echo -e "${BRIGHT_GREEN}Good"
		else
			echo -e "${BRIGHT_RED}Bad"
		fi
	else
		echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}The application sha256sum is not installed${RESET}"
	fi
}

# If we are in a graphical desktop environment...
if [[ -n "$DISPLAY" ]] || [[ -n "$WAYLAND_DISPLAY" ]]; then
	# Function to search Desktop applications
	function findapps() {
		local search_term="$1" # The keyword to search for

		# Ensure a search term is provided
		if [[ -z "$search_term" ]]; then
			echo -e "\e[1;31mPlease provide a search term.\e[0m"
			return 1
		fi

		# Search in both system-wide and user-specific application directories
		local directories=("/usr/share/applications" "$HOME/.local/share/applications")

		echo -e "\e[1;36mApplications matching\e[0m '\e[33m$search_term\e[0m':"
		echo -e "\e[1;90m------------------------------------\e[0m"

		# Fields to search within the .desktop file
		local fields="Name|GenericName|Comment|Keywords"

		# Process each directory and collect results
		while read -r line; do
			echo "$line"
		done < <(
			for dir in "${directories[@]}"; do
				if [[ -d "$dir" ]]; then
					grep -i -l -E "($fields)=.*$search_term" "$dir"/*.desktop | \
					while read -r desktop_file; do
						local app_name field_match
						app_name=$(grep -m 1 '^Name=' "$desktop_file" | sed 's/Name=//')
						field_match=$(grep -i -m 1 -E "($fields)=.*$search_term" "$desktop_file")
						echo -e "\e[1;32m✓\e[0m \e[1;33m$app_name\e[0m  \e[1;35m$desktop_file\e[0m"
						# Debug only: echo -e "    \e[1;90mMatch found in: $field_match\e[0m"
					done
				fi
			done | sort
		)
	}
fi

# Searches for filenames (can use wildcards)
alias findfile="f"
function f() {
	# Initialize the sudo prefix for running commands with elevated permissions
	local SUDO_PREFIX=""

	# Check for --sudo flag and remove it from arguments if present
	if [[ "$1" == "--sudo" ]]; then
		SUDO_PREFIX="sudo "
		shift
	fi

	# Check if any filename or pattern is specified; if not, show help text
	if [[ -z "$1" ]]; then
		echo -e "${BRIGHT_WHITE}findfile:${RESET} Searches for filenames recursively"
		echo -e "To use elevated permissions include the ${BRIGHT_YELLOW}--sudo${RESET} option"
		echo -e "${BRIGHT_WHITE}Usage:${RESET}"
		echo -e "  ${BRIGHT_CYAN}findfile${RESET} ${BRIGHT_YELLOW}[file_name_pattern]${RESET}"
		echo -e "${BRIGHT_WHITE}Examples:${RESET}"
		echo -e "  ${BRIGHT_CYAN}findfile${RESET} ${BRIGHT_YELLOW}'file.txt'${RESET}"
		echo -e "  ${BRIGHT_CYAN}findfile${RESET} ${BRIGHT_GREEN}--sudo${RESET} ${BRIGHT_YELLOW}'config'${RESET}  ${BRIGHT_BLUE}(${BRIGHT_MAGENTA}using sudo${BRIGHT_BLUE})${RESET}"
		return 1  # Exit with a non-zero status
	fi

	# Use fdfind if installed, else use fd or find as fallback
	if cmd-exists --strict fdfind; then
		# fdfind command options
		# --type 'file' : Only search for files (not directories)
		# --ignore-case : Perform a case-insensitive search
		# --no-ignore   : Do not respect .gitignore and .ignore files
		# --hidden      : Include hidden files in the search results
		# --follow      : Follow symlinks (WARNING: can get into an endless loop)
		echo "${SUDO_PREFIX}fdfind --type 'file' --ignore-case --no-ignore --hidden '$1' ."
		${SUDO_PREFIX}fdfind --type 'file' --ignore-case --no-ignore --hidden "$1" .

	elif cmd-exists --strict fd; then
		echo "${SUDO_PREFIX}fd --type 'file' --ignore-case --no-ignore --hidden '$1' ."
		${SUDO_PREFIX}fd --type 'file' --ignore-case --no-ignore --hidden "$1" .

	else  # Use find command as a last resort
		# find command options
		# -type f : Search for files only, not directories
		# -iname  : Perform a case-insensitive search
		# -follow : Dereference symlinks (follow them to their targets)
		echo "${SUDO_PREFIX}find . -type f -iname '$1'"
		${SUDO_PREFIX}find . -type f -iname "$1"
	fi
}

# Searches for text in source code files located in the current path
# Supported languages: Ada, Assembly, AWK, Batch, C, COBOL, Config, C++,
# C#(CS), CSS, Dart, Emacs Lisp, Erlang, Elixir, Fortran(90, 95, older), Go,
# Groovy, Header(C, C++), HTML, Haxe, Include, INI, Arduino, Java, JavaScript,
# JSON, Kotlin, Library, Lua, M4, Objective-C, MATLAB, Makefiles, Nim, Nix,
# Pascal, PHP, Perl, Python, R, Ruby, Racket, Rust, Scala, SASS/SCSS, Shell,
# Standard ML, SQL, Swift, TCL, Templates, LaTeX, TypeScript, VB, VBA, VBS,
# VHDL, Wren, XML, YAML, Zig
function findcode() {
	# Local constant for maximum line length cut-off
	# NOTE: This is necessary for certain files like minified javascript
	local -r LINE_LENGTH_CUTOFF=1000

	# The prefix to prepend to search commands for elevated permissions
	local SUDO_PREFIX=""

	# Check for --sudo flag and remove it from arguments if present
	if [[ "$1" == "--sudo" ]]; then
		SUDO_PREFIX="sudo "
		shift
	fi

	# If no parameter is specified, show help text
	if [ -z "$1" ]; then
		echo -e "${BRIGHT_WHITE}findcode:${RESET} Searches for code text in source files recursively"
		echo -e "You can use both ${BRIGHT_YELLOW}plain text${RESET} and ${BRIGHT_YELLOW}regular expressions${RESET} for searching"
		echo -e "To use elevated permissions include the ${BRIGHT_YELLOW}--sudo${RESET} option"
		echo -e "${BRIGHT_WHITE}Usage:${RESET}"
		echo -e "  ${BRIGHT_CYAN}findcode${RESET} ${BRIGHT_YELLOW}[search_text]${RESET}"
		echo -e "${BRIGHT_WHITE}Examples:${RESET}"
		echo -e "  ${BRIGHT_CYAN}findcode${RESET} ${BRIGHT_YELLOW}'function_name'${RESET}"
		echo -e "  ${BRIGHT_CYAN}findcode${RESET} ${BRIGHT_YELLOW}'console\.log\('${RESET} ${BRIGHT_BLUE}(${BRIGHT_MAGENTA}using regex${BRIGHT_BLUE})${RESET}"
		echo -e "  ${BRIGHT_CYAN}findcode${RESET} ${BRIGHT_GREEN}--sudo${RESET} ${BRIGHT_YELLOW}'todo'${RESET}    ${BRIGHT_BLUE}(${BRIGHT_MAGENTA}using sudo${BRIGHT_BLUE})${RESET}"
		return 1
	fi

	# If ripgrep is installed, use that
	# Link: https://github.com/BurntSushi/ripgrep
	if cmd-exists --strict rg; then
		${SUDO_PREFIX}rg --smart-case --no-ignore --hidden --pretty "${@}" -g '!*.min.*' \
			-g '*.{ada,asm,awk,bat,c,cbl,conf,cpp,cpy,cs,css,dart,el,erl,ex,f90,f95,f,for,go,groovy,h,hpp,hrl,htm,html,hx,hxsl,inc,ini,ino,java,js,json,kt,lib,lua,m4,m,mat,mk,nim,nix,pascal,php,pl,plx,py,r,rb,rkt,rlib,rs,sc,scala,scss,sh,sml,sql,swift,tcl,template,tpl,tex,ts,vb,vba,vbs,vhd,vhdl,wren,xml,yaml,yml,zig}' | \
			awk -v len=$LINE_LENGTH_CUTOFF '{ $0=substr($0, 1, len); print $0 }'

	# If The Silver Searcher is installed, use that
	# Link: https://github.com/ggreer/the_silver_searcher
	# Hint: You can use --ignore "dir/or/file"
	elif cmd-exists --strict ag; then
		${SUDO_PREFIX}ag --color             \
			--smart-case       \
			--hidden           \
			--literal          \
			--ignore "*.min.*" \
			--file-search-regex ".*\.(ada|asm|awk|bat|c|cbl|conf|cpp|cpy|cs|css|dart|el|erl|ex|f90|f95|f|for|go|groovy|h|hpp|hrl|htm|html|hx|hxsl|inc|ini|ino|java|js|json|kt|lib|lua|m4|m|mat|mk|nim|nix|pascal|php|pl|plx|py|r|rb|rkt|rlib|rs|sc|scala|scss|sh|sml|sql|swift|tcl|template|tpl|tex|ts|vb|vba|vbs|vhd|vhdl|wren|xml|yaml|yml|zig)" \
			"${@}"             \
			2> /dev/null       \
			| awk -v len=$LINE_LENGTH_CUTOFF '{ $0=substr($0, 1, len); print $0 }'

	# Use grep (see findtext function for options explanation)
	# Hint: You can use --exclude='/dir/or/file'
	else
		${SUDO_PREFIX}grep --color=always --recursive --ignore-case --binary-files=without-match --with-filename --line-number \
			--include=*.ada \
			--include=*.asm \
			--include=*.awk \
			--include=*.bat \
			--include=*.c \
			--include=*.cbl \
			--include=*.conf \
			--include=*.cpp \
			--include=*.cpy \
			--include=*.cs \
			--include=*.css \
			--include=*.dart \
			--include=*.el \
			--include=*.erl \
			--include=*.ex \
			--include=*.f90 \
			--include=*.f95 \
			--include=*.f \
			--include=*.for \
			--include=*.go \
			--include=*.groovy \
			--include=*.h \
			--include=*.hpp \
			--include=*.hrl \
			--include=*.htm \
			--include=*.html \
			--include=*.hx \
			--include=*.hxsl \
			--include=*.inc \
			--include=*.ini \
			--include=*.ino \
			--include=*.java \
			--include=*.js \
			--include=*.json \
			--include=*.kt \
			--include=*.lib \
			--include=*.lua \
			--include=*.m4 \
			--include=*.m \
			--include=*.mat \
			--include=*.mk \
			--include=*.nim \
			--include=*.nix \
			--include=*.pascal \
			--include=*.php \
			--include=*.pl \
			--include=*.plx \
			--include=*.py \
			--include=*.r \
			--include=*.rb \
			--include=*.rkt \
			--include=*.rlib \
			--include=*.rs \
			--include=*.sc \
			--include=*.scala \
			--include=*.scss \
			--include=*.sh \
			--include=*.sml \
			--include=*.sql \
			--include=*.swift \
			--include=*.tcl \
			--include=*.template \
			--include=*.tpl \
			--include=*.tex \
			--include=*.ts \
			--include=*.vb \
			--include=*.vba \
			--include=*.vbs \
			--include=*.vhd \
			--include=*.vhdl \
			--include=*.wren \
			--include=*.xml \
			--include=*.yaml \
			--include=*.yml \
			--include=*.zig \
			--exclude='*.min.*' \
			"${@}" \
			| awk -v len=$LINE_LENGTH_CUTOFF '{ $0=substr($0, 1, len); print $0 }'
	fi
}

# Searches for text in all files in the current folder
function findtext() {
	# Local constant for maximum line length cut-off
	# NOTE: This is necessary for certain files like binaries
	local -r LINE_LENGTH_CUTOFF=1000

	# The prefix to prepend to search commands for elevated permissions
	local SUDO_PREFIX=""

	# Check for --sudo flag and remove it from arguments if present
	if [[ "$1" == "--sudo" ]]; then
		SUDO_PREFIX="sudo "
		shift
	fi

	# If no search text is specified, show help text
	if [ -z "$1" ]; then
		echo -e "${BRIGHT_WHITE}findtext:${RESET} Searches for text in all files recursively"
		echo -e "You can use both ${BRIGHT_YELLOW}plain text${RESET} and ${BRIGHT_YELLOW}regular expressions${RESET} for searching"
		echo -e "To use elevated permissions include the ${BRIGHT_YELLOW}--sudo${RESET} option"
		echo -e "${BRIGHT_WHITE}Usage:${RESET}"
		echo -e "  ${BRIGHT_CYAN}findtext${RESET} ${BRIGHT_YELLOW}[search_text]${RESET}"
		echo -e "${BRIGHT_WHITE}Examples:${RESET}"
		echo -e "  ${BRIGHT_CYAN}findtext${RESET} ${BRIGHT_YELLOW}'example text'${RESET}"
		echo -e "  ${BRIGHT_CYAN}findtext${RESET} ${BRIGHT_YELLOW}'Hello\\s+world\\.'${RESET} ${BRIGHT_BLUE}(${BRIGHT_MAGENTA}using regex${BRIGHT_BLUE})${RESET}"
		echo -e "  ${BRIGHT_CYAN}findtext${RESET} ${BRIGHT_GREEN}--sudo${RESET} ${BRIGHT_YELLOW}'todo'${RESET}     ${BRIGHT_BLUE}(${BRIGHT_MAGENTA}using sudo${BRIGHT_BLUE})${RESET}"
		return 1
	fi

	# If ripgrep is installed, use that
	# Link: https://github.com/BurntSushi/ripgrep
	if cmd-exists --strict rg; then
		echo -e "${BRIGHT_CYAN}Search using ${BRIGHT_YELLOW}ripgrep${BRIGHT_CYAN}:${RESET}"
		echo "${SUDO_PREFIX}rg --smart-case --no-ignore --hidden --pretty '$@' ."
		${SUDO_PREFIX}rg --smart-case --no-ignore --hidden --pretty "$@" .  | \
			awk -v len=$LINE_LENGTH_CUTOFF '{ $0=substr($0, 1, len); print $0 }'

	# If The Silver Searcher is installed, use that
	# Link: https://github.com/ggreer/the_silver_searcher
	# Hint: You can use --ignore "dir/or/file"
	elif cmd-exists --strict ag; then
		echo -e "${BRIGHT_CYAN}Search using ${BRIGHT_YELLOW}The Silver Searcher${BRIGHT_CYAN}:${RESET}"
		echo "${SUDO_PREFIX}ag --color --smart-case --hidden --literal '$@'"
		${SUDO_PREFIX}ag --color --smart-case --hidden --literal "$@" 2> /dev/null | \
			awk -v len=$LINE_LENGTH_CUTOFF '{ $0=substr($0, 1, len); print $0 }'

	else # Use grep
		# Link: https://www.howtogeek.com/496056/how-to-use-the-grep-command-on-linux/
		# Hint: You can use --exclude='/dir/or/file'
		# --ignore-case (-i)        : Makes the search case-insensitive
		# --binary-files=without-match (-I) : Ignores binary files
		# --with-filename (-H)      : Displays the filename along with the matching line
		# --recursive (-r)          : Searches through all subdirectories recursively
		# --line-number (-n)        : Adds the line number to the output
		# Optional:
		# --fixed-strings (-F)      : Treats the search term as a fixed string (not a regular expression)
		# --files-with-matches (-l) : Only outputs the filenames that contain a match (e.g., grep -irl "$@" *)
		echo -e "${BRIGHT_CYAN}Search using ${BRIGHT_YELLOW}grep${BRIGHT_CYAN}:${RESET}"
		echo "${SUDO_PREFIX}grep --color=always --recursive --ignore-case --binary-files=without-match --with-filename --line-number '$@'"
		${SUDO_PREFIX}grep \
			--color=always \
			--recursive \
			--ignore-case \
			--binary-files=without-match \
			--with-filename \
			--line-number \
			"${@}" \
		| awk -v len=${LINE_LENGTH_CUTOFF} '{ $0=substr($0, 1, len); print $0 }'
	fi
}

# Performs case-insensitive text replacement in a file or directory recursively
function replacetext() {
	# Prefix for elevated permissions
	local SUDO_PREFIX=""

	# Check for --sudo flag and remove it from arguments if present
	if [[ "$1" == "--sudo" ]]; then
		SUDO_PREFIX="sudo "
		shift
	fi

	# Handle the optional [file_path] parameter
	local FILE_PATH="$(\pwd)"
	if [[ $# -eq 3 ]]; then
		FILE_PATH=$3
	fi

	# If not enough arguments, show help
	if [[ $# -lt 2 ]]; then
		echo -e "${BRIGHT_WHITE}replacetext:${RESET} Performs case-insensitive text replacement in a file or directory recursively"
		echo -e "To use elevated permissions include the ${BRIGHT_YELLOW}--sudo${RESET} option"
		echo -e "${BRIGHT_WHITE}Usage:${RESET}"
		echo -e "  ${BRIGHT_CYAN}replacetext${RESET} ${BRIGHT_YELLOW}[find-text] [replace-text]${RESET}"
		echo -e "  ${BRIGHT_CYAN}replacetext${RESET} ${BRIGHT_YELLOW}[find-text] [replace-text] [filename]${RESET}"
		echo -e "  ${BRIGHT_CYAN}replacetext${RESET} ${BRIGHT_GREEN}--sudo${RESET} ${BRIGHT_YELLOW}[find-text] [replace-text] [path]${RESET}"
		return 1
	fi

	# Capture the 'find' and 'replace' text
	local FIND_TEXT=$(regexformat "$1")
	local REPLACE_TEXT=$(regexformat "$2")

	# Show safety check and ask for confirmation only for directory operations
	if [[ -d "${FILE_PATH}" ]]; then
		echo -e "${BRIGHT_RED}Warning:${BRIGHT_YELLOW} You are about to recursively operate on the directory ${BRIGHT_CYAN}${FILE_PATH}${RESET}"
		if ! ask "${BRIGHT_MAGENTA}Are you sure?" "N"; then
			echo -e "${BRIGHT_RED}Aborted${RESET}"
			return 1
		fi
	fi

	# Execute the find-and-replace operation
	find "${FILE_PATH}" -type f -exec ${SUDO_PREFIX}sed -i "s/${FIND_TEXT}/${REPLACE_TEXT}/gi" {} +
}

# Enhanced lines function with uppercase variables and improved error messaging
function lines() {
	# Check for minimum required arguments
	if [ $# -lt 2 ]; then
		# Display help message with formatted output for clarity
		echo -e "${BRIGHT_WHITE}lines:${RESET} Display specific lines or line ranges from a file"
		echo -e "${BRIGHT_WHITE}Usage:${RESET}"
		echo -e "  ${BRIGHT_YELLOW}lines${RESET} ${BRIGHT_CYAN}<FILENAME>${RESET} ${BRIGHT_CYAN}<LINE_NUMBER> [OPTIONAL_LINE_NUMBERS...]${RESET}"
		echo -e "${BRIGHT_WHITE}Examples:${RESET}"
		echo -e "  ${BRIGHT_YELLOW}lines${RESET} ${BRIGHT_CYAN}filename.txt${RESET} ${BRIGHT_CYAN}123${RESET}"
		echo -e "  ${BRIGHT_YELLOW}lines${RESET} ${BRIGHT_CYAN}filename.txt${RESET} ${BRIGHT_CYAN}123 456 78${RESET}"
		echo -e "  ${BRIGHT_YELLOW}lines${RESET} ${BRIGHT_CYAN}filename.txt${RESET} ${BRIGHT_CYAN}50-100${RESET}"
		echo -e "  ${BRIGHT_YELLOW}lines${RESET} ${BRIGHT_CYAN}filename.txt${RESET} ${BRIGHT_CYAN}10 20 30-40${RESET}"
		return 1
	fi

	# Assign first argument to FILENAME and shift arguments
	FILENAME="$1"
	shift

	# Check if the specified file exists
	if [ ! -f "$FILENAME" ]; then
		echo -e "${BRIGHT_RED}Error:${RESET} File not found: ${BRIGHT_CYAN}$FILENAME${RESET}"
		return 1
	fi

	# Process each argument
	while [ $# -gt 0 ]; do
		ARG="$1"

		# Handle line range
		if [[ "$ARG" == *-* ]]; then
			# Extract start and end lines from the range
			START_LINE=$(echo "$ARG" | cut -d'-' -f1)
			END_LINE=$(echo "$ARG" | cut -d'-' -f2)

			# Display lines within the specified range using 'sed'
			sed -n "${START_LINE},${END_LINE}p" "$FILENAME"

		else # Handle individual line number
			# Display the specified line using 'sed'
			sed -n "${ARG}p" "$FILENAME"
		fi

		# Shift to the next argument
		shift
	done
}

# Analyzes a given code file to provide statistics
function analyze-code() {
	# Validate input
	if [[ $# -eq 0 ]]; then
		echo -e "${BRIGHT_WHITE}Usage: ${BRIGHT_CYAN}analyze_code${RESET} ${BRIGHT_GREEN}[filename]${RESET}"
		return 1
	fi

	# Check if the file exists and is readable
	local FILE="$1"
	if [[ ! -f ${FILE} ]] || [[ ! -r ${FILE} ]]; then
		echo "Error: File '${FILE}' does not exist or is not readable."
		return 1
	fi

	# Initialize counters and variables
	local TOTAL_LINES=$(wc -l < "${FILE}")
	local NON_COMMENT_LINES=0
	local COMMENT_LINES=0
	local BLANK_LINES=0
	local LONGEST_LINE=0
	local SHORTEST_LINE=999999
	local FILE_SIZE=$(stat -c%s "${FILE}")

	# Process each line
	while IFS= read -r LINE; do
		local LINE_LENGTH=${#LINE}
		[[ $LINE_LENGTH -gt $LONGEST_LINE ]] && LONGEST_LINE=$LINE_LENGTH
		[[ $LINE_LENGTH -lt $SHORTEST_LINE ]] && SHORTEST_LINE=$LINE_LENGTH

		# Count blank lines
		if [[ "$LINE" =~ ^[[:space:]]*$ ]]; then
			((BLANK_LINES++))
		elif [[ "$LINE" =~ ^[[:space:]]*([#]|\/\/) || "$LINE" =~ \/\* || "$LINE" =~ \*\/ ]]; then
			((COMMENT_LINES++))
		else
			((NON_COMMENT_LINES++))
		fi
	done < "$FILE"

	# Calculate percentages based on non-blank lines
	NON_BLANK_TOTAL_LINES=$((TOTAL_LINES - BLANK_LINES))
	NON_COMMENT_PERCENT=$((COMMENT_LINES * 100 / NON_BLANK_TOTAL_LINES))
	NON_BLANK_PERCENT=$((NON_BLANK_TOTAL_LINES * 100 / TOTAL_LINES))
	BLANK_PERCENT=$((BLANK_LINES * 100 / TOTAL_LINES))

	# Calculate indentation using awk
	local METRICS=$(awk '
		BEGIN {
			indentTabs = 0;
			indentSpaces = 0;
		}
		{
			if (match($0, /^[ \t]+/)) {
				indent = substr($0, RSTART, RLENGTH);
				indentTabs += gsub(/\t/, "", indent);
				indentSpaces += gsub(/ /, "", indent);
			}
		}
		END {
			print indentTabs, indentSpaces;
		}' "${FILE}")

	local INDENT_TABS=$(echo ${METRICS} | cut -d' ' -f1)
	local INDENT_SPACES=$(echo ${METRICS} | cut -d' ' -f2)

	local INDENT_TYPE="Unknown"
	[[ ${INDENT_TABS} -gt ${INDENT_SPACES} ]] && INDENT_TYPE="Tabs"
	[[ ${INDENT_SPACES} -gt ${INDENT_TABS} ]] && INDENT_TYPE="Spaces"

	local AVG_LINE_LENGTH=$((TOTAL_LINES ? FILE_SIZE / TOTAL_LINES : 0))

	echo "File Size: ${FILE_SIZE} bytes"
	echo "Total Lines: ${TOTAL_LINES}"
	echo "Longest Line: ${LONGEST_LINE} characters"
	echo "Shortest Line: ${SHORTEST_LINE} characters"
	echo "Average Line Length: ${AVG_LINE_LENGTH} characters"
	echo "Indentation: ${INDENT_TYPE}"
	echo "Non-Comment Lines: ${NON_COMMENT_LINES} ($((NON_COMMENT_LINES * 100 / TOTAL_LINES))%)"
	echo "Comment Lines: ${COMMENT_LINES} ($((COMMENT_LINES * 100 / TOTAL_LINES))%)"
	echo "Blank Lines: ${BLANK_LINES} ($((BLANK_LINES * 100 / TOTAL_LINES))%)"
}

# List and sort all function names from code files (with line numbers)
function get-functions() {
	# Check if a filename is provided
	if [[ -z "${1}" ]]; then
		echo -e "${BRIGHT_WHITE}Usage: ${BRIGHT_CYAN}get-functions${RESET} ${BRIGHT_GREEN}[filename]${RESET}"
		return 1
	fi

	# Perform a grep to find function names and include line numbers
	# Use awk for formatting, filtering comments, and cleaning up
	# Further filter with awk to exclude names that start with '_'
	# Remove leading spaces and sort by function name and then by line number, while also removing duplicates
	grep -n -E '(function[[:space:]]+\w+)|(def[[:space:]]+\w+)|(public[[:space:]]+static[[:space:]]+void[[:space:]]+\w+)|(public[[:space:]]+function[[:space:]]+\w+)' "${1}" | \
	awk -F: '$2 !~ /^[[:space:]]*(#|\/\/)/ { gsub(/^[[:space:]]+/, "", $2); print $1 ":\t" $2 }' | \
	sed -E 's/(function|def|public static void|public function)[[:space:]]+//' | \
	awk -F ':\t' '$2 !~ /^_/ {print $1 ":\t" $2}' | \
	sort -k2,2 -k1,1n | \
	uniq -f 1
}

# Function to copy a file or directory with a progress bar
function cpp() {
	# Check the parameters
	if [[ -z "${1}" ]]; then
		echo "Source is not specified."
		return 1
	fi
	if [[ -z "${2}" ]]; then
		echo "Destination path is not specified."
		return 1
	fi
	if [[ ! -d "${2}" ]]; then
		echo "Destination is not a directory."
		return 1
	fi

	# Check if rsync is available
	if cmd-exists --strict rsync; then
		# Use rsync with archive mode and overall progress bar
		rsync -ah --info=progress2 "${1}" "${2}"
	else
		# If rsync is not available, use strace with cp to show progress
		set -e
		strace -q -ewrite cp -- "${1}" "${2}" 2>&1 \
		| awk '{
		count += $NF
		if (count % 10 == 0) {
			percent = int(count / total_size * 100)
			printf "%3d%% [", percent
			for (i = 0; i <= percent; i++)
				printf "="
				printf ">"
				for (i = percent; i < 100; i++)
					printf " "
					printf "]\r"
				}
			}
		END { print "" }' total_size=$(stat -c '%s' "${1}") count=0
	fi
}

# Function to copy a file and optionally go to the directory
function cpg() {
	# Check the parameters
	if [[ -z "${1}" ]]; then
		echo "Source is not specified."
		return 1
	fi
	if [[ -z "${2}" ]]; then
		echo "Destination is not specified."
		return 1
	fi
	if [[ -d "${2}" ]]; then
		# Destination is a directory, copy the file and go to the directory
		cp "${1}" "${2}" && cd "${2}"
	else
		# Destination is not a directory, just copy the file
		cp "${1}" "${2}"
	fi
}

# Function to move a file or directory and optionally go to the directory
function mvg() {
	# Check the parameters
	if [[ -z "${1}" ]]; then
		echo "Source is not specified."
		return 1
	fi
	if [[ -z "${2}" ]]; then
		echo "Destination path is not specified."
		return 1
	fi

	if [[ -d "${2}" ]]; then
		# Destination is a directory, move the file and go to the directory
		mv "${1}" "${2}" && cd "${2}"
	else
		# Destination is not a directory, just move the file
		mv "${1}" "${2}"
	fi
}

# Function to create and go to the directory
alias md='mkdirg'
function mkdirg() {
	# Check if any arguments are provided
	if [[ $# -eq 0 ]]; then
		# Display usage message and return error code 1
		echo -e "${BRIGHT_WHITE}Usage: ${BRIGHT_CYAN}mkdirg${RESET} ${BRIGHT_GREEN}[directory]${RESET}"
		return 1
	fi

	# Verify if the directory already exists
	if [ -d "$1" ]; then
		# Directory exists, change into it
		cd "$1"
	else
		# Directory doesn't exist, create it and change into it
		\mkdir -p "$1"
		cd "$1"
	fi
}

# Repeats a given command a specified number of times
function repeat() {
	# Check that at least two arguments are provided (number and command)
	if [[ $# -lt 2 ]]; then
		# Display usage message and return error code 1
		echo -e "${BRIGHT_WHITE}Usage: ${BRIGHT_CYAN}repeat${RESET} ${BRIGHT_GREEN}[count] [command]${RESET}"
		return 1
	fi

	# Check that the first argument is a non-negative integer
	if ! [[ $1 =~ ^[0-9]+$ ]]; then
		# Display error message for invalid count
		echo "Error: The count must be a non-negative integer."
		return 1
	fi

	# Assign the provided count to maxCount and shift to remove it from arguments
	local count maxCount
	maxCount=$1; shift
	for ((count = 1; count <= maxCount; count++)); do
		# Execute the provided command using eval
		eval "$@"
	done
}

# Goes up a specified number of directories (i.e. up 4)
# If no argument is provided, it goes up by one directory
function up() {
	# Declare a variable to build the directory path
	local directory_path=""

	# Set the number of levels to go up - default to 1 if not provided
	local levels_to_go_up=${1:-1}

	# Loop from 1 to the number of levels to go up
	for ((i=1; i <= levels_to_go_up; i++)); do
		# Append "../" to the directory path for each iteration
		directory_path="../$directory_path"
	done

	# Change to the built directory path
	cd "$directory_path"
}

# Returns the last 2 fields of the working directory
function pwdtail() {
	pwd | awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}

# Encryption has been changed to gpg from SSL due to security
# Link: https://stackoverflow.com/questions/28247821/openssl-vs-gpg-for-encrypting-off-site-backups
# Install: pkginstall gnupg # gpg2 on SUSE
if cmd-exists --strict gpg; then
	## Uses OpenSSL AES 256bit Cipher Block Chaining Encryption to encrypt a file
	function encrypt() {
		if [[ "${#}" -lt 1 ]] || [[ "${1}" = "--help" ]] || [[ "${1}" = "-h" ]]; then
			echo -e "${BRIGHT_WHITE}Usage: ${BRIGHT_CYAN}encrypt${RESET} ${BRIGHT_GREEN}[input_file]${RESET} ${BRIGHT_MAGENTA}(output file will end in .gpg)${RESET}"
			return
		elif [[ ! -r "${1}" ]]; then
			echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}File ${BRIGHT_YELLOW}${1}${BRIGHT_CYAN} not found${RESET}"
			return 1
		fi
		echo "Encrypting ${1}..."
		# equivalents in the gpg.conf file
		# s2k-mode 3
		# s2k-count 65011712
		# s2k-digest-algo SHA512
		# s2k-cipher-algo AES256
		gpg --s2k-mode 3 --s2k-count 65011712 --s2k-digest-algo SHA512 --s2k-cipher-algo AES256 --symmetric "${1}"
		echo -e "${BRIGHT_GREEN}File ${_encrypted_file} successfully encrypted${RESET}"
	}

	## Uses OpenSSL AES 256bit Cipher Block Chaining Encryption to decrypt a file
	function decrypt() {
		if [[ "${#}" -lt 1 ]] || [[ "${1}" = "--help" ]] || [[ "${1}" = "-h" ]]; then
			echo -e "${BRIGHT_WHITE}Usage: ${BRIGHT_CYAN}decrypt${RESET} ${BRIGHT_GREEN}[encrypted_file.gpg]${RESET}"
			return
		elif [[ ! -r "${1}" ]]; then
			echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}File ${BRIGHT_YELLOW}${1}${BRIGHT_CYAN} not found${RESET}"
			return 1
		fi
		echo "Decrypting ${1}..."
		if gpg "${1}" ; then
			echo -e "${BRIGHT_GREEN}File successfully decrypted${RESET}"
		else
			echo -e "${BRIGHT_RED}Error decrypting ${BRIGHT_YELLOW}${1}${RESET}"
		fi
	}
fi

# Print a list of colors
function colors() {
	# Define variables for foreground, background, values, and sequence
	local foreground background values sequence

	# Print introductory information about color escapes and styles
	printf "Color escapes are %s\n" '\033[${value};...;${value}m'
	printf "Values 30..37 are \033[33mforeground colors\033[m\n"
	printf "Values 40..47 are \033[43mbackground colors\033[m\n"
	printf "Value 1 gives a  \033[1mbold-faced look\033[m\n\n"

	# Iterate through foreground colors (values 30 to 37)
	for foreground in {30..37}; do
		# Iterate through background colors (values 40 to 47)
		for background in {40..47}; do
			# Extract color names from numerical values
			foreground=${foreground#37} # white
			background=${background#40} # black

			# Construct values string for color escape sequences
			values="${foreground:+$foreground;}${background}"
			values=${values%%;}

			# Construct escape sequence for color styling
			sequence="${values:+\033[${values}m}"

			# Print formatted color examples
			printf " %-9s" "${sequence:-(default)}"
			printf " ${sequence}TEXT\033[m"
			printf " \033[${values:+${values+$values;}}1mBOLD\033[m"
		done
		echo; echo
	done
}

# Print a list of 256 colors
function colors256() {
	# Define the number of colors per line
	colors_per_line=8

	for i in {0..255}; do
		printf "\x1b[38;5;${i}mcolor%-5d" "$i"

		# Check if the current color is the last in the line
		if (( (i + 1) % colors_per_line == 0 )); then
			echo # Move to the next line
		fi
	done
	# Add a final newline if needed
	if ((255 % colors_per_line != 0)); then
		echo
	fi
}

# Test for 24bit true color in the terminal
function colors24bit() {
	echo 'If the gradients are smooth, you are displaying 24bit true color.'
	awk 'BEGIN{
		# Generate a long string of characters for testing
		s = "1234567890";
		s = s s s s s s s s s s s s s s s s s s s s s s s s; # Extended string
		len = length(s); # Length of the string

		# Generate and display color gradients
		for (colnum = 0; colnum < 256; colnum++) {
			r = 255 - (colnum * 255 / 255);
			g = (colnum * 510 / 255);
			b = (colnum * 255 / 255);
			if (g > 255) g = 510 - g;

			# Set background and foreground colors using ANSI escape sequences
			printf "\033[48;2;%d;%d;%dm", r, g, b; # Background color
			printf "\033[38;2;%d;%d;%dm", 255 - r, 255 - g, 255 - b; # Foreground color

			# Display a character with the defined colors and reset formatting
			printf "%s\033[0m", substr(s, (colnum % len) + 1, 1);
		}
		printf "\n"; # Move to the next line after printing colors
	}'
}

# Prints random height bars across the width of the screen
# (great with lolcat application on new terminal windows)
function sparkbars() {
	columns=$(tput cols)
	chars=▁▂▃▄▅▆▇█
	for ((i = 1; i <= $columns; i++))
	do
		echo -n "${chars:RANDOM%${#chars}:1}"
	done
	echo
}

# View Apache logs
function apachelog() {
	if [ -d /var/log/httpd ]; then
		sudo \ls -Ah /var/log/httpd && sudo logview "/var/log/httpd/*_log"
	else
		sudo \ls -Ah /var/log/apache2 && sudo logview "/var/log/apache2/*.log"
	fi
}

# Auto-find and edit the Apache configuration
function apacheconfig() {
	if cmd-exists --strict httpd || cmd-exists --strict apache2 || cmd-exists --strict apachectl; then
		# Define an array with common paths
		declare -a paths=(
			"/etc/httpd/conf/httpd.conf"
			"/etc/httpd/httpd.conf"
			"/etc/apache2/apache2.conf"
			"/usr/local/apache2/apache2.conf"
			"/usr/local/etc/httpd/httpd.conf"
		)

		# Check if a custom path is provided
		[[ -n "$1" ]] && paths=("$1")
		for path in "${paths[@]}"; do
			if [[ -f $path ]]; then
				edit "$path"
				return 0
			fi
		done

		echo "Error: Apache config file could not be found."
		echo "Searching for possible locations:"
		httpd -V 2> /dev/null || apachectl -V 2> /dev/null || apache2 -V
	else
		echo "Apache is not installed."
	fi
}

# Find the Apache service and restart/start it
function apacherestart() {
	# If we are using Systemd...
	if cmd-exists --strict systemctl; then
		if cmd-exists --strict httpd; then
			sudo systemctl restart httpd
		elif cmd-exists --strict apache2; then
			sudo systemctl restart apache2
		else
			echo 'Error: Could not find Apache service name'
			return 1
		fi

	# If using init.d...
	elif [[ -x /etc/init.d ]]; then
		if [[ -f /etc/init.d/httpd ]]; then
			sudo /etc/init.d/httpd restart
		elif [[ -f /etc/init.d/apache2 ]]; then
			sudo /etc/init.d/apache2 restart
		else
			echo 'Error: Could not find Apache service name'
			return 1
		fi

	# Other systems including OpenRC...
	elif cmd-exists --strict service; then
		if cmd-exists --strict httpd; then
			sudo service httpd restart
		elif cmd-exists --strict apache2; then
			sudo service apache2 restart
		else
			echo 'Error: Could not find Apache service name'
			return 1
		fi

	else # Unknown
		echo 'Error: Could not find service controller'
		return 1
	fi
}

# Auto-find and edit the Nginx configuration
function ngconfig() {
	if cmd-exists --strict nginx; then
		# Define an array with common paths
		declare -a paths=(
			"/etc/nginx/nginx.conf"
			"/usr/local/nginx/conf/nginx.conf"
			"/usr/local/etc/nginx/nginx.conf"
		)

		# Check if a custom path is provided
		[[ -n "$1" ]] && paths=("$1")

		for path in "${paths[@]}"; do
			if [[ -f $path ]]; then
				edit "$path"
				return 0
			fi
		done

		echo "Error: Nginx config file could not be found."
		echo "Please specify the location manually, or check your Nginx installation."
	else
		echo "Nginx is not installed."
	fi
}

# Find the Nginx service and restart/start it
function ngrestart() {
	# If we are using Systemd...
	if cmd-exists --strict systemctl; then
		# Check if Nginx executable is available
		if cmd-exists --strict nginx; then
			sudo systemctl restart nginx
			sudo nginx -t
		else
			echo 'Error: Could not find Nginx service name'
			return 1
		fi

	# If using init.d...
	elif [[ -x /etc/init.d ]]; then
		# Check if Nginx init script exists
		if [[ -f /etc/init.d/nginx ]]; then
			sudo /etc/init.d/nginx restart
		else
			echo 'Error: Could not find Nginx service name'
			return 1
		fi

	# Other systems including OpenRC...
	elif cmd-exists --strict service; then
		# Check if Nginx executable is available
		if cmd-exists --strict nginx; then
			sudo service nginx restart
		else
			echo 'Error: Could not find Nginx service name'
			return 1
		fi

	else # Unknown
		echo 'Error: Could not find service controller'
		return 1
	fi
}

# Check the syntax of a PHP file for errors
function phpcheck() {
	if [ $# -eq 0 ]; then
		echo -e "${BRIGHT_RED}ERROR: ${BRIGHT_CYAN}You must specify a PHP file${RESET}"
		return 1
	fi
	echo -e "${BRIGHT_RED}[${BRIGHT_CYAN}PHP Check${BRIGHT_RED}]${BRIGHT_YELLOW}->${BRIGHT_GREEN}${1}${RESET}"
	php -l "${1}"
}

# Auto-find and edit the PHP configuration file
function phpconfig() {
	if cmd-exists --strict php; then
		local _php_ini_file=$(php -r 'echo php_ini_loaded_file();')
		if [[ -f "${_php_ini_file}" ]]; then
			echo "Found: ${_php_ini_file}"
			edit "${_php_ini_file}"
		elif [[ -f /etc/php.ini ]]; then
			echo "Found: /etc/php.ini"
			edit /etc/php.ini
		elif [[ -f /etc/php/php.ini ]]; then
			echo "Found: /etc/php/php.ini"
			edit /etc/php/php.ini
		else
			echo "Error: php.ini file could not be found automatically."
			echo "Searching for possible locations:"
			# sudo updatedb && locate php.ini
			php --ini
		fi
	else
		echo "PHP is not installed."
	fi
}

# Auto-find and edit the MySQL configuration file
function mysqlconfig() {
	if cmd-exists --strict mysqld; then
		if [[ -f /etc/my.cnf ]]; then
			edit /etc/my.cnf
		elif [[ -f /etc/mysql/my.cnf ]]; then
			edit /etc/mysql/my.cnf
		elif [[ -f /usr/local/etc/my.cnf ]]; then
			edit /usr/local/etc/my.cnf
		elif [[ -f /usr/bin/mysql/my.cnf ]]; then
			edit /usr/bin/mysql/my.cnf
		elif [[ -f "$HOME/my.cnf" ]]; then
			edit "$HOME/my.cnf"
		else
			echo "Error: my.cnf file could not be found automatically."
			echo "Searching for possible locations:"
			# sudo updatedb && locate my.cnf
			mysqld --verbose --help | grep -A 1 "Default options"
		fi
	else
		echo "MySQL is not installed."
	fi
}

# Determine if a system reboot is required
function checkreboot() {
	# Initialize a variable to indicate if a reboot is required
	local reboot_required=0

	# Check if pacman exists (indicative of an Arch-based system)
	if command -v pacman &> /dev/null; then

		# Normalize running kernel version string
		local active_kernel=$(uname -r | tr '-' '.')

		# Query the current kernel version from installed packages
		local current_kernel=$(pacman -Q | grep '^linux[0-9]* ' | awk '{print $2}' | sort -V | tail -n1)

		# Normalize current kernel version string
		current_kernel=${current_kernel//-/.}

		# Compare running and installed kernel versions
		if [[ ${active_kernel} != ${current_kernel} ]]; then
			echo -e "${BRIGHT_RED}->${RESET} ${BRIGHT_CYAN}Arch Linux${RESET}: ${BRIGHT_YELLOW}Running kernel (${active_kernel}) does not match the boot kernel (${current_kernel}).${RESET}"
			reboot_required=1
		fi

	# Use cmd-exists to check if rpm exists (indicative of a RedHat-based system like CentOS)
	elif cmd-exists --strict rpm; then
		if ! rpm -q kernel | grep -q $(uname -r); then
			echo -e "${BRIGHT_RED}->${RESET} ${BRIGHT_CYAN}Red Hat Linux${RESET}: ${BRIGHT_YELLOW}Kernel update detected. A reboot is required.${RESET}"
			reboot_required=1
		fi

	# Check for the existence of /var/run/reboot-required (indicative of Ubuntu/Debian)
	elif [[ -f /var/run/reboot-required ]]; then
		# If the file exists, a reboot is required
		echo -e "${BRIGHT_RED}->${RESET} ${BRIGHT_CYAN}Ubuntu/Debian${RESET}: ${BRIGHT_YELLOW}A reboot is required.${RESET}"
		reboot_required=1

	# Check if zypper exists (indicative of a SUSE-based system)
	elif command -v zypper &> /dev/null; then
		if zypper ps -s | grep -q 'yes'; then
			echo -e "${BRIGHT_RED}->${RESET} ${BRIGHT_CYAN}SUSE${RESET}: ${BRIGHT_YELLOW}Kernel or service update detected. A reboot is required.${RESET}"
			reboot_required=1
		fi
	fi

	# General: Check for deleted libraries still in use
	local libs=$(lsof -n +c 0 2> /dev/null | grep 'DEL.*lib' | awk '{print $1 ": " $NF}' | sort -u)
	if [[ -n ${libs} ]]; then
		echo -e "${BRIGHT_RED}->${RESET} ${BRIGHT_CYAN}General${RESET}: ${BRIGHT_YELLOW}The following libraries require a reboot:${RESET}"
		echo "${libs}"
		reboot_required=1
	fi

	# Final message and exit code
	if [[ ${reboot_required} -eq 0 ]]; then
		echo -e "${BRIGHT_RED}->${RESET} ${BRIGHT_CYAN}Results${RESET}: ${BRIGHT_GREEN}No reboot is required.${RESET}"
		return 0
	else
		echo -e "${BRIGHT_RED}->${RESET} ${BRIGHT_CYAN}Results${RESET}: ${BRIGHT_YELLOW}A reboot is required.${RESET}"
		return 1
	fi
}

# Interactively create, configure, and test a new Linux user
function createuser() {
	sudo true
	local username

	# Check if a username was passed as a parameter
	if [ "$#" -eq 1 ]; then
		username="$1"
	else
		read -r -p $'${BRIGHT_CYAN}Enter the username for the new user:${RESET} ' username
	fi

	# Check if the user already exists
	if id "${username}" &>/dev/null; then
		echo -e "${BRIGHT_RED}User ${username} already exists. Aborting.${RESET}"
		return 1
	fi

	# Confirm if the user should be created with a home directory
	if ask "${BRIGHT_GREEN}Create a new user with a home folder?${RESET}" N; then
		sudo useradd -m "${username}"
	else
		echo -e "${BRIGHT_RED}User creation aborted.${RESET}"
		return 1
	fi

	# Set the user's password
	echo -e "${BRIGHT_YELLOW}\nSet the user's password:${RESET}"
	sudo passwd "${username}"

	# Ask if the user should change their password upon next login
	if ask "${BRIGHT_GREEN}Force user to change password on next login?${RESET}" N; then
		sudo passwd -e "${username}"
	else
		echo -e "${BRIGHT_YELLOW}No change password enforced.${RESET}"
	fi

	# Ask if the user should have root (sudo) access
	if ask "${BRIGHT_MAGENTA}⚠️ Give user root access? ⚠️${RESET}" N; then
		sudo usermod -a -G sudo "${username}"
	else
		echo -e "${BRIGHT_YELLOW}No root access granted.${RESET}"
	fi

	# Change the user's login shell to bash
	echo -e "${BRIGHT_CYAN}\nChange user’s login shell to bash${RESET}"
	sudo usermod --shell /bin/bash "${username}"

	# Verify the user's settings
	echo -e "${BRIGHT_YELLOW}\nVerifying user settings:${RESET}"
	sudo grep "${username}" /etc/passwd

	# Ask if you should copy over the local .bashrc to the new user
	if ask "${BRIGHT_GREEN}Copy over your local .bashrc?${RESET}" N; then
		sudo cp ~/.bashrc /home/"${username}"/
		sudo chown "${username}":"${username}" /home/"${username}"/.bashrc
		sudo chmod 644 /home/"${username}"/.bashrc
	else
		echo -e "${BRIGHT_YELLOW}No .bashrc copy.${RESET}"
	fi

	# Test login with the new user
	if ask "${BRIGHT_GREEN}⚠️ Test a login as this user? ⚠️${RESET}" N; then
		echo -e "${BRIGHT_CYAN}\nTesting: Logging in as ${username}${RESET}"
		sudo su - "${username}"
	fi
}

# Remove a user from the system
alias deleteuser='sudo userdel'
function wipeuser() {
	local username="$1"

	# If username is not provided, get the list of users and use createmenu
	if [[ -z "${username}" ]]; then
		echo -e "${BRIGHT_CYAN}Select a user to delete:${RESET}"
		username=$(sudo awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | createmenu)
	fi

	# If username is still empty (e.g. if the user cancels the menu selection), exit
	if [[ -z "${username}" ]]; then
		echo -e "${BRIGHT_RED}No user selected. Aborting.${RESET}"
		return 1

	# Check against this being the current user
	elif [[ "${username}" == "${USER}" ]]; then
		echo -e "${BRIGHT_RED}You cannot remove the currently logged-in user. Aborting.${RESET}"
		return 1
	fi

	# Check if the user exists
	if id "${username}" &>/dev/null; then

		# Confirm deletion
		if ask "${BRIGHT_RED}⚠️ Are you sure you want to delete user ${username} and all their data? ⚠️ This action cannot be undone! ⚠️${RESET}" N; then

			# Kill all processes by the user
			sudo pkill -U "${username}"

			# Remove the user and their home directory
			sudo userdel -rf "${username}"

			# Remove the user from any additional groups
			sudo delgroup "${username}" &>/dev/null

			echo -e "${BRIGHT_GREEN}User ${username} and their home directory have been deleted.${RESET}"
		else
			echo -e "${BRIGHT_YELLOW}User deletion aborted.${RESET}"
		fi
	else
		echo -e "${BRIGHT_RED}User ${username} does not exist.${RESET}"
	fi
}

# A full chmod calculator on command line (type chmodcalc for usage and examples)
function chmodcalc() {
	# Validate the number of arguments
	if [ "$#" -eq 1 ]; then
		# Validate the length of the argument
		if [ "${#1}" -ge 4 ]; then
			echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}Invalid octal.${RESET}"
			return 128
		fi

		local text="$1"
		local output=""
		local example=""
		local i=0

		while (( i++ < ${#text} )); do
			# Extract individual octal digit
			local char=$(expr substr "${text}" "${i}" 1)

			# Map octal digit to permissions
			case $char in
			0) part[${i}]="---" ;;
			1) part[${i}]="--x" ;;
			2) part[${i}]="-w-" ;;
			3) part[${i}]="-wx" ;;
			4) part[${i}]="r--" ;;
			5) part[${i}]="r-x" ;;
			6) part[${i}]="rw-" ;;
			7) part[${i}]="rwx" ;;
			*)
				echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}Invalid octal digit at position ${BRIGHT_YELLOW}${i}${RESET}"
				return 128
				;;
			esac

			# Create example representation
			example[${i}]="${part[${i}]//-}"
		done

		# Display formatted output and examples
		echo -e "${BRIGHT_GREEN}${part[1]}${RESET} ${BRIGHT_YELLOW}${part[2]}${RESET} ${BRIGHT_RED}${part[3]}${RESET}"
		echo -e "Examples:"
		echo -e "${BRIGHT_CYAN}chmod${RESET} ${BRIGHT_CYAN}-R${RESET} ${BRIGHT_MAGENTA}${text}${RESET} ${BRIGHT_BLUE}./*${RESET}"
		echo -e "${BRIGHT_CYAN}chmod${RESET} ${BRIGHT_CYAN}-R${RESET} ${BRIGHT_CYAN}u=${BRIGHT_GREEN}${example[1]}${RESET}${BRIGHT_CYAN},g=${BRIGHT_YELLOW}${example[2]}${RESET}${BRIGHT_CYAN},o=${BRIGHT_RED}${example[3]}${RESET} ${BRIGHT_BLUE}./*${RESET}"

	elif [ "$#" -eq 3 ]; then
		local formatted=""
		for p in "$@"; do
			local n=0
			[[ $p =~ .*r.* ]] && (( n+=4 ))
			[[ $p =~ .*w.* ]] && (( n+=2 ))
			[[ $p =~ .*x.* ]] && (( n+=1 ))
			formatted="${formatted}${n}"
		done
		echo -e "${BRIGHT_CYAN}${formatted}${RESET}"
		chmodcalc "${formatted}"

	else
		echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}1 or 3 parameters required.${RESET}"
		echo -e "Syntax: ${BRIGHT_CYAN}chmodcalc${RESET} ${BRIGHT_GREEN}[owner]${RESET} ${BRIGHT_YELLOW}[group]${RESET} ${BRIGHT_RED}[other]${RESET}"
		echo -e "Example: ${BRIGHT_GREEN}chmodcalc${RESET} ${BRIGHT_GREEN}rwx${RESET} ${BRIGHT_YELLOW}rw${RESET} ${BRIGHT_RED}r${RESET}"
		echo -e "Syntax: ${BRIGHT_CYAN}chmodcalc [octal]${RESET}"
		echo -e "Example: ${BRIGHT_GREEN}chmodcalc 777${RESET}"
		echo -e "You can also use symbols instead of numeric values with chmod"
		echo -e "${BRIGHT_BLUE}chmod u=rwx,g=rw,o=r filename.ext${RESET}"
		echo -e "To calculate octals: ${BRIGHT_BLUE}read${RESET} is ${BRIGHT_CYAN}4${RESET}, ${BRIGHT_BLUE}write${RESET} is ${BRIGHT_CYAN}2${RESET}, and ${BRIGHT_BLUE}execute${RESET} is ${BRIGHT_CYAN}1${RESET}"
	fi
}

# Function to recursively set permissions for only files
function chmodfiles() {
	# Initialize local variables
	local _DIRECTORY="${2:-${PWD}}" # Default to current directory if no directory is provided
	local _PERMISSION="$1"          # The permission mode to be set

	# Check for missing permission parameter
	if [ -z "${_PERMISSION}" ]; then
		echo -e "${BRIGHT_WHITE}chmodfiles:${RESET} Sets permissions for files recursively"
		echo -e "${BRIGHT_WHITE}Syntax:${RESET}"
		echo -e "  ${BRIGHT_CYAN}chmodfiles${RESET} ${BRIGHT_YELLOW}[mode]${RESET} ${BRIGHT_GREEN}[optional_folder]${RESET}"
		echo -e "${BRIGHT_WHITE}Example:${RESET}"
		echo -e "  ${BRIGHT_CYAN}chmodfiles${RESET} ${BRIGHT_YELLOW}664${RESET}"
		echo -e "  ${BRIGHT_CYAN}chmodfiles${RESET} ${BRIGHT_YELLOW}+x${RESET} ${BRIGHT_GREEN}/some/path${RESET}"
		return 1
	fi

	# Check if the specified directory exists
	if [ ! -d "${_DIRECTORY}" ]; then
		echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}Directory ${BRIGHT_YELLOW}${_DIRECTORY}${BRIGHT_CYAN} not found${RESET}"
		return 2
	fi

	# Ask the user if sudo should be used for the operation
	local SUDO_PREFIX=''
	if ask "${BRIGHT_CYAN}Use administrator priveledges for this operation?${RESET}" N; then
		SUDO_PREFIX='sudo '
	fi

	# Ask for confirmation
	if ask "${BRIGHT_CYAN}Are you sure you want to change file permissions in ${BRIGHT_YELLOW}${_DIRECTORY}${BRIGHT_CYAN}?${RESET}" N; then
		# Change permissions for files recursively
		${SUDO_PREFIX}find "${_DIRECTORY}" -type f -exec ${SUDO_PREFIX}chmod "${_PERMISSION}" {} \;
		echo -e "${BRIGHT_GREEN}Permissions set for files in ${BRIGHT_YELLOW}${_DIRECTORY}${RESET}"
	else
		echo -e "${BRIGHT_RED}Operation canceled${RESET}"
	fi
}

# Function to recursively set permissions for only directories
alias chmoddirectories='chmoddirs'
alias chmodfolders='chmoddirs'
function chmoddirs() {
	# Initialize local variables
	local _DIRECTORY="${2:-${PWD}}" # Default to current directory if no directory is provided
	local _PERMISSION="$1"          # The permission mode to be set

	# Check for missing permission parameter
	if [ -z "${_PERMISSION}" ]; then
		echo -e "${BRIGHT_WHITE}chmoddirs:${RESET} Sets permissions for directories recursively"
		echo -e "${BRIGHT_WHITE}Syntax:${RESET}"
		echo -e "  ${BRIGHT_CYAN}chmoddirs${RESET} ${BRIGHT_YELLOW}[mode]${RESET} ${BRIGHT_GREEN}[optional folder]${RESET}"
		echo -e "${BRIGHT_WHITE}Example:${RESET}"
		echo -e "  ${BRIGHT_CYAN}chmoddirs${RESET} ${BRIGHT_YELLOW}775${RESET}"
		echo -e "  ${BRIGHT_CYAN}chmoddirs${RESET} ${BRIGHT_YELLOW}+x${RESET} ${BRIGHT_GREEN}/some/path${RESET}"
		return 1
	fi

	# Check if the specified directory exists
	if [ ! -d "${_DIRECTORY}" ]; then
		echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}Directory ${BRIGHT_YELLOW}${_DIRECTORY}${BRIGHT_CYAN} not found${RESET}"
		return 2
	fi

	# Ask the user if sudo should be used for the operation
	local SUDO_PREFIX=''
	if ask "${BRIGHT_CYAN}Use administrator priveledges for this operation?${RESET}" N; then
		SUDO_PREFIX='sudo '
	fi

	# Confirm the action before proceeding
	if ask "${BRIGHT_CYAN}Are you sure you want to change directory permissions in ${BRIGHT_YELLOW}${_DIRECTORY}${BRIGHT_CYAN}?${RESET}" N; then
		# Change permissions for directories recursively
		${SUDO_PREFIX}find "${_DIRECTORY}" -type d -name \* -exec ${SUDO_PREFIX}chmod "${_PERMISSION}" {} \;
		echo -e "${BRIGHT_GREEN}Permissions set for directories in ${BRIGHT_YELLOW}${_DIRECTORY}${RESET}"
	else
		echo -e "${BRIGHT_RED}Operation canceled${RESET}"
	fi
}

# Recursively set permissions of code files and directories
# WARNING: Will add execute permissions to .sh files!
function chfix() {
	# Check if -h or --help is provided in any parameter using regex
	if [[ "${@}" =~ "-h" ]] || [[ "${@}" =~ "--help" ]]; then
		echo -e "${BRIGHT_WHITE}chfix:${RESET} Sets permissions and optionally changes ownership for files and directories recursively"
		echo -e "${BRIGHT_WHITE}Syntax:${RESET}"
		echo -e "  ${BRIGHT_CYAN}chfix${RESET} ${BRIGHT_YELLOW}[file_permissions] [dir_permissions]${RESET} ${BRIGHT_GREEN}[optional_owner] [optional_directory]${RESET}"
		echo -e "${BRIGHT_WHITE}Examples:${RESET}"
		echo -e "  ${BRIGHT_CYAN}chfix${RESET}"
		echo -e "  ${BRIGHT_CYAN}chfix${RESET} ${BRIGHT_YELLOW}664 775${RESET}"
		echo -e "  ${BRIGHT_CYAN}chfix${RESET} ${BRIGHT_YELLOW}644 755${RESET} ${BRIGHT_GREEN}www-data${RESET}"
		echo -e "  ${BRIGHT_CYAN}chfix${RESET} ${BRIGHT_YELLOW}664 775${RESET} ${BRIGHT_GREEN}www-data:developer /var/www${RESET}"
		return 1
	fi

	# Initialize variables with default values or passed arguments
	# Write access is also given to the group (e.g. for a group of developers)
	local FILE_PERMISSIONS="${1:-0664}" # Default to User:rw  Group:rw  Other:r
	local DIR_PERMISSIONS="${2:-0775}"  # Default to User:rwx Group:rwx Other:rx
	local OWNER="${3:-}"                # Optional owner
	local DIRECTORY="${4:-${PWD}}"      # Default to current directory

	# Check if the specified directory exists
	if [ ! -d "${DIRECTORY}" ]; then
		echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}Directory ${BRIGHT_YELLOW}${DIRECTORY}${BRIGHT_CYAN} not found${RESET}"
		return 2
	fi

	# Ask the user if sudo should be used for the operation
	local SUDO_PREFIX=''
	if ask "${BRIGHT_CYAN}Use administrator privileges for this operation?${RESET}" N; then
		SUDO_PREFIX='sudo '
	fi

	# Confirm the action
	if ask "${BRIGHT_CYAN}This will change all permissions and optionally ownership for directories and files in ${BRIGHT_YELLOW}${DIRECTORY}${RESET}. Are you sure?${RESET}" N; then
		# Change permissions
		${SUDO_PREFIX}find "${DIRECTORY}" -type f -exec ${SUDO_PREFIX}chmod "${FILE_PERMISSIONS}" {} \;
		${SUDO_PREFIX}find "${DIRECTORY}" -type d -exec ${SUDO_PREFIX}chmod "${DIR_PERMISSIONS}" {} \;

		# Add execute permissions to .sh files
		${SUDO_PREFIX}find "${DIRECTORY}" -type f -name "*.sh" -exec ${SUDO_PREFIX}chmod +x {} \;

		# Change ownership if OWNER is specified
		[ -n "${OWNER}" ] && ${SUDO_PREFIX}chown -R "${OWNER}" "${DIRECTORY}"
		echo -e "${BRIGHT_GREEN}Permissions and ownership set for ${BRIGHT_YELLOW}${DIRECTORY}${RESET}"
	fi
}

# Copy/clone file permissions
function chmodcopy() {
	# Check if at least two arguments are provided (source and destination)
	if [ $# -lt 2 ]; then
		# Display usage information if the required arguments are not provided
		echo -e "${BRIGHT_WHITE}Usage:${RESET} ${BRIGHT_CYAN}chmodcopy${RESET} ${BRIGHT_GREEN}[source_file]${RESET} ${BRIGHT_YELLOW}[destination_file]${RESET} ${BRIGHT_CYAN}[additional_optional_chmod_parameters]${RESET}"
		return 1
	fi

	# Prompt the user to confirm if they want tu use administrator privileges
	local SUDO_PREFIX=''
	if ask "${BRIGHT_CYAN}Use administrator privileges for this operation?${RESET}" N; then
		SUDO_PREFIX='sudo '
	fi

	# Execute the chmod command with --reference option
	${SUDO_PREFIX}chmod --reference="${@}"
	echo -e "${BRIGHT_GREEN}Permissions copied${RESET}"
}

# Improved terminal clipboard management for viewing, setting, and
# clearing content, with support for piping input and output.
function clipboard() {
	# Help message
	if [[ "$1" == "--help" || "$1" == "-h" ]]; then
		echo -e "${BRIGHT_WHITE}clipboard:${RESET} Improved terminal clipboard management for viewing, setting, and clearing content with support for piping input and output"
		echo -e "${BRIGHT_WHITE}Usage:${RESET}"
		echo -e "  ${BRIGHT_YELLOW}some_command${RESET} | ${BRIGHT_CYAN}clipboard${RESET}  # Put some_command's output into clipboard"
		echo -e "  ${BRIGHT_CYAN}clipboard${RESET} ${BRIGHT_YELLOW}'text'${RESET}          # Copy 'text' into clipboard"
		echo -e "  ${BRIGHT_CYAN}clipboard${RESET} | ${BRIGHT_YELLOW}some_command${RESET}  # Pipe clipboard's content into some_command"
		echo -e "${BRIGHT_WHITE}Examples:${RESET}"
		echo -e "  ${BRIGHT_YELLOW}cat file${RESET} | ${BRIGHT_CYAN}clipboard${RESET}      # Copy file's content into clipboard"
		echo -e "  ${BRIGHT_CYAN}clipboard${RESET} | ${BRIGHT_YELLOW}less${RESET}          # Paste clipboard's content into 'less'"
		return
	fi

	# Local variables
	local clipboard_content=""      # Content for clipboard
	local send_to_clipboard=false   # Flag if content needs to be sent to clipboard

	# If we are logged in via SSH...
	if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
		# No local clipboard access in SSH
		return
	# Determine if text is passed as a parameter
	elif [[ -n "${1}" ]]; then
		clipboard_content="${1}"
		send_to_clipboard=true
	# Determine if content is piped to clipboard
	elif [[ -p /dev/stdin ]]; then
		clipboard_content=$(cat -)
		send_to_clipboard=true
	fi

	# Handle content that needs to be sent to clipboard
	if $send_to_clipboard; then
		if [[ "$OSTYPE" == "darwin"* ]]; then
			# macOS
			echo -n "${clipboard_content}" | pbcopy
		elif cmd-exists --strict wl-copy && [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
			# Wayland
			echo -n "${clipboard_content}" | wl-copy
		elif cmd-exists --strict xclip; then
			# X11 - xclip
			echo -n "${clipboard_content}" | xclip -selection clipboard
		elif cmd-exists --strict xsel; then
			# X11 - xsel
			echo -n "${clipboard_content}" | xsel -ib
		fi
	else
		# Handle content that needs to be pasted from clipboard
		if [[ "$OSTYPE" == "darwin"* ]]; then
			# macOS
			pbpaste
		elif cmd-exists --strict wl-paste && [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
			# Wayland
			wl-paste
		elif cmd-exists --strict xclip; then
			# X11 - xclip
			xclip -o -selection clipboard
		elif cmd-exists --strict xsel; then
			# X11 - xsel
			xsel -ob
		fi
	fi

	# If Tmux is running and there is content for the clipboard...
	if [[ -n "$TMUX" ]] && [[ -n "${clipboard_content}" ]]; then
		echo -n "${clipboard_content}" | tmux loadb -
	fi
}

# Copy a file's contents to the clipboard
function file2cb() {
	# Check for parameters...
	if [[ $# -eq 0 ]]; then
		echo -e "${BRIGHT_WHITE}Usage: ${BRIGHT_CYAN}file2cb ${BRIGHT_YELLOW}[filename]${BRIGHT_WHITE}"
		echo -e "${BRIGHT_WHITE}Copy a file's contents to the clipboard.${RESET}"
		return 1
	# Check if the file exists...
	elif [[ ! -f "$1" ]]; then
		echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}The file ${BRIGHT_YELLOW}$1${BRIGHT_CYAN} does not exist.${RESET}"
		return 1
	fi
	\cat "$1" | clipboard
}

# Save the clipboard contents to a file
function cb2file() {
	if [[ $# -eq 0 ]]; then
		echo -e "${BRIGHT_WHITE}cb2file:${RESET} Save the clipboard contents to a file"
		echo -e "${BRIGHT_WHITE}Usage:${BRIGHT_CYAN} cb2file${RESET} ${BRIGHT_YELLOW}<filename>${RESET}"
		return 1
	fi
	clipboard > "$1"
}

# Dump the clipboard contents to the console
function cbshow() {
	clipboard
}

# When using the which command, copy the output to the clipboard or Tmux buffer
alias which='_which_to_clipboard'
# Call the 'which' command and copy its output to clipboard
function _which_to_clipboard() {
	# Get the path of the requested which command
	local which_output=$(\which "$@" 2>&1)

	# Capture the exit status of the 'which' command
	local exit_status=$?

	# Check if 'which' output is non-empty and not "/usr/bin/grc"
	if [ $exit_status -eq 0 ] && [ "${which_output}" != "/usr/bin/grc" ]; then
		# Copy the output to clipboard and display in terminal
		echo "${which_output}" | clipboard
	fi

	# Display the standard output of 'which'
	echo "${which_output}"

	# Return the captured exit status
	return $exit_status
}

# When using the pwd command, copy the directory to the clipboard or Tmux buffer
alias pwd='_pwd_to_clipboard'
function _pwd_to_clipboard() {
	# Run the real pwd command and capture its output
	_PWD_OUTPUT="$(\pwd $@)"
	echo "${_PWD_OUTPUT}"

	# If we are not in the enhancd program folder...
	if [[ "${PWD}" != *"/enhancd" ]]; then
		# Use the new clipboard command to copy the output
		clipboard "${_PWD_OUTPUT}"
	fi
}

# Compress a file (even binary files) to the clipboard as base64 text
function file2asc() {
	# Check if a parameter was passed and if the file exists
	if [ ${#} -eq 0 ] || [ ! -f "${1}" ]; then
		echo -e "${BRIGHT_WHITE}Usage: ${BRIGHT_CYAN}file2asc${RESET} ${BRIGHT_GREEN}[filename]${RESET}"
		return 1
	fi

	# Check if gzip is installed
	if ! cmd-exists --strict gzip; then
		>&2 echo "Requires gzip/gunzip"
		return 1
	fi

	# Create the base64-encoded gzipped content
	local encoded_content=$(\cat "${1}" | gzip -9 | base64)

	# Send the content to clipboard
	if clipboard "$encoded_content"; then
		echo "The clipboard now contains the file: ${1}"
	else
		# If clipboard function couldn't handle the content, fallback

		# We might have a headless environment with no clipboard
		if [[ -z "$PAGER" ]]; then
			echo printf '=%.0s' {1..80}
			echo "$encoded_content"
			echo printf '=%.0s' {1..80}
		else # Use the pager
			# To save text as a file from less, type s then type the file name
			echo "$encoded_content" | "$PAGER"
		fi
	fi

	# Done!
	echo "Use asc2file to convert the base64 ASCII text to a file."
}

# Convert compressed base64 clipboard back to a file
function asc2file() {
	# If no parameters...
	if [ ${#} -eq 0 ]; then
		echo -e "${BRIGHT_WHITE}Usage: ${BRIGHT_CYAN}asc2file${RESET} ${BRIGHT_GREEN}[filename]${RESET}"
		return 1
	fi

	# Check for gunzip
	if ! cmd-exists --strict gunzip; then
		>&2 echo "Requires gzip/gunzip"
		return 1
	fi

	# Fetch the current clipboard content
	local clipboard_content=$(clipboard)
	if [ -z "${clipboard_content}" ]; then
		echo -e "${BRIGHT_YELLOW}Paste the text and press ${BRIGHT_CYAN}CTRL+d${BRIGHT_YELLOW} when done:${RESET} "
		clipboard_content=$(</dev/stdin)
	fi

	# Decode and gunzip the clipboard content, then save to file
	echo "${clipboard_content}" | base64 -di | gunzip > ${1}

	# Display the saved file path
	if cmd-exists --strict realpath; then
		echo "The file was saved: $( \realpath "${1}" )"
	else
		echo "The file was saved: ${1}"
	fi
}

# png2jpg: Converts a PNG image to JPG format.
# Syntax: png2jpg <input_image> [quality]
# Example: png2jpg screenshot.png 90
function png2jpg() {
	# Check if ImageMagick's 'convert' command is available
	if ! command -v convert &> /dev/null; then
		echo "ImageMagick is not installed. Please install it first."
		return 1
	fi

	# Check if input image file exists
	if [ ! -f "$1" ]; then
		echo "Input image file does not exist."
		return 1
	fi

	# Default quality setting
	local QUALITY=85

	# Validate optional quality argument
	if [ ! -z "$2" ]; then
		if [[ ! "$2" =~ ^[0-9]+$ ]] || [ "$2" -le 0 ] || [ "$2" -gt 100 ]; then
			echo "Invalid quality percentage. It should be a positive integer between 1 and 100."
			return 1
		fi
		QUALITY=$2
	fi

	# Extract file name without extension
	local INPUT_FILENAME=$(basename -- "$1")
	local OUTPUT_FILENAME="${INPUT_FILENAME%.*}.jpg"

	# Perform the conversion
	convert "$1" -quality ${QUALITY} "${OUTPUT_FILENAME}"

	echo "Converted $1 to ${OUTPUT_FILENAME} with quality ${QUALITY}%."
}

# Convert an image to compressed JPG format
alias {png2jpg,image2png}='compressimage'
function compressimage() {
	# Show help message if no parameters are provided
	if [ -z "$1" ]; then
		echo -e "${BRIGHT_WHITE}compressimage:${RESET} Converts an image to compressed JPG format"
		echo -e "${BRIGHT_WHITE}Usage: ${BRIGHT_CYAN}compressimage ${BRIGHT_YELLOW}<input_image> ${BRIGHT_MAGENTA}[quality]${RESET}"
		echo -e "${BRIGHT_WHITE}Example: ${BRIGHT_CYAN}compressimage ${BRIGHT_YELLOW}screenshot.png ${BRIGHT_MAGENTA}90${RESET}"
		return 1
	fi

	# Check if ImageMagick's 'convert' and 'identify' commands are available
	if ! cmd-exists --strict convert || ! cmd-exists --strict identify; then
		echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}ImageMagick is not installed. Please install it first.${RESET}"
		return 1
	fi

	# Check if the input image file exists
	if [ ! -f "$1" ]; then
		echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}The input image file ${BRIGHT_YELLOW}$1${BRIGHT_CYAN} does not exist.${RESET}"
		return 1
	fi

	# Default quality setting
	local QUALITY=85

	# Validate optional quality argument
	if [ ! -z "$2" ]; then
		if [[ ! "$2" =~ ^[0-9]+$ ]] || [ "$2" -le 0 ] || [ "$2" -gt 100 ]; then
			echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}Invalid quality percentage. It should be a positive integer between 1 and 100.${RESET}"
			return 1
		fi
		QUALITY=$2
	fi

	# Extract file name without extension
	local INPUT_FILENAME=$(basename -- "$1")
	local OUTPUT_FILENAME="${INPUT_FILENAME%.*}.png"

	# Perform the conversion
	convert "$1" -quality ${QUALITY} "${OUTPUT_FILENAME}"

	echo -e "${BRIGHT_GREEN}Success: ${BRIGHT_WHITE}Converted ${BRIGHT_YELLOW}$1${BRIGHT_WHITE} to ${BRIGHT_YELLOW}${OUTPUT_FILENAME}${BRIGHT_WHITE} with quality ${BRIGHT_YELLOW}${QUALITY}%${RESET}."
}

# Converts a markdown title string into a markdown tag
alias md2tag='convert2mdtag'
function convert2mdtag() {
	# Trim leading '#' or spaces and trailing spaces
	local trimmed_input=$(echo "$1" | sed -e 's/^[\# ]*//' -e 's/[ ]*$//')

	# Convert to lowercase, replace spaces with hyphens,
	# remove unwanted characters, and fix double dashes
	local tag=$(echo "${trimmed_input,,}" | sed -e 's/ /-/g' | tr -dc 'a-z0-9-' | sed 's/--*/-/g')

	# Output the result in the desired markdown link format
	echo "[$trimmed_input](#$tag)" | clipboard
	echo "[$trimmed_input](#$tag)"
}

# Fixes permissions in a user's home folder
# If no user is specified, the current user is selected
function fixuserhome() {
	# Validate input parameters
	if [[ -z "${@}" ]]; then
		local _username="$(whoami)"
	else
		local _username="${@}"
	fi

	# Verify if the home folder exists
	if [ ! -d "/home/${_username}" ]; then
		echo "Error: User ${_username} does not have a home folder."
		return 1
	fi

	# Confirm with the user
	if ask "${BRIGHT_RED}WARNING:${RESET} Change all permissions for user ${BRIGHT_CYAN}${_username}${RESET}'s home folder?" N; then
		# Elevate privileges to root
		sudo true

		if ask "Reset group ownership permissions to ${BRIGHT_CYAN}${_username}${RESET}?" Y; then
			run-with-feedback \
				"Set the owner and group as ${_username}" \
				"sudo chown -R ${_username}:${_username} /home/${_username}"
		else
			run-with-feedback \
				"Set the owner and group as ${_username}" \
				"sudo chown -R ${_username} /home/${_username}"
		fi

		run-with-feedback \
			"Make sure we have read and write access" \
			"chmod -R u+rw /home/${_username}"

		run-with-feedback \
			"Remove write access from group" \
			"chmod -R g-w /home/${_username}"

		run-with-feedback \
			"Remove all access from others" \
			"chmod -R o-rwx /home/${_username}"

		run-with-feedback \
			"Make .sh shell script files executable" \
			"find /home/${_username} -type f \( -name \"*.sh\" -o -name \".*.sh\" \) -exec chmod ug+x {} \;"

		run-with-feedback \
			"Make sure all directories have execute permissions" \
			"chmod -R ug+X /home/${_username}"

		# Remove group permissions for directories without group read
		run-with-feedback \
			"Remove group permissions for directories without group read" \
			"find /home/${_username} -type d ! -perm -g+r -execdir chmod g-wx {} \;"

		if [[ -d "/home/${_username}/.local/share/kwalletd" ]]; then
			run-with-feedback \
				"User only access to KDE Wallet keyring" \
				"chmod -R go-rwx /home/${_username}/.local/share/kwalletd"
		fi

		# If there is a ~/.local/share/keyrings directory...
		if [[ -d "/home/${_username}/.local/share/keyrings" ]]; then
			run-with-feedback \
				"User only access to GNOME keyring" \
				"chmod -R go-rwx /home/${_username}/.local/share/keyrings"
		fi

		# If there is an .ssh directory...
		if [[ -d "/home/${_username}/.ssh" ]]; then
			# Setting ownership for .ssh directory and files
			run-with-feedback \
				"Setting ownership for .ssh directory and files" \
				"chown -R ${_username}:${_username} /home/${_username}/.ssh"

			# Setting strict permissions for .ssh and private keys
			run-with-feedback \
				"User only access to .ssh and private keys" \
				"chmod -R go-rwx /home/${_username}/.ssh"
		fi

		# If there is a .putty directory...
		if [[ -d "/home/${_username}/.putty" ]]; then
			run-with-feedback \
				"User only access to .putty and ssh keys" \
				"chmod -R go-rwx /home/${_username}/.putty"
		fi

		# If there is a .pki directory...
		if [[ -d "/home/${_username}/.pki" ]]; then
			run-with-feedback \
				"User only access to .pki keys and certificates" \
				"chmod -R go-rwx /home/${_username}/.pki"
		fi

		# If there is a .gnupg directory...
		if [[ -d "/home/${_username}/.gnupg" ]]; then
			run-with-feedback \
				"User only access to .gnupg and private keys" \
				"chmod -R go-rwx /home/${_username}/.gnupg"
		fi

		# If KeePassXC/KeePass/KeeWeb is installed...
		if cmd-exists --strict keepassxc || cmd-exists --strict keepass || cmd-exists --strict keeweb; then
			run-with-feedback \
				"User only access to KeePassXC/KeePass/KeeWeb .kdbx files" \
				"find /home/${_username} -type f \( -name '*.kdbx' -o -name '.*.kdbx' \) -exec chmod go-rwx {} \;"
		fi

		# If there is a pass directory...
		if [[ -d "/home/${_username}/.password-store" ]]; then
			run-with-feedback \
				"User only access to pass data" \
				"chmod -R go-rwx /home/${_username}/.password-store"
		fi

		# If there is a Bitwarden directory...
		if [[ -d "/home/${_username}/.config/Bitwarden" ]]; then
			run-with-feedback \
				"User only access to Bitwarden data" \
				"chmod -R go-rwx /home/${_username}/.config/Bitwarden"
		fi
		if [[ -d "/home/${_username}/.var/app/com.bitwarden.desktop" ]]; then
			run-with-feedback \
				"User only access to Bitwarden data (Flatpak)" \
				"chmod -R go-rwx /home/${_username}/.var/app/com.bitwarden.desktop"
		fi

		# Check for Tor settings
		if [[ -d "/home/${_username}/.local/share/torbrowser" ]]; then
			run-with-feedback \
				"User only access to Tor browser data" \
				"chmod -R go-rwx /home/${_username}/.local/share/torbrowser"
		fi
		if [[ -d "/home/${_username}/.var/app/com.github.micahflee.torbrowser-launcher" ]]; then
			run-with-feedback \
				"User only access to Tor browser data (Flatpak)" \
				"chmod -R go-rwx /home/${_username}/.var/app/com.github.micahflee.torbrowser-launcher"
		fi

		# Check for Brave settings
		if [[ -d "/home/${_username}/.config/BraveSoftware" ]]; then
			run-with-feedback \
				"User only access to Brave browser data" \
				"chmod -R go-rwx /home/${_username}/.config/BraveSoftware"
		fi
		if [[ -d "/home/${_username}/.var/app/com.brave.Browser" ]]; then
			run-with-feedback \
				"User only access to Brave browser data (Flatpak)" \
				"chmod -R go-rwx /home/${_username}/.var/app/com.brave.Browser"
		fi

		# Check for Chrome settings
		if [[ -d "/home/${_username}/.config/google-chrome" ]]; then
			run-with-feedback \
				"User only access to Chrome browser data" \
				"chmod -R go-rwx /home/${_username}/.config/google-chrome"
		fi
		if [[ -d "/home/${_username}/.var/app/com.google.Chrome" ]]; then
			run-with-feedback \
				"User only access to Chrome browser data (Flatpak)" \
				"chmod -R go-rwx /home/${_username}/.var/app/com.google.Chrome"
		fi

		# Check for Chromium settings
		if [[ -d "/home/${_username}/.config/chromium" ]]; then
			run-with-feedback \
				"User only access to Chromium browser data" \
				"chmod -R go-rwx /home/${_username}/.config/chromium"
		fi
		if [[ -d "/home/${_username}/.var/app/org.chromium.Chromium" ]]; then
			run-with-feedback \
				"User only access to Chromium browser data (Flatpak)" \
				"chmod -R go-rwx /home/${_username}/.var/app/org.chromium.Chromium"
		fi
		if [[ -d "/home/${_username}/.var/app/net.sourceforge.chromium-bsu" ]]; then
			run-with-feedback \
				"User only access to Ungoogled Chromium browser data (Flatpak)" \
				"chmod -R go-rwx /home/${_username}/.var/app/net.sourceforge.chromium-bsu"
		fi

		# Check for Firefox settings
		if [[ -d "/home/${_username}/.mozilla" ]]; then
			run-with-feedback \
				"User only access to Firefox browser data" \
				"chmod -R go-rwx /home/${_username}/.mozilla"
		fi
		if [[ -d "/home/${_username}/.var/app/org.mozilla.firefox" ]]; then
			run-with-feedback \
				"User only access to Firefox browser data (Flatpak)" \
				"chmod -R go-rwx /home/${_username}/.var/app/org.mozilla.firefox"
		fi

		# Check for LibreWolf settings
		if [[ -d "/home/${_username}/.librewolf" ]]; then
			run-with-feedback \
				"User only access to LibreWolf browser data" \
				"chmod -R go-rwx /home/${_username}/.librewolf"
		fi
		if [[ -d "/home/${_username}/.var/app/io.gitlab.librewolf-community" ]]; then
			run-with-feedback \
				"User only access to LibreWolf browser data (Flatpak)" \
				"chmod -R go-rwx /home/${_username}/.var/app/io.gitlab.librewolf-community"
		fi

		# Check for Opera settings
		if [[ -d "/home/${_username}/.config/opera" ]]; then
			run-with-feedback \
				"User only access to Opera browser data" \
				"chmod -R go-rwx /home/${_username}/.config/opera"
		fi

		# Check for Vivaldi settings
		if [[ -d "/home/${_username}/.config/vivaldi" ]]; then
			run-with-feedback \
				"User only access to Vivaldi browser data" \
				"chmod -R go-rwx /home/${_username}/.config/vivaldi"
		fi

		# Check for Evolution settings
		if [[ -d "/home/${_username}/.config/evolution" ]]; then
			run-with-feedback \
				"User only access to Evolution email data" \
				"chmod -R go-rwx /home/${_username}/.config/evolution"
		fi
		if [[ -d "/home/${_username}/.var/app/org.gnome.Evolution" ]]; then
			run-with-feedback \
				"User only access to Evolution email data (Flatpak)" \
				"chmod -R go-rwx /home/${_username}/.var/app/org.gnome.Evolution"
		fi

		# Check for Geary settings
		if [[ -d "/home/${_username}/.local/share/geary" ]]; then
			run-with-feedback \
				"User only access to Geary email data" \
				"chmod -R go-rwx /home/${_username}/.local/share/geary"
		fi
		if [[ -d "/home/${_username}/.var/app/org.gnome.Geary" ]]; then
			run-with-feedback \
				"User only access to Geary email data (Flatpak)" \
				"chmod -R go-rwx /home/${_username}/.var/app/org.gnome.Geary"
		fi

		# Check for Thunderbird settings
		if [[ -d "/home/${_username}/.thunderbird" ]]; then
			run-with-feedback \
				"User only access to Thunderbird email data" \
				"chmod -R go-rwx /home/${_username}/.thunderbird"
		fi
		if [[ -d "/home/${_username}/.var/app/org.mozilla.Thunderbird" ]]; then
			run-with-feedback \
				"User only access to Thunderbird email data (Flatpak)" \
				"chmod -R go-rwx /home/${_username}/.var/app/org.mozilla.Thunderbird"
		fi

		# Check for Element settings
		if [[ -d "/home/${_username}/.config/Element" ]]; then
			run-with-feedback \
				"User only access to Element chat data" \
				"chmod -R go-rwx /home/${_username}/.config/Element"
		fi
		if [[ -d "/home/${_username}/.var/app/im.riot.Riot" ]]; then
			run-with-feedback \
				"User only access to Element chat data (Flatpak)" \
				"chmod -R go-rwx /home/${_username}/.var/app/im.riot.Riot"
		fi

		# Check for Signal settings
		if [[ -d "/home/${_username}/.config/Signal" ]]; then
			run-with-feedback \
				"User only access to Signal chat data" \
				"chmod -R go-rwx /home/${_username}/.config/Signal"
		fi
		if [[ -d "/home/${_username}/.var/app/org.signal.Signal" ]]; then
			run-with-feedback \
				"User only access to Signal chat data (Flatpak)" \
				"chmod -R go-rwx /home/${_username}/.var/app/org.signal.Signal"
		fi

		if [[ -f "/home/${_username}/.config/birthdays.csv" ]]; then
			run-with-feedback \
				"User only access to birthday/anniversary reminder data" \
				"chmod 600 /home/${_username}/.config/birthdays.csv"
		elif [[ -f "${_BDAY_FILE}" ]]; then
			run-with-feedback \
				"User only access to birthday/anniversary reminder data (from variable)" \
				"chmod 600 \"${_BDAY_FILE}\""
		fi

		# [OPTIONAL] Copy group permissions to other
		#run-with-feedback \
		#	"Copy group permissions to other" \
		#	"chmod -R o=g /home/${_username}"

		# [OPTIONAL] Copy user permissions to group
		#run-with-feedback \
		#	"Copy user permissions to group" \
		#	"chmod -R g=u /home/${_username}"

		# Set the setgid bit, so that files/folder under the directory
		# will be created with the same group as <directory>
		run-with-feedback \
			"Set the setgid bit to inherit folder permissions" \
			"chmod g+s /home/${_username}"

		# If Access Control Lists (ACL) is installed...
		# To "activate" ACL, you have to remount the drive with the "acl" option
		# NOTE: Btrfs and Xfs filesystem use the ACL mount option by default
		# Example /etc/fstab Entry:
		# UUID=abc123def456 / ext4 defaults,acl 0 1
		# Type "man acl" for more information
		if cmd-exists --strict setfacl; then
			# Use getfacl [directory] to check ACL for these directories
			run-with-feedback \
				"Set user default ACL entries" \
				"setfacl -d -m u::rwx /home/${_username}"
			run-with-feedback \
				"Set group default ACL entries" \
				"setfacl -d -m g::rx /home/${_username}"
			run-with-feedback \
				"Set others default ACL entries" \
				"setfacl -d -m o::X /home/${_username}"
		fi

		echo "Done!"
	else
		return 0
	fi
}

# Copy over configuration settings from one account to root/default/another
# It also handles special cases for 'root' and 'default' (skel) directories
# Syntax:
#    configcopy [from_user] [to_user]
# Parameters:
#    from_user - The user from whom to copy the configuration files
#    to_user   - The user to whom to copy the configuration files
# Examples:
#     configcopy alice jimbob # Copies files from user alice's home to bob's home
#     configcopy default root # Copies files from /etc/skel to /root
alias copyconfig='configcopy'
function configcopy() {
	# Config files to copy over
	declare -a files=(
		".bash_logout"
		".bash_profile"
		".bashrc"
		".bashrc_help"
		".commacd.sh"
		".config/micro/bindings.json"
		".config/micro/settings.json"
		".dir_colors"
		".inputrc"
		".nanorc"
		".p10k.zsh"
		".screenrc"
		".tmux.conf"
		".vimrc"
		".Xauthority"
		".zshrc"
		"git-completion.bash"
		"gitalias.txt"
	)

	# Config directories to copy over
	declare -a dirs=(
		".config/bashrc"
		".config/fish"
		".config/htop"
		".config/mc"
		".config/micro/colorschemes"
		".config/micro/plug"
		".qfc"
		"bashmarks"
		"ble.sh"
		"enhancd"
		"fzf-tab-completion"
		"hstr"
	)

	if [ -z "${1}" ] || [ -z "${2}" ]; then
		echo -e "Usage: ${BRIGHT_GREEN}copyconfig [from_user] [to_user]${RESET}"
		echo -ne "Users can be ${BRIGHT_CYAN}root${RESET}, ${BRIGHT_CYAN}default${RESET} (/etc/skel), or users ${BRIGHT_CYAN}"
		\awk -F: '$3 ~ /^[0-9]{4}$/' /etc/passwd | \cut -d: -f1 | \tr '\n' ' ' | \tr -d '[:space:]'
		echo -e "${RESET}."
		return
	elif [ "${1}" == "${2}" ]; then
		echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}The from and to user parameters cannot be the same${RESET}"
		return 2
	elif [ ! -d "/home/${1}" ] && [ "${1}" != "root" ] && [ "${1}" != "default" ]; then
		echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}User ${BRIGHT_YELLOW}${1}${BRIGHT_CYAN} does not exist${RESET}"
		return 1
	elif [ ! -d "/home/${2}" ] && [ "${2}" != "root" ] && [ "${2}" != "default" ]; then
		echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}User ${BRIGHT_YELLOW}${2}${BRIGHT_CYAN} does not exist${RESET}"
		return 1
	elif [ "${1}" == "default" ] && [ "${2}" == "root" ]; then
		dirfrom=/etc/skel/
		dirto=/root/
		owner=root
	elif [ "${1}" == "default" ]; then
		dirfrom=/etc/skel/
		dirto=/home/"${2}"/
		owner="${2}"
	elif [ "${2}" == "default" ] && [ "${1}" == "root" ]; then
		dirfrom=/root/
		dirto=/etc/skel/
		owner=root
	elif [ "${2}" == "default" ]; then
		dirfrom=/home/"${1}"/
		dirto=/etc/skel/
		owner=root
	elif [ "${1}" == "root" ]; then
		dirfrom=/root/
		dirto=/home/"${2}"/
		owner="${2}"
	elif [ "${2}" == "root" ]; then
		dirfrom=/home/"${1}"/
		dirto=/root/
		owner=root
	else
		dirfrom=/home/"${1}"/
		dirto=/home/"${2}"/
		owner="${2}"
	fi

	# Ask for confirmation
	if ! ask "${BRIGHT_RED}Are you sure? ${BRIGHT_CYAN}This will overwrite configuration files in ${BRIGHT_YELLOW}${dirto%/}${RESET}" N; then
		return
	fi

	# Loop through and copy the files over
	for file in "${files[@]}"; do
		src="${dirfrom}${file}"
		dest="${dirto}${file}"
		dest_dir=$(dirname "${dest}")

		# Check if the source file exists
		if [[ -f "${src}" ]]; then
			# Ensure destination directory exists
			[[ ! -d "${dest_dir}" ]] && \
				sudo mkdir -p "${dest_dir}" && \
				sudo chown "${owner}":"${owner}" "${dest_dir}"

			# Copy and change permissions
			sudo cp "${src}" "${dest_dir}" && \
				sudo chown "${owner}":"${owner}" "${dest}" && \
				echo -e "${BRIGHT_GREEN}✓${RESET} Copied file: ${BRIGHT_CYAN}${file}${RESET}"
		fi
	done

	# Loop through and copy directories over
	for dir in "${dirs[@]}"; do
		src="${dirfrom}${dir}"
		dest="${dirto}${dir}"
		dest_dir=$(dirname "${dest}")

		# Check if the source directory exists
		if [[ -d "${src}" ]]; then
			# Ensure destination directory exists
			[[ ! -d "${dest_dir}" ]] && \
				sudo mkdir -p "${dest_dir}" && \
				sudo chown "${owner}":"${owner}" "${dest_dir}"

			# Copy directory
			sudo cp -R "${src}" "${dest_dir}" && \
				echo -e "${BRIGHT_GREEN}✓${RESET} Copied directory ${BRIGHT_CYAN}${dir}${RESET}"
		fi
	done

	# We are done
	echo -e "Owner set to: ${BRIGHT_MAGENTA}${owner}${RESET}"
	echo -e "${BRIGHT_GREEN}Finished copying configuration files from ${BRIGHT_YELLOW}${dirfrom%/}${BRIGHT_GREEN} to ${BRIGHT_YELLOW}${dirto%/}${RESET}"
	return
}

# Synchronize files using rsync over SSH
function sync2ssh() {
	# Check the number of arguments
	if [[ $# -lt 3 ]]; then
		echo -e "${BRIGHT_WHITE}sync2ssh:${RESET} Synchronize files using rsync over SSH"
		echo -e "${BRIGHT_WHITE}Usage:${RESET}"
		echo -e "  ${BRIGHT_CYAN}sync2ssh${RESET} ${BRIGHT_YELLOW}[LOCAL_DIR] ${BRIGHT_BLUE}[USER@REMOTE_HOST${BRIGHT_CYAN}[:PORT]${BRIGHT_BLUE}] ${BRIGHT_YELLOW}[REMOTE_DIR]${RESET} ${BRIGHT_GREEN}[OPTIONAL_SSH_PASSWORD]${RESET}"
		echo -e "${BRIGHT_WHITE}Examples:${RESET}"
		echo -e "  ${BRIGHT_CYAN}sync2ssh${RESET} ${BRIGHT_YELLOW}~/local/folder/${RESET} ${BRIGHT_BLUE}user@example.com${RESET} ${BRIGHT_YELLOW}/path/on/remote${RESET}"
		echo -e "  ${BRIGHT_CYAN}sync2ssh${RESET} ${BRIGHT_YELLOW}~/local/folder/${RESET} ${BRIGHT_BLUE}user@example.com${RESET} ${BRIGHT_YELLOW}/path/on/remote${RESET} ${BRIGHT_GREEN}password123${RESET}"
		echo -e "  ${BRIGHT_CYAN}sync2ssh${RESET} ${BRIGHT_YELLOW}~/local/folder/${RESET} ${BRIGHT_BLUE}user@example.com${BRIGHT_WHITE}:${BRIGHT_CYAN}22${RESET} ${BRIGHT_YELLOW}/path/on/remote${RESET}"
		return 1
	fi

	# Append trailing slash to directories if it's not present
	[[ "${1: -1}" != "/" ]] && LOCAL_DIR="${1}/" || LOCAL_DIR="$1"
	SSH_USER_HOST_PORT="$2"
	REMOTE_DIR="$3"

	# Extract the port (if present)
	SSH_PORT=$(echo "$SSH_USER_HOST_PORT" | awk -F: '{print $NF}')
	if [[ "$SSH_PORT" == "$SSH_USER_HOST_PORT" ]]; then
		SSH_PORT=22  # default SSH port
		SSH_USER_HOST=$SSH_USER_HOST_PORT
	else
		SSH_USER_HOST=$(echo "$SSH_USER_HOST_PORT" | awk -F: '{print $1}')
	fi

	# Rsync options:
	# --recursive: Transfer files and directories recursively
	# --links: Treat symbolic links as references to their target files/directories
	# --compress: Compress files during transfer for efficiency
	# --verbose: Display a detailed log of files being transferred
	# --times: Maintain file timestamps during the transfer
	# --perms: Retain file permissions during the transfer (like read/write/execute)
	# --delete: Delete files on the destination that aren't present at the source
	# -e: Use SSH with a 10-second connection timeout for transfers
	#RSYNC_OPTIONS="--recursive --links --compress --verbose --times --perms --delete -e 'ssh -o ConnectTimeout=10 -p ${SSH_PORT}'"
	RSYNC_OPTIONS="--recursive --links --compress --verbose --delete -e 'ssh -o ConnectTimeout=10 -p ${SSH_PORT}'"

	# Check if SSH password is provided
	if [[ -n "$4" ]]; then
		# Ensure sshpass is installed
		if ! cmd-exists --strict sshpass; then
			echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}Install sshpass or use SSH keys instead${RESET}"
			return 1
		fi
		SSH_PASS="$4"
		RSYNC_COMMAND="sshpass -p '${SSH_PASS}' rsync ${RSYNC_OPTIONS}"
	else
		RSYNC_COMMAND="rsync ${RSYNC_OPTIONS}"
	fi

	# Execute the rsync command
	eval "${RSYNC_COMMAND}" "${LOCAL_DIR}" "${SSH_USER_HOST}:${REMOTE_DIR}"

	# Check the result of the rsync command
	if [[ $? -ne 0 ]]; then
		echo -e "${BRIGHT_RED}Error: ${BRIGHT_CYAN}rsync command failed${RESET}"
		return 1
	fi

	echo -e "${BRIGHT_GREEN}Files synchronized successfully${RESET}"
}

# When executed, will toggle the hosts file on and off
function hoststoggle() {
	# Confirm we want to do this...
	if ask "Are you sure you wish to modify the hosts file?" N; then

		# If the hosts backup file exists, restore it
		if [ -f /etc/hosts.backup_temporary ]; then
			sudo \rm -f /etc/hosts
			sudo \mv /etc/hosts.backup_temporary /etc/hosts
			sudo chmod 644 /etc/hosts
			echo -e "${BRIGHT_BLUE}Hosts file ${BRIGHT_GREEN}restored${BRIGHT_BLUE}.${RESET}"
			echo -e "(File is $(sudo cat /etc/hosts | wc -l) lines long.)"
			sudo head -16 /etc/hosts

		# Make a backup of the hosts file
		elif [ -f /etc/hosts ]; then
			sudo \mv /etc/hosts /etc/hosts.backup_temporary

			# Replaces the hosts file with a generic empty hosts file
			sudo bash -c 'printf "#\n# /etc/hosts: static lookup table for host names\n#\n\n127.0.0.1       localhost\n255.255.255.255 broadcasthost\n::1             localhost\n::1             ip6-localhost ip6-loopback\nfe00::0         ip6-localnet\nff00::0         ip6-mcastprefix\nff02::1         ip6-allnodes\nff02::2         ip6-allrouters\nff02::3         ip6-allhosts\n" >> /etc/hosts'

			sudo chmod 644 /etc/hosts
			echo -e "${BRIGHT_BLUE}Hosts file ${BRIGHT_RED}disabled${BRIGHT_BLUE}.${RESET}"

		# Supports hBlock - A POSIX-compliant shell script that gets a list of domains
		# that serve ads, tracking scripts and malware from multiple sources and creates
		# a hosts file, among other formats, that prevents your system from connecting
		# to them. See https://github.com/hectorm/hblock
		elif cmd-exists --strict hblock; then
			if [ -f /etc/hosts.personal ]; then
				sudo /usr/bin/hblock --header /etc/hosts.personal
			else
				sudo /usr/bin/hblock
			fi
			sudo chmod 644 /etc/hosts
			echo -e "${BRIGHT_BLUE}Hosts file ${BRIGHT_YELLOW}recreated${BRIGHT_BLUE}.${RESET}"

		# No hosts file was found
		else
			echo -e "${BRIGHT_RED}ERROR: ${BRIGHT_CYAN}Hosts file and backup not found.${RESET}"
		fi
	fi
}

function time-elapsed() {
	# Check if at least one parameter is provided
	if [ -z "$1" ]; then
		echo -e "Please provide a date in ${BRIGHT_CYAN}YYYY-MM-DD${RESET} format."
		return 1
	fi

	# Parameters
	local date_given="$1"
	local message="$2"

	# Check if the first parameter is a valid date...
	if ! date -d "$date_given" >/dev/null 2>&1; then
		echo -e "Invalid date format. Please provide a date in ${BRIGHT_CYAN}YYYY-MM-DD${RESET} format."
		return 1
	fi

	# Default message if the second parameter is empty...
	if [ -z "$message" ]; then
		message="${BRIGHT_CYAN}The date${RESET} ${BRIGHT_GREEN}${date_given}${RESET} ${BRIGHT_CYAN}was"
	else
		message="${BRIGHT_CYAN}${message}${RESET}"
	fi

	# Calculate total days elapsed
	local total_days=$(( ( $(date '+%s') - $(date -d "$date_given" '+%s') ) / 86400 ))

	# Initialize years, months, and days
	local years=0
	local months=0
	local days=0

	# Calculate years, months, and days
	local remaining_days=$total_days
	while [ $remaining_days -ge 365 ]; do
		((years++))
		remaining_days=$((remaining_days - 365))
	done

	while [ $remaining_days -ge 30 ]; do
		((months++))
		remaining_days=$((remaining_days - 30))
	done
	days=$remaining_days

	# Display message with colors
	echo -e "${message} ${BRIGHT_MAGENTA}${total_days} total days${BRIGHT_CYAN} ago which is ${BRIGHT_YELLOW}${years} years${BRIGHT_CYAN}, ${BRIGHT_YELLOW}${months} months${BRIGHT_CYAN}, and ${BRIGHT_YELLOW}${days} days${BRIGHT_CYAN}!${RESET}"
}

# For some reason, rot13 pops up everywhere
function rot13() {
	if [[ $# -eq 0 ]]; then
		tr '[a-m][n-z][A-M][N-Z]' '[n-z][a-m][N-Z][A-M]'
	else
		echo $* | tr '[a-m][n-z][A-M][N-Z]' '[n-z][a-m][N-Z][A-M]'
	fi
}

# Trim leading and trailing spaces
function trim() {
	local var=$@
	var="${var#"${var%%[![:space:]]*}"}"  # remove leading whitespace characters
	var="${var%"${var##*[![:space:]]}"}"  # remove trailing whitespace characters
	echo -n "$var"
}

#######################################################
# Show the initial information HUD on initial Bash load
#######################################################

# If we are NOT root or in a virtual terminal console or TMUX or Git Bash...
if [[ $EUID -ne 0 ]] && \
	[[ ! "$(tty)" =~ /dev/tty ]] && \
	[[ ! "$TERM" =~ screen ]] && \
	[[ -z "$TMUX" ]] && \
	[[ "$_KERNEL_NAME" != "MINGW" ]] && \
	[[ "$_KERNEL_NAME" != "CYGWI" ]] && \
	[[ $_SKIP_SYSTEM_INFO = false ]]; then

	# Link: https://github.com/LinusDierheimer/fastfetch
	if cmd-exists --strict fastfetch; then
		fastfetch

	# Link: https://ostechnix.com/neofetch-display-linux-systems-information/
	elif cmd-exists --strict neofetch; then
		neofetch
		printf '\033[A\033[K' # Move the cursor up one line

	# Link: https://github.com/KittyKatt/screenFetch
	elif cmd-exists --strict screenfetch; then
		screenfetch

	# Link: https://github.com/deater/linux_logo
	elif cmd-exists --strict linuxlogo; then
		linuxlogo

	# Link: https://lclarkmichalek.github.io/archey3/
	elif cmd-exists --strict archey; then
		archey

	# Link: https://github.com/dylanaraps/pfetch
	elif [[ -f "$HOME/pfetch.sh" ]]; then
		"$HOME/pfetch.sh"
	elif cmd-exists --strict pfetch.sh; then
		pfetch.sh
	elif cmd-exists --strict pfetch; then
		pfetch
	fi
fi

#######################################################
# Show text or ASCII on initial Bash load
# Create ASCII: jp2a --color ~/input_image.jpg > ~/.bash_motd_shown
# Test: cat ~/.bash_motd_shown
#######################################################

# If the file exists and we are NOT root...
if [[ -f "$HOME/.bash_motd_shown" ]] && [[ $EUID -ne 0 ]]; then

	# Show the ASCII text or image
	cat "$HOME/.bash_motd_shown"
fi

#######################################################
# Show upgrade information on new terminal windows
# Note: This is disabled by default because it takes several seconds to run
#######################################################

if [[ $_SKIP_UPGRADE_NOTIFY = false ]]; then

	# If this is an Arch based distrobution...
	# Add to your crontab (this runs every 3 hours): 0 */3 * * * /usr/bin/pacman -Sy
	if cmd-exists --strict pacman && cmd-exists --strict paccache; then

		# Show if there are updates available
		_PACKAGE_UPDATE_COUNT=$(pacman -Q --upgrades | wc -l)
		if [[ "$_PACKAGE_UPDATE_COUNT" -gt "0" ]]; then
			echo -e "${BRIGHT_YELLOW}*${RESET} ${BRIGHT_GREEN}There are${RESET} ${BRIGHT_WHITE}"$_PACKAGE_UPDATE_COUNT"${RESET} ${BRIGHT_GREEN}avaliable program updates${RESET}"
			echo -e "${BRIGHT_BLACK}*${RESET} ${BRIGHT_CYAN}Type${RESET} ${BRIGHT_MAGENTA}pacman -Qu${RESET} ${BRIGHT_CYAN}for more information${RESET}"
			echo
		fi

	# If this is an Ubuntu based distro...
	# Add to your crontab (this runs every 3 hours): 0 */3 * * * /usr/bin/apt update
	elif [[ -x "/usr/lib/update-notifier/apt-check" ]]; then

		# Show if there are updates available
		IFS=';' read _PACKAGE_UPDATE_COUNT _PACKAGE_SECURITY_UPDATE_COUNT < <(/usr/lib/update-notifier/apt-check 2>&1)
		if [[ "$_PACKAGE_UPDATE_COUNT" -gt "0" ]]; then
			echo -e "${BRIGHT_YELLOW}*${RESET} ${BRIGHT_GREEN}There are${RESET} ${BRIGHT_WHITE}"$_PACKAGE_UPDATE_COUNT"${RESET} ${BRIGHT_GREEN}avaliable program updates${RESET}"
		fi
		if [[ "$_PACKAGE_SECURITY_UPDATE_COUNT" -gt "0" ]]; then
			echo -e "${BRIGHT_BLACK}*${RESET} ${BRIGHT_CYAN}There are${RESET} ${BRIGHT_MAGENTA}"$_PACKAGE_SECURITY_UPDATE_COUNT"${RESET} ${BRIGHT_CYAN}security updates.${RESET}"
		fi
		if [[ "$_PACKAGE_UPDATE_COUNT" -gt "0" ]] || [[ "$_PACKAGE_SECURITY_UPDATE_COUNT" -gt "0" ]]; then
			echo
		fi
	fi
fi

################################################################################
# Birthday/anniversary reminder that shows a message in your teminal
# Reads the birthday CSV file: ~/.config/birthdays.csv
# The format is (year is optional and can be left blank):
# Month,Day,Year,"Message"
# Jan,1,2000,"This is a message!"
#
# Toilet application is a required dependency
# Arch/Manjaro:  sudo pacman -S toilet
# Ubuntu/Debian: sudo apt-get install toilet
################################################################################

# Make an alias to edit the birthday csv file
if [[ -f "${HOME}/.config/birthdays.csv" ]]; then
	alias ebd="edit ~/.config/birthdays.csv"
elif [[ -f "${_BDAY_FILE}" ]]; then
	alias ebd="edit ${_BDAY_FILE}"
fi

# Show a birthday or anniversary reminder
function birthday() {
	# Use extended globbing for more advanced pattern matching
	# This is also necessary for programmable completion
	shopt -s extglob

	# If the birthday CSV file exists and toilet is installed...
	if [[ $_SKIP_BDAY_REMINDER = false ]] && [[ -f "${_BDAY_FILE}" ]]; then

		# Loop through the birthday CSV file: ~/.config/birthdays.csv
		# The first line is ignored (header) and the format is:
		# Month,Day,Year,"Message"
		# Jan,1,1985,"This is a message!"
		while IFS=, read -r _BDAY_MONTH _BDAY_DAY _BDAY_YEAR _BDAY_MESSAGE; do

			# Compare the month (case insensitive) and the day (remove leading zeros)
			if [[ "$(date +%^b)" = "${_BDAY_MONTH^^}" ]] && [[ "$(date +%-d)" = "${_BDAY_DAY##+(0)}" ]]; then

				# Remove the surrounding quotes from the message
				_BDAY_MESSAGE="${_BDAY_MESSAGE%\"}"
				_BDAY_MESSAGE="${_BDAY_MESSAGE#\"}"

				# Show the message using toilet and the future font
				if cmd-exists --strict toilet; then
					toilet --font="${_BDAY_FONT}" --termwidth --gay "${_BDAY_MESSAGE}"
				elif cmd-exists --strict lolcat; then
					echo "${_BDAY_MESSAGE}" | lolcat --spread=0.4
				else
					echo -e "${BRIGHT_CYAN}${_BDAY_MESSAGE}${RESET}"
				fi

				# If the year is a number and not blank...
				if [ -n "${_BDAY_YEAR}" ] && [ "${_BDAY_YEAR}" -eq "${_BDAY_YEAR}" ] 2>/dev/null; then
					echo -e "${BRIGHT_YELLOW}$(( ($(date +%s) - $(date --date="${_BDAY_MONTH} ${_BDAY_DAY} ${_BDAY_YEAR}" +%s))/(60*60*24)/365 ))${RESET} Years"
				fi

				#echo ""
			fi

		# Strip off the first line in the CSV file
		done < <(tail -n +2 "${_BDAY_FILE}")
	fi
}

# If we aren't supposed to skip this...
if [[ $_SKIP_BDAY_REMINDER = false ]]; then
	# Call the birthday function
	birthday
fi

#######################################################
# Show the calendar when Bash starts
#######################################################

if [[ $_SHOW_BASH_CALENDAR = true ]]; then
	if cmd-exists --strict gcal; then
		gcal -H '\033[34m:${RESET}:\033[32m:${RESET}' -q "${_GCAL_COUNTRY_CODE}"
	else
		cal -3
	fi
fi

#######################################################
# bashmarks Directory Bookmarks
# Link: https://github.com/huyng/bashmarks
# Install: git clone git://github.com/huyng/bashmarks.git
# s <bookmark_name> - Saves the current directory as "bookmark_name"
# g <bookmark_name> - Goes (cd) to the directory associated with "bookmark_name"
# p <bookmark_name> - Prints the directory associated with "bookmark_name"
# d <bookmark_name> - Deletes the bookmark
# l                 - Lists all available bookmarks
#######################################################

# If bashmarks is installed, load it
if [[ -f "$HOME/bashmarks/bashmarks.sh" ]]; then
	source "$HOME/bashmarks/bashmarks.sh"
elif [[ -f "$HOME/.local/bin/bashmarks.sh" ]]; then
	source "$HOME/.local/bin/bashmarks.sh"
elif [[ -f /usr/share/bashmarks/bashmarks.sh ]]; then
	source /usr/share/bashmarks/bashmarks.sh
fi

#######################################################
# Zoxide is a smarter cd command (inspired by z and autojump)
# Link: https://github.com/ajeetdsouza/zoxide
# Install: curl -sS https://webinstall.dev/zoxide | bash
#######################################################

# If Zoxide is installed, run it's initialization
if cmd-exists --strict zoxide; then
	eval "$(zoxide init bash)"
fi

#######################################################
# commacd Improved cd
# Link: https://github.com/shyiko/commacd
# Install: curl -sSL https://github.com/shyiko/commacd/raw/v1.0.0/commacd.sh -o ~/.commacd.sh
#######################################################

# If commacd is installed
if [[ -f "$HOME/.commacd.sh" ]]; then
	source "$HOME/.commacd.sh"
elif [[ -f /usr/share/commacd/commacd.bash ]]; then
	source /usr/share/commacd/commacd.bash
fi

#######################################################
# Improve navigation and searching your command history
#######################################################

# Search command line history
alias h='history | grep'

# Enable incremental history search with up/down arrows and other Readline features
# Learn more about this here: http://codeinthehole.com/writing/the-most-important-command-line-tip-incremental-history-searching-with-inputrc/
bind '"\033[A": history-search-backward'
bind '"\033[B": history-search-forward'

# HSTR Easily navigate and search your command history and favorites
# (has favorites, syncs across shells, does not require an extra database, but does not show the time since a command)
# Link: https://github.com/dvorka/hstr
# Manual: man hstr
if cmd-exists --strict hstr; then

	# Alias hh for hstr
	alias hh='hstr'

	# Get more colors
	export HSTR_CONFIG=hicolor

	# Bind hstr to CTRL+r (for Vi mode check doc)
	bind '"\C-r": "\C-a hstr -- \C-j"'

	# Bind 'kill last command' to CTRL+x k
	bind '"\C-xk": "\C-a hstr -k \C-j"'

# McFly - fly through your shell history using a small neural network
# (shows the time since the command, but does not have favorites, and has issues syncing history across multiple shells)
# NOTE: You can type % to match any number of characters when searching
# Link: https://github.com/cantino/mcfly
# Install: curl -LSfs https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh | sh -s -- --git cantino/mcfly
elif cmd-exists --strict mcfly; then

	# Initialize McFly
	eval "$(mcfly init bash)"

	# Alias hh for McFly
	alias hh='mcfly search'

	# Enable fuzzy searching
	export MCFLY_FUZZY=2

	# Change the maximum number of results shown (default: 10)
	export MCFLY_RESULTS=60

	# To swap the color scheme for use in a light terminal, change this
	export MCFLY_LIGHT=FALSE

# Rich Enhanced Shell History (resh) Context-based replacement/enhancement for zsh and bash shell history
# (shows more information, has raw mode, but uses own database, does not have favorites, can't delete history)
# Link: https://github.com/curusarn/resh
# Install: (git clone https://github.com/curusarn/resh.git && cd resh && scripts/rawinstall.sh)
# Update: reshctl update
# WARNING: Install automatically adds lines to the end of the ~/.bashrc file
elif [[ -f ~/.resh/shellrc ]]; then

	# Source the scripts
	source ~/.resh/shellrc
	[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh

	# Bind 'kill last command' to CTRL+x k
	bind '"\C-xk": "\C-a hstr -k \C-j"'

	# Alias hh for resh
	alias hh='resh'

fi

#######################################################
# qfc Command Line File Completion (CTRL+F to list files)
# Link: https://github.com/pindexis/qfc
# Install: git clone https://github.com/pindexis/qfc $HOME/.qfc
#######################################################

# If qfc is installed, run it's initiation script
# CTRL+f will pop up to select directories or files
# CTRL+/ to cd into directory using qfc
if [[ -f "$HOME/.qfc/bin/qfc.sh" ]]; then
	source "$HOME/.qfc/bin/qfc.sh"
	qfc_quick_command 'cd' '\C-_' 'cd "$0"'
	qfc_quick_command 'edit' '\C-e' 'edit $0'
elif [[ -f /usr/share/qfc/qfc.sh ]]; then
	source /usr/share/qfc/qfc.sh
	qfc_quick_command 'cd' '\C-_' 'cd "$0"'
	qfc_quick_command 'edit' '\C-e' 'edit $0'
fi

#######################################################
# Settings and Exports
#######################################################

# Make sure 256 color terminals are enabled
# export TERM=xterm-256color
# Linux tries very hard to set it to a sane value depending on things
# like which terminal you are actually using and how you are connected
# You can override a particular value which the login process
# often chooses but which is not to your liking
case $TERM in "") TERM=xterm-256color;; esac

# For use with LS_COLORS
export use_color=true

# Tell NCURSES to use UTF-8 encoding
export NCURSES_NO_UTF8_ACS=1

if cmd-exists --strict moar; then
	# Use moar
	# Link: https://github.com/walles/moar
	export PAGER='moar'
	export MANPAGER='moar'
	alias less='moar'
	alias les='moar -no-linenumbers'
elif [[ -n "$LESSOPEN" ]]; then
	# Use less over most if it has syntax highlighting
	export PAGER='less'
	export MANPAGER='less'
	alias les='less -n'
elif cmd-exists --strict most; then
	# Use most
	# Link: https://www.jedsoft.org/most/
	export PAGER='most'
	export MANPAGER='most'
	alias less='most'
	alias les='\less -n'
else
	export PAGER='less'
	export MANPAGER='less'
	alias les='less -n'
fi

# If bat is installed...
# https://github.com/sharkdp/bat
if cmd-exists --strict batcat; then
	export PAGER='less' # Bat expects and uses less
	export MANPAGER='batcat --style=plain'
	alias bat='batcat --force-colorization'
elif cmd-exists --strict bat; then
	export PAGER='less' # Bat expects and uses less
	export MANPAGER='bat --style=plain'
	alias bat='bat --force-colorization'
fi

# If bat-extras is installed with the extra commands:
# batgrep, batman, batpipe, batwatch, batdiff, prettybat
# Link: https://github.com/eth-p/bat-extras
if cmd-exists --strict batman; then
	alias man='batman'
fi

# ccat is the colorizing cat
# Link: https://github.com/owenthereal/ccat
if cmd-exists --strict ccat; then
	alias cat='ccat'
fi

# Color for manpages in less makes manpages a little easier to read
if [[ -f /usr/share/source-highlight/src-hilite-lesspipe.sh ]]; then
	export LESSOPEN="| /usr/share/source-highlight/src-hilite-lesspipe.sh %s"
elif cmd-exists --strict src-hilite-lesspipe.sh; then
	export LESSOPEN="| src-hilite-lesspipe.sh %s"
fi

# NOTE: Use \less with the back-slash to remove line numbers
# or you can use -n or --line-numbers if moar/most are not installed
export LESS='-N -x4 --force --ignore-case --quit-if-one-screen --no-init --RAW-CONTROL-CHARS --LONG-PROMPT --prompt=%t?f%f :stdin .?pb%pb\%:?lbLine %lb:?bbByte %bb:-...'
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# Make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

#######################################################
# Vivid LS_COLORS Generator
# Link: https://github.com/sharkdp/vivid
# Themes: https://github.com/sharkdp/vivid/tree/master/themes
#######################################################
# LS_COLORS (lscolors-git in Arch AUR repository)
# Link: https://github.com/trapd00r/LS_COLORS
# Install:
# mkdir /tmp/LS_COLORS && curl -L https://api.github.com/repos/trapd00r/LS_COLORS/tarball/master | tar xzf - --directory=/tmp/LS_COLORS --strip=1
# ( cd /tmp/LS_COLORS && sh install.sh )
#######################################################

# Colors for ls
export CLICOLOR=1

if cmd-exists --strict vivid; then
	# Vivid is installed
	export LS_COLORS="$(vivid generate snazzy)"
	_LS_COLORS_SOURCE="Vivid"
elif [[ -f "$HOME/.local/share/lscolors.sh" ]]; then
	# LS_COLORS is installed locally
	source "$HOME/.local/share/lscolors.sh"
	_LS_COLORS_SOURCE="LS_COLORS Local"
elif [[ -f /usr/share/LS_COLORS/dircolors.sh ]]; then
	# LS_COLORS is installed system wide
	source /usr/share/LS_COLORS/dircolors.sh
	_LS_COLORS_SOURCE="LS_COLORS System Wide"
elif cmd-exists --strict dircolors; then
	# dircolors is used by ls to set LS_COLORS for colorized directory output
	# Check if a custom .dircolors file exists in the user's home directory
	if test -r ~/.dircolors; then
		# If the file exists and is readable, use it to set LS_COLORS instead
		eval "$(dircolors -b ~/.dircolors)"
	else
		# If no custom .dircolors file exists then use the default settings
		eval "$(dircolors -b)"
	fi
	_LS_COLORS_SOURCE="dircolors"
else
	# Otherwise, export a full featured custom ls color profile
	LS_COLORS='bd=38;5;68:ca=38;5;17:cd=38;5;113;1:di=38;5;30:do=38;5;127:ex=38;5;208;1:pi=38;5;126:fi=0:ln=target:mh=38;5;222;1:no=0:or=48;5;196;38;5;232;1:ow=38;5;220;1:sg=48;5;3;38;5;0:su=38;5;220;1;3;100;1:so=38;5;197:st=38;5;86;48;5;234:tw=48;5;235;38;5;139;3:*LS_COLORS=48;5;89;38;5;197;1;3;4;7:*.txt=38;5;253:*README=38;5;220;1:*README.rst=38;5;220;1:*README.md=38;5;220;1:*LICENSE=38;5;220;1:*COPYING=38;5;220;1:*INSTALL=38;5;220;1:*COPYRIGHT=38;5;220;1:*AUTHORS=38;5;220;1:*HISTORY=38;5;220;1:*CONTRIBUTORS=38;5;220;1:*PATENTS=38;5;220;1:*VERSION=38;5;220;1:*NOTICE=38;5;220;1:*CHANGES=38;5;220;1:*.log=38;5;190:*.adoc=38;5;184:*.asciidoc=38;5;184:*.etx=38;5;184:*.info=38;5;184:*.markdown=38;5;184:*.md=38;5;184:*.mkd=38;5;184:*.nfo=38;5;184:*.org=38;5;184:*.pod=38;5;184:*.rst=38;5;184:*.tex=38;5;184:*.textile=38;5;184:*.bib=38;5;178:*.json=38;5;178:*.jsonl=38;5;178:*.jsonnet=38;5;178:*.libsonnet=38;5;142:*.ndjson=38;5;178:*.msg=38;5;178:*.pgn=38;5;178:*.rss=38;5;178:*.xml=38;5;178:*.fxml=38;5;178:*.toml=38;5;178:*.yaml=38;5;178:*.yml=38;5;178:*.RData=38;5;178:*.rdata=38;5;178:*.xsd=38;5;178:*.dtd=38;5;178:*.sgml=38;5;178:*.rng=38;5;178:*.rnc=38;5;178:*.accdb=38;5;60:*.accde=38;5;60:*.accdr=38;5;60:*.accdt=38;5;60:*.db=38;5;60:*.fmp12=38;5;60:*.fp7=38;5;60:*.localstorage=38;5;60:*.mdb=38;5;60:*.mde=38;5;60:*.sqlite=38;5;60:*.typelib=38;5;60:*.nc=38;5;60:*.cbr=38;5;141:*.cbz=38;5;141:*.chm=38;5;141:*.djvu=38;5;141:*.pdf=38;5;141:*.PDF=38;5;141:*.mobi=38;5;141:*.epub=38;5;141:*.docm=38;5;111;4:*.doc=38;5;111:*.docx=38;5;111:*.odb=38;5;111:*.odt=38;5;111:*.rtf=38;5;111:*.pages=38;5;111:*.odp=38;5;166:*.pps=38;5;166:*.ppt=38;5;166:*.pptx=38;5;166:*.ppts=38;5;166:*.pptxm=38;5;166;4:*.pptsm=38;5;166;4:*.csv=38;5;78:*.tsv=38;5;78:*.numbers=38;5;112:*.ods=38;5;112:*.xla=38;5;76:*.xls=38;5;112:*.xlsx=38;5;112:*.xlsxm=38;5;112;4:*.xltm=38;5;73;4:*.xltx=38;5;73:*.key=38;5;166:*config=1:*cfg=1:*conf=1:*rc=1:*authorized_keys=1:*known_hosts=1:*.ini=1:*.plist=1:*.profile=1:*.bash_profile=1:*.bash_login=1:*.bash_logout=1:*.zshenv=1:*.zprofile=1:*.zlogin=1:*.zlogout=1:*.viminfo=1:*.pcf=1:*.psf=1:*.hidden-color-scheme=1:*.hidden-tmTheme=1:*.last-run=1:*.merged-ca-bundle=1:*.sublime-build=1:*.sublime-commands=1:*.sublime-keymap=1:*.sublime-settings=1:*.sublime-snippet=1:*.sublime-project=1:*.sublime-workspace=1:*.tmTheme=1:*.user-ca-bundle=1:*.rstheme=1:*.epf=1:*.git=38;5;197:*.gitignore=38;5;240:*.gitattributes=38;5;240:*.gitmodules=38;5;240:*.awk=38;5;172:*.bash=38;5;172:*.bat=38;5;172:*.BAT=38;5;172:*.sed=38;5;172:*.sh=38;5;172:*.zsh=38;5;172:*.vim=38;5;172:*.kak=38;5;172:*.ahk=38;5;41:*.py=38;5;41:*.ipynb=38;5;41:*.xsh=38;5;41:*.rb=38;5;41:*.gemspec=38;5;41:*.pl=38;5;208:*.PL=38;5;160:*.pm=38;5;203:*.t=38;5;114:*.msql=38;5;222:*.mysql=38;5;222:*.pgsql=38;5;222:*.sql=38;5;222:*.tcl=38;5;64;1:*.r=38;5;49:*.R=38;5;49:*.gs=38;5;81:*.clj=38;5;41:*.cljs=38;5;41:*.cljc=38;5;41:*.cljw=38;5;41:*.scala=38;5;41:*.sc=38;5;41:*.dart=38;5;51:*.asm=38;5;81:*.cl=38;5;81:*.lisp=38;5;81:*.rkt=38;5;81:*.el=38;5;81:*.elc=38;5;241:*.eln=38;5;241:*.lua=38;5;81:*.moon=38;5;81:*.c=38;5;81:*.C=38;5;81:*.h=38;5;110:*.H=38;5;110:*.tcc=38;5;110:*.c++=38;5;81:*.h++=38;5;110:*.hpp=38;5;110:*.hx=38;5;110:*.hxx=38;5;110:*.hxsl=38;5;110:*.ii=38;5;110:*.M=38;5;110:*.m=38;5;110:*.cc=38;5;81:*.cs=38;5;81:*.cp=38;5;81:*.cpp=38;5;81:*.cxx=38;5;81:*.cr=38;5;81:*.go=38;5;81:*.f=38;5;81:*.F=38;5;81:*.for=38;5;81:*.ftn=38;5;81:*.f90=38;5;81:*.F90=38;5;81:*.f95=38;5;81:*.F95=38;5;81:*.f03=38;5;81:*.F03=38;5;81:*.f08=38;5;81:*.F08=38;5;81:*.nim=38;5;81:*.nimble=38;5;81:*.s=38;5;110:*.S=38;5;110:*.rs=38;5;81:*.scpt=38;5;219:*.swift=38;5;219:*.sx=38;5;81:*.vala=38;5;81:*.vapi=38;5;81:*.hi=38;5;110:*.hs=38;5;81:*.lhs=38;5;81:*.agda=38;5;81:*.lagda=38;5;81:*.lagda.tex=38;5;81:*.lagda.rst=38;5;81:*.lagda.md=38;5;81:*.agdai=38;5;110:*.zig=38;5;81:*.v=38;5;81:*.pyc=38;5;240:*.tf=38;5;168:*.tfstate=38;5;168:*.tfvars=38;5;168:*.css=38;5;125;1:*.less=38;5;125;1:*.sass=38;5;125;1:*.scss=38;5;125;1:*.htm=38;5;125;1:*.html=38;5;125;1:*.jhtm=38;5;125;1:*.mht=38;5;125;1:*.eml=38;5;125;1:*.mustache=38;5;125;1:*.coffee=38;5;074;1:*.java=38;5;074;1:*.js=38;5;074;1:*.mjs=38;5;074;1:*.jsm=38;5;074;1:*.jsp=38;5;074;1:*.ada=38;5;81:*.cbl=38;5;81:*.conf=38;5;81:*.cpy=38;5;81:*.ctp=38;5;81:*.erl=38;5;81:*.groovy=38;5;81:*.hrl=38;5;81:*.inc=38;5;81:*.ino=38;5;81:*.kt=38;5;81:*.lib=38;5;81:*.mat=38;5;81:*.mk=38;5;81:*.pascal=38;5;81:*.php=38;5;81:*.plx=38;5;81:*.sml=38;5;81:*.template=38;5;81:*.tpl=38;5;81:*.twig=38;5;81:*.vb=38;5;81:*.vba=38;5;81:*.vbs=38;5;81:*.wren=38;5;81:*Dockerfile=38;5;155:*.dockerignore=38;5;240:*Makefile=38;5;155:*MANIFEST=38;5;243:*pm_to_blib=38;5;240:*.nix=38;5;155:*.dhall=38;5;178:*.rake=38;5;155:*.am=38;5;242:*.in=38;5;242:*.hin=38;5;242:*.scan=38;5;242:*.m4=38;5;242:*.old=38;5;242:*.out=38;5;242:*.SKIP=38;5;244:*.diff=48;5;197;38;5;232:*.patch=48;5;197;38;5;232;1:*.bmp=38;5;97:*.dicom=38;5;97:*.tiff=38;5;97:*.tif=38;5;97:*.TIFF=38;5;97:*.cdr=38;5;97:*.flif=38;5;97:*.gif=38;5;97:*.icns=38;5;97:*.ico=38;5;97:*.jpeg=38;5;97:*.JPG=38;5;97:*.jpg=38;5;97:*.nth=38;5;97:*.png=38;5;97:*.psd=38;5;97:*.pxd=38;5;97:*.pxm=38;5;97:*.xpm=38;5;97:*.webp=38;5;97:*.ai=38;5;99:*.eps=38;5;99:*.epsf=38;5;99:*.drw=38;5;99:*.ps=38;5;99:*.svg=38;5;99:*.avi=38;5;114:*.divx=38;5;114:*.IFO=38;5;114:*.m2v=38;5;114:*.m4v=38;5;114:*.mkv=38;5;114:*.MOV=38;5;114:*.mov=38;5;114:*.mp4=38;5;114:*.mpeg=38;5;114:*.mpg=38;5;114:*.ogm=38;5;114:*.rmvb=38;5;114:*.sample=38;5;114:*.wmv=38;5;114:*.3g2=38;5;115:*.3gp=38;5;115:*.gp3=38;5;115:*.webm=38;5;115:*.gp4=38;5;115:*.asf=38;5;115:*.flv=38;5;115:*.ts=38;5;115:*.ogv=38;5;115:*.f4v=38;5;115:*.VOB=38;5;115;1:*.vob=38;5;115;1:*.ass=38;5;117:*.srt=38;5;117:*.ssa=38;5;117:*.sub=38;5;117:*.sup=38;5;117:*.vtt=38;5;117:*.3ga=38;5;137;1:*.S3M=38;5;137;1:*.aac=38;5;137;1:*.amr=38;5;137;1:*.au=38;5;137;1:*.caf=38;5;137;1:*.dat=38;5;137;1:*.dts=38;5;137;1:*.fcm=38;5;137;1:*.m4a=38;5;137;1:*.mod=38;5;137;1:*.mp3=38;5;137;1:*.mp4a=38;5;137;1:*.oga=38;5;137;1:*.ogg=38;5;137;1:*.opus=38;5;137;1:*.s3m=38;5;137;1:*.sid=38;5;137;1:*.wma=38;5;137;1:*.ape=38;5;136;1:*.aiff=38;5;136;1:*.cda=38;5;136;1:*.flac=38;5;136;1:*.alac=38;5;136;1:*.mid=38;5;136;1:*.midi=38;5;136;1:*.pcm=38;5;136;1:*.wav=38;5;136;1:*.wv=38;5;136;1:*.wvc=38;5;136;1:*.afm=38;5;66:*.fon=38;5;66:*.fnt=38;5;66:*.pfb=38;5;66:*.pfm=38;5;66:*.ttf=38;5;66:*.otf=38;5;66:*.woff=38;5;66:*.woff2=38;5;66:*.PFA=38;5;66:*.pfa=38;5;66:*.7z=38;5;40:*.a=38;5;40:*.arj=38;5;40:*.bz2=38;5;40:*.cpio=38;5;40:*.gz=38;5;40:*.lrz=38;5;40:*.lz=38;5;40:*.lzma=38;5;40:*.lzo=38;5;40:*.rar=38;5;40:*.s7z=38;5;40:*.sz=38;5;40:*.tar=38;5;40:*.tbz=38;5;40:*.tgz=38;5;40:*.warc=38;5;40:*.WARC=38;5;40:*.xz=38;5;40:*.z=38;5;40:*.zip=38;5;40:*.zipx=38;5;40:*.zoo=38;5;40:*.zpaq=38;5;40:*.zst=38;5;40:*.zstd=38;5;40:*.zz=38;5;40:*.apk=38;5;215:*.ipa=38;5;215:*.deb=38;5;215:*.rpm=38;5;215:*.jad=38;5;215:*.jar=38;5;215:*.ear=38;5;215:*.war=38;5;215:*.cab=38;5;215:*.pak=38;5;215:*.pk3=38;5;215:*.vdf=38;5;215:*.vpk=38;5;215:*.bsp=38;5;215:*.dmg=38;5;215:*.crx=38;5;215:*.xpi=38;5;215:*.iso=38;5;124:*.img=38;5;124:*.bin=38;5;124:*.nrg=38;5;124:*.qcow=38;5;124:*.fvd=38;5;124:*.sparseimage=38;5;124:*.toast=38;5;124:*.vcd=38;5;124:*.vdi=38;5;124:*.vhd=38;5;124:*.vhdl=38;5;124:*.vhdx=38;5;124:*.vfd=38;5;124:*.vmdk=38;5;124:*.swp=38;5;244:*.swo=38;5;244:*.tmp=38;5;244:*.sassc=38;5;244:*.pacnew=38;5;33:*.un~=38;5;241:*.orig=38;5;241:*.BUP=38;5;241:*.bak=38;5;241:*.o=38;5;241:*core=38;5;241:*.mdump=38;5;241:*.rlib=38;5;241:*.dll=38;5;241:*.aria2=38;5;241:*.dump=38;5;241:*.stackdump=38;5;241:*.zcompdump=38;5;241:*.zwc=38;5;241:*.part=38;5;239:*.r[0-9]{0,2}=38;5;239:*.zx[0-9]{0,2}=38;5;239:*.z[0-9]{0,2}=38;5;239:*.pid=38;5;248:*.state=38;5;248:*lockfile=38;5;248:*lock=38;5;248:*.err=38;5;160;1:*.error=38;5;160;1:*.stderr=38;5;160;1:*.pcap=38;5;29:*.cap=38;5;29:*.dmp=38;5;29:*.allow=38;5;112:*.deny=38;5;196:*.service=38;5;45:*@.service=38;5;45:*.socket=38;5;45:*.swap=38;5;45:*.device=38;5;45:*.mount=38;5;45:*.automount=38;5;45:*.target=38;5;45:*.path=38;5;45:*.timer=38;5;45:*.snapshot=38;5;45:*.lnk=38;5;39:*.application=38;5;116:*.cue=38;5;116:*.description=38;5;116:*.directory=38;5;116:*.m3u=38;5;116:*.m3u8=38;5;116:*.md5=38;5;116:*.properties=38;5;116:*.sfv=38;5;116:*.theme=38;5;116:*.torrent=38;5;116:*.urlview=38;5;116:*.webloc=38;5;116:*.asc=38;5;192;3:*.bfe=38;5;192;3:*.enc=38;5;192;3:*.gpg=38;5;192;3:*.signature=38;5;192;3:*.sig=38;5;192;3:*.p12=38;5;192;3:*.pem=38;5;192;3:*.pgp=38;5;192;3:*.p7s=38;5;192;3:*id_dsa=38;5;192;3:*id_rsa=38;5;192;3:*id_ecdsa=38;5;192;3:*id_ed25519=38;5;192;3:*.32x=38;5;213:*.cdi=38;5;213:*.fm2=38;5;213:*.rom=38;5;213:*.sav=38;5;213:*.st=38;5;213:*.a00=38;5;213:*.a52=38;5;213:*.A64=38;5;213:*.a64=38;5;213:*.a78=38;5;213:*.adf=38;5;213:*.atr=38;5;213:*.gb=38;5;213:*.gba=38;5;213:*.gbc=38;5;213:*.gel=38;5;213:*.gg=38;5;213:*.ggl=38;5;213:*.ipk=38;5;213:*.j64=38;5;213:*.nds=38;5;213:*.nes=38;5;213:*.sms=38;5;213:*.8xp=38;5;121:*.8eu=38;5;121:*.82p=38;5;121:*.83p=38;5;121:*.8xe=38;5;121:*.stl=38;5;216:*.dwg=38;5;216:*.ply=38;5;216:*.wrl=38;5;216:*.xib=38;5;208:*.iml=38;5;166:*.DS_Store=38;5;239:*.localized=38;5;239:*.CFUserTextEncoding=38;5;239:*CodeResources=38;5;239:*PkgInfo=38;5;239:*.nib=38;5;57:*.car=38;5;57:*.dylib=38;5;241:*.entitlements=1:*.pbxproj=1:*.strings=1:*.storyboard=38;5;196:*.xcconfig=1:*.xcsettings=1:*.xcuserstate=1:*.xcworkspacedata=1:*.pot=38;5;7:*.pcb=38;5;7:*.mm=38;5;7:*.gbr=38;5;7:*.scm=38;5;7:*.xcf=38;5;7:*.spl=38;5;7:*.Rproj=38;5;11:*.sis=38;5;7:*.1p=38;5;7:*.3p=38;5;7:*.cnc=38;5;7:*.def=38;5;7:*.ex=38;5;7:*.example=38;5;7:*.feature=38;5;7:*.ger=38;5;7:*.ics=38;5;7:*.map=38;5;7:*.mf=38;5;7:*.mfasl=38;5;7:*.mi=38;5;7:*.mtx=38;5;7:*.pc=38;5;7:*.pi=38;5;7:*.plt=38;5;7:*.rdf=38;5;7:*.ru=38;5;7:*.sch=38;5;7:*.sty=38;5;7:*.sug=38;5;7:*.tdy=38;5;7:*.tfm=38;5;7:*.tfnt=38;5;7:*.tg=38;5;7:*.vcard=38;5;7:*.vcf=38;5;7:*.xln=38;5;7:'
	_LS_COLORS_SOURCE="Custom Colors"
fi

#######################################################
# grc Generic Colouriser
# Link: https://github.com/garabik/grc
#######################################################

if [[ $_SKIP_GRC = false ]] && cmd-exists --strict grc; then
	GRC_ALIASES=true
	if [[ -f "$HOME/.local/bin/grc.sh" ]]; then
		source ~/.local/bin/grc.sh
	elif [[ -f "/etc/profile.d/grc.sh" ]]; then
		source /etc/profile.d/grc.sh
	elif [[ -f "/etc/grc.sh" ]]; then
		source /etc/grc.sh
	else
		GRC="$(\which grc)"
		if tty -s && [ -n "$TERM" ] && [ "$TERM" != dumb ] && [ -n "$GRC" ]; then
			alias as='colourify as'
			alias blkid='colourify blkid'
			alias colourify="$GRC -es"
			alias configure='colourify ./configure'
			if [[ "$(type -t df)" != 'alias' ]]; then alias df='colourify df -khT'; fi
			if [[ "$(type -t diff)" != 'alias' ]]; then alias diff='colourify diff'; fi
			alias dig='colourify dig'
			alias docker-compose='colourify docker-compose'
			alias docker-machine='colourify docker-machine'
			alias docker='colourify docker'
			alias du='colourify du'
			#alias env='colourify env'
			alias fdisk='colourify fdisk'
			alias findmnt='colourify findmnt'
			alias free='colourify free -m'
			alias g++='colourify g++'
			alias gas='colourify gas'
			alias gcc='colourify gcc'
			alias getsebool='colourify getsebool'
			alias head='colourify head'
			alias id='colourify id'
			alias ifconfig='colourify ifconfig'
			alias ip='colourify ip'
			alias iptables='colourify iptables'
			alias journalctl='colourify journalctl'
			alias kubectl='colourify kubectl'
			if [[ "$(type -t ld)" != 'alias' ]]; then alias ld='colourify ld'; fi
			alias lsof='colourify lsof'
			alias lspci='colourify lspci'
			alias m='colourify mount'
			alias make='colourify make'
			alias mount='colourify mount'
			alias mtr='colourify mtr'
			alias netstat='colourify netstat'
			alias ping='colourify ping -c 5'
			alias ps='colourify ps auxf'
			alias semanage='colourify semanage'
			alias sockstat='colourify sockstat'
			alias ss='colourify ss'
			alias tail='colourify tail'
			alias traceroute6='colourify traceroute6'
			alias traceroute='colourify traceroute'
		fi
	fi
	# Override lsblk to enhance the color output
	#alias lsblk='colourify lsblk --exclude 1,7 --output NAME,MAJ:MIN,RM,SIZE,RO,TYPE,MOUNTPOINTS'
	alias lsblk='colourify lsblk --exclude 1,7 --output NAME,MAJ:MIN,TYPE,FSTYPE,RM,MOUNTPOINTS,LABEL,SIZE,FSUSE%,RO,UUID 2> /dev/null || colourify lsblk --exclude 1,7'
else
	# List block devices but show more info including the files systems and permissions
	# and removes all mem and loopback devices (like snap packages) from the list
	#alias lsblk='\lsblk --exclude 1,7 --output NAME,MAJ:MIN,RM,SIZE,RO,TYPE,MOUNTPOINTS'
	alias lsblk='\lsblk --exclude 1,7 --output NAME,MAJ:MIN,TYPE,FSTYPE,RM,MOUNTPOINTS,LABEL,SIZE,FSUSE%,RO,UUID 2> /dev/null || \lsblk --exclude 1,7'
fi

#######################################################
# mysql-colorize
# Link: https://github.com/zpm-zsh/mysql-colorize
# Install: git clone https://github.com/horosgrisa/mysql-colorize.bash ~/.bash/mysql-colorize
#######################################################

# If qfc is installed
if [[ -f "$HOME/.bash/mysql-colorize/mysql-colorize.bash" ]]; then
	source "$HOME/.bash/mysql-colorize/mysql-colorize.bash"
fi

#######################################################
# Nethogs shows which processes are using network bandwidth
# Link: https://github.com/raboof/nethogs
#######################################################
# lsof command stands for List Of Open File
# Link: https://www.geeksforgeeks.org/lsof-command-in-linux-with-examples/
#######################################################
# iftop is a network analyzing tool used to view the bandwidth related stats
# Link: https://www.geeksforgeeks.org/iftop-command-in-linux-with-examples/
#######################################################

if cmd-exists --strict nethogs; then
	# Watch real time network activity by process
	alias netwatch='sudo nethogs -d 0.5 -C'
elif cmd-exists --strict iftop; then
	# Use iftop
	alias netwatch='sudo iftop'
else
	# Watch real time network activity using lsof instead
	alias netwatch='lsof -i -r 10'
fi

#######################################################
# Diff Enhancement
#######################################################

if cmd-exists --strict delta; then
	if cmd-exists --strict batdiff; then
		# bat-extras diff uses delta
		# Link: https://github.com/eth-p/bat-extras
		alias diff='batdiff --delta'
	else
		# delta - Beautiful side by side colored diff with Git support and syntax highlighting
		# Link: https://github.com/dandavison/delta
		# Info: Add listed settings to your ~/.gitconfig
		alias diff='delta --side-by-side --line-numbers'
	fi
	export DIFFPROG="delta --side-by-side --line-numbers"
elif cmd-exists --strict icdiff; then
	# Icdiff - Improved (side by side) colored diff
	# Link: https://github.com/jeffkaufman/icdiff
	alias diff='icdiff --line-numbers --strip-trailing-cr'
	export DIFFPROG="icdiff --line-numbers --strip-trailing-cr"
elif cmd-exists --strict colordiff; then
	# Colorize diff output if colordiff is installed
	alias diff='colordiff'
	export DIFFPROG="colordiff"
else
	if [[ ${EDITOR} = 'nvim' ]]; then
		export DIFFPROG="nvim -d"
	elif [[ ${EDITOR} = 'vim' ]]; then
		export DIFFPROG="vim -d"
	else
		export DIFFPROG="\diff --side-by-side --suppress-common-lines --ignore-all-space --ignore-blank-lines --strip-trailing-cr --report-identical-files"
	fi
fi

# If we are inside a desktop environment (and not TTY or SSH)
if [[ -n "${XDG_CURRENT_DESKTOP}" ]]; then

	# Alias to log out the currect user
	alias logout="sudo pkill -u ${USER}"

	# Check if the user's session type is X11
	if [[ "${XDG_SESSION_TYPE}" == "x11" ]]; then
		# Ensure the ffmpeg command is available
		if cmd-exists --strict ffmpeg; then
			# Create an alias to capture video on X11 using ffmpeg
			# Documentation for ffmpeg: https://ffmpeg.org/documentation.html
			alias grabvideo='ffmpeg -f x11grab -s wxga -r 25 -i :0.0 -qscale 0'
		fi

	# Check if the user's session type is Wayland
	elif [[ "${XDG_SESSION_TYPE}" == "wayland" ]]; then
		# Ensure the wf-recorder command is available (requires wl-roots compositor)
		if cmd-exists wf-recorder; then
			# Create an alias to capture video on Wayland using wf-recorder
			# Documentation for wf-recorder: https://github.com/ammen99/wf-recorder
			alias grabvideo='wf-recorder -f output.mp4'
		fi
	fi

	# If a gui diff/merge application is installed, use that instead
	for _DIFF_APP_GUI in \
		meld \
		kompare \
		kdiff3 \
		xxdiff
	do
		if cmd-exists --strict ${_DIFF_APP_GUI}; then
			alias diff="${_DIFF_APP_GUI}"
			export DIFFPROG="${_DIFF_APP_GUI}"
			break
		fi
	done

	# Switch over to UI starting in the current directory
	if cmd-exists --strict exo-open; then
		alias ui='exo-open --launch FileManager "${PWD}" > /dev/null 2>&1 & disown'
	elif cmd-exists --strict kde-open; then
		alias ui='kde-open "${PWD}" > /dev/null 2>&1 & disown'
	elif cmd-exists --strict gnome-open; then
		alias ui='gnome-open "${PWD}" > /dev/null 2>&1 & disown'
	elif cmd-exists --strict xdg-open; then
		alias ui='xdg-open "${PWD}" > /dev/null 2>&1 & disown'
	elif cmd-exists --strict krusader; then
		alias ui='krusader "${PWD}" > /dev/null 2>&1 & disown'
	elif cmd-exists --strict dolphin; then
		alias ui='dolphin "${PWD}" > /dev/null 2>&1 & disown'
	elif cmd-exists --strict thunar; then
		alias ui='thunar "${PWD}" > /dev/null 2>&1 & disown'
	elif cmd-exists --strict pcmanfm; then
		alias ui='pcmanfm "${PWD}" > /dev/null 2>&1 & disown'
	elif cmd-exists --strict nautilus; then
		alias ui='nautilus "${PWD}" > /dev/null 2>&1 & disown'
	elif cmd-exists --strict nemo; then
		alias ui='nemo "${PWD}" > /dev/null 2>&1 & disown'
	elif cmd-exists --strict caja; then
		alias ui='caja "${PWD}" > /dev/null 2>&1 & disown'
	elif cmd-exists --strict konqueror; then
		alias ui='konqueror "${PWD}" > /dev/null 2>&1 & disown'
	elif cmd-exists --strict ranger; then
		alias ui='ranger "${PWD}"'
	elif cmd-exists --strict nnn; then
		alias ui='nnn "${PWD}"'
	elif cmd-exists --strict mc; then
		alias ui='mc "${PWD}"'
	fi
fi

#######################################################
# Bash Completion
# Link: https://github.com/scop/bash-completion
#######################################################

# Use extended globbing for more advanced pattern matching
# This is necessary for programmable completion
shopt -s extglob

if [[ $_SCRIPT_BASH_COMPLETION = false ]]; then
	# Use bash-completion, if available
	if [[ -f /usr/share/bash-completion/bash_completion ]]; then
		source /usr/share/bash-completion/bash_completion
	elif [[ -f /etc/bash_completion ]]; then
		source /etc/bash_completion
	elif [[ -f "$HOME/bash_completion" ]]; then
		source "$HOME/bash_completion"
	elif [[ -f "$HOME/.local/share/bash_completion" ]]; then
		source "$HOME/.local/share/bash_completion"
	elif [[ -f "$HOME/.config/bash_completion" ]]; then
		source "$HOME/.config/bash_completion"
	fi
fi

#######################################################
# Cod is a completion daemon for bash, fish, and zsh
# Link: https://github.com/dim-an/cod
#######################################################

if cmd-exists --strict cod; then
	source <(cod init $$ bash)
fi

###########################################################################
# fzf-tab-completion tab completion using fzf in bash, GNU readline apps
# Link: https://github.com/lincheney/fzf-tab-completion
# Install: git clone https://github.com/lincheney/fzf-tab-completion
###########################################################################

# Check if the fzf-bash-completion.sh script exists in known locations
if [[ -f "/usr/share/fzf-tab-completion/bash/fzf-bash-completion.sh" ]]; then
	# Source the fzf bash completion script
	source "/usr/share/fzf-tab-completion/bash/fzf-bash-completion.sh"

	# Bind the tab key to the fzf_bash_completion function
	bind -x '"\t": fzf_bash_completion'

	# Bind Shift+Tab to the default completion function as a backup
	bind '"\033[Z": complete'

	# If nodejs is installed, enable fzf-tab-completion for nodejs repl
	if cmd-exists node; then
		alias node='node -r /usr/share/fzf-tab-completion/node/fzf-node-completion.js'
	fi
elif [[ -f "$HOME/fzf-tab-completion/bash/fzf-bash-completion.sh" ]]; then
	# Source the fzf bash completion script if git cloned
	source "$HOME/fzf-tab-completion/bash/fzf-bash-completion.sh"

	# Bind the tab key to the fzf_bash_completion function
	bind -x '"\t": fzf_bash_completion'

	# Bind Shift+Tab to the default completion function as a backup
	bind '"\033[Z": complete'

	# If nodejs is installed, enable fzf-tab-completion for nodejs repl
	if cmd-exists node; then
		alias node='node -r $HOME/fzf-tab-completion/node/fzf-node-completion.js'
	fi
fi

#######################################################
# Enable the "Command not found" hook
# Link: https://github.com/falconindy/pkgfile
# NOTE: pkgfile is targetted at Arch Linux users
# Install: pacman -S pkgfile
#######################################################

if [[ -r /usr/share/doc/pkgfile/command-not-found.bash ]]; then
	source /usr/share/doc/pkgfile/command-not-found.bash
fi

#######################################################
# Better Bash Defaults
# Link: http://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html
#######################################################

# Bind the Right arrow key to forward-char (move cursor forward)
bind '"\033[C": forward-char'

# Bind the Left arrow key to backward-char (move cursor backward)
bind '"\033[D": backward-char'

# CTRL+u will now undo (CTRL+z may or may not work)
bind '"\C-u": undo'
bind '"\C-z": undo'

# CRTL+q will now clear the entire line in the terminal (remember quit command)
bind '"\C-q": kill-whole-line'

# CTRL+d will disconnect even if there is text on the line
bind '"\C-d":"\C-k\C-u\C-d"'

# Disable the bell sound but make it visible
bind 'set bell-style visible'

# Prevent overwriting an existing file with the >, >&, and <> redirection operators
# Use `>|` to force redirection to an existing file
#set -o noclobber

# Update window size after each command and, if necessary, update the values of LINES and COLUMNS
# shopt -s checkwinsize
[[ $DISPLAY ]] && shopt -s checkwinsize

# Automatically trim long paths in the prompt (requires Bash 4.x)
PROMPT_DIRTRIM=3

# Turn on recursive globbing (enables ** to recurse all directories)
# For example, ls **/*.txt will list all text files in the current directory hierarchy
shopt -s globstar 2> /dev/null

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;

# Report the status of terminated background jobs immediately rather than before the next primary prompt
set -o notify

# Bash checks that a command found in the hash table exists before trying to execute it
shopt -s checkhash

# Bash includes filenames beginning with a "." in the results of filename expansion
shopt -s dotglob

# Turns off CTRL+D to log out
#set -o ignoreeof

# Disable coredumps
ulimit -S -c 0

# Don't let my shell warn me of incoming mail
shopt -u mailwarn
unset MAILCHECK

# Fix the HOME and END keys in PuTTY
if [[ "$COLORTERM" ]]; then # rxvt
	bind '"\033[7~": beginning-of-line'
	bind '"\033[8~": end-of-line'
else # xterm
	bind '"\033[1~": beginning-of-line'
	bind '"\033[4~": end-of-line'
fi

#######################################################
### SMARTER TAB-COMPLETION (Readline bindings)
#######################################################

# Perform file completion in a case insensitive fashion
bind 'set completion-ignore-case on'

# Treat hyphens and underscores as equivalent
bind 'set completion-map-case on'

# Display matches for ambiguous patterns at first tab press instead of bell
bind 'set show-all-if-ambiguous on'

# This line sets the completions to be listed immediately instead of ringing
# the bell when the completing word has more than one possible completion but
# no partial completion can be made
bind 'set show-all-if-unmodified on'

# Immediately add a trailing slash when autocompleting symlinks to directories
bind 'set mark-symlinked-directories on'

# Add a trailing slash when completing a directory name
bind 'set mark-directories on'

# Set autoexpansion of the '~' when TAB is pressed
bind 'set expand-tilde off'

# This line sets readline to display possible completions using different
# colors to indicate their file types. The colors are determined by the
# environmental variable LS_COLORS, which can be nicely configured
bind 'set colored-stats on'

# This lines sets completions to be appended by characters that indicate their
# file types reported by the stat system call
bind 'set visible-stats on'

#######################################################
### HISTORY DEFAULTS
#######################################################

# If missing, recreate a new empty history file so apps don't show errors
if [[ -z ${HISTFILE+x} ]]; then
	[[ ! -f "$HOME/.bash_history" ]] && touch "$HOME/.bash_history"
else
	[[ ! -f "$HISTFILE" ]] && touch "$HISTFILE"
fi

# Turn off bash history completely
# set +o history

# Enable history expansion with space
# E.g. typing !!<space> will replace the !! with your last command
bind Space:magic-space

# Huge history. Doesn't appear to slow things down, so why not?
export HISTFILESIZE=100000
export HISTSIZE=${HISTFILESIZE}

# Avoid duplicate lines in the history and do not add lines that start with a space
export HISTCONTROL=ignoreboth:erasedups

# Append to history instead of overwriting it so if you start a new terminal, you have old session history
shopt -s histappend histverify

# Save and reload the history after each command finishes
# WARNING: Some of these mess up the history counter and is slower as history grows larger
# WARNING: It can also break some more advanced installed prompts
# This has issues with McFly so only set if it's not installed
if ! cmd-exists --strict mcfly; then
	## Append new history to history file, clear internal history list, and re-read the history file
	export PROMPT_COMMAND="history -a; history -c; history -r; ${PROMPT_COMMAND}"
	## -Or- just record each line as it gets issued but new history is not in other sessions (faster)
	#export PROMPT_COMMAND="history -a; ${PROMPT_COMMAND}"
fi

# Save multi-line commands as one command
shopt -s cmdhist

# Consecutive duplicate commands, invocations of common commands like ls without parameters,
# plus calls to the bg, fg and exit built-ins will not be appended to the history list
export HISTIGNORE='&:[ ]*:ls:ll:[bf]g:history:clear:cls:exit'

# Use standard ISO 8601 timestamp
# %F equivalent to %Y-%m-%d
# %T equivalent to %H:%M:%S (24-hours format)
export HISTTIMEFORMAT='%F %T '

# Allow CTRL+S for history navigation (with CTRL+R)
stty -ixon

#######################################################
### BETTER DIRECTORY NAVIGATION
#######################################################

# Prepend cd to directory names automatically
shopt -s autocd 2> /dev/null

# Correct spelling errors during tab-completion
shopt -s dirspell 2> /dev/null
shopt -s direxpand 2> /dev/null

# Correct spelling errors in arguments supplied to cd
shopt -s cdspell 2> /dev/null

# This defines where cd looks for targets
# Add the directories you want to have fast access to, separated by colon
# Ex: CDPATH=".:~:~/projects" will look for targets in the current working directory, in home and in the ~/projects folder
CDPATH="."

# The source builtin uses the value of PATH to find the directory containing the file supplied as an argument
shopt -s sourcepath

# If Readline is being used, Bash will not attempt to search the PATH for possible completions when completion is attempted on an empty line
shopt -s no_empty_cmd_completion

# This allows you to bookmark your favorite places across the file system
# Define a variable containing a path and you will be able to cd into it regardless of the directory you're in
shopt -s cdable_vars

# Examples:
# export backup="$HOME/Backup"
# export desktop="$HOME/Desktop"
# export documents="$HOME/Documents"
# export music="$HOME/Music"
# export pictures="$HOME/Pictures"
# export videos="$HOME/Videos"

#######################################################
# User Specific Aliases
# This runs towards the end of the script in order to
# have supporting aliases and features and also so
# these can be over-written or modified (see unalias)
#######################################################

if [[ -f "$HOME/.bash_aliases" ]]; then
	source "$HOME/.bash_aliases"
elif [[ -f "$HOME/.config/bashrc/aliases" ]]; then
	source "$HOME/.config/bashrc/aliases"
fi

#######################################################
# Enhancd next-generation cd command with an interactive filter
# Link: https://github.com/b4b4r07/enhancd
# Install: cd ~ && git clone https://github.com/b4b4r07/enhancd
# NOTE: Breaks/replaces Bash shell option "shopt -s cdable_vars"
#######################################################

# If enhancd is installed, initialize it
if [[ -f "$HOME/enhancd/init.sh" ]]; then
	ENHANCD_FILTER=fzy:sk:fzf:peco:percol:pick:icepick:selecta:sentaku:zf
	export ENHANCD_FILTER
	source ~/enhancd/init.sh
fi

#######################################################
# Fasd keeps track of files and directories you have
# accessed so that you can quickly reference them
# a  - any (directory or file)
# s  - show / search / select
# d  - directory
# f  - file
# sd - interactive directory selection
# sf - interactive file selection
# z  - cd, same functionality as j in autojump
# zz - cd with interactive selection
# Link: https://github.com/clvv/fasd
#######################################################

# If fasd is installed, initialize it
if cmd-exists --strict fasd; then
	eval "$(fasd --init auto)"
fi

#######################################################
# Automatically source node.js and npm
#######################################################

# Load the npm configuration and bash completion
if cmd-exists --strict npm; then
	export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# Source Node Version Manager to manage multiple active node.js versions
if [[ -f /usr/share/nvm/init-nvm.sh ]]; then
	source /usr/share/nvm/init-nvm.sh
fi

#######################################################
# Automatically source all files/links in the directory:
# ~/.config/bashrc/bashrc.d
#######################################################

# If the auto-source folder exists and has files in it...
if [[ -d $HOME/.config/bashrc/bashrc.d ]]; then

	# If the directory is not empty...
	if [[ "$(\ls -A $HOME/.config/bashrc/bashrc.d)" ]]; then

		# Loop through files (in alphabetical order) and source them
		# To specify a load order, files can be prefixed with numbers
		# (e.g. 00--filename, 50--filename, 95--filename)
		for file in $HOME/.config/bashrc/bashrc.d/*; do
			source "${file}"
		done
	fi
fi

#######################################################
# This default prompt will be used if another prompt is not installed
# Link: https://ezprompt.net/ (some modifications below)
# Git Code Reference:
# > Renamed
# * Ahead
# + New File
# ? Untracked
# x Deleted
# ! Dirty
#######################################################

# Get current branch in Git repo
function _parse_git_branch() {
	if [[ $_GIT_IS_SLOW = false ]]; then
		BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
		if [[ ! "${BRANCH}" == "" ]]; then
			STAT=`_parse_git_dirty`
			echo " [${BRANCH}${STAT}]"
		else
			echo ""
		fi
	else
		_fast_git_ps1 "${@}"
	fi
}

# Get current status of Git repo
function _parse_git_dirty {
	# Check if we are in a git directory
	if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
		echo ""
		return
	fi

	# Get git status only once
	local status=$(git status --porcelain 2>&1)

	# Check for conditions using pattern matching
	local dirty=$(echo "$status" | grep -c '^ M')
	local untracked=$(echo "$status" | grep -c '^??')
	local ahead=$(git rev-list --count HEAD...@'{u}' 2>/dev/null || echo 0)
	local newfile=$(echo "$status" | grep -c '^A')
	local renamed=$(echo "$status" | grep -c '^R')
	local deleted=$(echo "$status" | grep -c '^D')

	# Build the status string
	local bits=''
	[ ${renamed:-0} -ne 0 ] && bits=">${bits}"
	[ ${ahead:-0} -ne 0 ]   && bits="*${bits}"
	[ ${newfile:-0} -ne 0 ] && bits="+${bits}"
	[ ${untracked:-0} -ne 0 ] && bits="?${bits}"
	[ ${deleted:-0} -ne 0 ] && bits="x${bits}"
	[ ${dirty:-0} -ne 0 ]   && bits="!${bits}"

	# Output result
	[ ! -z "${bits}" ] && echo " ${bits}" || echo ""
}

# Faster Git information for Git Bash and slow networks
# https://stackoverflow.com/questions/4485059/git-bash-is-extremely-slow-in-windows-7-x64/19500237#19500237
# https://stackoverflow.com/questions/4485059/git-bash-is-extremely-slow-in-windows-7-x64/13476961#13476961
# https://stackoverflow.com/questions/39518124/check-if-directory-is-git-repository-without-having-to-cd-into-it/39518382#39518382
function _fast_git_ps1 () {
	git -C . rev-parse 2>/dev/null && echo " [$((git symbolic-ref --short -q HEAD || git rev-parse -q --short HEAD) 2> /dev/null)]"
}

# Return the path for the "full path" multi-line prompt
function _pwd() {
	# Returns the full path but still shows the home directory as ~
	echo $PWD | sed 's@'${HOME}'@~@'
}

# Clear out the prompt command before we begin
# Some environments can set this and cause errors
export PROMPT_COMMAND=''

# Set the prompt
# If using Git Bash or Cygwin...
if [[ "$_KERNEL_NAME" = "MINGW" ]] || [[ "$_KERNEL_NAME" = "CYGWI" ]]; then

	# Prompt using faster and less intensive functions on Git Bash
	export PS1="\[\033[0;35m\]\u \[\033[0;34m\]\D{%b %d} \[\033[0;36m\]\A \[\033[0;33m\]\w\[\033[0;31m\]\`_fast_git_ps1\`\[\033[0m\]\n\\$ "

else # Standard default prompt

	# Prompt color changes if logged on as root
	if [[ $EUID > 0 ]]; then
		_COLOR_USER="\033[0;32m"
	else
		_COLOR_USER="\033[1;31m"
	fi

	# Date formats can be found here (man strftime):
	# https://manpages.ubuntu.com/manpages/xenial/man3/strftime.3.html
	# https://www.cyberciti.biz/faq/linux-unix-formatting-dates-for-display/

	# Only if connected SSH, show the host
	if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
		if [[ $_PROMPT_BUILTIN_FULL_PATH = false ]]; then
			# Remote SSH with short path (1 line)
			export PS1="\[\033[0;35m\]\u@\[\033[1;35m\]\h \[\033[0;34m\]\D{%b %-d} \[\033[0;36m\]\D{%-H:%M} \[\033[0;33m\]\w\[\033[0;31m\]\`_parse_git_branch\` \[${_COLOR_USER}\]>\[\033[0m\] "
		else
			# Remote SSH with full path (2 lines)
			export PS1="\[\033[0;35m\]\u@\[\033[1;35m\]\h \[\033[0;34m\]\D{%b %-d} \[\033[0;36m\]\D{%-H:%M:%S} \[\033[0;33m\]\$(_pwd)\[\033[0;31m\]\`_parse_git_branch\`\[\033[0m\]\n\[${_COLOR_USER}\]>\[\033[0m\] "
		fi
	else # Otherwise, only show the name
		if [[ $_PROMPT_BUILTIN_FULL_PATH = false ]]; then
			# Local with short path (1 line)
			export PS1="\[\033[0;35m\]\u \[\033[0;34m\]\D{%b %-d} \[\033[0;36m\]\D{%-H:%M} \[\033[0;33m\]\w\[\033[0;31m\]\`_parse_git_branch\` \[${_COLOR_USER}\]>\[\033[0m\] "
		else
			# Local with full path (2 lines)
			export PS1="\[\033[0;35m\]\u \[\033[0;34m\]\D{%b %-d} \[\033[0;36m\]\D{%-H:%M:%S} \[\033[0;33m\]\$(_pwd)\[\033[0;31m\]\`_parse_git_branch\`\[\033[0m\]\n\[${_COLOR_USER}\]>\[\033[0m\] "
		fi
	fi
fi

#######################################################
# Attempt to find and load some of the top installed prompts
# Only set and replace the custom prompt script if installed
# Otherwise, the standard prompt in a section above is already set
#######################################################

# The original older Extreme Ultimate .bashrc File prompt with added Git support
if [[ -f "$HOME/.bashrc_prompt" ]] && [[ $_SKIP_PROMPT_ORIGINAL = false ]]; then
	source "$HOME/.bashrc_prompt"
elif [[ -f "$HOME/.config/bashrc/prompt" ]] && [[ $_SKIP_PROMPT_ORIGINAL = false ]]; then
	source "$HOME/.config/bashrc/prompt"

# Trueline Bash (true 24-bit color and glyph support)
# This is the preferred prompt since it looks amazing,
# has so many features, is easily extended using functions,
# and is a single Bash script file that is easy to install.
# NOTE: You can place trueline.sh in the ~/.config/bashrc directory to keep it out of home
# Link: https://github.com/petobens/trueline
# Install: wget https://raw.githubusercontent.com/petobens/trueline/master/trueline.sh -P ~/
# Fonts: https://github.com/powerline/fonts
elif cmd-exists --strict trueline && [[ $_SKIP_PROMPT_TRUELINE = false ]]; then
	source "$(\which trueline)"
elif [[ -f /usr/bin/trueline ]] && [[ $_SKIP_PROMPT_TRUELINE = false ]]; then
	source /usr/bin/trueline
elif [[ -f "$HOME/.config/bashrc/trueline.sh" ]] && [[ $_SKIP_PROMPT_TRUELINE = false ]]; then
	source "$HOME/.config/bashrc/trueline.sh"
elif [[ -f "$HOME/trueline/trueline.sh" ]] && [[ $_SKIP_PROMPT_TRUELINE = false ]]; then
	source "$HOME/trueline/trueline.sh"
elif [[ -f "$HOME/trueline.sh" ]] && [[ $_SKIP_PROMPT_TRUELINE = false ]]; then
	source "$HOME/trueline.sh"

# Powerline-Go Global Install (this prompt uses no special glyphs)
# Link: https://github.com/justjanne/powerline-go
elif [[ -f "/usr/bin/powerline-go" ]] && [[ $_SKIP_PROMPT_POWERLINE_GO = false ]]; then

	# Prompt Configuration for Powerline-Go
	function _powerline_go_update_ps1() {
		PS1="$(/usr/bin/powerline-go -error $? -jobs $(jobs -p | wc -l))"

		# Automatically clear errors after showing them once (can cause problems)
		#set "?"
	}
	PROMPT_COMMAND="_powerline_go_update_ps1; $PROMPT_COMMAND"
# Powerline-Go Home Folder Install (this prompt uses no special glyphs)
elif [[ -f "$GOPATH/bin/powerline-go" ]] && [[ $_SKIP_PROMPT_POWERLINE_GO = false ]]; then

	# Prompt Configuration for Powerline-Go
	function _powerline_go_update_ps1() {
		PS1="$($GOPATH/bin/powerline-go -error $? -jobs $(jobs -p | wc -l))"

		# Automatically clear errors after showing them once (can cause problems)
		#set "?"
	}
	PROMPT_COMMAND="_powerline_go_update_ps1; $PROMPT_COMMAND"

# Powerline-Shell (details about git/svn/hg/fossil branch and Python virtualenv environment)
# Link: https://github.com/b-ryan/powerline-shell
elif cmd-exists --strict powerline-shell && [[ $_SKIP_PROMPT_POWERLINE_SHELL = false ]]; then

	# Prompt Configuration for Powerline-Shell
	function _powerline_shell_update_ps1() {
		PS1=$(powerline-shell $?)
	}
	PROMPT_COMMAND="_powerline_shell_update_ps1; $PROMPT_COMMAND"

# Pureline (256 color written in bash script)
# Link: https://github.com/chris-marsh/pureline
# Install:
# git clone https://github.com/chris-marsh/pureline.git
# cp pureline/configs/powerline_full_256col.conf ~/.pureline.conf
elif [[ -f "$HOME/pureline/pureline" ]] && [[ $_SKIP_PROMPT_PURELINE = false ]]; then
	source "$HOME/pureline/pureline $HOME/.pureline.conf"

# Starship Cross Shell Prompt (focus on compatibility and written in Rust)
# Link: https://starship.rs
# Install: sh -c "$(curl -fsSL https://starship.rs/install.sh)"
elif cmd-exists --strict starship && [[ $_SKIP_PROMPT_STARSHIP = false ]]; then
	eval "$(starship init bash)"

# Oh-My-Git (only used for Git but has huge support for it, requires font)
# Link: https://github.com/arialdomartini/oh-my-git
# Install: git clone https://github.com/arialdomartini/oh-my-git.git ~/.oh-my-git
elif [[ -f "$HOME/.oh-my-git/prompt.sh" ]] && [[ $_SKIP_PROMPT_OH_MY_GIT = false ]]; then
	source "$HOME/.oh-my-git/prompt.sh"

# Bash Git Prompt (shows git repository, branch name, difference with remote branch, number of files staged, changed, etc)
# Link: https://github.com/magicmonty/bash-git-prompt
# Install: git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt --depth=1
elif [[ -f /usr/lib/bash-git-prompt/gitprompt.sh ]] && [[ $_SKIP_PROMPT_BASH_GIT_PROMPT = false ]]; then
	# To only show the git prompt in or under a repository directory
	GIT_PROMPT_ONLY_IN_REPO=1
	# To use upstream's default theme
	# GIT_PROMPT_THEME=Default
	# To use upstream's default theme, modified by arch maintainer
	GIT_PROMPT_THEME=Default_Arch
	source /usr/lib/bash-git-prompt/gitprompt.sh
elif [[ -f "$HOME/.bash-git-prompt/gitprompt.sh" ]] && [[ $_SKIP_PROMPT_BASH_GIT_PROMPT = false ]]; then
	# To only show the git prompt in or under a repository directory
	GIT_PROMPT_ONLY_IN_REPO=1
	# To use upstream's default theme
	# GIT_PROMPT_THEME=Default
	# To use upstream's default theme, modified by arch maintainer
	GIT_PROMPT_THEME=Default_Arch
	source "$HOME/.bash-git-prompt/gitprompt.sh"

# Bash Powerline (no need for patched fonts, supports git, previous command execution status, platform-dependent prompt symbols)
# Link: https://github.com/riobard/bash-powerline
# Install: curl https://raw.githubusercontent.com/riobard/bash-powerline/master/bash-powerline.sh > ~/.bash-powerline.sh
elif [[ -f "$HOME/.bash-powerline.sh" ]] && [[ $_SKIP_PROMPT_BASH_POWERLINE = false ]]; then
	source "$HOME/.bash-powerline.sh"

# Sexy Bash Prompt (supports git, 256 color)
# Link: https://github.com/twolfson/sexy-bash-prompt
# Install: (cd /tmp && ([[ -d sexy-bash-prompt ]] || git clone --depth 1 --config core.autocrlf=false https://github.com/twolfson/sexy-bash-prompt) && cd sexy-bash-prompt && make install)
elif [[ -f "$HOME/.bash_prompt" ]] && [[ $_SKIP_PROMPT_SEXY_BASH_PROMPT = false ]]; then
	source "$HOME/.bash_prompt"

# Liquid Prompt (adaptive prompt with low color and no glyphs)
# Link: https://github.com/nojhan/liquidprompt
# Install: git clone --branch stable https://github.com/nojhan/liquidprompt.git ~/liquidprompt
elif [[ -f "$HOME/liquidprompt/liquidprompt" ]] && [[ $_SKIP_PROMPT_LIQUIDPROMPT = false ]]; then
	source "$HOME/liquidprompt/liquidprompt"

# Original Powerline Status Line for Vim Bash Zsh fish tmux IPython Awesome i3 Qtile
# Link: https://github.com/powerline/powerline
# Install: https://medium.com/earlybyte/powerline-for-bash-6d3dd004f6fc
# NOTE: Requires Python and can be used with Trueline in Bash
# WARNING: This path may change or break in the future with new Python versions
elif [[ $_SKIP_PROMPT_POWERLINE = false ]]; then
	_POWERLINE_PATH=$(find /usr/lib/python3* -type f -path "*/site-packages/powerline/bindings/bash/powerline.sh" 2>/dev/null | head -n 1)
	if [[ -f "$_POWERLINE_PATH" ]]; then
		source "$_POWERLINE_PATH"
	fi
fi

#######################################################
# Play nice with Midnight Commander subshell
# Link: https://midnight-commander.org/
# Link: https://superuser.com/questions/526201/how-to-change-the-prompt-of-mcs-subshell
#######################################################

if [[ -n "$(ps $PPID | grep -w [m]c)" ]]; then
	# The Midnight Commander subshell doesn't like aliases for pwd
	unalias pwd >/dev/null 2>/dev/null

	# Exit here
	return
fi

#######################################################
# Blesh: Bash Line Editor replaces default GNU Readline (Do this step last)
# Link: https://github.com/akinomyoga/ble.sh
# Link for configuration: https://github.com/akinomyoga/ble.sh/blob/master/blerc
# WARNING: Can be buggy with certain prompts (like Trueline)
# To Update (in a ble.sh session): ble-update
# To Install:
# git clone --recursive https://github.com/akinomyoga/ble.sh.git
# make -C ble.sh
#######################################################

# Define an array of possible locations for ble.sh (checked in order)
_BLESH_PATHS=(
	"$HOME/ble.sh/out/ble.sh"          # Local installation
	"$HOME/.local/share/blesh/ble.sh"  # User-level installation
	"/usr/share/blesh/ble.sh"          # System-wide installation
)

# Loop through each potential path to find where ble.sh might be located
for _BLESH_PATH in "${_BLESH_PATHS[@]}"; do
	# Check if ble.sh exists at the current path in the loop
	if [[ -f $_BLESH_PATH ]]; then

		# Check if Blesh should be skipped
		if [[ $_SKIP_BLESH = false ]]; then

			# If found, source ble.sh from the located path
			source "${_BLESH_PATH}"

			# Set the prompt end-of-line mark to a specific character
			bleopt prompt_eol_mark='⏎'

			# Easier to read syntax highlighting for function names
			ble-face -s syntax_function_name  fg=171,bold
			ble-face -s command_function      fg=171
			ble-face -s varname_expr          fg=171,bold

			# Bind 'C-d' to exit in ble.sh and suppress any output or error
			ble-bind -x 'C-d' 'exit' > /dev/null 2>&1 # CTRL+d to exit

			# Create an alias to load/reload ble.sh
			alias blesh="ble-reload"
		else
			# Create an alias to load/reload ble.sh
			alias blesh="source ${_BLESH_PATH} && bleopt prompt_eol_mark='⏎' && ble-face -s syntax_function_name fg=171,bold && ble-face -s command_function fg=171 && ble-face -s varname_expr fg=171,bold && ble-bind -x 'C-d' 'exit' > /dev/null 2>&1"
		fi

		# Exit the loop as ble.sh has been found and sourced
		break
	fi
done

# Clean up
unset _BLESH_PATH
unset _BLESH_PATHS

#######################################################
# Terminology is a graphical EFL terminal emulator that can run in TTY sessions
# To split the window horizontally press Ctrl+Shift+PgUp
# To split the window vertically press Ctrl+Shift+PgDn
# To create Tabs press Ctrl+Shift+T and cycle through using Ctrl+1-9
# Link: https://github.com/borisfaure/terminology
# Link: https://linoxide.com/terminology-terminal/
#######################################################

if [[ $_SKIP_TERMINOLOGY_TTY = false ]] && cmd-exists --strict terminology; then
	# If we are in a TTY window , not in TMUX, and not logged in via SSH...
	if [[ "$(tty)" =~ /dev/tty ]] && [[ ! "$TERM" =~ screen ]] && [[ -z "$SSH_CLIENT" ]] && [[ -z "$SSH_TTY" ]]; then

		# If TMUX is installed and set to load at TTY
		if [[ $_TMUX_LOAD_TTY = true ]] && cmd-exists --strict tmux; then

			# Get the default session name
			if [[ -z "${_TMUX_LOAD_SESSION_NAME}" ]]; then
				if [[ "$(tmux list-sessions 2> /dev/null | wc -l)" -gt 0 ]]; then
					_TMUX_LOAD_SESSION_NAME=""
				else
					_TMUX_LOAD_SESSION_NAME="$(whoami)"
				fi
			fi

			# Create the TMUX session if it doesn't exist
			TMUX='' tmux -u new-session -d -s "${_TMUX_LOAD_SESSION_NAME}" 2> /dev/null
			terminology --fullscreen --borderless --256color --exec "tmux attach -t ${_TMUX_LOAD_SESSION_NAME}"

		# No TMUX
		else
			terminology --fullscreen --borderless --256color && exit
		fi

	fi

#######################################################
# Automatically launch TMUX if this is a TTY Console or SSH session
# Most terminals can launch TMUX and automatically exit when TMUX is detached:
# konsole -e 'tmux new-session -A -s main'
# xfce4-terminal -e 'tmux new-session -A -s main'
# gnome-terminal -e 'tmux new-session -A -s main'
# kitty sh -c "tmux new-session -A -s main"
# terminology --exec "tmux new-session -A -s main"
# guake -e tmux
# Yakuake Profile -> Command -> /bin/bash -c "tmux new-session -A -s main"
# Alacritty: https://github.com/alacritty/alacritty/issues/2956
# ssh user@server -t tmux new-session -A -s main
#######################################################

# If TMUX is installed...
elif cmd-exists --strict tmux; then

	# We're in a TTY terminal...
	if [[ "$(tty)" =~ /dev/tty ]] && [[ ! "$TERM" =~ screen ]]; then
		[[ $_TMUX_LOAD_TTY = true ]] && tm

	# We're logged in via SSH...
	elif [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
		[[ $_TMUX_LOAD_SSH = true ]] && tm

	# We are local and not using SSH or TTY...
	else
		[[ $_TMUX_LOAD_LOCAL = true ]] && tm
	fi
fi

#######################################################
# Tilix VTE Configuration
# Link: https://gnunn1.github.io/tilix-web/manual/vteconfig/
#######################################################

if [[ $TILIX_ID ]] || [[ $VTE_VERSION ]]; then
	if [[ -f /etc/profile.d/vte.sh ]]; then
		source /etc/profile.d/vte.sh
	fi
fi
. "$HOME/.cargo/env"
