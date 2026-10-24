# ~/.zshrc : interactive zsh (login shell is bash; this is for when zsh is run)
# part of sys7mfaul7 dotfiles
[[ -o interactive ]] || return

export EDITOR=nvim VISUAL=nvim
typeset -U path; path=("$HOME/.local/bin" $path)

# history
mkdir -p "$HOME/.local/state/zsh"
HISTFILE="$HOME/.local/state/zsh/history"
HISTSIZE=10000 SAVEHIST=10000
setopt append_history share_history hist_ignore_space hist_ignore_all_dups hist_reduce_blanks
setopt auto_cd interactive_comments prompt_subst complete_in_word

# completion
autoload -Uz compinit && compinit -d "$HOME/.local/state/zsh/compdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
_comp_options+=(globdots)

# keys: emacs style, plus Home/End/Delete
bindkey -e
bindkey '^[[H' beginning-of-line '^[[F' end-of-line '^[[3~' delete-char

# prompt: user@host dir (git branch), green on black like the rest
autoload -Uz vcs_info add-zsh-hook
zstyle ':vcs_info:git:*' formats ' %F{2}(%b)%f'
add-zsh-hook precmd vcs_info
PROMPT='%F{10}%n@%m%f %F{7}%~%f${vcs_info_msg_0_} %(?.%F{10}.%F{9})>%f '

# window title = cwd / running command
_title_dir() { print -Pn '\e]2;%~\a' }
_title_cmd() { print -n "\e]2;$1\a" }
add-zsh-hook precmd _title_dir
add-zsh-hook preexec _title_cmd

# plugins from the Guix system profile, if present
for p in zsh-autosuggestions zsh-syntax-highlighting; do
    f=/run/current-system/profile/share/zsh/plugins/$p/$p.zsh
    [[ -r $f ]] && source "$f"
done

command -v eza >/dev/null && { alias ls='eza --icons=auto' ll='eza -la --icons=auto'; }
