pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.core
import qs.components.base

/**
 * CalendarPanel - Month view pocket; opens from bar date/time.
 */
PocketTopPanel {
    id: root

    panelFlag: "calendar"
    edgeInset: 8
    animationDuration: Settings.animationDurationMedium
    easingType: Settings.easingStandard

    readonly property int panelW: 320
    readonly property int panelH: 408
    readonly property int sectionInset: 8
    readonly property int sectionRadius: Math.max(8, Settings.screenCornerRadius - sectionInset)

    implicitWidth: panelW
    implicitHeight: panelH
    width: panelW
    height: panelH

    property int viewYear: clock.date.getFullYear()
    property int viewMonth: clock.date.getMonth() + 1 // 1..12
    property int selectedDay: clock.date.getDate()

    readonly property var monthNames: [
        "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
        "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
    ]
    readonly property var weekdayLabels: ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]

    readonly property int todayYear: clock.date.getFullYear()
    readonly property int todayMonth: clock.date.getMonth() + 1
    readonly property int todayDay: clock.date.getDate()

    readonly property int firstWeekday: {
        // Monday = 0 .. Sunday = 6
        const wd = new Date(viewYear, viewMonth - 1, 1).getDay();
        return wd === 0 ? 6 : wd - 1;
    }

    readonly property int daysInMonth: new Date(viewYear, viewMonth, 0).getDate()

    readonly property string selectedHoliday: ColombianHolidays.nameOn(viewYear, viewMonth, selectedDay)
    readonly property var monthHolidays: ColombianHolidays.holidaysInMonth(viewYear, viewMonth)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    onOpened: {
        viewYear = todayYear;
        viewMonth = todayMonth;
        selectedDay = todayDay;
        Qt.callLater(() => keyboardScope.forceActiveFocus());
    }

    function prevMonth() {
        if (viewMonth === 1) {
            viewMonth = 12;
            viewYear--;
        } else {
            viewMonth--;
        }
    }

    function nextMonth() {
        if (viewMonth === 12) {
            viewMonth = 1;
            viewYear++;
        } else {
            viewMonth++;
        }
    }

    function goToday() {
        viewYear = todayYear;
        viewMonth = todayMonth;
        selectedDay = todayDay;
    }

    FocusScope {
        id: keyboardScope
        anchors.fill: parent
        focus: root.shouldBeActive

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (root.panelState)
                    root.panelState.calendar = false;
                event.accepted = true;
            } else if (event.key === Qt.Key_Left) {
                prevMonth();
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                nextMonth();
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.sectionInset
            spacing: 8

            SectionCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 54

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: root.monthNames[root.viewMonth - 1] + " " + root.viewYear
                        color: Theme.textPrimary
                        font.family: Settings.fontFamilyDefault
                        font.pixelSize: Settings.fontSizeMedium
                        font.weight: Font.DemiBold
                    }

                    IconButton {
                        iconName: "go-previous"
                        fallbackIcon: "\ue5cb"
                        onClicked: root.prevMonth()
                    }
                    IconButton {
                        iconName: "go-next"
                        fallbackIcon: "\ue5cc"
                        onClicked: root.nextMonth()
                    }
                }
            }

            SectionCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 236

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Repeater {
                            model: root.weekdayLabels
                            delegate: Text {
                                required property string modelData
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                color: Theme.textSecondary
                                font.family: Settings.fontFamilyDefault
                                font.pixelSize: Settings.fontSizeSmall
                                font.weight: Font.Medium
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 7
                        rowSpacing: 4
                        columnSpacing: 4

                        Repeater {
                            model: 42
                            delegate: Item {
                                required property int index
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30

                                readonly property int cell: index - root.firstWeekday + 1
                                readonly property bool inMonth: cell >= 1 && cell <= root.daysInMonth
                                readonly property bool isToday: inMonth
                                    && cell === root.todayDay
                                    && root.viewMonth === root.todayMonth
                                    && root.viewYear === root.todayYear
                                readonly property bool isSelected: inMonth && cell === root.selectedDay
                                readonly property bool isHoliday: inMonth
                                    && ColombianHolidays.isHoliday(root.viewYear, root.viewMonth, cell)

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 28
                                    height: 28
                                    radius: 14
                                    visible: parent.inMonth
                                    color: {
                                        if (parent.isSelected)
                                            return Theme.withAlpha(Theme.primary, 0.55);
                                        if (parent.isHoliday)
                                            return Theme.withAlpha(Theme.tertiary, 0.35);
                                        if (parent.isToday)
                                            return Theme.withAlpha(Theme.accentSecondary, 0.28);
                                        return dayMa.containsMouse
                                            ? Theme.withAlpha(Theme.textPrimary, 0.1)
                                            : "transparent";
                                    }
                                    border.width: parent.isToday && !parent.isSelected ? 1 : 0
                                    border.color: Theme.withAlpha(Theme.accentSecondary, 0.65)

                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.parent.inMonth ? String(parent.parent.cell) : ""
                                        color: parent.parent.isHoliday && !parent.parent.isSelected
                                            ? Theme.tertiary
                                            : Theme.textPrimary
                                        font.family: Settings.fontFamilyDefault
                                        font.pixelSize: Settings.fontSizeSmall
                                        font.weight: parent.parent.isToday || parent.parent.isSelected
                                            ? Font.DemiBold
                                            : Font.Normal
                                    }

                                    MouseArea {
                                        id: dayMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: parent.parent.inMonth
                                        onClicked: root.selectedDay = parent.parent.cell
                                    }
                                }
                            }
                        }
                    }
                }
            }

            SectionCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 90

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: root.selectedHoliday !== ""
                            ? root.selectedHoliday
                            : "Sin festivo"
                        color: root.selectedHoliday !== "" ? Theme.tertiary : Theme.textSecondary
                        font.family: Settings.fontFamilyDefault
                        font.pixelSize: Settings.fontSizeSmall
                        font.weight: root.selectedHoliday !== "" ? Font.DemiBold : Font.Normal
                        wrapMode: Text.WordWrap
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: root.monthHolidays.length > 0

                        Repeater {
                            model: root.monthHolidays
                            delegate: Rectangle {
                                required property var modelData
                                radius: 10
                                height: 22
                                width: holidayLabel.implicitWidth + 14
                                color: Theme.withAlpha(Theme.tertiary, 0.22)
                                border.color: Theme.withAlpha(Theme.tertiary, 0.45)
                                border.width: 1

                                Text {
                                    id: holidayLabel
                                    anchors.centerIn: parent
                                    text: modelData.day + " · " + modelData.name.split(",")[0]
                                    color: Theme.textPrimary
                                    font.family: Settings.fontFamilyDefault
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectedDay = modelData.day
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Hoy"
                        visible: root.viewYear !== root.todayYear
                            || root.viewMonth !== root.todayMonth
                            || root.selectedDay !== root.todayDay
                        color: Theme.accent
                        font.family: Settings.fontFamilyDefault
                        font.pixelSize: Settings.fontSizeSmall
                        font.underline: true

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.goToday()
                        }
                    }
                }
            }
        }
    }

    component SectionCard: Rectangle {
        color: Theme.glass(Math.max(Settings.glassOpacity, 0.62), Settings.glassTintStrength)
        border.color: Theme.glassBorder(Math.max(Settings.glassBorderOpacity, 0.22), Settings.glassTintStrength)
        border.width: Settings.cardBorderWidth
        radius: root.sectionRadius
        antialiasing: true
        clip: true
    }

    component IconButton: Rectangle {
        id: btn
        property string iconName: ""
        property string fallbackIcon: "\ue5c4"
        signal clicked()

        width: 28
        height: 28
        radius: 14
        color: ma.containsMouse ? Theme.withAlpha(Theme.textPrimary, 0.12) : "transparent"

        Text {
            anchors.centerIn: parent
            text: btn.fallbackIcon
            color: Theme.textPrimary
            font.family: Settings.fontFamilyIcons
            font.pixelSize: 16
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
