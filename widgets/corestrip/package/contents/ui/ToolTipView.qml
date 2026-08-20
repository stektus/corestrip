/* Hover summary: everything the panel cannot fit, without opening the popup.
 * The repeater model is a static key list so new readings update bindings
 * instead of rebuilding rows. */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../code/util.js" as Util

Item {
    id: tip

    property var backend

    readonly property var rowKeys: {
        var keys = ["cpu"]
        if (backend && backend.hasGpu)
            keys.push("gpu")
        keys.push("memory")
        return keys
    }

    function rowLabel(key) {
        if (!backend)
            return ""
        switch (key) {
        case "cpu": return "Processor"
        case "gpu": return Util.shortGpuName(backend.gpuName.value)
        case "memory": return "Memory"
        }
        return ""
    }

    function rowColor(key) {
        switch (key) {
        case "cpu": return Util.accent.cpu
        case "gpu": return Util.accent.gpu
        case "memory": return Util.accent.memory
        }
        return Util.accent.cpu
    }

    function rowRatio(key) {
        if (!backend)
            return 0
        switch (key) {
        case "cpu": return Util.clamp01(backend.cpuUsage.value / 100)
        case "gpu": return Util.clamp01(backend.gpuUsage.value / 100)
        case "memory": return Util.clamp01(backend.memUsedPercent.value / 100)
        }
        return 0
    }

    function rowNote(key) {
        if (!backend)
            return ""
        switch (key) {
        case "cpu": return Util.celsius(backend.cpuTemp.value)
        case "gpu": return Util.celsius(backend.gpuTemp.value)
        case "memory": return Util.bytes(backend.memUsed.value)
        }
        return ""
    }

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        /* Width comes from the tooltip, height from the content: anchoring all
           four sides while the item sizes itself from this layout would loop. */
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading {
                text: tip.backend && tip.backend.hostname.value
                      ? tip.backend.hostname.value : "System load"
                level: 5
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: tip.backend ? "up " + Util.uptime(tip.backend.uptime.value) : ""
                color: Kirigami.Theme.textColor
                opacity: 0.5
                font: Kirigami.Theme.smallFont
            }
        }

        Repeater {
            model: tip.rowKeys

            GridLayout {
                id: tipRow

                required property string modelData

                readonly property real ratio: tip.rowRatio(modelData)

                Layout.fillWidth: true
                columns: 3
                columnSpacing: Kirigami.Units.smallSpacing
                rowSpacing: Math.round(Kirigami.Units.smallSpacing / 2)

                Text {
                    text: tip.rowLabel(tipRow.modelData)
                    color: Kirigami.Theme.textColor
                    opacity: 0.7
                    font: Kirigami.Theme.smallFont
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                }

                Text {
                    text: tip.rowNote(tipRow.modelData)
                    opacity: text === "--" ? 0 : 0.45
                    color: Kirigami.Theme.textColor
                    font: Kirigami.Theme.smallFont
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    text: Util.percent(tipRow.ratio * 100)
                    color: Util.loadColor(tip.rowColor(tipRow.modelData), tipRow.ratio)
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                }

                MeterBar {
                    Layout.columnSpan: 3
                    Layout.fillWidth: true
                    Layout.bottomMargin: Kirigami.Units.smallSpacing
                    value: tipRow.ratio
                    barColor: Util.loadColor(tip.rowColor(tipRow.modelData), tipRow.ratio)
                }
            }
        }

        Text {
            text: tip.backend
                  ? "Network   ▾ " + Util.rate(tip.backend.netDown.value)
                    + "   ▴ " + Util.rate(tip.backend.netUp.value)
                  : ""
            color: Util.accent.network
            font: Kirigami.Theme.smallFont
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            visible: tip.backend !== undefined && tip.backend !== null && tip.backend.panelDisk
            text: tip.backend
                  ? "Disk   ▾ " + Util.rate(tip.backend.diskRead.value)
                    + "   ▴ " + Util.rate(tip.backend.diskWrite.value)
                  : ""
            color: Util.accent.disk
            font: Kirigami.Theme.smallFont
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            text: "Click for details"
            color: Kirigami.Theme.textColor
            opacity: 0.4
            font: Kirigami.Theme.smallFont
            Layout.topMargin: Kirigami.Units.smallSpacing
        }
    }
}
