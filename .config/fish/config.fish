# Seamless auto-start for Niri
if status is-login
    if test -z "$WAYLAND_DISPLAY" -a "$XDG_VTNR" = 1
        # The '-l' flag forces niri-session to bypass its internal login shell loop,
        # which prevents an infinite recursion fork-bomb in Fish.
        exec niri-session -l
    end
end

if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -x PATH $PATH /usr/lib/qt6/bin/
# Android Development Setup
set -x ANDROID_HOME /home/httpkiwi/android-sdk

set -gx JAVA_HOME /usr/lib/jvm/java-17-openjdk
set -gx CHROME_EXECUTABLE /usr/sbin/chromium
set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
# Flutter
set -gx FLUTTER_ROOT /opt/flutter
set -gx QS_ICON_THEME Papirus
set -x QT_QPA_PLATFORMTHEME kvantum

set -U fish_greeting
# Add paths
fish_add_path /opt/flutter/bin
fish_add_path $ANDROID_HOME/tools
fish_add_path $ANDROID_HOME/tools/bin
fish_add_path $ANDROID_HOME/platform-tools
fish_add_path $ANDROID_HOME/cmdline-tools/latest/bin

starship init fish | source
export PATH="$HOME/.local/bin:$PATH"

# Added by Antigravity CLI installer
set -gx PATH "/home/httpkiwi/.local/bin" $PATH
