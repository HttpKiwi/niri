pragma Singleton

import QtQuick
import Quickshell

/**
 * Ui - which screen's menu is open, and on which section.
 */
Singleton {
    id: root

    property string menuOn: ""          // output name, "" when closed
    property string section: "all"      // all | apps | windows | tools | phone | clipboard | inbox | system

    function open(output, sec) {
        section = sec || "all";
        menuOn = output;
    }
    function close() { menuOn = ""; }
    function toggle(output, sec) {
        if (menuOn && (!sec || sec === section)) close(); else open(output, sec);
    }
}
