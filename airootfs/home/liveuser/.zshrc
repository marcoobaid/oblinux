# OBLinux live session shell config for liveuser.
# This is a live/rescue account only; it is not carried over to installs made with Calamares.

autoload -Uz compinit && compinit
PS1='%F{cyan}oblinux%f:%~%# '

# THEMING.md item 6: branded system-info banner on new interactive shells.
# Guarded so non-interactive invocations (scripts, command substitution)
# don't get it. Config/logo: /etc/xdg/fastfetch/ (system-wide, see that
# directory's config.jsonc for why no per-user copy is needed).
[[ $- == *i* ]] && command -v fastfetch &>/dev/null && fastfetch
