# Prevent a problem with p10k redirecting stdin to /dev/null that causes GPG to not ask for the passphrase for a key.
export GPG_TTY=$TTY

# Function to detect GPU and set GLX vendor library
set_glx_vendor() {
    if lspci 2>/dev/null | grep -iq "nvidia"; then
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
    elif lspci 2>/dev/null | grep -iq "amd" || lspci 2>/dev/null | grep -iq "radeon"; then
        export __GLX_VENDOR_LIBRARY_NAME=mesa
    else
        export __GLX_VENDOR_LIBRARY_NAME=mesa
    fi
}

set_glx_vendor

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "powerlevel10k/powerlevel10k" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Aliases for others
alias sudo='sudo '
alias pkexec='pkexec '

# # Add $PATH for NPM
# export NPM_PACKAGES="${HOME}/.npm-packages"
# export NODE_PATH="$NPM_PACKAGES/lib/node_modules${NODE_PATH:+:$NODE_PATH}"
# export PATH="$PATH:$NPM_PACKAGES/bin:$PATH"

# # Preserve MANPATH if you already defined it somewhere in your config.
# # Otherwise, fall back to `manpath` so we can inherit from `/etc/manpath`.
# export MANPATH="${MANPATH-$(manpath)}:$NPM_PACKAGES/share/man"

# Consistently display only our custom directories.
function ls() {
    local new_args=()
    for arg in "$@"; do
        if [[ "$arg" == "/" ]]; then
            new_args+=("/System" "/Applications" "/Users")
        elif [[ "$arg" == "/home/$USER" ]]; then
            new_args+=("/Users/$USER")
        else
            new_args+=("$arg")
        fi
    done
    command ls "${new_args[@]}"
}

function tree() {
    local new_args=()
    for arg in "$@"; do
        if [[ "$arg" == "/" ]]; then
            new_args+=("/System" "/Applications" "/Users")
        elif [[ "$arg" == "/home/$USER" ]]; then
            new_args+=("/Users/$USER")
        else
            new_args+=("$arg")
        fi
    done
    command tree "${new_args[@]}"
}

function dir() {
    local new_args=()
    for arg in "$@"; do
        if [[ "$arg" == "/" ]]; then
            new_args+=("/System" "/Applications" "/Users")
        elif [[ "$arg" == "/home/$USER" ]]; then
            new_args+=("/Users/$USER")
        else
            new_args+=("$arg")
        fi
    done
    command dir "${new_args[@]}"
}

function vdir() {
    local new_args=()
    for arg in "$@"; do
        if [[ "$arg" == "/" ]]; then
            new_args+=("/System" "/Applications" "/Users")
        else
            new_args+=("$arg")
        fi
    done
    command vdir "${new_args[@]}"
}

function grep() {
    local new_args=()
    for arg in "$@"; do
        if [[ "$arg" == "/" ]]; then
            new_args+=("/System" "/Applications" "/Users")
        elif [[ "$arg" == "/home/$USER" ]]; then
            new_args+=("/Users/$USER")
        else
            new_args+=("$arg")
        fi
    done
    command grep "${new_args[@]}"
}

function cat() {
    local new_args=()
    for arg in "$@"; do
        if [[ "$arg" == "/" ]]; then
            new_args+=("/System" "/Applications" "/Users")
        elif [[ "$arg" == "/home/$USER" ]]; then
            new_args+=("/Users/$USER")
        else
            new_args+=("$arg")
        fi
    done
    command cat "${new_args[@]}"
}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Add $PATH for system AppImages
export PATH="/Applications:$PATH"

# Add $PATH for sbin
export PATH="/usr/local/sbin:/usr/sbin:/sbin:$PATH"

# Add environment variables for Wayland to use NVIDIA GBM
export GBM_BACKEND=nvidia-drm
export __NV_PRIME_RENDER_OFFLOAD=1

# Add Flatpak environment variables to XDG_DATA_DIRS
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"

# Add variable for Qt scale factor
export QT_SCALE_FACTOR=1

# Supress AT-SPI warning message
export NO_AT_BRIDGE=1
