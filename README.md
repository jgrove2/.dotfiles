# dotfiles

Personal dotfiles for macOS and Linux, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Prerequisites

- `git`
- `stow`

```bash
# macOS
brew install stow

# Ubuntu/Debian
sudo apt install stow

# Arch
sudo pacman -S stow
```

> macOS users also need [Homebrew](https://brew.sh) — it's used to install all packages automatically.

## Install

### 1. Clone the repo

```bash
git clone https://github.com/jgrove2/.dotfiles ~/.dotfiles
```

### 2. Backup existing dotfiles (optional)

If you have existing dotfiles you want to save before stowing, back them up first:

```bash
mkdir -p ~/.dotfiles-backup
for f in ~/.zshrc ~/.zshenv ~/.bashrc ~/.tmux.conf; do
  [ -f "$f" ] && mv "$f" ~/.dotfiles-backup/
done
[ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.dotfiles-backup/nvim
```

To restore them later just move them back from `~/.dotfiles-backup/`.

### 3. Stow

```bash
cd ~/.dotfiles
stow .
```

That's it. Stow will symlink everything into `$HOME`.

## What happens next

On the next shell startup, `bootstrap_packages` runs automatically and installs:

| Tool | Description |
|---|---|
| `neovim` | Text editor |
| `fzf` | Fuzzy finder |
| `ripgrep` | Fast grep (`rg`) |
| `tmux` | Terminal multiplexer |
| `fd` | Fast `find` alternative |
| `lazygit` | Terminal UI for git |
| `opencode` | AI coding agent |
| `odin` | Odin programming language |
| TPM | Tmux plugin manager |

Neovim plugins are managed by [LazyVim](https://lazyvim.org) and install automatically on first launch.

## Keeping up to date

To update all packages and tools:

```bash
bootstrap_packages --update
```
