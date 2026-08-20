/* Top consumers, Activity-Monitor style.  The process model walks /proc on
 * every tick, so it stays disabled until the popup is actually showing it.
 *
 * Rows are always laid out, empty ones included: the model needs two ticks
 * before CPU shares mean anything, and a table that grows from zero to five
 * rows would resize the whole popup underneath the pointer. */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.process as Process
import org.kde.kitemmodels as KItemModels
import "../code/util.js" as Util

ColumnLayout {
    id: table

    property bool active: false
    property int interval: 2000
    property int rowCountLimit: 5
    property int revision: 0
    property string mode: "cpu"

    readonly property int sortColumn: mode === "cpu" ? 1 : 2

    spacing: Kirigami.Units.smallSpacing

    Process.ProcessDataModel {
        id: processes
        enabled: table.active
        flatList: true
        enabledAttributes: ["name", "usage", "memory"]
    }

    KItemModels.KSortFilterProxyModel {
        id: sorted
        sourceModel: processes
        sortColumn: table.sortColumn
        sortOrder: Qt.DescendingOrder
        sortRoleName: "Value"
    }

    Repeater {
        model: table.rowCountLimit

        RowLayout {
            id: row

            required property int index

            readonly property var snapshot: {
                var reactOnRevision = table.revision
                var reactOnMode = table.mode
                if (!table.active || index >= sorted.rowCount())
                    return null
                var usageValue = sorted.data(sorted.index(index, 1), Process.ProcessDataModel.Value)
                var memoryValue = sorted.data(sorted.index(index, 2), Process.ProcessDataModel.Value)
                return {
                    name: String(sorted.data(sorted.index(index, 0), Qt.DisplayRole) || ""),
                    usage: usageValue === undefined || usageValue === null ? 0 : usageValue,
                    /* the memory attribute is reported in KiB */
                    memory: (memoryValue === undefined || memoryValue === null ? 0 : memoryValue) * 1024
                }
            }

            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Text {
                text: row.snapshot ? row.snapshot.name : "—"
                color: Kirigami.Theme.textColor
                opacity: row.snapshot ? 0.85 : 0.25
                font: Kirigami.Theme.smallFont
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: row.snapshot ? Util.percent(row.snapshot.usage) : ""
                color: table.mode === "cpu" ? Util.accent.cpu : Kirigami.Theme.textColor
                opacity: table.mode === "cpu" ? 1 : 0.6
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.weight: table.mode === "cpu" ? Font.DemiBold : Font.Normal
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.6
            }

            Text {
                text: row.snapshot ? Util.bytes(row.snapshot.memory) : ""
                color: table.mode === "memory" ? Util.accent.memory : Kirigami.Theme.textColor
                opacity: table.mode === "memory" ? 1 : 0.6
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.weight: table.mode === "memory" ? Font.DemiBold : Font.Normal
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3.6
            }
        }
    }
}
