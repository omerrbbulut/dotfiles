# Dotfiles

Personal development environment configuration managed with **GNU Stow and Git**.

Designed for a consistent, reproducible terminal-based development environment across Ubuntu installations.

## Components

| Component | Tool |
|-----------|------|
| Terminal | Kitty |
| Shell | Zsh |
| Prompt | Starship |
| Terminal Multiplexer | tmux |
| Theme | Catppuccin Mocha |
| Font | JetBrainsMono Nerd Font |
| Editor | Neovim |
| Package Manager | APT |
| Configuration Management | GNU Stow |
| Version Control | Git |
| SSH Authentication | OpenSSH Agent |
| CLI Tools | fzf, zoxide, ripgrep, fd, bat, btop |

## Supported Systems

| Distribution | Status |
|--------------|--------|
| Ubuntu 24.04 LTS | Supported; tested on an existing installation |
| Ubuntu 26.04 LTS | Experimental; validation required |
| Arch Linux | Future Work |

The current installer targets Ubuntu 24.04 and Ubuntu 26.04.

Ubuntu 24.04 configuration and installation checks have been validated on an existing system. A completely fresh installation has not yet been tested.

Ubuntu 26.04 requires additional validation.

Arch Linux support is planned but is not currently part of the supported installation workflow.

## Repository Structure

```text
dotfiles/
├── install.sh
├── packages/
│   ├── ubuntu.sh
│   └── arch.sh
├── scripts/
│   └── setup-ssh.sh
├── kitty/
│   └── .config/kitty/
├── zsh/
│   └── .zshrc
├── starship/
│   └── .config/starship.toml
├── tmux/
│   └── .tmux.conf
├── git/
│   ├── .gitconfig
│   └── .config/git/
│       ├── personal.gitconfig
│       └── work.gitconfig
└── ssh/
    └── .ssh/config
```

## Installation

### 1. Install Bootstrap Dependencies

On a fresh Ubuntu installation:

```bash
sudo apt-get update
sudo apt-get install -y git ca-certificates
```

### 2. Clone the Repository

```bash
git clone <repository-url> ~/dotfiles
cd ~/dotfiles
```

Review the installation scripts before executing them.

### 3. Run the Installer

```bash
./install.sh --all
```

The full installation performs the following operations:

1. Detect the operating system.
2. Install required Ubuntu packages.
3. Install Starship if missing.
4. Install JetBrainsMono Nerd Font if missing.
5. Create GNU Stow configuration symlinks.
6. Configure SSH identities interactively.
7. Install tmux plugins.
8. Verify configuration links.

The installer may request sudo privileges, SSH key passphrases, and confirmation before certain operations.

Existing SSH private keys are preserved.

### 4. Validate Installation

```bash
./install.sh --check
```

This verifies installed tools, configuration symlinks, fonts, SSH setup, and tmux plugins.

Some SSH checks require the relevant identities to have been configured.

### 5. Restart the Terminal

Restart Kitty or open a new terminal session to load the configured shell environment.

## Available Commands

| Command | Description |
|---------|-------------|
| `./install.sh` | Manage configuration symlinks and tmux plugins |
| `./install.sh --all` | Perform complete installation |
| `./install.sh --packages` | Install Ubuntu packages |
| `./install.sh --starship` | Install Starship if missing |
| `./install.sh --font` | Install Nerd Font if missing |
| `./install.sh --ssh` | Configure SSH identities and agent |
| `./install.sh --dry-run` | Simulate Stow operations |
| `./install.sh --all --dry-run` | Simulate configuration linking without installing software |
| `./install.sh --check` | Verify installation |
| `./install.sh --help` | Display available options |

The `--dry-run` option does not install packages, generate SSH keys, or modify configuration files.

## GNU Stow

Configuration files are managed through symbolic links.

For example:

```text
~/.zshrc
    -> ~/dotfiles/zsh/.zshrc

~/.gitconfig
    -> ~/dotfiles/git/.gitconfig

~/.ssh/config
    -> ~/dotfiles/ssh/.ssh/config
```

### Install a Single Configuration

```bash
cd ~/dotfiles

stow --no-folding -t "$HOME" kitty
```

### Remove Managed Symlinks

```bash
cd ~/dotfiles

stow --no-folding -D -t "$HOME" kitty
```

### Check for Conflicts

```bash
./install.sh --dry-run
```

The installer does not automatically back up conflicting configuration files.

Resolve conflicts manually before installation.

## SSH Configuration

Personal and corporate SSH identities are managed separately.

### SSH Directory Structure

```text
~/.ssh/
├── config
├── config.work
├── github_personal
├── github_personal.pub
├── gitlab_work
├── gitlab_work.pub
└── known_hosts
```

### Personal GitHub

The personal GitHub connection uses:

```text
Host: github.com
Key: ~/.ssh/github_personal
```

Test authentication:

```bash
ssh -T git@github.com
```

A successful authentication normally displays a GitHub welcome message.

### Corporate GitLab

Corporate GitLab settings are stored locally in:

```text
~/.ssh/config.work
```

This file contains machine-specific connection settings and is not tracked by Git.

Example:

```sshconfig
Host gitlab-work
    HostName <corporate-gitlab-host>
    User git
    Port 22
    IdentityFile ~/.ssh/gitlab_work
    IdentitiesOnly yes
    AddKeysToAgent yes
```

The actual hostname and SSH port depend on the corporate GitLab installation.

Test authentication:

```bash
ssh -T gitlab-work
```

### SSH Agent

The setup script uses the existing SSH agent exposed through `SSH_AUTH_SOCK`.

It does not start a new SSH agent for every terminal session.

Existing identities are detected using SSH key fingerprints.

Keys already loaded into the agent are not added again.

Check loaded identities:

```bash
ssh-add -l
```

Manually load identities:

```bash
ssh-add ~/.ssh/github_personal
ssh-add ~/.ssh/gitlab_work
```

### New Computer Setup

Run:

```bash
./install.sh --ssh
```

The setup script can:

- Create missing SSH key pairs with user confirmation.
- Preserve existing keys.
- Configure corporate GitLab connection settings.
- Add keys to an existing SSH agent.
- Detect identities already loaded into the agent.

**Important:** New public SSH keys must be registered with GitHub and the corporate GitLab account separately.

Private SSH keys must never be committed to this repository.

SSH host key fingerprints must be verified before trusting a new server.

## Git Identities

Git commit identities are selected automatically according to repository remote URLs.

Repository directory location does not determine the identity.

### Personal GitHub

Supported remote examples:

```text
git@github.com:username/repository.git
git@github-personal:username/repository.git
ssh://git@github.com/username/repository.git
https://github.com/username/repository.git
```

Identity configuration:

```text
~/.config/git/personal.gitconfig
```

### Corporate GitLab

Supported remote examples:

```text
git@gitlab-work:group/repository.git
ssh://git@gitlab-work/group/repository.git
```

Identity configuration:

```text
~/.config/git/work.gitconfig
```

Corporate repositories should use the configured `gitlab-work` SSH alias.

Direct IP-based or HTTPS corporate remotes are not covered by the current automatic identity rules.

### Identity Verification

Inside a Git repository:

```bash
git remote -v

git config --show-origin --get user.name
git config --show-origin --get user.email
```

The output identifies which configuration file provided the active Git identity.

### Identity Safety

The global Git configuration includes:

```gitconfig
[user]
    useConfigOnly = true
```

This prevents Git from guessing an identity when no explicit identity has been configured.

Repositories without a matching remote may require a manually configured identity.

For example:

```bash
git config --local user.name "Your Name"
git config --local user.email "your@email.com"
```

### Repositories with Multiple Remotes

A repository containing both personal GitHub and corporate GitLab remotes can match multiple identity conditions.

Git does not automatically change the commit author according to the selected push destination.

For these repositories, configure the intended identity explicitly:

```bash
git config --local user.name "Your Name"
git config --local user.email "your@email.com"
```

Git author identity and SSH authentication are independent mechanisms.

## CLI Compatibility

Ubuntu may install some tools using different executable names.

The package setup configures compatibility links when necessary:

```text
fd  -> fdfind
bat -> batcat
```

These links are created in:

```text
~/.local/bin/
```

Existing files and unrelated symbolic links are preserved.

## Validation

### Verify Installation

```bash
./install.sh --check
```

### Simulate Installation

```bash
./install.sh --all --dry-run
```

### Validate Bash Scripts

```bash
bash -n install.sh
bash -n packages/ubuntu.sh
bash -n scripts/setup-ssh.sh
```

### Verify Git Changes

```bash
git diff --check
git status --short
```

## Security

- Never commit private SSH keys.
- Never commit passwords or access tokens.
- Keep corporate connection details in local configuration files.
- Verify remote SSH server fingerprints.
- Use separate personal and corporate SSH identities.
- Review downloaded installation scripts before running them.
- Preserve existing configuration files when conflicts occur.
- Protect SSH private keys with passphrases.

## Roadmap

### Completed

- [x] Kitty configuration
- [x] Zsh configuration
- [x] Starship configuration
- [x] tmux configuration
- [x] Catppuccin Mocha theme
- [x] Nerd Font integration
- [x] GNU Stow configuration management
- [x] SSH configuration templates
- [x] Interactive SSH setup
- [x] SSH agent identity detection
- [x] Remote-based Git identity selection
- [x] Ubuntu package installation script
- [x] Installer health checks
- [x] Dry-run support

### Future Work

- [ ] Validate installation on a clean Ubuntu 24.04 system
- [ ] Validate installation on Ubuntu 26.04
- [ ] Implement automated installer integration tests
- [ ] Improve first-run setup and error handling
- [ ] Validate installation with existing conflicting configuration files
- [ ] Improve SSH agent persistence across desktop sessions
- [ ] Add Neovim configuration
- [ ] Validate and enable Arch Linux support
- [ ] Improve installer security and dependency verification

## License

No license has been specified.
