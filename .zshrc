# ==============================================================================
# .zshrc — Chromebook Crostini Power-User Shell
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Environment
# ------------------------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LESS="-R --use-color"
export LANG="en_US.UTF-8"
export TERM="xterm-256color"
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# ------------------------------------------------------------------------------
# 2. History
# ------------------------------------------------------------------------------
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$HOME/.zsh_history"

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE

# ------------------------------------------------------------------------------
# 3. ZVM Variable Setup (Must be declared BEFORE loading zsh-vi-mode)
# ------------------------------------------------------------------------------
ZVM_VI_ESCAPE_BINDKEY="jk"

# ------------------------------------------------------------------------------
# 4. Load Plugins (Ordered Core Framework Contract)
# ------------------------------------------------------------------------------
# 1st: Load Vi Mode framework so its ZLE hooks initialize first
source "$HOME/.zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh" 2>/dev/null

# 2nd: Load Syntax Highlighting to avoid 'unhandled ZLE widget accept' warnings
source "$HOME/.zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" 2>/dev/null

# 3rd: Load Complements and suggestions
source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null
source "$HOME/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh" 2>/dev/null

# ------------------------------------------------------------------------------
# 5. Post-Initialization Plugin Hooks
# ------------------------------------------------------------------------------
function zvm_after_init() {
  # History substring search configuration bindings
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
}

# ------------------------------------------------------------------------------
# 6. Binary Initializations
# ------------------------------------------------------------------------------
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# ------------------------------------------------------------------------------
# 7. Core Options & Safe Completions
# ------------------------------------------------------------------------------
setopt NO_BG_NICE
setopt NO_HUP
setopt NO_LIST_BEEP
setopt LOCAL_OPTIONS
setopt LOCAL_TRAPS

autoload -Uz compinit
[[ -d "$XDG_CACHE_HOME/zsh" ]] || mkdir -p "$XDG_CACHE_HOME/zsh/compcache"
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

# ------------------------------------------------------------------------------
# 8. Key bindings
# ------------------------------------------------------------------------------
bindkey '^A'    beginning-of-line
bindkey '^E'    end-of-line
bindkey '^K'    kill-line
bindkey '^U'    backward-kill-line
bindkey '^W'    backward-kill-word
bindkey '^[[3~' delete-char
bindkey '^H'    backward-delete-char

# Optional extras
[[ -f "$HOME/.zsh/dotfiles/functions/extras.zsh" ]] && source "$HOME/.zsh/dotfiles/functions/extras.zsh"

# G.O.D. Stack Master CLI Alias
alias god='/home/tangleroot013/scripts/god_cli.sh'

# ==========================================
# POWER USER ZSH CUSTOMIZATIONS
# ==========================================

# 1. Advanced FZF Previews (Uses bat/eza if installed, falls back gracefully)
if command -v bat &> /dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}' --bind 'ctrl-d:page-down,ctrl-u:page-up'"
fi

if command -v eza &> /dev/null; then
    export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
fi

# 2. Interactive Fuzzy History Search
fh() {
  eval $(history | fzf +s --tac | sed -E 's/^[0-9]+[[:space:]]+//')
}

# 3. Fuzzy Directory Jumper (Integrates z with fzf)
unalias z 2>/dev/null
z() {
  if [ $# -gt 0 ]; then
    _z "$*"
  else
    local dir
    dir=$(_z -l 2>&1 | fzf --height 40% --nth 2.. --reverse --inline-info +s --tac | sed 's/^[0-9.]* *//')
    [ -n "$dir" ] && cd "$dir"
  fi
}

# 4. Project-Specific Shortcuts & Quality of Life Aliases
alias dcmp="docker-compose"
alias run-tests="./run_tests.sh"
alias god-master="python3 ~/god_master.py"
alias restore-limits="python3 ~/restore_limits.py"


# POWER USER UPGRADES
if command -v bat &> /dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}' --bind 'ctrl-d:page-down,ctrl-u:page-up'"
fi
if command -v eza &> /dev/null; then
    export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
fi
fh() {
  eval $(history | fzf +s --tac | sed -E 's/^[0-9]+[[:space:]]+//')
}
unalias z 2>/dev/null
z() {
  if [ $# -gt 0 ]; then
    _z "$*"
  else
    local dir
    dir=$(
      _z -l 2>&1 | fzf --height 40th 2.. --reverse --inline-info +s --tac | sed 's/^[0-9.]* *//'
    )
    [ -n "$dir" ] && cd "$dir"
  fi
}
alias dcmp="docker-compose"
alias run-tests="./run_tests.sh"
alias god-master="python3 ~/god_master.py"
alias restore-limits="python3 ~/restore_limits.py"

# TERMINAL ADVANCEMENTS
# 1. Advanced Git Log Browser (Fuzzy Search Commits)

# 2. Kill Processes Smarter
fkill() {
  local pid
  if [ "$UID" -ne 0 ]; then
    pid=$(ps -f -u $USER | sed 1d | fzf -m --ansi --layout=reverse --minimum-match --bind 'ctrl-r:toggle-search' | awk '{print $2}')
  else
    pid=$(ps -ef | sed 1d | fzf -m --ansi --layout=reverse --minimum-match --bind 'ctrl-r:toggle-search' | awk '{print $2}')
  fi
  if [ -n "$pid" ]; then
    echo "$pid" | xargs kill -${1:-9}
  fi
}

# 3. Guardrails for Critical Files

# 4. Global Extra Utilities
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# HIGH-TIER TERMINAL ADVANCEMENTS
# 1. Interactive Docker Container Logs/Shell Explorer
fdop() {
  local container
  container=$(docker ps --format "{{.Names}} - {{.Status}}" | fzf --height 40% --reverse)
  if [ -n "$container" ]; then
    container=$(echo "$container" | awk '{print $1}')
    echo "Choose action for $container:"
    echo "1) Stream Logs  2) Interactive Shell (bash/sh)"
    read -k 1 "action"
    echo ""
    if [ "$action" = "1" ]; then
      docker logs -f "$container"
    elif [ "$action" = "2" ]; then
      docker exec -it "$container" /bin/bash || docker exec -it "$container" /bin/sh
    fi
  fi
}

# 2. Automated Matrix Execution Benchmark Macro
benchmark() {
  local start_time=$(date +%s.%N)
  echo "➔ Starting Execution Matrix via Zsh Engine..."
  "$@"
  local end_time=$(date +%s.%N)
  local elapsed=$(echo "$end_time - $start_time" | bc 2>/dev/null || python3 -c "print($end_time - $start_time)")
  printf "➔ Matrix Execution: %.2fs
" "$elapsed"
}

# 3. Quick System Resource Peek
alias systop="htop 2>/dev/null || top"

# METRIC COMPLETION AND AUTO-SUGGESTIONS
# 1. Smarter Tab Behavior & Menu Selection
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# 2. Workspace Status Dash Macro
ws() {
  echo "=== SYSTEMD WORKSPACE STATUS ==="
  echo "📍 Active Dir : $PWD"
  echo "📦 Containers : $(docker ps -q | wc -l) running"
  echo "🐍 Target Core : $(ls -1 *.py 2>/dev/null | wc -l) Python elements"
  echo "================================"
}

# 3. Dynamic Quick-Build Switch
matrix-run() {
  if [ -f "run_production_matrix.py" ]; then
    benchmark python3 run_production_matrix.py "$@"
  elif [ -f "run_workspace_refactor.py" ]; then
    benchmark python3 run_workspace_refactor.py "$@"
  else
    echo "❌ No standard operational matrix found in this path."
  fi
}

# TMUX WORKSPACE MULTIPLEXER
ide() {
  if [ -n "$TMUX" ]; then
    echo "⚠️ Already inside a tmux session."
    return
  fi
  local session="workspace_$(date +%s)"
  tmux new-session -d -s "$session"
  tmux rename-window -t "$session:0" 'Main Matrix'
  tmux split-window -h -p 35 -t "$session:0"
  tmux send-keys -t "$session:0.1" 'systop' C-m
  tmux split-window -v -p 50 -t "$session:0.1"
  tmux send-keys -t "$session:0.2" 'ws' C-m
  tmux select-pane -t "$session:0.0"
  tmux attach-session -t "$session"
}

# LONG-RUNNING MATRIX NOTIFIERS
# 1. Alert when a task completes
notify-me() {
  "$@"
  local exit_code=$?
  if [ $exit_code -eq 0 ]; then
    echo -e "
🔹 [1;32mSUCCESS[0m: Matrix task finished cleanly."
  else
    echo -e "
🔸 [1;31mFAILURE[0m: Task exited with status $exit_code"
  fi
}

# 2. Automatically isolate latest Python tracebacks
last-crash() {
  local log_file=$(ls -t *.log 2>/dev/null | head -n 1)
  if [ -n "$log_file" ]; then
    echo "🔍 Scanning most recent log: $log_file"
    grep -A 10 -B 2 -i "traceback\|error\|exception" "$log_file" || echo "✅ No visible exceptions found."
  else
    echo "❌ No workspace execution logs detected."
  fi
}

# MASTER TEXT SEARCH AND WORKSPACE ARCHIVING
# 1. Interactive Project-Wide Code Search (Live Preview)
fif() {
  if ! command -v rg &> /dev/null; then
    echo "❌ ripgrep (rg) is not installed. Install via: sudo apt install ripgrep"
    return 1
  fi
  local file
  file=$(rg --files-with-matches --no-messages "$*" | fzf --preview "rg --ignore-case --pretty --context 10 '$*' {}")
  if [ -n "$file" ]; then
    if [ -n "$EDITOR" ]; then
      "$EDITOR" "$file"
    else
      nano "$file"
    fi
  fi
}

# 2. Workspace Snapshorter (Quick Local Backup)
snapshot() {
  local archive_name="workspace_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
  echo "📦 Packing development elements into $archive_name..."
  tar --exclude='*.deb' --exclude='.gradle' --exclude='.pytest_cache' -czf "$archive_name" development projects *.py scripts
  echo "✅ Snapshot saved cleanly."
}

# PERFORMANCE MAINTENANCE AND NET TOOLS
# 1. Quick Local Port & Network Listener Check
ports() {
  echo "=== ACTIVE LOCAL LISTENERS ==="
  ss -tulnp 2>/dev/null || netstat -tulnp 2>/dev/null || lsof -i -P -n | grep LISTEN
}

# 2. Automation Engine Garbage Collection (Free Space)
workspace-clean() {
  echo "🧹 Initiating environment optimization cleanup..."
  echo "-> Cleaning Python __pycache__ bytecode files..."
  find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
  find . -type f -name "*.pyc" -delete 2>/dev/null
  if command -v docker &> /dev/null; then
    echo "-> Checking for unused dangling Docker layers..."
    docker system prune -f --volumes
  fi
  echo "✅ Optimization sequence finished."
}

# HIGH-EFFICIENCY HISTORY & PERSISTENCE
# 1. Substring History Search (Arrow Up/Down matches typed prefix)
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# 2. Prevent Duplicate Entries in History Storage
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

# 3. Dynamic Tmux Quick Attacher
matrix-attach() {
  local target_session
  target_session=$(tmux list-sessions -F "#S" 2>/dev/null | fzf --height 40% --reverse --prompt="Target Session ❯ ")
  if [ -n "$target_session" ]; then
    tmux attach-session -t "$target_session"
  else
    echo "ℹ️ No tmux sessions selected or active. Run 'ide' to spawn a grid."
  fi
}

# HYPER-SPEED ALIASING AND WORKSPACE QUICK-JUMPS
# 1. Structural Project Navigation Jumps
alias ..="cd .."
alias ...="cd ../.."
alias dev="cd ~/development"
# System Update Shortcuts
alias update='sudo apt update'
alias upgrade='sudo apt upgrade -y'

# 2. Safety Wrappers for Destructive Global Operations

# 3. Quick Core Matrix Configurations View

# REAL-TIME METRIC STREAMING AND EXTRACTION
# 1. Live Micro-Dashboard Watcher
matrix-watch() {
  local interval=${1:-2}
  echo "🖥️ Initializing active matrix stream... (Press Ctrl+C to exit)"
  sleep 1
  watch -n "$interval" -c "
    echo '=== WORKSPACE CORE TELEMETRY ==='
    echo '📍 Dir: '$PWD
    echo '🐍 Core scripts detected: '$(ls -1 *.py 2>/dev/null | wc -l)
    echo ''
    echo '=== NETWORK SOCKET BINDINGS ==='
    ss -tuln 2>/dev/null | head -n 5 || echo 'No active sockets.'
    echo ''
    echo '=== ACTIVE DOCKER STATE ==='
    docker ps --format 'table {{.Names}}	{{.Status}}	{{.Ports}}' | head -n 5
  "
}

# 2. Automated Smart Tar/Zip Extractor
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.gz|*.tgz) tar -xzf "$1" ;;
      *.tar)          tar -xf "$1"  ;;
      *.zip)          unzip "$1"    ;;
      *.deb)          ar x "$1"     ;;
      *)              echo "❌ Cannot extract '$1' via uniform handler." ;;
    esac
  else
    echo "❌ '$1' is not a valid operational file."
  fi
}

# ADVANCED CONTEXT SWITCHING AND GIT TELEMETRY
# 1. Hyper-Fast Git Status Streamlining

# 2. Automated Smart Synchronization Commit Macro
lsync() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "❌ No repository framework active here."
    return 1
  fi
  local msg=${1:-'workspace backup checkpoint'}
  echo "📦 Staging files for local tracking matrix..."
  git add -A
  git commit -m "$msg"
}

# 3. Fast Workspace State Jumper (Memory Switcher)
jump() {
  local target
  target=$(find ~/development ~/projects -maxdepth 2 -type d 2>/dev/null | fzf --height 40% --reverse --prompt="Teleport Matrix ❯ ")
  if [ -n "$target" ]; then
    cd "$target" && echo "📍 Switched space to: $PWD" && ls
  fi
}
 

# Rootless NPM Global Binary Path
export PATH="/home/tangleroot013/.npm-global/bin:$PATH"

autoload -U url-quote-magic
zle -N self-insert url-quote-magic
zstyle ':url-quote-magic:*' url-metas '* ?[]^()~#{}='

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
export NPM_PACKAGES="/home/tangleroot013/.npm-packages"
export PATH="$NPM_PACKAGES/bin:$PATH"
export NODE_PATH="$NPM_PACKAGES/lib/node_modules${NODE_PATH:+:$NODE_PATH}"
alias profit='python3 ~/claude_workspace/scripts/launch_claude.py'
alias hatch='python3 ~/.local/bin/hatch.py'
alias hatch='python3 ~/.local/bin/hatch.py'
alias hatch='python3 ~/.local/bin/hatch.py'
# Disable history expansion globally (safest for developers)
set +H

# Keep interactive comments enabled
setopt INTERACTIVE_COMMENTS

. "$HOME/.local/share/../bin/env"

# bun completions
[ -s "/home/tangleroot013/.bun/_bun" ] && source "/home/tangleroot013/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# ==========================================
# Audio & Terminal Music Manager Toolkit
# ==========================================
alias m="ncmpcpp"                   # Launch the main UI
alias m-update="mpc update"         # Force library rescan
alias m-stop="mpc stop"             # Instantly kill audio
alias m-play="mpc play"             # Resume audio
alias m-next="mpc next"             # Skip track
alias m-sys="systemctl --user status mpd" # Check daemon health

# Cmus (Fallback lightweight player)
alias cm="cmus"
alias crostini-cpu='htop -d 2 -p $(pgrep -d, -f "mpd|pipewire|wireplumber")'
export TMUX="${TMUX:-}"

# >>> source .zshrc.local >>>
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
# <<< source .zshrc.local <<<
