# -----------------------------------------------------------------------------
# 1. HELPER: TMUX PLUGIN MANAGER (TPM)
# -----------------------------------------------------------------------------
install_tpm() {
  local TPM_DIR="$HOME/.tmux/plugins/tpm"
  
  if [[ -d "$TPM_DIR" ]]; then
    if [[ "$1" == "--update" ]]; then
      echo "🔄 Updating TPM..."
      cd "$TPM_DIR" && git pull
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
# MAIN: BOOTSTRAP PACKAGES
# -----------------------------------------------------------------------------
bootstrap_packages() {
  local update_mode=false
  if [[ "$1" == "--update" ]]; then
    echo "🚀 Update mode enabled."
    update_mode=true
  fi

  # --- LIST OF PACKAGES ---
  local PACKAGES=(
    neovim
    fzf
    ripgrep
    tmux
  )

  # --- BINARY MAPPING ---
  typeset -A BINARY_MAP
  BINARY_MAP[neovim]="nvim"
  BINARY_MAP[ripgrep]="rg"

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
      echo "⬇️  $pkg not found. Installing..."
      eval "$install_cmd $pkg"
    fi
  done
  
  # --- RUN HELPERS ---
  install_tpm "$1"
  
  echo "🎉 System check complete."
}
