#!/usr/bin/env bash
set -euo pipefail

log() { echo -e "\e[1;34m==> $*\e[0m"; }

log "=== Initializing Environment Setup ==="

# 1. Ensure directories exist
mkdir -p "$HOME/.oh-my-zsh/custom/plugins" "$HOME/development"

# 2. Setup standard development packages
log "Installing foundational tools..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq && sudo apt-get install -y zsh git curl wget nano build-essential python3

# 3. Clone Oh-My-Zsh framework if missing
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log "Cloning Oh-My-Zsh..."
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi

# 4. Generate your custom .zshrc profile
log "Building your custom .zshrc profile..."
cat > "$HOME/.zshrc" <<'INNER_EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Navigation and Custom Aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gl='git log --oneline --graph --decorate'
alias dev='cd ~/development'
alias zshrc='nano ~/.zshrc && source ~/.zshrc'

# Custom Functions
mcd() { mkdir -p "$1" && cd "$1"; }

sysinfo() {
    echo -e "\e[1;32m--- Container Status ---\e[0m" && uname -a
    echo -e "\e[1;32m--- Memory Usage ---\e[0m" && free -h
    echo -e "\e[1;32m--- Storage State ---\e[0m" && df -h /
}

serve() {
    local port="${1:-8080}"
    python3 -m http.server "$port"
}
INNER_EOF

# 5. Switch default shell to Zsh
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "/usr/bin/zsh" ]]; then
    log "Setting Zsh as default shell..."
    sudo chsh -s /usr/bin/zsh "$USER"
fi

log "=== Environment Setup Complete! ==="
