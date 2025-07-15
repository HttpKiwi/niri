pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

import "Modules/Bar"
import "Modules/Decorations"
import "Modules/Bar/BarModules"
import "Modules/Popups"

ShellRoot {
    Bar {}
    RoundedScreen {}
    ScreenBorder {}
    Osd {}
}
