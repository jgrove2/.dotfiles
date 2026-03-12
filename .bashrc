# -----------------------------------------------------------------------------
# Bootstrap: switch to zsh as soon as possible.
#
# On a fresh machine where the login shell is still bash, this file ensures
# that opening a terminal immediately drops into zsh. It also permanently
# fixes the login shell via chsh so that future sessions start zsh directly.
# -----------------------------------------------------------------------------

_install_zsh() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew > /dev/null 2>&1; then
      brew install zsh
    else
      echo "Homebrew not found. Install it from https://brew.sh, then reopen the terminal."
      return 1
    fi
  elif [ -f /etc/debian_version ]; then
    sudo apt update && sudo apt install -y zsh
  elif [ -f /etc/redhat-release ]; then
    sudo dnf install -y zsh
  elif [ -f /etc/arch-release ]; then
    sudo pacman -S --noconfirm zsh
  else
    echo "Unknown OS — please install zsh manually and reopen the terminal."
    return 1
  fi
}

if ! command -v zsh > /dev/null 2>&1; then
  echo "zsh not found. Installing..."
  _install_zsh
fi

if command -v zsh > /dev/null 2>&1; then
  _zsh_path=$(command -v zsh)

  # Permanently fix the login shell in the background (silent, non-blocking).
  # This means the *next* terminal open won't need this file at all.
  if [ "$SHELL" != "$_zsh_path" ]; then
    (
      grep -qx "$_zsh_path" /etc/shells 2>/dev/null || echo "$_zsh_path" | sudo tee -a /etc/shells > /dev/null 2>&1
      chsh -s "$_zsh_path" > /dev/null 2>&1
    ) &
  fi

  unset _zsh_path
  unfunction _install_zsh 2>/dev/null || unset -f _install_zsh

  # Replace this bash process with zsh — happens immediately, this session.
  exec zsh -l
fi
