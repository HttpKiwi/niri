pragma Singleton

import QtQuick
import Quickshell

/**
 * Ui - which screen's menu is open, and on which section.
 */
Singleton {
    id: root

    property string menuOn: ""          // output name, "" when closed
    property string section: "all"      // all | apps | windows | tools | clipboard | system | wallpapers | inbox | phone | emoji

    // which pebble opens: the launcher, the wallpaper picker or the inbox
    readonly property string kind: section === "wallpapers" ? "wall" : section === "inbox" ? "inbox"
        : section === "phone" ? "phone" : section === "emoji" ? "emoji" : "menu"

    function open(output, sec) {
        section = sec || "all";
        menuOn = output;
    }
    function close() { menuOn = ""; }
    function toggle(output, sec) {
        if (menuOn && (!sec || sec === section)) close(); else open(output, sec);
    }
}
