import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config

ColumnLayout {
    id: root
    property string label: ""
    property string valueText: ""
    property real from: 0
    property real to: 1
    property real stepSize: 0.01
    property real value: 0
    // When set, shows a restore control while the value differs from default
    property real defaultValue: Number.NaN
    signal moved(real value)

    readonly property bool hasDefault: !isNaN(defaultValue)
    readonly property bool isAtDefault: {
        if (!hasDefault)
            return true;
        const tol = Math.max(Math.abs(stepSize) * 0.49, 1e-6);
        return Math.abs(value - defaultValue) <= tol;
    }

    Layout.fillWidth: true
    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: root.label
            color: Theme.textPrimary
            font.family: Settings.fontFamilyDefault
            font.pixelSize: Settings.fontSizeMedium
        }

        Text {
            text: root.valueText
            color: Theme.accent
            font.family: Settings.fontFamilyDefault
            font.pixelSize: Settings.fontSizeSmall
            font.weight: Font.DemiBold
        }

        Item {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            visible: root.hasDefault
            opacity: root.isAtDefault ? 0.28 : 1
            enabled: !root.isAtDefault

            Text {
                anchors.centerIn: parent
                text: "\ue8ba"
                color: resetMa.containsMouse && parent.enabled ? Theme.accent : Theme.textSecondary
                font.family: Settings.fontFamilyIcons
                font.pixelSize: 16
            }

            MouseArea {
                id: resetMa
                anchors.fill: parent
                enabled: parent.enabled
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (!root.hasDefault || root.isAtDefault)
                        return;
                    slider.value = root.defaultValue;
                    root.moved(root.defaultValue);
                }

                ToolTip.visible: containsMouse
                ToolTip.delay: 400
                ToolTip.text: root.isAtDefault ? "Default" : "Restore default"
            }
        }
    }

    Slider {
        id: slider
        Layout.fillWidth: true
        Layout.preferredHeight: 22
        from: root.from
        to: root.to
        stepSize: root.stepSize
        value: root.value
        live: true
        wheelEnabled: true
        onMoved: root.moved(value)

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + (slider.availableHeight - height) / 2
            implicitWidth: 200
            implicitHeight: 22
            width: slider.availableWidth
            height: 6
            radius: 3
            color: Theme.withAlpha(Theme.textPrimary, 0.12)

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: parent.radius
                color: Theme.accent
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + (slider.availableHeight - height) / 2
            implicitWidth: 18
            implicitHeight: 18
            width: 18
            height: 18
            radius: 9
            color: Theme.textPrimary
            border.width: 2
            border.color: Theme.accent
        }
    }
}
