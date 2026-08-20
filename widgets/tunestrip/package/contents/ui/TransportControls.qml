/*
 * Shuffle, previous, play/pause, next, repeat — the play button carries the
 * accent so the eye lands on it first.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

RowLayout {
    id: controls

    property var backend
    property color accentColor: Kirigami.Theme.highlightColor
    property real playSize: Kirigami.Units.gridUnit * 2.6

    spacing: Kirigami.Units.smallSpacing

    Item { Layout.fillWidth: true }

    PlasmaComponents.ToolButton {
        icon.name: "media-playlist-shuffle"
        display: PlasmaComponents.AbstractButton.IconOnly
        text: controls.backend && controls.backend.shuffled ? "Shuffle: on" : "Shuffle: off"
        checkable: true
        checked: controls.backend ? controls.backend.shuffled : false
        enabled: controls.backend && controls.backend.canControl
        onClicked: controls.backend.toggleShuffle()
    }

    PlasmaComponents.ToolButton {
        icon.name: "media-skip-backward"
        display: PlasmaComponents.AbstractButton.IconOnly
        text: "Previous"
        enabled: controls.backend && controls.backend.canGoPrevious
        onClicked: controls.backend.previous()
    }

    /* The one button that is not a tool button: it is the thing you reach
       for, so it gets a filled circle. */
    Item {
        implicitWidth: controls.playSize
        implicitHeight: controls.playSize
        Layout.alignment: Qt.AlignVCenter

        Kirigami.ShadowedRectangle {
            anchors.fill: parent
            radius: width / 2
            color: playMouse.containsMouse ? Qt.lighter(controls.accentColor, 1.12) : controls.accentColor
            opacity: controls.backend && controls.backend.canControl ? 1 : 0.4
            shadow.size: Kirigami.Units.smallSpacing * 2
            shadow.yOffset: 1
            shadow.color: Qt.rgba(0, 0, 0, 0.25)

            Behavior on color { ColorAnimation { duration: 100 } }
        }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.round(controls.playSize * 0.5)
            height: width
            source: controls.backend && controls.backend.playing
                    ? "media-playback-pause" : "media-playback-start"
            color: "white"
            isMask: true
        }

        MouseArea {
            id: playMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: controls.backend && controls.backend.canControl
            onClicked: controls.backend.playPause()
        }
    }

    PlasmaComponents.ToolButton {
        icon.name: "media-skip-forward"
        display: PlasmaComponents.AbstractButton.IconOnly
        text: "Next"
        enabled: controls.backend && controls.backend.canGoNext
        onClicked: controls.backend.next()
    }

    PlasmaComponents.ToolButton {
        icon.name: controls.backend ? controls.backend.loopIcon : "media-playlist-repeat"
        display: PlasmaComponents.AbstractButton.IconOnly
        text: controls.backend ? controls.backend.loopLabel : "Repeat"
        checkable: true
        checked: controls.backend ? controls.backend.loop > 1 : false
        enabled: controls.backend && controls.backend.canControl
        onClicked: controls.backend.cycleLoop()
    }

    Item { Layout.fillWidth: true }
}
