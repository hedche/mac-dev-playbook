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
- The default wallpaper path is repo-relative: `{{ playbook_dir }}/files/IMG_1950.jpeg`.

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
