pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

import "Modules/Bar"
import "Modules/Decorations"
import "Modules/Bar/BarModules"

ShellRoot {
    Bar {}
    BarDecorations {}
    RoundedScreen {}
}
