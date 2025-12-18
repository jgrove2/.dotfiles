# ~/.zsh/setup.zsh

bootstrap_packages() {
  # 1. Define the list of packages you want to ensure are installed
  local PACKAGES=(
    neovim
    fzf
    # Add others here later, e.g., ripgrep, jq, bat
  )

  # 2. Map packages to binaries if names differ
  # Syntax: BINARY_MAP[package_name]="binary_command"
  typeset -A BINARY_MAP
  BINARY_MAP[neovim]="nvim"
  # fzf binary is just "fzf", so no mapping needed

  # 3. Detect the Package Manager
  local install_cmd=""
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &> /dev/null; then
      echo "❌ Homebrew is not installed. Please install it first."
      return 1
    fi
    install_cmd="brew install"
  elif [[ -f /etc/debian_version ]]; then
    install_cmd="sudo apt update && sudo apt install -y"
  elif [[ -f /etc/redhat-release ]]; then
    install_cmd="sudo dnf install -y"
  elif [[ -f /etc/arch-release ]]; then
    install_cmd="sudo pacman -S --noconfirm"
  else
    echo "❌ Unknown operating system. Cannot auto-install."
    return 1
  fi

  echo "🔍 Checking dependencies..."

  # 4. Loop through packages and check/install
  for pkg in "${PACKAGES[@]}"; do
    # Determine the binary name to check for (default to package name)
    local binary="${BINARY_MAP[$pkg]:-$pkg}"

    if command -v "$binary" &> /dev/null; then
      echo "✅ $pkg (binary: $binary) is already installed."
    else
      echo "⬇️  $pkg not found. Installing..."
      # Run the install command
      eval "$install_cmd $pkg"
    fi
  done
  
  echo "🎉 Package check complete."
}
