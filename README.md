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
| GitHub CLI | gh (official GitHub apt repository) |
| SSH Authentication | OpenSSH Agent |
| CLI Tools | eza, fzf, zoxide, ripgrep, fd, bat, btop |

## Supported Systems

| Distribution | Status |
|--------------|--------|
| Ubuntu 26.04 LTS | Supported; validated on a fresh installation |
| Ubuntu 24.04 LTS | Supported; tested on an existing installation |
| Arch Linux | Future Work |

The current installer targets Ubuntu 24.04 and Ubuntu 26.04.

Ubuntu 26.04 has been validated end to end on a freshly installed system: full installation with `./install.sh --all`, SSH authentication to GitHub and corporate GitLab, and a passing `./install.sh --check`.

Ubuntu 24.04 configuration and installation checks have been validated on an existing system. A completely fresh 24.04 installation has not yet been tested.

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
│       └── personal.gitconfig
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
2. Install required Ubuntu packages and the GitHub CLI.
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

The personal GitHub key (`~/.ssh/github_personal`) is required: the check fails if it is missing. Run `./install.sh --ssh` to create it.

The corporate GitLab key is optional and is only reported when absent.

### 5. Restart the Terminal

Restart Kitty or open a new terminal session to load the configured shell environment.

Kitty and tmux start Zsh directly, even if the login shell is still Bash.

## Post-Installation Steps

The installer cannot complete these steps. Perform them manually after `./install.sh --all`.

### 1. Register Public SSH Keys

The installer creates key pairs but does not upload them.

Print each public key:

```bash
cat ~/.ssh/github_personal.pub
cat ~/.ssh/gitlab_work.pub
```

Register them:

| Key | Where |
|-----|-------|
| `github_personal.pub` | GitHub → Settings → SSH and GPG keys → New SSH key (type: Authentication) |
| `gitlab_work.pub` | Corporate GitLab → Preferences → SSH Keys → Add new key |

Only ever share the `.pub` file. Never upload or copy the private key.

### 2. Test Authentication

```bash
ssh -T git@github.com
ssh -T gitlab-work
```

Expected responses:

```text
Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
Welcome to GitLab, @<username>!
```

On the first connection SSH asks whether to trust the server host key.

- GitHub: compare against GitHub's published SSH key fingerprints.
- Corporate GitLab: obtain the fingerprint from the GitLab administrator before accepting.

### 3. Switch This Repository to SSH

The repository is usually cloned over HTTPS before an SSH key exists. Afterwards, switch the remote so pushes use the SSH key instead of a token:

```bash
git remote set-url origin git@github.com:<username>/dotfiles.git
git fetch origin
```

### 4. Log In to the GitHub CLI

```bash
gh auth login
```

Choose:

- **GitHub.com**
- **SSH** as the Git protocol
- The existing `~/.ssh/github_personal.pub` key. Do not generate or upload a new one.
- **Login with a web browser**

Verify:

```bash
gh auth status
```

`./install.sh --check` warns when the GitHub CLI is not logged in.

### 5. Set Zsh as the Login Shell (Optional)

Other terminals and SSH logins use the login shell. To use Zsh everywhere:

```bash
chsh -s /usr/bin/zsh
```

Log out and back in for the change to take effect.

### 6. Post-Quantum Key Exchange Warning (Optional)

OpenSSH 10 and later warn when a server does not support post-quantum key exchange:

```text
** WARNING: connection is not using a post-quantum key exchange algorithm.
```

This is caused by an older OpenSSH version on the server. The connection remains encrypted. The proper fix is a server-side upgrade.

To silence the warning for the corporate server only, add the following to the `Host gitlab-work` block in `~/.ssh/config.work`:

```sshconfig
    WarnWeakCrypto no
```

Do not disable it globally.

### 7. Final Check

```bash
./install.sh --check
```

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
- Create the local corporate Git identity (prompts for work name and email).
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

This file is created locally by `./install.sh --ssh` and is not tracked by Git, so the corporate email never enters the repository:

```gitconfig
[user]
    name = Your Name
    email = you@company.example
```

`./install.sh --check` fails if corporate GitLab is configured but this file is missing.

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

## GitHub CLI

The GitHub CLI is installed from GitHub's official apt repository instead of Ubuntu's archive, which lags behind upstream releases.

The installer:

- Downloads the repository signing key and verifies it against the fingerprints published in the [GitHub CLI installation docs](https://github.com/cli/cli/blob/trunk/docs/install_linux.md). The repository is not added if they do not match.
- Adds `/etc/apt/sources.list.d/github-cli.list` and installs `gh` with APT, so regular `sudo apt upgrade` keeps it current.
- Falls back to Ubuntu's `gh` package if the repository cannot be set up.

Zsh completion for `gh` is generated once into `~/.cache/zsh/completions/_gh` and refreshed automatically when `gh` is upgraded.

### Contribution Workflow

The `main` branch is protected by a repository ruleset:

- Direct pushes are rejected. Changes must go through a pull request.
- Force pushes and branch deletion are blocked.
- No approval is required, so a single maintainer can merge their own pull requests.

Typical workflow:

```bash
git switch -c my-change
# edit, then commit
git push -u origin my-change

gh pr create --fill
gh pr merge --merge --delete-branch

git switch main
git pull --ff-only
```

### Releases

```bash
gh release create vX.Y.Z --target main --generate-notes
```

## Shell Aliases

### Directory Listings

When `eza` is installed, the following aliases use it. Otherwise they fall back to colored `ls`.

| Alias | Description |
|-------|-------------|
| `ls` | Icons and colors, directories first |
| `ll` | Long listing including hidden files, Git status, ISO timestamps |
| `la` | All files including hidden files |
| `lt` | Tree view, two levels, respecting `.gitignore` (eza only) |

Icons require the installed Nerd Font. They are disabled automatically when output is piped.

### Git and tmux

| Alias | Command |
|-------|---------|
| `gs` | `git status` |
| `gd` | `git diff` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gl` | `git log --oneline --graph --decorate` |
| `tn <name>` | `tmux new -s <name>` |
| `ta` | `tmux attach` |
| `tl` | `tmux list-sessions` |

The tmux prefix is `Ctrl+a`.

## Machine-Specific Settings

Settings that only apply to one computer (for example extra tool paths such as STM32CubeCLI) go in `~/.zprofile.local`. This file is not tracked by Git and is sourced by `.zprofile` only if it exists:

```zsh
# ~/.zprofile.local
if [[ -d /opt/st/STM32CubeProgrammer/bin ]]; then
    path=(/opt/st/STM32CubeProgrammer/bin $path)
fi
```

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
zsh -n zsh/.zshrc
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
- [x] eza directory listings
- [x] Validate installation on a clean Ubuntu 26.04 system
- [x] Corporate GitLab SSH alias and identity configuration
- [x] Required personal GitHub key check in `--check`
- [x] Post-installation documentation (key registration, authentication tests, remote switch)
- [x] GitHub CLI from the official repository with verified signing key
- [x] Protected `main` branch with pull request workflow
- [x] First release (v1.0.0)

### Future Work

- [ ] Validate installation on a clean Ubuntu 24.04 system
- [ ] Print public keys and registration instructions at the end of SSH setup
- [ ] Offer to set Zsh as the login shell during installation
- [ ] Implement automated installer integration tests
- [ ] Improve first-run setup and error handling
- [ ] Validate installation with existing conflicting configuration files
- [ ] Improve SSH agent persistence across desktop sessions
- [ ] Add Neovim configuration
- [ ] Validate and enable Arch Linux support
- [ ] Improve installer security and dependency verification

## License

No license has been specified.
