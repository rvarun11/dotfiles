
export PATH="$HOME/.ghcup/bin:$PATH"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

eval "$(direnv hook zsh)"

ZSH_THEME="powerlevel10k/powerlevel10k"
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# Enable vi
bindkey -v

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

[ -f "/Users/varunrajput/.ghcup/env" ] && . "/Users/varunrajput/.ghcup/env" # ghcup-env

# history setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ---- Eza (better ls) -----
alias ls="eza --icons=always"

# ---- Zoxide (better cd) ----
eval "$(zoxide init zsh)"

# -- zsh-secrets --
# It contains the API keys to different models
[ -f ~/.zsh_secrets ] && source ~/.zsh_secrets



# TODO: WIP - Tmux split on cd into git repo

# Store the original path to the cd command if it's not already stored
# This prevents potential issues if this function is sourced multiple times
if ! command -v __original_cd > /dev/null; then
  # Find the actual 'cd' builtin or command
  # Handle cases where 'cd' might already be an alias or function
  __cd_path=$(command -V cd)
  if [[ $__cd_path == *"is a shell builtin"* ]]; then
     alias __original_cd="builtin cd"
  elif [[ $__cd_path == *"is a function"* || $__cd_path == *"is an alias for"* ]]; then
     # If it's already wrapped, we need to call that wrapper.
     # This is a common pattern for tools like zoxide, autojump etc.
     # We create an alias to the *current* definition of 'cd' before overriding it.
     # Make sure this function definition comes *after* any other tools that might wrap 'cd'.
     alias __original_cd="cd"
  else
     # Fallback to assuming 'cd' is an external command (less common)
     alias __original_cd="/usr/bin/cd" # Adjust path if needed
  fi
fi


cd() {
  # 1. Execute the original cd command with all arguments
  #    Use the stored original command/builtin/function
  __original_cd "$@"
  local cd_exit_code=$? # Capture exit code of cd

  # 2. Only proceed if cd was successful
  if [ $cd_exit_code -ne 0 ]; then
    return $cd_exit_code
  fi

  # --- Conditions for Tmux split ---

  # 3. Check if inside Tmux
  if [ -z "$TMUX" ]; then
    return 0 # Not in Tmux, nothing more to do
  fi

  # 4. Check if the new directory is a Git repository
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    return 0 # Not in a git repo, nothing more to do
  fi

  # --- Checks passed, prepare for Tmux actions ---

  # 5. Check if the current Tmux window has only one pane
  local pane_count
  pane_count=$(tmux display-message -p '#{window_panes}')
  if [ "$pane_count" -ne 1 ]; then
    # Already split or multiple panes exist, do nothing to avoid messing up layout
    return 0
  fi

  # --- Perform Tmux Actions ---
  local current_pane
  current_pane=$(tmux display-message -p '#{pane_id}')

  # Split vertically: new (right) pane gets 30%, original (left) keeps 70%
  # -h: horizontal layout (vertical split line)
  # -p 30: new pane takes 30%
  # -d: don't switch focus to the new pane
  # Capture the new pane ID if needed, though not strictly necessary here
  # tmux split-window -h -p 30 -d -t "$current_pane"
  tmux split-window -h -p 40 -d # Simpler version, splits the current pane

  # Send the 'nvim .' command to the *original* (left) pane.
  # The focus remains on the left pane because we used '-d' during split.
  # C-m sends the Enter key.
  tmux send-keys -t "$current_pane" 'nvim .' C-m

  # Optional: Switch focus to the new (right) pane if desired
  # tmux select-pane -t ! # Select the last created pane

  return 0 # Success
}

# Optional: Add a message to confirm the function is loaded when sourcing the file
# echo "Custom 'cd' function with Tmux Git support loaded."
