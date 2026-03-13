#!/usr/bin/env bash
# =============================================================================
# install.sh - yesika-zsh plugin installer
# =============================================================================
set -e

PLUGIN_NAME="yesika-zsh"
PLUGIN_FILE="yesika-zsh.plugin.zsh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

echo ""
echo "  yesika-zsh installer"
echo "  ===================="
echo ""

# -----------------------------------------------------------------------------
# 1. Check dependencies
# -----------------------------------------------------------------------------
info "Checking dependencies..."

command -v zsh  >/dev/null 2>&1 || error "zsh is not installed."
command -v curl >/dev/null 2>&1 || error "curl is not installed."
command -v jq   >/dev/null 2>&1 || {
  warn "jq not found. Installing..."
  if command -v apt-get >/dev/null 2>&1; then
    apt-get install -y jq >/dev/null 2>&1 && success "jq installed." || error "Failed to install jq."
  elif command -v yum >/dev/null 2>&1; then
    yum install -y jq >/dev/null 2>&1 && success "jq installed." || error "Failed to install jq."
  elif command -v brew >/dev/null 2>&1; then
    brew install jq >/dev/null 2>&1 && success "jq installed." || error "Failed to install jq."
  else
    error "Cannot install jq automatically. Please install it manually and re-run."
  fi
}
success "Dependencies OK."

# -----------------------------------------------------------------------------
# 2. Detect oh-my-zsh
# -----------------------------------------------------------------------------
OMZ_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
PLUGIN_DIR="$OMZ_CUSTOM/plugins/$PLUGIN_NAME"

if [[ -d "$HOME/.oh-my-zsh" ]]; then
  info "oh-my-zsh detected at $HOME/.oh-my-zsh"
  if [[ -L "$PLUGIN_DIR" || -d "$PLUGIN_DIR" ]]; then
    warn "Plugin directory already exists at $PLUGIN_DIR — overwriting symlink."
    rm -rf "$PLUGIN_DIR"
  fi
  ln -s "$SCRIPT_DIR" "$PLUGIN_DIR"
  success "Symlink created: $PLUGIN_DIR -> $SCRIPT_DIR"

  # Add to plugins list in .zshrc if not already present
  ZSHRC="$HOME/.zshrc"
  if grep -q "plugins=" "$ZSHRC" 2>/dev/null; then
    if grep -q "$PLUGIN_NAME" "$ZSHRC"; then
      success "$PLUGIN_NAME already in plugins list."
    else
      sed -i "s/^plugins=(\(.*\))/plugins=(\1 $PLUGIN_NAME)/" "$ZSHRC"
      success "Added $PLUGIN_NAME to plugins in $ZSHRC"
    fi
  else
    warn "Could not find plugins=(...) in $ZSHRC. Add '$PLUGIN_NAME' manually."
  fi
else
  # No oh-my-zsh: source directly from .zshrc
  warn "oh-my-zsh not found. Adding direct source to ~/.zshrc"
  ZSHRC="$HOME/.zshrc"
  SOURCE_LINE="source \"$SCRIPT_DIR/$PLUGIN_FILE\""
  if grep -qF "$SOURCE_LINE" "$ZSHRC" 2>/dev/null; then
    success "Plugin already sourced in $ZSHRC"
  else
    echo "" >> "$ZSHRC"
    echo "# yesika-zsh plugin" >> "$ZSHRC"
    echo "$SOURCE_LINE" >> "$ZSHRC"
    success "Added source line to $ZSHRC"
  fi
fi

# -----------------------------------------------------------------------------
# 3. API key setup
# -----------------------------------------------------------------------------
ZSHENV="$HOME/.zshenv"
echo ""
info "API key setup"
echo ""
echo "  You need at least one of:"
echo "    OPENROUTER_API_KEY  (recommended — uses minimax/minimax-m2.5 by default)"
echo "    OPENAI_API_KEY      (direct OpenAI)"
echo ""

read -r -p "  Enter OPENROUTER_API_KEY (press Enter to skip): " OR_KEY
if [[ -n "$OR_KEY" ]]; then
  if grep -q "OPENROUTER_API_KEY" "$ZSHENV" 2>/dev/null; then
    sed -i "s|^export OPENROUTER_API_KEY=.*|export OPENROUTER_API_KEY=\"$OR_KEY\"|" "$ZSHENV"
  else
    echo "export OPENROUTER_API_KEY=\"$OR_KEY\"" >> "$ZSHENV"
  fi
  chmod 600 "$ZSHENV"
  success "OPENROUTER_API_KEY saved to $ZSHENV"
fi

read -r -p "  Enter OPENAI_API_KEY (press Enter to skip): " OA_KEY
if [[ -n "$OA_KEY" ]]; then
  if grep -q "OPENAI_API_KEY" "$ZSHENV" 2>/dev/null; then
    sed -i "s|^export OPENAI_API_KEY=.*|export OPENAI_API_KEY=\"$OA_KEY\"|" "$ZSHENV"
  else
    echo "export OPENAI_API_KEY=\"$OA_KEY\"" >> "$ZSHENV"
  fi
  chmod 600 "$ZSHENV"
  success "OPENAI_API_KEY saved to $ZSHENV"
fi

if [[ -z "$OR_KEY" && -z "$OA_KEY" ]]; then
  warn "No API key provided. Edit $ZSHENV and add one before using the plugin."
fi

# -----------------------------------------------------------------------------
# 4. Done
# -----------------------------------------------------------------------------
echo ""
success "Installation complete!"
echo ""
echo "  Open a new terminal or run:  source ~/.zshrc"
echo ""
echo "  Usage:"
echo "    yesika list all running containers     → translates & executes"
echo "    yesika? what does chmod 777 do         → prints answer only"
echo "    yesikall \"what is a zombie process\"    → standalone question"
echo "    yesika --help                          → full reference"
echo ""
