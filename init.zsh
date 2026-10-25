alias doff="${0:A:h}/doff"

# installs the LaunchAgent and hot corner on the first shell start
[ -f "$HOME/Library/LaunchAgents/io.github.yuma-satake.doff-hot-corner.plist" ] || "${0:A:h}/install"
