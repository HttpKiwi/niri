import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import Services 1.0

WrapperItem {

    // Your existing content in a layout
    RowLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: 8

        Text {
            Layout.maximumWidth: 200
            elide: Text.ElideRight
            color: "white"  // Changed from Color.on_background for visibility
            text: Mpris.players.values[0]?.trackArtist || "No artist"
        }

        Text {
            Layout.maximumWidth: 120
            color: "white"  // Changed from Color.on_background
            elide: Text.ElideRight
            text: Mpris.players.values[0]?.trackTitle ? "- " + Mpris.players.values[0].trackTitle : "No track"
        }
      }
}
