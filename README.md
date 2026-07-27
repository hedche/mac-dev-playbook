<img src="https://raw.githubusercontent.com/hedche/mac-dev-playbook/master/files/Mac-Dev-Playbook-Logo.png" width="250" height="156" alt="Mac Dev Playbook Logo" />

# Mac Development Ansible Playbook

[![CI][badge-gh-actions]][link-gh-actions]

This repository is a fork of Jeff Geerling's macOS playbook, updated for this fork's current setup.

It provisions a Mac with Homebrew packages and casks, dotfiles, Dock configuration, Terminal settings, Oh My Zsh, Stats preferences, optional repo cloning, and additional package-manager installs.

## What this fork does

The playbook currently wires together:

- `elliotweiser.osx-command-line-tools`
- `geerlingguy.mac.homebrew`
- `geerlingguy.dotfiles`
- `geerlingguy.mac.mas`
- `geerlingguy.mac.dock`
- local tasks for:
  - sudoers configuration
  - Terminal profile installation
  - macOS defaults via `.osx`
  - Oh My Zsh installation
  - Stats app preferences
  - cloning personal GitHub repositories
  - extra Composer / npm / pip / gem packages
  - optional post-provision task files

## Current assumptions in this fork

This repository is tailored to the local setup and is not fully generic as-is.

- The default config clones dotfiles from `git@github.com:hedche/dot-files.git`.
- The dotfiles are expected at `~/dv/dot-files`.
- User-specific paths have been converted to `HOME`-relative Ansible variables where possible.
- The default wallpaper path is repo-relative: `{{ playbook_dir }}/files/background.jpeg`.

If you are using this on another machine or username, review `config.yml` and the files under `tasks/` before running the playbook.

## Installation

1. Install Apple's command line tools:

   ```sh
   xcode-select --install
   ```

2. Install Ansible:

   ```sh
   export PATH="$HOME/Library/Python/3.9/bin:/opt/homebrew/bin:$PATH"
   sudo pip3 install --upgrade pip
   pip3 install ansible
   ```

3. Clone this repository:

   ```sh
   cd "$HOME" && mkdir -p dv && cd dv
   git clone git@github.com:hedche/mac-dev-playbook.git
   cd mac-dev-playbook
   ```

4. Install Ansible Galaxy requirements:

   ```sh
   ansible-galaxy install -r requirements.yml
   ```

5. Review `config.yml` and update any machine-specific values.

6. Run the playbook:

   ```sh
   ansible-playbook main.yml --ask-become-pass
   ```

   Or use the helper script:

   ```sh
   ./run.sh
   ```

If Homebrew-related steps fail, run `brew doctor` and resolve any Xcode or Homebrew issues first.

## Configuration

`default.config.yml` contains the upstream-style defaults. This fork's actual local defaults live in `config.yml`.

Notable settings in `config.yml`:

- `configure_dotfiles: true`
- `configure_terminal: true`
- `configure_osx: true`
- `configure_oh_my_zsh: true`
- `configure_stats: true`
- `configure_dock: true`
- `git_clone: true`

You can override any of these values in `config.yml`.

## Dotfiles

This fork uses the following dotfiles repository:

- repo: `git@github.com:hedche/dot-files.git`
- local destination: `~/dv/dot-files`
- branch: `master`

The playbook installs these files from that repo into the current user's home directory:

- `.zshrc`
- `.gitignore`
- `.gitconfig`
- `.inputrc`
- `.osx`
- `.vimrc`

You can disable dotfile management by setting `configure_dotfiles: false`.

## Default software in this fork

### Homebrew packages

- autoconf
- bash-completion
- git
- iperf
- nmap
- node
- ssh-copy-id
- openssl
- pv
- wget
- htop
- zsh-history-substring-search
- ffmpeg
- neovim
- defaultbrowser
- tmux
- yt-dlp
- tesseract
- ollama
- terraform
- watch
- oci-cli
- gh
- tree
- tailscale
- talosctl
- direnv
- k9s
- `fluxcd/tap/flux@2.6`
- kubeseal
- jq

### Homebrew taps

- `fluxcd/tap`

### Homebrew cask apps

- docker-desktop
- nordvpn
- arc
- chatgpt
- raycast
- visual-studio-code
- vlc
- whatsapp
- stats
- bitwarden
- transmission
- google-chrome
- microsoft-teams
- ghostty

### Git repositories cloned by default

Into `~/dv/`:

- `git@github.com:hedche/about-me.git`
- `git@github.com:hedche/devops-cheatsheet.git`
- `git@github.com:hedche/check-ping-shutdown.git`

## Dock setup

When `configure_dock` is enabled, the playbook removes a set of default macOS apps from the Dock and persists:

- Arc
- Terminal
- Visual Studio Code
- ChatGPT
- WhatsApp

## Docker Desktop CLI

Docker Desktop keeps its CLI binaries inside the app bundle and only symlinks
them into `/usr/local/bin` when you grant it privileged access from the GUI. A
Homebrew cask install never triggers that prompt, so `docker` ends up missing
from `PATH` entirely.

When `configure_docker` is enabled, `tasks/docker.yml` creates those symlinks
itself, which makes the CLI available to every shell and to GUI apps rather
than only to shells that source `~/.zshrc`. Configure it with:

- `docker_desktop_bin_dir` — where the bundled binaries live
- `docker_desktop_symlinks` — which binaries to link

`kubectl` also ships in the bundle but is deliberately left out, so the Homebrew
`kubernetes-cli` version stays authoritative.

The dotfiles repo covers the same ground from the shell side: `.zshrc` appends
`$HOME/.docker/bin` (Docker Desktop 4.18+) and the bundle's `bin` to `PATH` if
they exist. The two are complementary — the symlinks need sudo and cover
everything, the `PATH` entries need no privileges and cover interactive zsh.

## tmux session persistence

When `configure_tmux` is enabled, `tasks/tmux.yml` sets up tmux so your sessions
survive a reboot — names, windows, pane layouts, working directories, and the
Claude Code conversations that were running in them.

The stack is the standard one: [tpm](https://github.com/tmux-plugins/tpm) +
[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) (serialises the
environment to `~/.tmux/resurrect`) +
[tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) (saves every 5
minutes, restores when the tmux server starts). Config lives in the dotfiles
repo as `.tmux.conf`.

Two deliberate departures from the usual advice:

**Boot is handled by a LaunchAgent, not `@continuum-boot`.** Continuum's own boot
option opens a GUI terminal window at login and only supports
Terminal.app/iTerm2/kitty/Alacritty — not Ghostty. Instead
`~/Library/LaunchAgents/uk.leafbit.tmux-server.plist` runs `boot-tmux.sh`, which
starts a *headless* server; by the time you open a terminal and run `tmux a` the
sessions are already back. Logs go to `~/Library/Logs/tmux-boot.log`.

**Claude Code panes are tracked by hooks, not process detection.** Claude's
`pane_current_command` reports its version string (e.g. `2.1.220`) rather than
`claude`, so the `ps`-based detection used by third-party plugins does not find
it. Instead a `SessionStart` hook records the session ID against `$TMUX_PANE`,
resurrect's post-save hook resolves that to stable `session:window.pane`
coordinates, and the post-restore hook types `claude --resume <id>` into the
matching pane. **The command is typed but not executed** — after a reboot you
may have a dozen of them, so you press Enter on the ones you actually want. A
`SessionEnd` hook drops conversations you deliberately ended.

Scripts live in the dotfiles repo under `tmux/` and are symlinked into
`~/.tmux/scripts/`. The Claude hooks are merged into `~/.claude/settings.json`.

### Recovering a bad save

Continuum can overwrite a good save with a near-empty one if it fires while the
server is nearly empty. Resurrect keeps every save, so point `last` at an older
one and restore with `prefix + Ctrl-r`:

```sh
ls -t ~/.tmux/resurrect/tmux_resurrect_*.txt | head
ln -sf tmux_resurrect_<timestamp>.txt ~/.tmux/resurrect/last
```

### Limitations

- Claude returns with full conversation history, but any in-flight request at
  reboot is lost.
- A restored pane is only offered a resume if it is sitting at an idle shell.
- Conversations already running when the hooks were first installed are not
  recorded until their next start or resume.

## Supported tags

You can run a subset of the playbook with Ansible tags. Tags currently used in this repo include:

- `dotfiles`
- `homebrew`
- `mas`
- `dock`
- `sudoers`
- `terminal`
- `osx`
- `oh-my-zsh`
- `stats`
- `docker`
- `tmux`
- `git-clone`
- `extra-packages`
- `post`

Example:

```sh
ansible-playbook main.yml -K --tags "dotfiles,homebrew,dock"
```

## Remote Mac usage

You can also target another Mac over SSH.

1. Enable Remote Login on the target Mac:

   ```sh
   sudo systemsetup -setremotelogin on
   ```

2. Update `inventory` from:

   ```ini
   [all]
   127.0.0.1  ansible_connection=local
   ```

   to something like:

   ```ini
   [all]
   your-mac-hostname-or-ip ansible_user=your-username
   ```

## Testing and CI

GitHub Actions currently runs:

- `yamllint .`
- `ansible-lint`
- integration runs on `macos-14` and `macos-15`
- playbook syntax check
- full playbook execution
- idempotence check

## Notes

- `full-mac-setup.md` is still present in the repo, but it remains largely upstream/personal historical documentation and should not be treated as an exact description of this fork.
- The playbook sets Arc as the default browser by calling `defaultbrowser browser`.
- The playbook applies the wallpaper only when `wallpaper_path` is defined.

[badge-gh-actions]: https://github.com/hedche/mac-dev-playbook/actions/workflows/ci.yml/badge.svg
[link-gh-actions]: https://github.com/hedche/mac-dev-playbook/actions/workflows/ci.yml
