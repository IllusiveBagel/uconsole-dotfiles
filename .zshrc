# ~/.zshrc
#
# "Tape Deck 01" — cassette-futurism zsh config.
# Hand-rolled prompt, no Powerlevel10k/Starship/Oh-My-Zsh — matches the
# minimal, build-it-yourself approach of the rest of this rice, and
# keeps things light on the uConsole's modest hardware.
#
# Palette (matches theme.lua / alacritty.yml):
#   bg        #1c1712   fg        #ffb45c   fg bright #ff9d3f
#   accent    #7ee0c4   urgent    #e5502f   muted     #8a6a2f

# ── History ─────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt EXTENDED_HISTORY       # timestamp each entry
setopt HIST_IGNORE_DUPS       # don't record a line twice in a row
setopt HIST_IGNORE_SPACE      # lines starting with space aren't recorded
setopt HIST_VERIFY            # expand history refs before running them
setopt SHARE_HISTORY          # share history across concurrent sessions
setopt APPEND_HISTORY

# ── Completion ──────────────────────────────────────────────
autoload -Uz compinit
# Only rebuild the completion cache once a day — noticeably faster
# startup on slower ARM hardware like the uConsole.
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case-insensitive
zmodload zsh/complist

# ── Keybindings ─────────────────────────────────────────────
bindkey -e                          # emacs-style bindings (default);
                                     # swap to `bindkey -v` for vi-mode
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^R' history-incremental-search-backward

# ── Aliases ─────────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -lAh --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# ── Git info for the prompt ─────────────────────────────────
# Uses zsh's own bundled vcs_info (ships with zsh itself, not an
# external framework) rather than hand-parsing `git status`.
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '%b'
zstyle ':vcs_info:git:*' actionformats '%b|%a'
# check-for-changes is what lets us show a "dirty" indicator below —
# it costs an extra `git status`, negligible for normal repo sizes.
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '+'
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' formats '%b%c%u'

precmd_functions+=(vcs_info)

# ── Prompt ──────────────────────────────────────────────────
setopt PROMPT_SUBST

# Exit-code "recording LED": lit teal on success, red on failure —
# echoes the focus LED on the custom Awesome titlebar.
_cassette_status_led() {
    if [[ $? -eq 0 ]]; then
        echo "%F{#7ee0c4}●%f"
    else
        echo "%F{#e5502f}●%f"
    fi
}

# Git segment: only shown inside a repo, styled like a little cassette
# label — dim amber branch name, brighter amber if the tree is dirty.
_cassette_git_segment() {
    if [[ -n "$vcs_info_msg_0_" ]]; then
        if [[ "$vcs_info_msg_0_" == *[*+]* ]]; then
            echo " %F{#ef8a2c}[${vcs_info_msg_0_}]%f"
        else
            echo " %F{#8a6a2f}[${vcs_info_msg_0_}]%f"
        fi
    fi
}

# Two-line prompt:
#   [●] user@host  ~/path [branch]
#   ❯
PROMPT='$(_cassette_status_led) %F{#ffb45c}%n%f%F{#8a6a2f}@%f%F{#7ee0c4}%m%f %F{#ff9d3f}%~%f$(_cassette_git_segment)
%F{#e5502f}❯%f '

# Right prompt: quiet amber clock, echoes the wibar's LED readout.
RPROMPT='%F{#8a6a2f}%D{%H:%M}%f'

# ── Optional syntax highlighting / autosuggestions ──────────
# Not installed by default. If you'd like them:
#   sudo apt install zsh-syntax-highlighting zsh-autosuggestions
# they'll be picked up automatically below once present — no edits
# needed here.
for _plugin in \
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
    [[ -f "$_plugin" ]] && source "$_plugin"
done
unset _plugin

# Autosuggestion color, if the plugin above got sourced.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#3a2e20'

# ── Editor / misc environment ───────────────────────────────
export EDITOR='nvim'
export VISUAL="$EDITOR"
export TERMINAL='alacritty'
export LANG='en_US.UTF-8'
