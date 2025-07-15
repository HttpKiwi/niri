import Quickshell
import Quickshell.Io
import QtQuick
import Services 1.0

Item {
	Connections {
		target: Audio

		function onVolumeChanged() {
			console.log("Volume changed to: " + Audio.volume);
		}
	}
}
