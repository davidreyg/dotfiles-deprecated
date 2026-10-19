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
render home/dot_bashrc.tmpl bashrc
render home/dot_profile.tmpl profile
render home/dot_config/zsh/conf.d/exports.zsh.tmpl exports
render home/dot_config/zsh/conf.d/evals.zsh.tmpl evals
render home/dot_config/zsh/conf.d/aliases.zsh.tmpl aliases
render home/.chezmoiscripts/run_before_10_install-packages.sh.tmpl packages.sh
render home/.chezmoiscripts/run_before_20_install-zinit.sh.tmpl zinit.sh
render home/.chezmoiscripts/run_onchange_after_20_mise-install.sh.tmpl mise-install.sh
render home/.chezmoiscripts/run_onchange_after_30_font-cache.sh.tmpl font-cache.sh
render home/.chezmoiexternal.toml.tmpl external.toml
chezmoi execute-template --source="$DOTFILES_ROOT" --init \
    --promptBool '¿Perfil de desarrollo?=false' \
    -f "$DOTFILES_ROOT/home/.chezmoi.toml.tmpl" > "$tmpdir/chezmoi.toml"

for shell_file in zshrc exports evals aliases; do
    zsh -n "$tmpdir/$shell_file"
done
sh -n "$tmpdir/bashrc" "$tmpdir/profile"
sh -n "$tmpdir/packages.sh"
sh -n "$tmpdir/zinit.sh"
sh -n "$tmpdir/mise-install.sh"
sh -n "$tmpdir/font-cache.sh"

if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "$tmpdir/packages.sh" "$tmpdir/zinit.sh"
fi

grep -F 'setopt append_history' "$tmpdir/zshrc" >/dev/null
grep -F 'zinit ice as"completion"' "$tmpdir/zshrc" >/dev/null
grep -F 'zinit ice atload"unalias grv"' "$tmpdir/zshrc" >/dev/null
grep -F 'zinit ice atinit"zicompinit; zicdreplay"' "$tmpdir/zshrc" >/dev/null
grep -F 'fpath=("$mise_completion_dir" $fpath)' "$tmpdir/zshrc" >/dev/null
grep -F '"$HOME/.local/bin"' "$tmpdir/zshrc" >/dev/null
if grep -F 'autoload -Uz compinit' "$tmpdir/zshrc" >/dev/null; then
    printf '%s\n' 'zshrc must not run compinit a second time.' >&2
    exit 1
fi
grep -F "zinit snippet 'https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/docker/completions/_docker'" "$tmpdir/zshrc" >/dev/null
grep -F 'mise_completion_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions"' "$tmpdir/zshrc" >/dev/null
grep -F 'brew install --cask' "$tmpdir/packages.sh" >/dev/null
if grep -E 'package_installed [^ ]+ "(rbw|starship)"' "$tmpdir/packages.sh" >/dev/null; then
    printf '%s\n' 'rbw and starship must not be installed by the system package script.' >&2
    exit 1
fi
grep -F "git clone 'https://github.com/zdharma-continuum/zinit.git'" "$tmpdir/zinit.sh" >/dev/null
grep -F 'completion zsh --install' "$tmpdir/mise-install.sh" >/dev/null
grep -F 'profiles = ["base", "shell"]' "$tmpdir/chezmoi.toml" >/dev/null
grep -F '[".local/bin/rbw"]' "$tmpdir/external.toml" >/dev/null
grep -F '[".local/bin/starship"]' "$tmpdir/external.toml" >/dev/null
grep -F '[".local/bin/mise"]' "$tmpdir/external.toml" >/dev/null
grep -F 'rbw_1.15.0_linux_amd64.tar.gz' "$tmpdir/external.toml" >/dev/null
