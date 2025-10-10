if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -x PATH $PATH /usr/lib/qt6/bin/
# Android Development Setup
set -gx ANDROID_HOME $HOME/Android/Sdk
set -gx JAVA_HOME /usr/lib/jvm/java-17-openjdk
set -gx CHROME_EXECUTABLE /usr/bin/chromium

# Flutter
set -gx FLUTTER_ROOT /opt/flutter

# Add paths
fish_add_path /opt/flutter/bin
fish_add_path $ANDROID_HOME/tools
fish_add_path $ANDROID_HOME/tools/bin
fish_add_path $ANDROID_HOME/platform-tools
fish_add_path $ANDROID_HOME/cmdline-tools/latest/bin

starship init fish | source
