#!/bin/sh

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Preparing for for ${HOSTNAME} backup to lizzy"

BORG=/usr/bin/borg

# Avoid the need to give repo path/URL on the commandline:
export BORG_REPO=lizzy:/media/doug/backup/borg/greta

# Read repository passphrase from file:
export BORG_PASSCOMMAND="cat ${HOME}/.borg-passphrase"

info "Starting ${HOSTNAME} backup to lizzy"

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

${BORG} create                                                   \
    --verbose                                                    \
    --filter AME                                                 \
    --list                                                       \
    --stats                                                      \
    --show-rc                                                    \
    --compression auto,zstd                                      \
                                                                 \
    --exclude-caches                                             \
    --exclude "${HOME}/.borg-passphrase"                         \
    --exclude "${HOME}/.cache"                                   \
    --exclude "${HOME}/.config/Microsoft/Microsoft Teams/Cache"  \
    --exclude "${HOME}/.dbus"                                    \
    --exclude "${HOME}/.local/lib/python*"                       \
    --exclude "${HOME}/.local/share/flatpak*"                    \
    --exclude "${HOME}/.var"                                     \
    --exclude "${HOME}/.vscode"                                  \
    --exclude "${HOME}/Downloads"                                \
    --exclude "${HOME}/snap"                                     \
    --exclude "${HOME}/conda-envs"                          \
    --exclude "${HOME}/miniconda3"                          \
    --exclude "${HOME}/.local/share/Trash"                   \
    --exclude "${HOME}/.config/Slack/Cache"                \
    --exclude "${HOME}/Desktop/Old Firefox Data"            \
    --exclude "sh:${HOME}**/SalishSea_1h_*.nc"                   \
                                                                  \
    ::'{hostname}-{now}'                                         \
    ${HOME}                                                      \

backup_exit=$?

info "Pruning repository"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-' prefix is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

${BORG} prune                       \
    --list                          \
    --prefix '{hostname}-'          \
    --show-rc                       \
    --keep-daily    7               \
    --keep-weekly   4               \
    --keep-monthly  6               \

prune_exit=$?

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 1 ];
then
    info "Backup and/or Prune finished with a warning"
fi

if [ ${global_exit} -gt 1 ];
then
    info "Backup and/or Prune finished with an error"
fi

exit ${global_exit}
