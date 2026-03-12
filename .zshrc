# --- 0. PATH ---
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$HOME/.local/bin:$HOME/bin:$HOME/.opencode/bin:$PATH"

# --- 1. Zinit Setup ---
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# --- 2. Load Plugins ---
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

# --- 3. Basic Settings & History ---
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# --- 4. Load Completions ---
autoload -U compinit && compinit

# --- 5. Keybinds (Fixed Typo) ---
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# -- Aliases
if [[ "$OSTYPE" == "darwin"* ]]; then
  alias ls='ls -G'
else
  alias ls='ls --color'
fi

# -- Shell Integration
if command -v fzf &> /dev/null; then
  local fzf_minor
  fzf_minor=$(fzf --version | cut -d. -f2)
  [[ "$fzf_minor" -ge 48 ]] && eval "$(fzf --zsh)"
fi

# -- Environment variables
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# --- 6. Load Custom Configs (functions, aliases, etc.) ---
export ZSH_CONFIG_DIR="$HOME/.zsh"
if [[ -d "$ZSH_CONFIG_DIR" ]]; then
  for config_file in "$ZSH_CONFIG_DIR"/*.zsh(N); do
    source "$config_file"
  done
  unset config_file
fi

# --- 7. Run Daily Check (MUST BE LAST) ---
# Placing this last ensures 'bootstrap_packages' is definitely loaded
LAST_CHECK_FILE="/tmp/zsh_update_check_$(date +%Y%m%d)"
if [[ ! -f "$LAST_CHECK_FILE" ]]; then
  if command -v bootstrap_packages &> /dev/null; then
    echo "📅 Daily system check..."
    bootstrap_packages
    touch "$LAST_CHECK_FILE"
  fi
fi

# --- 8. Prompt ---
command -v starship &> /dev/null && eval "$(starship init zsh)"
