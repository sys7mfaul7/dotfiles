# h4ck3r prompt: [user@host path]+$ (bright red when root), blank line after output
# Interactive shells only: scripts, ssh commands and cron never get the prompt,
# the DEBUG trap or readline binds.
case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac
# The vi-mode indicator (+ insert, : command) sits right before $/#: readline
# always prints the mode string first, so the [user@host path] part is folded
# into the mode strings, refreshed before each prompt by __ps_mode.
if [ "$EUID" -eq 0 ]; then __ps_col='1;38;2;255;51;51'; else __ps_col='38;2;0;255;65'; fi
if [ "$EUID" -eq 0 ]; then PS1='\n\[\e[1;38;2;255;51;51m\]\$\[\e[0m\] '; else PS1='\n\$ '; fi
# Without vi mode in readline (e.g. a root shell with no ~/.inputrc), keep the
# [user@host path] part in PS1 itself.
case "$(bind -v 2>/dev/null)" in *"show-mode-in-prompt on"*) ;; *)
  PS1='\n\[\e['"$__ps_col"'m\][\u@\h \w]\$\[\e[0m\] '; __ps_novi=1 ;; esac
__ps_mode() {
  [ -n "$__ps_novi" ] && return
  local u="${USER:-$(id -un)}" h="${HOSTNAME%%.*}" p="${PWD/#$HOME/\~}"
  p=${p//\\/\\\\}; p=${p//\"/\\\"}
  # brackets nvim amber #e6db74, @ nvim white #ffffff, text in the prompt colour
  local B='\1\e[38;2;230;219;116m\2' A='\1\e[38;2;255;255;255m\2' C="\\1\\e[${__ps_col}m\\2" R='\1\e[0m\2'
  local t="${B}[${C}${u}${A}@${C}${h} ${p}${B}]${R}"
  local M=""; [ "$EUID" -eq 0 ] && M="\\1\\e[1;38;2;255;51;51m\\2"
  bind "set vi-ins-mode-string \"${t}${M}+\"" 2>/dev/null
  bind "set vi-cmd-mode-string \"${t}${M}:\"" 2>/dev/null
}
PS0='\n\[\e[3;38;2;47;90;47m\] - cmd start: $(TZ=America/Chicago date "+%a %b %-d %Y %-I:%M:%S %p %Z")\[\e[0m\]\n\n'

# finished stamp + duration + audit log
__cmd_log="${XDG_STATE_HOME:-$HOME/.local/state}/bash/cmd-audit.log"
__cmd_fmt() { TZ=America/Chicago date -d "@$1" '+%a %b %-d %Y %-I:%M:%S %p %Z'; }
__cmd_finished() {
  local rc=$?
  if [ -z "$_cmd_init" ]; then _cmd_init=1; unset _cmd_ran; return; fi
  if [ -n "$_cmd_ran" ]; then
    local end=$EPOCHSECONDS d=$(( EPOCHSECONDS - _cmd_start )) dur
    if [ $d -ge 3600 ]; then dur="$((d/3600))h$((d%3600/60))m$((d%60))s"
    elif [ $d -ge 60 ]; then dur="$((d/60))m$((d%60))s"; else dur="${d}s"; fi
    printf '\n\e[3;38;2;47;90;47m - cmd finished: %s (took %s, exit %s)\e[0m\n' "$(__cmd_fmt $end)" "$dur" "$rc"
    local cmd; cmd=$(HISTTIMEFORMAT= history 1 | sed 's/^ *[0-9]* *//')
    mkdir -p "${__cmd_log%/*}"; ( umask 077; printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(__cmd_fmt $_cmd_start)" "$(__cmd_fmt $end)" "$dur" "$rc" "$PWD" "$cmd" >> "$__cmd_log" )
    unset _cmd_ran
  fi
}
# readline widgets (fzf Ctrl-T/Ctrl-R, bind -x) and Tab-completion functions
# also fire DEBUG; skip them so they do not count as a command run.
trap '[ -z "${READLINE_LINE+x}" ] && [ -z "${COMP_LINE+x}" ] && [ "$BASH_COMMAND" != "__cmd_finished" ] && [ "$BASH_COMMAND" != "__ps_mode" ] && [ -z "$_cmd_ran" ] && { _cmd_ran=1; _cmd_start=$EPOCHSECONDS; }' DEBUG
PROMPT_COMMAND='__cmd_finished; __ps_mode'
alias cmdlog='column -t -s $'"'"'\t'"'"' "$__cmd_log" | less -S +G'
