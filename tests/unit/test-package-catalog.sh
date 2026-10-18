#!/bin/sh

set -eu

: "${DOTFILES_ROOT:?DOTFILES_ROOT is required}"

catalog=$DOTFILES_ROOT/home/.chezmoidata/packages.yaml
zsh_catalog=$DOTFILES_ROOT/home/.chezmoidata/zsh.yaml

for package in git nmap jetbrains-mono-nerd-font fzf eza; do
    grep -E "^        ${package}:" "$catalog" >/dev/null
done

grep -A8 '^        jetbrains-mono-nerd-font:' "$catalog" |
    grep -F 'brew_cask: true' >/dev/null
grep -A7 '^        starship:' "$catalog" |
    grep -F 'brew_cask: false' >/dev/null

for source in \
    'OMZL::git.zsh' \
    'OMZP::git' \
    'OMZP::colored-man-pages' \
    'OMZP::docker' \
    'OMZ::plugins/docker/completions/_docker'; do
    grep -F "source: $source" "$zsh_catalog" >/dev/null
done

grep -F "atload\"unalias grv\"" "$zsh_catalog" >/dev/null
grep -F "as\"completion\"" "$zsh_catalog" >/dev/null
grep -F "atinit\"zicompinit; zicdreplay\"" "$zsh_catalog" >/dev/null
