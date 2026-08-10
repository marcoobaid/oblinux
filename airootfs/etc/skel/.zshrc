# OBLinux default .zshrc for newly created users (installed systems only —
# the live session's liveuser has its own separate config, see
# airootfs/home/liveuser/.zshrc).
#
# `useradd -m` populates a new user's home directory from /etc/skel, not
# from liveuser's home — without a file here, a new user's login shell
# being zsh (users.conf: user.shell) would trigger zsh's interactive
# first-run configuration wizard instead of a working shell. This is
# deliberately minimal, not the live session's branded prompt: an
# OBLinux-themed prompt for installed systems is theming/ricing work,
# out of scope for this phase (see README's phase 3/4 notes).

autoload -Uz compinit && compinit
