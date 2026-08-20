/*
 * Tunestrip — what is playing, in the panel: album art, an animated equalizer,
 * the title and transport buttons, with the full controls one click away.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property Backend backend: Backend {
        detailed: root.expanded
        tracksPosition: Plasmoid.configuration.progressLine
    }

    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar
                             ? fullRepresentation : compactRepresentation

    /* In the system tray this is what hides the widget while the music is off;
       in a panel the compact view collapses itself. */
    Plasmoid.status: backend.active
                     ? PlasmaCore.Types.ActiveStatus
                     : (Plasmoid.configuration.hideWhenIdle
                        ? PlasmaCore.Types.HiddenStatus : PlasmaCore.Types.PassiveStatus)

    compactRepresentation: CompactView {
        backend: root.backend
        onToggleRequested: root.expanded = !root.expanded
    }

    fullRepresentation: FullView {
        backend: root.backend
    }

    toolTipItem: ToolTipView {
        backend: root.backend
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        Layout.maximumWidth: Kirigami.Units.gridUnit * 22
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: root.backend.playing ? "Pause" : "Play"
            icon.name: root.backend.playing ? "media-playback-pause" : "media-playback-start"
            enabled: root.backend.canControl
            onTriggered: root.backend.playPause()
        },
        PlasmaCore.Action {
            text: "Previous track"
            icon.name: "media-skip-backward"
            enabled: root.backend.canGoPrevious
            onTriggered: root.backend.previous()
        },
        PlasmaCore.Action {
            text: "Next track"
            icon.name: "media-skip-forward"
            enabled: root.backend.canGoNext
            onTriggered: root.backend.next()
        },
        PlasmaCore.Action {
            text: "Bring the player forward"
            icon.name: "window"
            enabled: root.backend.canRaise
            onTriggered: root.backend.raisePlayer()
        }
    ]
}
