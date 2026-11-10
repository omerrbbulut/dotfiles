# Dotfiles

Personal development environment configuration for Ubuntu and Arch Linux.

Managed with GNU Stow and Git.

## Components

| Component | Tool |
|-----------|------|
| Terminal | Kitty |
| Shell | Zsh |
| Prompt | Starship |
| Multiplexer | tmux |
| Theme | Catppuccin Mocha |
| Font | JetBrainsMono Nerd Font |
| Package management | APT / Pacman |
| Configuration management | GNU Stow |

## Supported Systems

- Ubuntu 24.04 LTS
- Arch Linux

Ubuntu configuration has been tested. Arch Linux support
requires validation on an Arch installation.

## Repository Structure

```text
dotfiles/
├── install.sh
├── packages/
│   ├── ubuntu.sh
│   └── arch.sh
├── kitty/
├── zsh/
├── starship/
├── tmux/
└── git/
```

## Installation

Clone the repository:

```bash
git clone <repository-url> ~/dotfiles
cd ~/dotfiles
```

Review the scripts before running them.

For a full installation:

```bash
./install.sh --all
```

To install only configuration symlinks and tmux plugins:

```bash
./install.sh
```

## Available Commands

```bash
./install.sh --help
./install.sh --check
./install.sh --dry-run
./install.sh --packages
./install.sh --starship
./install.sh --font
./install.sh --all
```

Note: The installer does not automatically back up conflicting
configuration files. Resolve Stow conflicts before installation.

## GNU Stow

Configuration files are managed using symbolic links.

Example:

```bash
cd ~/dotfiles
stow --no-folding -t "$HOME" kitty
```

To remove managed symlinks:

```bash
stow --no-folding -D -t "$HOME" kitty
```

## Git Identities

Git identities are managed using conditional configuration.

Personal projects:

```text
~/projects/personal/
```

Work projects:

```text
~/projects/work/
```

Check the active identity:

```bash
git config user.name
git config user.email
git config --show-origin --get user.email
```

Git author identity and remote authentication are configured
separately.

## Validation

Check the installation:

```bash
./install.sh --check
```

Simulate Stow operations:

```bash
./install.sh --dry-run
```

## Security

- Never commit passwords, access tokens or private SSH keys.
- Review configuration files before pushing.
- Use separate Git identities for personal and work repositories.
- Review downloaded installation scripts before executing them.

## Roadmap

- [x] Kitty configuration
- [x] Zsh configuration
- [x] Starship configuration
- [x] tmux configuration
- [x] Git conditional identities
- [x] GNU Stow integration
- [x] Installer health checks
- [ ] Validate Arch Linux installation
- [ ] Improve installer security
- [ ] Add SSH configuration templates
- [ ] Add Neovim configuration
- [ ] Add automated configuration tests
