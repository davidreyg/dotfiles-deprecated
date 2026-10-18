# Dotfiles

This repository is managed with [chezmoi](https://www.chezmoi.io/). The source
layout uses `.chezmoiroot` to keep the repository metadata and documentation at
the root while all home-directory sources live under `home/`.

The first provisioning module installs and configures Zsh without changing the
default login shell or modifying the existing Bash configuration.

## Source layout

```text
.
├── .chezmoiroot
├── README.md
└── home/
    ├── .chezmoidata/packages.yaml
    ├── .chezmoitemplates/
    │   ├── shell/aliases.tmpl
    │   └── shared/paths.tmpl
    ├── .chezmoiscripts/
    │   ├── run_before_00_preflight.sh.tmpl
    │   ├── run_before_10_install-packages.sh.tmpl
    │   └── run_onchange_after_90_change-shell.sh.tmpl
    ├── dot_config/
    │   ├── chezmoi/chezmoi.toml
    │   └── zsh/conf.d/
    │       ├── aliases.zsh.tmpl
    │       └── exports.zsh.tmpl
    ├── dot_bashrc.tmpl
    ├── dot_gitconfig.tmpl
    └── dot_zshrc.tmpl
```

Files under `.chezmoitemplates/` are reusable definitions, not home-directory
targets. The `.tmpl` suffix on `aliases.zsh` and `exports.zsh` is intentional:
it renders those files while preserving the clean target names in `$HOME`.
The default-shell script is present but disabled by default. Its setting is
managed in `~/.config/chezmoi/chezmoi.toml`, which is itself managed by this
repository. This keeps the decision reproducible without managing unrelated
directories under `~/.config`.

## Safe Zsh setup

The package installer reads package names from
[`home/.chezmoidata/packages.yaml`](./home/.chezmoidata/packages.yaml) and
installs every enabled group. It supports Debian/Ubuntu, Fedora/RHEL/CentOS,
Arch-based systems, openSUSE/SLES, Alpine, and macOS with Homebrew. Package
managers are idempotent, so adding a package to an enabled group is safe.

Use the groups as profiles:

- `base`: tools required on every machine.
- `shell`: Zsh and shell-related packages.
- `development`: optional development tools such as `curl`, `ripgrep`, and
  `fd`; set `enabled: true` when you want that profile.

For occasional packages, prefer adding a new named group in the same catalog
instead of editing the installation script. For example, create an `office` or
`cloud` group and enable it per machine. This keeps package names declarative
and the installer generic. If a package is truly one-off, install it manually;
do not add a special command to the script.

Inspect changes before applying them:

```sh
chezmoi diff
chezmoi apply --dry-run --verbose
```

Apply the configuration:

```sh
chezmoi apply
```

Start Zsh for testing without changing the default shell:

```sh
zsh
```

The default shell is not changed by default. After testing, edit
`home/dot_config/chezmoi/chezmoi.toml`:

```toml
[data.shell]
change_default = true
```

Commit that change and run `chezmoi apply`. The post-apply script verifies that
Zsh is listed in `/etc/shells` before calling `chsh`. Set the value back to
`false` for machines where you want to keep the current login shell.

Because chezmoi reads its configuration before applying files, after changing
this managed file you should run `chezmoi apply` twice: the first run updates
`~/.config/chezmoi/chezmoi.toml`, and the second run reads the new value. The
`run_onchange_after_90_change-shell.sh.tmpl` script then runs because its
rendered content changed. It will not run again unless the rendered script
changes, so repeated `chezmoi apply` calls are safe.

Changing the login shell may require interactive authentication. If `chsh`
fails with a PAM authentication error, run the command directly in an
interactive terminal and then verify the account entry:

```sh
chsh -s "$(command -v zsh)"
getent passwd "$USER" | cut -d: -f7
```

The current terminal keeps its old shell; start a new login session to observe
the change.

The configuration includes history, basic aliases, shell completion, and the
Bitwarden `rbw` SSH agent socket when `XDG_RUNTIME_DIR` is available. Bash and
Starship remain unchanged. Only the explicitly managed `chezmoi`, `rbw`, and
`zsh` directories under `~/.config` are part of this repository; unrelated
directories such as `Code` and `ubuntu-insights` are left alone.

To verify idempotence, run `chezmoi apply` a second time and confirm that it
does not report unexpected changes. Review `chezmoi diff` before accepting any
conflict; do not use `--force` to hide one.
