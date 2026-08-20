/* One column per logical CPU, height = its current load. */
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import "../code/util.js" as Util

Item {
    id: grid

    property var backend
    property color coreColor: Util.accent.cpu
    readonly property real barSpacing: Math.max(1, Math.round(width / Math.max(1, backend.coreCount) * 0.18))

    implicitHeight: Kirigami.Units.gridUnit * 1.6

    Row {
        anchors.fill: parent
        spacing: grid.barSpacing

        Repeater {
            model: grid.backend.coreCount

            Item {
                width: (grid.width - (grid.backend.coreCount - 1) * grid.barSpacing) / Math.max(1, grid.backend.coreCount)
                height: grid.height

                readonly property real load: {
                    var reactOnTick = grid.backend.historyTick
                    var reactOnReady = grid.backend.coresModel.ready
                    if (index >= grid.backend.coresModel.columnCount())
                        return 0
                    var v = grid.backend.coresModel.data(grid.backend.coresModel.index(0, index),
                                                         Sensors.SensorDataModel.Value)
                    return Util.clamp01((v === undefined || v === null || isNaN(v)) ? 0 : v / 100)
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height
                    radius: Math.min(width, 2)
                    color: Qt.rgba(grid.coreColor.r, grid.coreColor.g, grid.coreColor.b, 0.08)
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(parent.load > 0 ? 1 : 0, parent.height * parent.load)
                    radius: Math.min(width, 2)
                    color: Util.loadColor(grid.coreColor, parent.load)

                    Behavior on height {
                        NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}
