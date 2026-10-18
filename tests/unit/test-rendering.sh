#!/bin/sh

set -eu

: "${DOTFILES_ROOT:?DOTFILES_ROOT is required}"

command -v chezmoi >/dev/null 2>&1 || {
    printf '%s\n' 'chezmoi is required.' >&2
    exit 1
}
command -v zsh >/dev/null 2>&1 || {
    printf '%s\n' 'zsh is required.' >&2
    exit 1
}

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

render() {
    source_file=$1
    output_file=$2
    chezmoi execute-template --source="$DOTFILES_ROOT" \
        < "$DOTFILES_ROOT/$source_file" > "$tmpdir/$output_file"
}

render home/dot_zshrc.tmpl zshrc
render home/.chezmoiscripts/run_before_10_install-packages.sh.tmpl packages.sh
render home/.chezmoiscripts/run_before_20_install-zinit.sh.tmpl zinit.sh

zsh -n "$tmpdir/zshrc"
sh -n "$tmpdir/packages.sh"
sh -n "$tmpdir/zinit.sh"

if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "$tmpdir/packages.sh" "$tmpdir/zinit.sh"
fi

grep -F 'setopt append_history' "$tmpdir/zshrc" >/dev/null
grep -F 'zinit ice as"completion"' "$tmpdir/zshrc" >/dev/null
grep -F 'zinit ice atload"unalias grv"' "$tmpdir/zshrc" >/dev/null
grep -F 'zinit ice atinit"zicompinit; zicdreplay"' "$tmpdir/zshrc" >/dev/null
grep -F "zinit snippet 'OMZ::plugins/docker/completions/_docker'" "$tmpdir/zshrc" >/dev/null
grep -F 'brew install --cask' "$tmpdir/packages.sh" >/dev/null
grep -F "git clone 'https://github.com/zdharma-continuum/zinit.git'" "$tmpdir/zinit.sh" >/dev/null
