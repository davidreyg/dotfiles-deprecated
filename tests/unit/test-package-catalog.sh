#!/bin/sh

set -eu

: "${DOTFILES_ROOT:?DOTFILES_ROOT is required}"

catalog=$DOTFILES_ROOT/home/.chezmoidata/packages.yaml
zsh_catalog=$DOTFILES_ROOT/home/.chezmoidata/zsh.yaml

for package in git nmap make pinentry; do
    grep -E "^        ${package}:" "$catalog" >/dev/null
done

if grep -E '^        (rbw|starship):' "$catalog" >/dev/null; then
    printf '%s\n' 'rbw and starship must use external binaries, not system packages.' >&2
    exit 1
fi

for source in \
    'OMZL::git.zsh' \
    'OMZP::git' \
    'OMZP::colored-man-pages' \
    'OMZP::docker' \
    'https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/docker/completions/_docker'; do
    grep -F "source: $source" "$zsh_catalog" >/dev/null
done

grep -F "atload\"unalias grv\"" "$zsh_catalog" >/dev/null
grep -F "as\"completion\"" "$zsh_catalog" >/dev/null
grep -F "atinit\"zicompinit; zicdreplay\"" "$zsh_catalog" >/dev/null

external=$DOTFILES_ROOT/home/.chezmoiexternal.toml.tmpl
external_catalog=$DOTFILES_ROOT/home/.chezmoidata/external.yaml
grep -F 'archive-file' "$external" >/dev/null
grep -F 'binaries:' "$external_catalog" >/dev/null
grep -F '    mise:' "$external_catalog" >/dev/null
grep -F '  fonts:' "$external_catalog" >/dev/null
