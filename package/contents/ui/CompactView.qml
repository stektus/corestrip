/* What lives in the panel: a small, deliberately sparse row of gauges.
 *
 * The repeater model is the list of *enabled metric keys*, which only changes
 * when the configuration does. Values are pulled per property through the
 * lookup functions below, so a new reading re-evaluates a binding instead of
 * rebuilding every delegate — otherwise the plots would be thrown away and
 * recreated on every tick. */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "../code/util.js" as Util

MouseArea {
    id: compact

    property var backend
    signal toggleRequested()

    property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property string style: Plasmoid.configuration.compactStyle
    property bool showLabels: Plasmoid.configuration.showLabels
    property bool showTemperature: Plasmoid.configuration.showTemperature
    readonly property real padding: Math.round(Kirigami.Units.smallSpacing / 2)
    readonly property real gaugeSize: Math.max(Kirigami.Units.gridUnit * 0.7,
        Math.min(Kirigami.Units.gridUnit * 2.6,
                 (vertical ? width : height) - padding * 2))

    readonly property var metricKeys: {
        var keys = []
        if (!backend)
            return keys
        var config = Plasmoid.configuration
        if (config.showCpu)
            keys.push("cpu")
        if (config.showGpu && backend.hasGpu)
            keys.push("gpu")
        if (config.showMemory)
            keys.push("memory")
        if (config.showNetwork)
            keys.push("network")
        if (config.showDisk)
            keys.push("disk")
        return keys
    }

    function metricKind(key) {
        return (key === "network" || key === "disk") ? "rate" : "percent"
    }

    function metricLabel(key) {
        switch (key) {
        case "cpu": return "CPU"
        case "gpu": return "GPU"
        case "memory": return "RAM"
        case "network": return "NET"
        case "disk": return "DISK"
        }
        return ""
    }

    function metricColor(key) {
        switch (key) {
        case "cpu": return Util.accent.cpu
        case "gpu": return Util.accent.gpu
        case "memory": return Util.accent.memory
        case "network": return Util.accent.network
        case "disk": return Util.accent.disk
        }
        return Util.accent.cpu
    }

    function metricRatio(key) {
        if (!backend)
            return 0
        switch (key) {
        case "cpu": return Util.clamp01(backend.cpuUsage.value / 100)
        case "gpu": return Util.clamp01(backend.gpuUsage.value / 100)
        case "memory": return Util.clamp01(backend.memUsedPercent.value / 100)
        }
        return 0
    }

    function metricText(key) {
        return Util.percent(metricRatio(key) * 100)
    }

    function metricCaption(key) {
        if (!backend)
            return ""
        switch (key) {
        case "cpu": return showTemperature ? Util.celsius(backend.cpuTemp.value) : ""
        case "gpu": return showTemperature ? Util.celsius(backend.gpuTemp.value) : ""
        case "memory": return Util.bytes(backend.memUsed.value)
        }
        return ""
    }

    function metricHistory(key) {
        if (!backend)
            return []
        switch (key) {
        case "cpu": return backend.cpuHistory
        case "gpu": return backend.gpuHistory
        case "memory": return backend.memHistory
        }
        return []
    }

    function metricDown(key) {
        if (!backend)
            return 0
        return (key === "network" ? backend.netDown.value : backend.diskRead.value) || 0
    }

    function metricUp(key) {
        if (!backend)
            return 0
        return (key === "network" ? backend.netUp.value : backend.diskWrite.value) || 0
    }

    function metricDownHistory(key) {
        if (!backend)
            return []
        return key === "network" ? backend.netDownHistory : backend.diskReadHistory
    }

    function metricUpHistory(key) {
        if (!backend)
            return []
        return key === "network" ? backend.netUpHistory : backend.diskWriteHistory
    }

    function metricMaximum(key) {
        if (!backend)
            return 1
        return key === "network" ? backend.netPeak : backend.diskPeak
    }

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onClicked: compact.toggleRequested()

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Layout.minimumWidth: vertical ? Kirigami.Units.gridUnit : content.implicitWidth
    Layout.maximumWidth: vertical ? Number.POSITIVE_INFINITY : content.implicitWidth
    Layout.preferredWidth: vertical ? Kirigami.Units.gridUnit * 2 : content.implicitWidth
    Layout.minimumHeight: vertical ? content.implicitHeight : Kirigami.Units.gridUnit
    Layout.maximumHeight: vertical ? content.implicitHeight : Number.POSITIVE_INFINITY
    Layout.preferredHeight: vertical ? content.implicitHeight : Kirigami.Units.gridUnit * 2

    GridLayout {
        id: content

        anchors.centerIn: parent
        rows: compact.vertical ? compact.metricKeys.length : 1
        columns: compact.vertical ? 1 : compact.metricKeys.length
        rowSpacing: Kirigami.Units.smallSpacing
        columnSpacing: Kirigami.Units.smallSpacing * 1.5

        Repeater {
            model: compact.metricKeys

            CompactMetric {
                required property string modelData

                style: compact.style
                kind: compact.metricKind(modelData)
                label: compact.metricLabel(modelData)
                caption: compact.metricCaption(modelData)
                captionInline: modelData === "cpu" || modelData === "gpu"
                metricColor: compact.metricColor(modelData)
                showLabel: compact.showLabels
                vertical: compact.vertical
                gaugeSize: compact.gaugeSize
                revision: compact.backend ? compact.backend.historyTick : 0

                ratio: compact.metricRatio(modelData)
                valueText: compact.metricText(modelData)
                history: compact.metricHistory(modelData)

                downValue: compact.metricDown(modelData)
                upValue: compact.metricUp(modelData)
                downHistory: compact.metricDownHistory(modelData)
                upHistory: compact.metricUpHistory(modelData)
                rateMaximum: compact.metricMaximum(modelData)

                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: compact.gaugeSize
            }
        }
    }
}
