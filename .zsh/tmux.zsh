t() {
  local session_name=${PWD:t}

  session_name=${session_name//[^a-zA-Z0-9_-]/_}

  if [[ -n "$TMUX" ]]; then
    print -P "%F{yellow}Already inside tmux session%f"
    return 1
  fi

  if ! command -v tmux &> /dev/null; then
    print -P "%F{red}tmux is not installed%f"
    return 1
  fi

  if tmux has-session -t "$session_name" 2>/dev/null; then
    print -P "%F{green} Attaching to existing session '${session_name}'%f"
    tmux attach-session -t "$session_name"
    return 0
  fi

  print -P "%F{blue} Creating new session '$session_name'%f"

  tmux new-session -d -s "$session_name" -n 'nvim' -c "$PWD"
  tmux new-window -t "$session_name" -n 'ai' -c "$PWD"
  tmux new-window -t "$session_name" -n 'zsh-term' -c "$PWD"

  sleep 1

  if command -v nvim &> /dev/null; then
    tmux send-keys -t "$session_name:nvim" 'nvim .' C-m
  else
    print -P "%F{yellow} nvim not found, opening shell instead%f"
  fi

  if command -v opencode &> /dev/null; then
    tmux send-keys -t "$session_name:ai" 'opencode' C-m
  else
    print -P "%F{yellow} opencode not found%f"
  fi

  tmux select-window -t "$session_name:nvim"

  print -P "%F{green} Attaching to session '$session_name'%f"
  tmux attach-session -t "$session_name"
}

tk() {
  if ! command -v tmux &> /dev/null; then
    print -P "%F{red}tmux is not installed%f"
    return 1
  fi

  if [[ -n "$1" ]]; then
    tmux kill-session -t "$1" && print -P "%F{green}Killed session '$1'%f"
  elif [[ -n "$TMUX" ]]; then
    tmux kill-session
  else
    print -P "%F{red}Not inside a tmux session. Pass a session name to kill.%f"
    return 1
  fi
}

tka() {
  if ! command -v tmux &> /dev/null; then
    print -P "%F{red}tmux is not installed%f"
    return 1
  fi

  read "answer?Kill all tmux sessions? [y/N] "
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    tmux kill-server && print -P "%F{green}All tmux sessions killed%f"
  else
    print -P "%F{yellow}Aborted%f"
  fi
}

ts() {
  if ! command -v tmux &> /dev/null; then
    print -P "%F{red}tmux is not installed%f"
    return 1
  fi

  if [[ -z "$1" ]]; then
    if ! tmux list-sessions &>/dev/null; then
      print -P "%F{red}No tmux sessions exist%f"
      return 1
    fi
    local target
    target=$(tmux list-sessions -F '#{session_name}' | fzf --prompt="session> ")
    [[ -z "$target" ]] && return 0
    if [[ -n "$TMUX" ]]; then
      tmux switch-client -t "$target"
    else
      tmux attach-session -t "$target"
    fi
    return 0
  fi

  local session_name="$1"

  if tmux has-session -t "$session_name" 2>/dev/null; then
    print -P "%F{green} Switching to existing session '$session_name'%f"
    if [[ -n "$TMUX" ]]; then
      tmux switch-client -t "$session_name"
    else
      tmux attach-session -t "$session_name"
    fi
    return 0
  fi

  print -P "%F{blue} Creating new session '$session_name'%f"

  tmux new-session -d -s "$session_name" -n 'nvim' -c "$PWD"
  tmux new-window -t "$session_name" -n 'ai' -c "$PWD"
  tmux new-window -t "$session_name" -n 'zsh-term' -c "$PWD"

  sleep 1

  if command -v nvim &> /dev/null; then
    tmux send-keys -t "$session_name:nvim" 'nvim .' C-m
  fi

  if command -v opencode &> /dev/null; then
    tmux send-keys -t "$session_name:ai" 'opencode' C-m
  fi

  tmux select-window -t "$session_name:nvim"

  print -P "%F{green} Attaching to session '$session_name'%f"
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$session_name"
  else
    tmux attach-session -t "$session_name"
  fi
}
