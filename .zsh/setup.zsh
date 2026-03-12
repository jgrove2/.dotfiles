# -----------------------------------------------------------------------------
# 1. HELPER: SET DEFAULT SHELL TO ZSH
# -----------------------------------------------------------------------------
set_default_shell() {
  local zsh_path
  zsh_path=$(command -v zsh)

  if [[ -z "$zsh_path" ]]; then
    echo "zsh not found, skipping shell change."
    return 1
  fi

  if [[ "$SHELL" == "$zsh_path" ]]; then
    echo "✅ Default shell is already zsh ($zsh_path)."
    return 0
  fi

  # chsh requires the shell to be listed in /etc/shells
  if ! grep -qx "$zsh_path" /etc/shells; then
    echo "Adding $zsh_path to /etc/shells..."
    echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
  fi

  echo "Changing default shell to $zsh_path..."
  chsh -s "$zsh_path"
  echo "Shell changed. Open a new terminal for the change to take effect."
}

# -----------------------------------------------------------------------------
# 2. HELPER: INSTALL LAZYGIT
# -----------------------------------------------------------------------------
install_lazygit() {
  if command -v lazygit &> /dev/null; then
    if [[ "$1" == "--update" ]]; then
      echo "🔄 Updating lazygit..."
      if [[ "$OSTYPE" == "darwin"* ]]; then
        brew upgrade lazygit
      else
        local tag arch
        tag=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
        case "$(uname -m)" in
          x86_64)  arch="x86_64" ;;
          aarch64) arch="arm64" ;;
          armv7l)  arch="armv6" ;;
          *)       echo "❌ Unsupported arch: $(uname -m)"; return 1 ;;
        esac
        local tmp_dir
        tmp_dir=$(mktemp -d)
        curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${tag}_Linux_${arch}.tar.gz" | tar -xz -C "$tmp_dir"
        sudo install "$tmp_dir/lazygit" /usr/local/bin/lazygit
        rm -rf "$tmp_dir"
        echo "✅ lazygit updated to v${tag}."
      fi
    else
      echo "✅ lazygit is installed."
    fi
    return 0
  fi

  echo "⬇️  lazygit not found. Installing..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install lazygit
  else
    local tag arch
    tag=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
    case "$(uname -m)" in
      x86_64)  arch="x86_64" ;;
      aarch64) arch="arm64" ;;
      armv7l)  arch="armv6" ;;
      *)       echo "❌ Unsupported arch: $(uname -m)"; return 1 ;;
    esac
    local tmp_dir
    tmp_dir=$(mktemp -d)
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${tag}_Linux_${arch}.tar.gz" | tar -xz -C "$tmp_dir"
    sudo install "$tmp_dir/lazygit" /usr/local/bin/lazygit
    rm -rf "$tmp_dir"
    echo "✅ lazygit v${tag} installed."
  fi
}

# -----------------------------------------------------------------------------
# 3. HELPER: INSTALL OPENCODE
# -----------------------------------------------------------------------------
install_opencode() {
  if command -v opencode &> /dev/null; then
    if [[ "$1" == "--update" ]]; then
      echo "🔄 Updating opencode..."
      curl -fsSL https://opencode.ai/install | bash
    else
      echo "✅ opencode is installed."
    fi
    return 0
  fi

  echo "⬇️  opencode not found. Installing..."
  curl -fsSL https://opencode.ai/install | bash
}

# -----------------------------------------------------------------------------
# 4. HELPER: INSTALL NEOVIM (nightly via appimage on Linux, brew on macOS)
# -----------------------------------------------------------------------------
install_neovim() {
  if command -v nvim &> /dev/null; then
    if [[ "$1" == "--update" ]]; then
      echo "🔄 Updating neovim..."
      if [[ "$OSTYPE" == "darwin"* ]]; then
        brew upgrade neovim
      else
        echo "⬇️  Downloading neovim nightly appimage..."
        curl -fsSL "https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage" -o "$HOME/.local/bin/nvim"
        chmod u+x "$HOME/.local/bin/nvim"
        echo "✅ neovim nightly updated."
      fi
    else
      echo "✅ neovim is installed."
    fi
    return 0
  fi

  echo "⬇️  neovim not found. Installing..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install neovim
  else
    mkdir -p "$HOME/.local/bin"
    curl -fsSL "https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage" -o "$HOME/.local/bin/nvim"
    chmod u+x "$HOME/.local/bin/nvim"
    echo "✅ neovim nightly installed to ~/.local/bin/nvim."
  fi
}

# -----------------------------------------------------------------------------
# 5. HELPER: TMUX PLUGIN MANAGER (TPM)
# -----------------------------------------------------------------------------
install_tpm() {
  local TPM_DIR="$HOME/.tmux/plugins/tpm"
  
  if [[ -d "$TPM_DIR" ]]; then
    if [[ "$1" == "--update" ]]; then
      echo "🔄 Updating TPM..."
      ( cd "$TPM_DIR" && git pull )
    else
      echo "✅ TPM is already installed."
    fi
  else
    echo "⬇️  Installing TPM..."
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  fi
}

# -----------------------------------------------------------------------------
# 6. HELPER: INSTALL STARSHIP PROMPT
# -----------------------------------------------------------------------------
install_starship() {
  if command -v starship &> /dev/null; then
    if [[ "$1" == "--update" ]]; then
      echo "🔄 Updating starship..."
      curl -sS https://starship.rs/install.sh | sh -s -- --yes
    else
      echo "✅ starship is installed."
    fi
    return 0
  fi

  echo "⬇️  starship not found. Installing..."
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
}

# -----------------------------------------------------------------------------
# MAIN: BOOTSTRAP PACKAGES
# -----------------------------------------------------------------------------
bootstrap_packages() {
  local update_mode=false
  if [[ "$1" == "--update" ]]; then
    echo "🚀 Update mode enabled."
    update_mode=true
  fi

  # --- LIST OF PACKAGES ---
  # neovim is handled separately by install_neovim()
  local PACKAGES=(
    fzf
    ripgrep
    tmux
    fd
  )

  # --- BINARY MAPPING (package name -> binary name) ---
  typeset -A BINARY_MAP
  BINARY_MAP[ripgrep]="rg"
  # fd on apt is 'fd-find' and installs as 'fdfind'
  BINARY_MAP[fd]="fd"

  # --- APT PACKAGE NAME OVERRIDES ---
  # Some packages have different names in apt vs brew
  typeset -A APT_NAME_MAP
  APT_NAME_MAP[fd]="fd-find"

  # --- OS DETECTION ---
  local install_cmd=""
  local update_cmd=""
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &> /dev/null; then
      echo "❌ Homebrew required for Mac setup."
      return 1
    fi
    install_cmd="brew install"
    update_cmd="brew upgrade"
  elif [[ -f /etc/debian_version ]]; then
    install_cmd="sudo apt update && sudo apt install -y"
    update_cmd="sudo apt update && sudo apt install --only-upgrade -y"
  elif [[ -f /etc/redhat-release ]]; then
    install_cmd="sudo dnf install -y"
    update_cmd="sudo dnf upgrade -y"
  elif [[ -f /etc/arch-release ]]; then
    install_cmd="sudo pacman -S --noconfirm"
    update_cmd="sudo pacman -S --noconfirm"
  else
    echo "❌ Unknown OS."
    return 1
  fi

  # --- INSTALL LOOP ---
  echo "🔍 Checking System Packages..."
  for pkg in "${PACKAGES[@]}"; do
    local binary="${BINARY_MAP[$pkg]:-$pkg}"

    if command -v "$binary" &> /dev/null; then
      if $update_mode; then
        echo "🔄 Updating $pkg..."
        eval "$update_cmd $pkg"
      else
        echo "✅ $pkg is installed."
      fi
    else
      # Use apt-specific package name if defined, otherwise use pkg name
      local install_pkg="$pkg"
      if [[ -n "${APT_NAME_MAP[$pkg]}" ]] && [[ -f /etc/debian_version ]]; then
        install_pkg="${APT_NAME_MAP[$pkg]}"
      fi
      echo "⬇️  $pkg not found. Installing..."
      eval "$install_cmd $install_pkg"
    fi
  done

  # On Debian/Ubuntu, apt installs fd as 'fdfind' — symlink to 'fd' in ~/.local/bin
  if [[ -f /etc/debian_version ]] && command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    echo "✅ Symlinked fdfind -> ~/.local/bin/fd"
  fi
  
  # --- RUN HELPERS ---
  set_default_shell
  install_neovim "$1"
  install_tpm "$1"
  install_lazygit "$1"
  install_opencode "$1"
  install_starship "$1"
  
  echo "🎉 System check complete."
}
