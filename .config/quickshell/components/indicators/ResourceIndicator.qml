import QtQuick
import Quickshell.Widgets
import qs.core
import qs.config

/**
 * ResourceIndicator - CPU and memory ring gauges for the bar.
 * Hover a gauge to see its percentage.
 */
WrapperItem {
    id: root

    Row {
        spacing: 6
        anchors.centerIn: parent

        RingGauge {
            icon: "memory"
            value: ResourceUsage.cpuUsage
        }

        RingGauge {
            icon: "memory_alt"
            value: ResourceUsage.memoryUsedPercentage
        }
    }
}
