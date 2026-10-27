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
# Prompt colours come from the active rice (theme.conf [ui] prompt_* ->
# ~/.config/rices/current/ui.sh, re-read before every prompt so `rice set`
# shows in open shells too). The defaults below are the green master values.
__ps_ui() {
  RICE_PS_BRACKET='38;2;230;219;116' RICE_PS_USER='38;2;0;255;65' RICE_PS_AT='38;2;255;255;255'
  RICE_PS_HOST='38;2;0;255;65' RICE_PS_PATH='38;2;0;255;65' RICE_PS_SYMBOL= RICE_PS_ERROR= RICE_PS_META='38;2;47;90;47'
  . "$HOME/.config/rices/current/ui.sh" 2>/dev/null
}
__ps_mode() {
  __ps_ui
  local m="3${RICE_PS_META:+;$RICE_PS_META}"
  PS0='\n\[\e['"$m"'m\] - cmd start: $(TZ=America/Chicago date "+%a %b %-d %Y %-I:%M:%S %p %Z")\[\e[0m\]\n\n'
  [ -n "$__ps_novi" ] && return
  local u="${USER:-$(id -un)}" h="${HOSTNAME%%.*}" p="${PWD/#$HOME/\~}"
  p=${p//\\/\\\\}; p=${p//\"/\\\"}
  local cu=$RICE_PS_USER ch=$RICE_PS_HOST cp=$RICE_PS_PATH
  [ "$EUID" -eq 0 ] && cu=$__ps_col ch=$__ps_col cp=$__ps_col
  # brackets, user, @, host, path: one colour each ([ui] prompt_bracket/_user/_at/_host/_path)
  local B="\\1\\e[${RICE_PS_BRACKET}m\\2" A="\\1\\e[${RICE_PS_AT}m\\2" U="\\1\\e[${cu}m\\2" Hc="\\1\\e[${ch}m\\2" P= R='\1\e[0m\2'
  [ "$cp" != "$ch" ] && P="\\1\\e[${cp}m\\2"
  local t="${B}[${U}${u}${A}@${Hc}${h}${P} ${p}${B}]${R}"
  # +/: and $ : prompt_symbol (prompt_error after a failed command); unset = terminal default
  local s=$RICE_PS_SYMBOL; [ "${__ps_rc:-0}" -ne 0 ] && [ -n "$RICE_PS_ERROR" ] && s=$RICE_PS_ERROR
  local M="" E=""; [ -n "$s" ] && M="\\1\\e[${s}m\\2" E='\1\e[0m\2'
  [ "$EUID" -eq 0 ] && M="\\1\\e[1;38;2;255;51;51m\\2" E=
  bind "set vi-ins-mode-string \"${t}${M}+${E}\"" 2>/dev/null
  bind "set vi-cmd-mode-string \"${t}${M}:${E}\"" 2>/dev/null
  if [ "$EUID" -ne 0 ]; then
    if [ -n "$s" ]; then PS1='\n\[\e['"$s"'m\]\$\[\e[0m\] '; else PS1='\n\$ '; fi
  fi
}

# finished stamp + duration + audit log
__cmd_log="${XDG_STATE_HOME:-$HOME/.local/state}/bash/cmd-audit.log"
__cmd_fmt() { TZ=America/Chicago date -d "@$1" '+%a %b %-d %Y %-I:%M:%S %p %Z'; }
__cmd_finished() {
  local rc=$?
  __ps_rc=$rc
  if [ -z "$_cmd_init" ]; then _cmd_init=1; unset _cmd_ran; return; fi
  if [ -n "$_cmd_ran" ]; then
    local end=$EPOCHSECONDS d=$(( EPOCHSECONDS - _cmd_start )) dur
    if [ $d -ge 3600 ]; then dur="$((d/3600))h$((d%3600/60))m$((d%60))s"
    elif [ $d -ge 60 ]; then dur="$((d/60))m$((d%60))s"; else dur="${d}s"; fi
    printf '\n\e[3%sm - cmd finished: %s (took %s, exit %s)\e[0m\n' "${RICE_PS_META:+;$RICE_PS_META}" "$(__cmd_fmt $end)" "$dur" "$rc"
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
