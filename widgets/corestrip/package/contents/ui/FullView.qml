/* The popup: an overview strip on top, detail cards below.
 *
 * Repeater models here are static lists (metric keys, discovered GPUs) and the
 * numbers arrive through bindings, so a new reading never rebuilds a delegate
 * — rebuilding is what used to make the rings and plots jump. */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import "../code/util.js" as Util

Item {
    id: full

    property var backend
    property string processMode: "cpu"

    Layout.minimumWidth: Kirigami.Units.gridUnit * 19
    Layout.preferredWidth: Kirigami.Units.gridUnit * 22
    Layout.minimumHeight: Kirigami.Units.gridUnit * 18
    Layout.preferredHeight: Kirigami.Units.gridUnit * 32

    Launcher {
        id: launcher
    }

    Sensors.Sensor {
        id: systemLogo
        sensorId: "os/system/logo"
    }

    readonly property var overviewKeys: {
        var keys = ["cpu"]
        if (backend && backend.hasGpu)
            keys.push("gpu")
        keys.push("memory")
        return keys
    }

    function overviewLabel(key) {
        switch (key) {
        case "cpu": return "CPU"
        case "gpu": return "GPU"
        case "memory": return "Memory"
        }
        return ""
    }

    function overviewColor(key) {
        switch (key) {
        case "cpu": return Util.accent.cpu
        case "gpu": return Util.accent.gpu
        case "memory": return Util.accent.memory
        }
        return Util.accent.cpu
    }

    function overviewRatio(key) {
        if (!backend)
            return 0
        switch (key) {
        case "cpu": return Util.clamp01(backend.cpuUsage.value / 100)
        case "gpu": return Util.clamp01(backend.gpuUsage.value / 100)
        case "memory": return Util.clamp01(backend.memUsedPercent.value / 100)
        }
        return 0
    }

    function overviewCaption(key) {
        if (!backend)
            return ""
        switch (key) {
        case "cpu": return Util.celsius(backend.cpuTemp.value)
        case "gpu": return Util.celsius(backend.gpuTemp.value)
        case "memory": return Util.bytes(backend.memUsed.value)
        }
        return ""
    }

    /* Nothing is instantiated before the backend is handed over, so no
       binding ever evaluates against an undefined sensor object. */
    Loader {
        anchors.fill: parent
        active: full.backend !== null && full.backend !== undefined
        sourceComponent: contentComponent
    }

    Component {
    id: contentComponent

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        // ------------------------------------------------------------ header
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            Layout.topMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                id: distroIcon

                /* ksystemstats reports e.g. "manjarolinux" while the installed
                   icon is often just "manjaro", so walk a few candidates. */
                readonly property var candidates: {
                    var list = []
                    var logo = systemLogo.status === Sensors.Sensor.Ready ? String(systemLogo.value || "") : ""
                    if (logo.length > 0) {
                        list.push(logo)
                        if (logo.length > 5 && logo.lastIndexOf("linux") === logo.length - 5)
                            list.push(logo.substring(0, logo.length - 5))
                    }
                    list.push("computer")
                    return list
                }
                property int candidateIndex: 0

                source: candidates[Math.min(candidateIndex, candidates.length - 1)]
                implicitWidth: Kirigami.Units.iconSizes.medium
                implicitHeight: Kirigami.Units.iconSizes.medium

                onStatusChanged: {
                    if (status === Kirigami.Icon.Error && candidateIndex < candidates.length - 1)
                        candidateIndex++
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Kirigami.Heading {
                    text: full.backend.hostname.value || "This system"
                    level: 4
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: {
                        var parts = []
                        if (full.backend.osName.value)
                            parts.push(String(full.backend.osName.value))
                        if (full.backend.uptime.value)
                            parts.push("up " + Util.uptime(full.backend.uptime.value))
                        return parts.join("  ·  ")
                    }
                    color: Kirigami.Theme.textColor
                    opacity: 0.55
                    font: Kirigami.Theme.smallFont
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            PlasmaComponents.ToolButton {
                id: monitorButton
                icon.name: "utilities-system-monitor"
                display: PlasmaComponents.AbstractButton.IconOnly
                text: "Open System Monitor"
                onClicked: launcher.run("plasma-systemmonitor")

                PlasmaComponents.ToolTip {
                    text: monitorButton.text
                }
            }
        }

        // ---------------------------------------------------------- overview
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.largeSpacing

            Repeater {
                model: full.overviewKeys

                ColumnLayout {
                    id: overviewItem

                    required property string modelData

                    readonly property real ratio: full.overviewRatio(modelData)

                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Ring {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                        value: overviewItem.ratio
                        ringColor: Util.loadColor(full.overviewColor(overviewItem.modelData), overviewItem.ratio)
                        thickness: Kirigami.Units.gridUnit * 0.42

                        Row {
                            anchors.centerIn: parent
                            spacing: 1

                            Text {
                                id: overviewValue
                                text: Math.round(overviewItem.ratio * 100)
                                color: Kirigami.Theme.textColor
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.45
                                font.weight: Font.Light
                            }

                            Text {
                                anchors.baseline: overviewValue.baseline
                                text: "%"
                                color: Kirigami.Theme.textColor
                                opacity: 0.45
                                font.pointSize: Math.max(6, Kirigami.Theme.smallFont.pointSize - 1)
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: full.overviewLabel(overviewItem.modelData)
                        color: Kirigami.Theme.textColor
                        opacity: 0.75
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.8
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        /* kept in the layout even when empty so the strip
                           never changes height */
                        text: full.overviewCaption(overviewItem.modelData)
                        color: Kirigami.Theme.textColor
                        opacity: text === "--" ? 0 : 0.45
                        font: Kirigami.Theme.smallFont
                    }
                }
            }
        }

        // ------------------------------------------------------------- cards
        PlasmaComponents.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width
                spacing: Kirigami.Units.smallSpacing * 2

                // ---- CPU
                Card {
                    title: "Processor"
                    accentColor: Util.accent.cpu
                    headline: full.backend.coreCount === 1 ? "1 thread"
                                                           : full.backend.coreCount + " threads"

                    Sparkline {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.6
                        cornerRadius: Kirigami.Units.cornerRadius
                        values: full.backend.cpuHistory
                        revision: full.backend.historyTick
                        capacity: full.backend.historyLength
                        maximum: 100
                        lineColor: Util.accent.cpu
                    }

                    CoreGrid {
                        Layout.fillWidth: true
                        visible: Plasmoid.configuration.popupCores && full.backend.coreCount > 0
                        backend: full.backend
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Kirigami.Units.largeSpacing
                        rowSpacing: Kirigami.Units.smallSpacing

                        StatLine {
                            label: "Load"
                            value: Util.percent(full.backend.cpuUsage.value)
                            valueSample: "100%"
                            emphasized: true
                            valueColor: Util.loadColor(Util.accent.cpu,
                                                       full.backend.cpuUsage.value / 100)
                        }
                        StatLine {
                            label: "Clock"
                            value: Util.hertz(full.backend.cpuClock)
                            valueSample: "9.99 GHz"
                        }
                        StatLine {
                            label: "User"
                            value: Util.percent(full.backend.cpuUser.value)
                            valueSample: "100%"
                        }
                        StatLine {
                            label: "System"
                            value: Util.percent(full.backend.cpuSystem.value)
                            valueSample: "100%"
                        }
                        StatLine {
                            label: "Temperature"
                            value: Util.celsius(full.backend.cpuTemp.value)
                            valueSample: "100°"
                            valueColor: full.backend.cpuTemp.value > 85
                                        ? Util.accent.thermal : Kirigami.Theme.textColor
                        }
                    }
                }

                // ---- GPUs
                Repeater {
                    model: Plasmoid.configuration.popupGpu ? full.backend.gpus : []

                    GpuCard {
                        required property var modelData

                        gpuId: modelData.id
                        fallbackName: modelData.label
                        interval: full.backend.interval
                        active: full.backend.detailed
                    }
                }

                // ---- Memory
                Card {
                    title: "Memory"
                    accentColor: Util.accent.memory
                    visible: Plasmoid.configuration.popupMemory
                    headline: Util.bytes(full.backend.memUsed.value) + " / "
                              + Util.bytes(full.backend.memTotal.value)

                    MeterBar {
                        Layout.fillWidth: true
                        segments: {
                            var total = Math.max(1, full.backend.memTotal.value)
                            return [
                                { value: full.backend.memApplication.value / total, color: Util.accent.memory },
                                { value: full.backend.memBuffer.value / total, color: Util.alpha(Util.accent.memory, 0.55) },
                                { value: full.backend.memCache.value / total, color: Util.alpha(Util.accent.memory, 0.28) }
                            ]
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Kirigami.Units.largeSpacing
                        rowSpacing: Kirigami.Units.smallSpacing

                        StatLine {
                            label: "Applications"
                            value: Util.bytes(full.backend.memApplication.value)
                            valueSample: "999.9 GiB"
                            emphasized: true
                        }
                        StatLine {
                            label: "Cache"
                            value: Util.bytes(full.backend.memCache.value + full.backend.memBuffer.value)
                            valueSample: "999.9 GiB"
                        }
                        StatLine {
                            label: "Swap"
                            value: full.backend.swapTotal.value > 0
                                   ? Util.bytes(full.backend.swapUsed.value) + " / "
                                     + Util.bytes(full.backend.swapTotal.value)
                                   : "off"
                            valueSample: "999 GiB / 999 GiB"
                        }
                        StatLine {
                            label: "In use"
                            value: Util.percent(full.backend.memUsedPercent.value)
                            valueSample: "100%"
                        }
                    }
                }

                // ---- Network
                Card {
                    title: "Network"
                    accentColor: Util.accent.network
                    visible: Plasmoid.configuration.popupNetwork
                    headline: Util.rate(full.backend.netDown.value + full.backend.netUp.value)

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.8

                        Sparkline {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: parent.height / 2 - 1
                            values: full.backend.netDownHistory
                            revision: full.backend.historyTick
                            capacity: full.backend.historyLength
                            maximum: full.backend.netPeak
                            lineColor: Util.accent.network
                        }

                        Sparkline {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: parent.height / 2 - 1
                            values: full.backend.netUpHistory
                            revision: full.backend.historyTick
                            capacity: full.backend.historyLength
                            maximum: full.backend.netPeak
                            lineColor: Util.accent.disk
                            mirrored: true
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Kirigami.Units.largeSpacing
                        rowSpacing: Kirigami.Units.smallSpacing

                        StatLine {
                            label: "Download"
                            value: Util.rate(full.backend.netDown.value)
                            valueSample: "999.9 MiB/s"
                            valueColor: Util.accent.network
                            emphasized: true
                        }
                        StatLine {
                            label: "Upload"
                            value: Util.rate(full.backend.netUp.value)
                            valueSample: "999.9 MiB/s"
                            valueColor: Util.accent.disk
                            emphasized: true
                        }
                        StatLine {
                            label: "Received"
                            value: Util.bytes(full.backend.netTotalDown.value)
                            valueSample: "999.9 GiB"
                        }
                        StatLine {
                            label: "Sent"
                            value: Util.bytes(full.backend.netTotalUp.value)
                            valueSample: "999.9 GiB"
                        }
                    }
                }

                // ---- Disk
                Card {
                    title: "Storage"
                    accentColor: Util.accent.disk
                    visible: Plasmoid.configuration.popupDisk
                    headline: Util.percent(full.backend.diskUsedPercent.value)

                    MeterBar {
                        Layout.fillWidth: true
                        value: Util.clamp01(full.backend.diskUsedPercent.value / 100)
                        barColor: Util.loadColor(Util.accent.disk,
                                                 full.backend.diskUsedPercent.value / 100)
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Kirigami.Units.largeSpacing
                        rowSpacing: Kirigami.Units.smallSpacing

                        StatLine {
                            label: "Used"
                            value: Util.bytes(full.backend.diskUsed.value) + " / "
                                   + Util.bytes(full.backend.diskTotal.value)
                            valueSample: "999 GiB / 999 GiB"
                            emphasized: true
                        }
                        StatLine {
                            label: "Free"
                            value: Util.bytes(full.backend.diskTotal.value - full.backend.diskUsed.value)
                            valueSample: "999.9 GiB"
                        }
                        StatLine {
                            label: "Read"
                            value: Util.rate(full.backend.diskRead.value)
                            valueSample: "999.9 MiB/s"
                        }
                        StatLine {
                            label: "Write"
                            value: Util.rate(full.backend.diskWrite.value)
                            valueSample: "999.9 MiB/s"
                        }
                    }
                }

                // ---- Battery
                Card {
                    title: "Battery"
                    accentColor: Util.accent.battery
                    visible: Plasmoid.configuration.popupBattery && full.backend.hasBattery
                    headline: Util.percent(full.backend.batteryCharge.value)

                    MeterBar {
                        Layout.fillWidth: true
                        value: Util.clamp01(full.backend.batteryCharge.value / 100)
                        barColor: full.backend.batteryCharge.value < 20
                                  ? Util.accent.thermal : Util.accent.battery
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Kirigami.Units.largeSpacing
                        rowSpacing: Kirigami.Units.smallSpacing

                        StatLine {
                            label: full.backend.batteryRate.value >= 0 ? "Charging" : "Discharging"
                            value: Util.watts(Math.abs(full.backend.batteryRate.value))
                            valueSample: "999.9 W"
                            emphasized: true
                        }
                        StatLine {
                            label: "Health"
                            value: Util.percent(full.backend.batteryHealth.value)
                            valueSample: "100%"
                        }
                    }
                }

                // ---- Processes
                Card {
                    title: "Top processes"
                    accentColor: Util.accent.thermal
                    visible: Plasmoid.configuration.popupProcesses

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Item { Layout.fillWidth: true }

                        Repeater {
                            model: [
                                { key: "cpu", label: "by CPU" },
                                { key: "memory", label: "by memory" }
                            ]

                            Rectangle {
                                id: modeChip

                                required property var modelData

                                readonly property bool selected: full.processMode === modelData.key

                                implicitWidth: modeLabel.implicitWidth + Kirigami.Units.largeSpacing
                                implicitHeight: modeLabel.implicitHeight + Kirigami.Units.smallSpacing
                                radius: height / 2
                                color: selected
                                       ? Util.alpha(Kirigami.Theme.highlightColor, 0.22)
                                       : Util.alpha(Kirigami.Theme.textColor, 0.06)

                                Text {
                                    id: modeLabel
                                    anchors.centerIn: parent
                                    text: modeChip.modelData.label
                                    color: Kirigami.Theme.textColor
                                    opacity: modeChip.selected ? 0.95 : 0.55
                                    font: Kirigami.Theme.smallFont
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: full.processMode = modeChip.modelData.key
                                }
                            }
                        }
                    }

                    ProcessTable {
                        Layout.fillWidth: true
                        active: full.backend.detailed && Plasmoid.configuration.popupProcesses
                        interval: full.backend.interval
                        revision: full.backend.historyTick
                        mode: full.processMode
                    }
                }
            }
        }
    }
    }
}
