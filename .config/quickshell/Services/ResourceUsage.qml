pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, and CPU usage.
 */
QtObject {
  id: statusService
  property double memoryTotal: 1
  property double memoryFree: 1
  property double memoryUsed: memoryTotal - memoryFree
  property double memoryUsedPercentage: memoryUsed / memoryTotal
  property double swapTotal: 1
  property double swapFree: 1
  property double swapUsed: swapTotal - swapFree
  property double swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
  property double cpuUsage: 0
  property var previousCpuStats

  property QtObject timer: Timer {
    interval: 1000
    running: true 
    repeat: true
    onTriggered: {
      // Reload files
      fileMeminfo.reload()
      fileStat.reload()

      // Parse memory and swap usage
      const textMeminfo = fileMeminfo.text()
      statusService.memoryTotal = Number(textMeminfo.match(/MemTotal:\s*(\d+)/)?.[1] ?? 1)
      statusService.memoryFree = Number(textMeminfo.match(/MemAvailable:\s*(\d+)/)?.[1] ?? 0)
      statusService.swapTotal = Number(textMeminfo.match(/SwapTotal:\s*(\d+)/)?.[1] ?? 1)
      statusService.swapFree = Number(textMeminfo.match(/SwapFree:\s*(\d+)/)?.[1] ?? 0)

      // Parse CPU usage
      const textStat = fileStat.text()
      const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
      if (cpuLine) {
          const stats = cpuLine.slice(1).map(Number)
          const total = stats.reduce((a, b) => a + b, 0)
          const idle = stats[3]

          if (statusService.previousCpuStats) {
              const totalDiff = total - statusService.previousCpuStats.total
              const idleDiff = idle - statusService.previousCpuStats.idle
              statusService.cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
          }

          statusService.previousCpuStats = { total, idle }
      }
    }
  }

  property QtObject fileMeminfo: FileView { 
    id: fileMeminfo
    path: "/proc/meminfo" 
  }
  
  property QtObject fileStat: FileView { 
    id: fileStat
    path: "/proc/stat" 
  }
}
