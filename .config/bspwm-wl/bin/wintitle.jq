# wintitle.jq: "App: title" for a bspc query -T node (used by wl-wintitle, wl-winpick).
# $max = max characters (0 = no limit); longer results end with an ellipsis.
def app:
  (.client.className // "") as $c | ($c | ascii_downcase) as $l
  | if   $l | test("^brave")               then "Brave"
    elif $l | test("^(chromium|chrome)")   then "Chromium"
    elif $l | test("^google-chrome")       then "Chrome"
    elif $l | test("qutebrowser")          then "qutebrowser"
    elif $l | test("^floorp")              then "Floorp"
    elif $l | test("^(firefox|librewolf)") then "Firefox"
    elif $l | test("^emacs")               then "Emacs"
    elif $l | test("zed")                  then "Zed"
    elif $l | test("libreoffice|soffice")  then "LibreOffice"
    elif $l | test("^foot")                then "foot"
    elif $l == "grok-bot"                  then "Grok Bot"
    elif $c == "" then "" else ($c | sub("-float$"; "")) end;
def clean:
  sub("\\s+[-—–]\\s+(Brave|Chromium|Google Chrome|Mozilla Firefox|Firefox|Floorp|LibreWolf|qutebrowser|Zed|GNU Emacs.*|LibreOffice( [A-Za-z]+)?)$"; "")
  | gsub("[[:cntrl:]]"; " ");
def wintitle($max):
  app as $a | ((.title // "") | clean) as $t
  | (if $t == "" or ($t | ascii_downcase) == ($a | ascii_downcase) then $a
     elif $a == "" then $t else "\($a): \($t)" end) as $s
  | if $max > 0 and ($s | length) > $max then ($s[0:($max - 1)] + "…") else $s end;
