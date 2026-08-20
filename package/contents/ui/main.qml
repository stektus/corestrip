/*
 * Corestrip — panel gauges for CPU, GPU, memory and network, with a detail popup.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property Backend backend: Backend {
        id: sensorBackend
        interval: Math.max(500, Plasmoid.configuration.updateInterval)
        detailed: root.expanded
        panelDisk: Plasmoid.configuration.showDisk
        panelGpuId: {
            var configured = Plasmoid.configuration.panelGpu
            if (configured && configured !== "auto")
                return configured
            return sensorBackend.gpus.length > 0 ? sensorBackend.gpus[0].id : ""
        }
    }

    readonly property Launcher launcher: Launcher {}

    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar
                             ? fullRepresentation : compactRepresentation

    compactRepresentation: CompactView {
        backend: root.backend
        onToggleRequested: root.expanded = !root.expanded
    }

    fullRepresentation: FullView {
        backend: root.backend
    }

    toolTipItem: ToolTipView {
        backend: root.backend
        Layout.minimumWidth: Kirigami.Units.gridUnit * 15
        Layout.preferredWidth: Kirigami.Units.gridUnit * 15
        Layout.maximumWidth: Kirigami.Units.gridUnit * 18
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Open System Monitor"
            icon.name: "utilities-system-monitor"
            onTriggered: root.launcher.run("plasma-systemmonitor")
        }
    ]
}
