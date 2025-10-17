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

# Add paths
fish_add_path /opt/flutter/bin
fish_add_path $ANDROID_HOME/tools
fish_add_path $ANDROID_HOME/tools/bin
fish_add_path $ANDROID_HOME/platform-tools
fish_add_path $ANDROID_HOME/cmdline-tools/latest/bin

starship init fish | source
export PATH="$HOME/.local/bin:$PATH"