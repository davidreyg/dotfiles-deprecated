# Dotfiles

This repository is managed with [chezmoi](https://www.chezmoi.io/). The source
layout uses `.chezmoiroot` to keep the repository metadata and documentation at
the root while all home-directory sources live under `home/`.

The provisioning configures Zsh and can change the default login shell according
to `home/dot_config/chezmoi/chezmoi.toml`; the existing Bash configuration is
not modified.

## Source layout

```text
.
├── .chezmoiroot
├── README.md
└── home/
    ├── .chezmoidata/
    │   ├── packages.yaml
    │   └── zsh.yaml
    ├── .chezmoitemplates/
    │   ├── shell/aliases.tmpl
    │   └── shared/paths.tmpl
    ├── .chezmoiscripts/
    │   ├── run_before_00_preflight.sh.tmpl
    │   ├── run_before_10_install-packages.sh.tmpl
    │   ├── run_before_20_install-zinit.sh.tmpl
    │   └── run_onchange_after_90_change-shell.sh.tmpl
    ├── dot_config/
    │   ├── chezmoi/chezmoi.toml
    │   ├── starship.toml
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
The default-shell setting is managed in `~/.config/chezmoi/chezmoi.toml`, which
is itself managed by this repository. It is currently enabled
(`change_default = true`), so chezmoi changes the login shell to Zsh after
verifying that Zsh is listed in `/etc/shells`. Set it to `false` on machines
where the current login shell must be preserved.

## Safe Zsh setup

The package installer reads package names from
[`home/.chezmoidata/packages.yaml`](./home/.chezmoidata/packages.yaml) and
installs every enabled group. It supports Debian/Ubuntu, Fedora/RHEL/CentOS,
Arch-based systems, openSUSE/SLES, Alpine, and macOS with Homebrew. Package
managers are idempotent, so adding a package to an enabled group is safe.

Use the groups as profiles:

- `base`: tools required on every machine, including the JetBrains Mono Nerd
  Font required by the Starship prompt symbols.
- `shell`: Zsh and Starship.
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

Start a new Zsh session for testing:

```sh
zsh
```

To keep the current default shell, edit
`home/dot_config/chezmoi/chezmoi.toml`:

```toml
[data.shell]
change_default = false
```

Run `chezmoi apply`. The post-apply script verifies that Zsh is listed in
`/etc/shells` before calling `chsh`. Set the value back to `true` when Zsh
should be the login shell.

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

## Zinit and Starship

Zsh integrations are configured independently from the system package catalog
in [`home/.chezmoidata/zsh.yaml`](./home/.chezmoidata/zsh.yaml). The default
profile installs Starship and clones Zinit into
`${XDG_DATA_HOME:-$HOME}/zinit/zinit.git` when it is missing. Existing Zinit
checkouts are preserved and are not updated automatically.

The recommended plugin set includes:

- `zsh-users/zsh-completions` for additional completions.
- `zdharma-continuum/fast-syntax-highlighting` for command highlighting.
- `zsh-users/zsh-autosuggestions` for history-based suggestions.
- `Aloxaf/fzf-tab` for fuzzy completion menus.
- `MichaelAquilina/zsh-you-should-use` for alias reminders.

Plugins and snippets are enabled or disabled by changing their `enabled` value
in `zsh.yaml`. Each entry can define an `ice` list; every item is rendered as
one `zinit ice` command immediately before that load. This supports options
such as `atload`, `as`, and `atinit` without changing the template. For example:

```yaml
- enabled: true
  source: OMZ::plugins/docker/completions/_docker
  ice:
    - 'as"completion"'
```

The `for` section supports `zinit for` loads with multiple sources, while
`zsh.options` supports shell options such as `promptsubst`. The catalog includes
enabled examples for `OMZL::git.zsh`, `OMZP::git`, `OMZL::key-bindings.zsh`,
colored man pages, and the Docker plugin/completion. The prompt-information
example using `zinit for` is disabled by default; enable it when needed.
Starship is initialized only when its command is available, so a partial
provisioning run does not prevent Zsh from starting. The prompt configuration is
managed in
[`home/dot_config/starship.toml`](./home/dot_config/starship.toml). The base
profile also installs JetBrains Mono Nerd Font; Homebrew installs it as a cask
on macOS. Bash is intentionally left unchanged.

The configuration includes history, basic aliases, shell completion, and the
Bitwarden `rbw` SSH agent socket when `XDG_RUNTIME_DIR` is available. Only the
explicitly managed `chezmoi`, `rbw`, `starship`, and `zsh` directories under
`~/.config` are part of this repository; unrelated directories such as `Code`
and `ubuntu-insights` are left alone.

To verify idempotence, run `chezmoi apply` a second time and confirm that it
does not report unexpected changes. Review `chezmoi diff` before accepting any
conflict; do not use `--force` to hide one.

## Tests

The repository includes fast tests that validate rendered chezmoi templates,
shell syntax, package metadata, and the configured Zinit commands. They do not
install the real package profile or modify the host home directory.

Install `chezmoi`, `zsh`, and `shellcheck`, then run:

```sh
make test
```

The same suite can run in a clean Ubuntu 24.04 container. Docker is used only
for isolation; package installation and Zinit cloning are not executed by the
tests:

```sh
make test-docker
```

GitHub Actions runs both the native Ubuntu test and the Docker test. The
package installer remains intentionally outside the default test path because
its behavior depends on the host distribution, privileges, package mirrors,
and (on macOS) Homebrew casks.
