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

# carapace (1.8.1) quotes file names with spaces, ( ) $ etc. itself and is
# registered with `-o noquote`, so readline stats the quoted text
# ("a b.txt" with the quotes) for colored-stats, finds nothing and shows the
# LS_COLORS missing-file style (struck through). When every match is an
# existing path (or a symlink, broken or not), hand readline the plain names
# with `-o filenames` instead: it stats the real file and quotes on insert.
__carapace_dequote() {  # quoted word -> REPLY (no eval)
  local s=$1 out= c q= i n=${#1}
  for ((i = 0; i < n; i++)); do
    c=${s:i:1}
    if [[ $q == "'" ]]; then
      if [[ $c == "'" ]]; then q=; else out+=$c; fi
    elif [[ $q == '"' ]]; then
      if [[ $c == '"' ]]; then q=
      elif [[ $c == '\' && ${s:i+1:1} == [\"\\\$\`] ]]; then ((i++)); out+=${s:i:1}
      else out+=$c; fi
    else
      case $c in
        "'" | '"') q=$c ;;
        '\') ((i++)); out+=${s:i:1} ;;
        *) out+=$c ;;
      esac
    fi
  done
  REPLY=$out
}
__carapace_plain_files() {
  local r REPLY changed= plain=()
  ((${#COMPREPLY[@]})) || return 0
  for r in "${COMPREPLY[@]}"; do
    __carapace_dequote "$r"
    [[ $REPLY == "~"* ]] && return 0             # leave ~ paths to carapace
    [[ -e $REPLY || -L $REPLY ]] || return 0     # not all files: keep as is
    [[ $REPLY != "$r" ]] && changed=1
    # -o filenames adds the / for directories itself (avoid "sub//")
    [[ $REPLY == ?*/ && -d $REPLY ]] && REPLY=${REPLY%/}
    plain+=("$REPLY")
  done
  [[ $changed ]] || return 0
  COMPREPLY=("${plain[@]}")
  compopt +o noquote -o filenames 2>/dev/null
}
if declare -F _carapace_completer >/dev/null && ! declare -F __carapace_completer_orig >/dev/null; then
  eval "$(declare -f _carapace_completer | sed '1s/^_carapace_completer/__carapace_completer_orig/')"
  _carapace_completer() { __carapace_completer_orig "$@"; __carapace_plain_files; }
fi

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
