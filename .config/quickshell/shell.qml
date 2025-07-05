pragma ComponentBehavior: Bound

import Quickshell
import QtQuick.Shapes
// import Quickshell.Io
import QtQuick
import Services 1.0

import "Modules/Bar"
import "Modules/Common"
import "Modules/Bar/BarModules"

ShellRoot {
    Bar {}
    BarDecorations {}
    RoundedScreen {}
}
