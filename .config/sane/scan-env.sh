# Environment for SANE + Brother brscan4 on Guix (sourced by scanimage/scan2image/simple-scan wrappers)
# brscan4 is a binary driver that hard-codes /opt/brother and /etc/opt/brother paths;
# nonguix ships an LD_PRELOAD shim that redirects those into the store and to
# $BRSANENETDEVICE4_CFG_FILENAME for the network-device list.
_gp="$HOME/.guix-profile"
_brs="$(dirname "$(dirname "$(readlink -f "$_gp/bin/brsaneconfig4")")")"
export SANE_CONFIG_DIR="$HOME/.config/sane.d:$_gp/etc/sane.d"
export SANE_BACKEND_LIB_PATH="$_gp/lib/sane"
export BRSANENETDEVICE4_CFG_FILENAME="$HOME/.config/brscan4/brsanenetdevice4.cfg"
export LD_PRELOAD="$_brs/libexec/brother/scanner/brscan4/libpreload.so${LD_PRELOAD:+:$LD_PRELOAD}"
unset _gp _brs
