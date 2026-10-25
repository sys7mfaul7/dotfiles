# Tab completion: LS_COLORS, bash-completion, carapace (flag descriptions), fzf.
# Sourced from ~/.bashrc after prompt.sh. Interactive shells only.
case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac

# Colours for `ls --color` and readline's coloured completion lists.
# Green palette, no blue: dirs bold mid green, links "previous" green,
# executables bold accent, typed prefix in the accent, broken links dim+struck.
export LS_COLORS='rs=0:di=1;38;2;95;191;95:ln=38;2;143;239;143:mh=0:pi=38;2;230;219;116:so=38;2;230;219;116:do=38;2;230;219;116:bd=1;38;2;230;219;116:cd=1;38;2;230;219;116:or=9;38;2;79;127;90:mi=9;38;2;79;127;90:su=1;38;2;230;219;116:sg=1;38;2;230;219;116:ca=0:tw=1;38;2;95;191;95:ow=1;38;2;95;191;95:st=1;38;2;95;191;95:ex=1;38;2;0;255;65:*readline-colored-completion-prefix=38;2;0;255;65'

# bash-completion: /etc/bashrc.d/bash_completion.sh normally loads it already;
# only load the profile copy if that did not happen (no double-sourcing).
if [ -z "${BASH_COMPLETION_VERSINFO-}" ] && shopt -q progcomp &&
   [ -r "$HOME/.guix-profile/share/bash-completion/bash_completion" ]; then
  . "$HOME/.guix-profile/share/bash-completion/bash_completion"
fi

# Source a tool's generated init script from a cache, regenerated only when
# the binary changes (keeps shell startup fast).
__compl_cached() {  # name binary [args...]
  local name=$1 bin real f first=; bin=$(type -P "$2") || return 1; shift 2
  real=$(readlink -f "$bin")
  f="${XDG_CACHE_HOME:-$HOME/.cache}/bash/$name.bash"
  [ -s "$f" ] && read -r first < "$f"
  if [ "$first" != "# $real" ] || [ "$real" -nt "$f" ]; then
    mkdir -p "${f%/*}"
    if { printf '# %s\n' "$real"; "$bin" "$@" 2>/dev/null; } > "$f.tmp"; then
      mv -f "$f.tmp" "$f"
    else
      rm -f "$f.tmp"; return 1
    fi
  fi
  . "$f"
}

# carapace: completions with descriptions for ~1000 commands. Loaded BEFORE
# fzf so fzf wraps it (plain Tab -> carapace, **<Tab> -> fzf). Commands it
# does not know (guix, herd, ...) keep their bash-completion completers.
# Descriptions show with Ctrl-O (list view); Tab cycles plain values.
__compl_cached carapace carapace _carapace bash

# fzf: Ctrl-R history, Ctrl-T files, Alt-C cd, **<Tab> fuzzy completion.
export FZF_DEFAULT_OPTS="--color=dark,bg:#000000,fg:#c0ffc0,hl:#00ff41,fg+:#c0ffc0,bg+:#1f6f2f,hl+:#00ff41,info:#5fbf5f,prompt:#00ff41,pointer:#00ff41,marker:#00ff41,spinner:#5fbf5f,header:#4f7f5a,border:#2f5a2f,gutter:#000000,query:#c0ffc0,separator:#2f5a2f,scrollbar:#2f5a2f,label:#5fbf5f,preview-fg:#c0ffc0,preview-bg:#000000,disabled:#4f7f5a,ghost:#4f7f5a"
__compl_cached fzf fzf --bash
# bash-completion 2.11 owns `complete -D`, which stops fzf hooking **<Tab> for
# commands outside its built-in list; fzf's default handler still lazy-loads
# bash-completion's completers, so let fzf own the default.
if declare -F __fzf_default_completion >/dev/null; then
  complete -D -F __fzf_default_completion -o default -o bashdefault 2>/dev/null
fi
unset -f __compl_cached
