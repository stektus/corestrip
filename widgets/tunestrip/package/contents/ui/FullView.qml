/* The popup: the cover, what it is, where it is, and the controls — plus the
   list of players when more than one is running. */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../code/util.js" as Util

Item {
    id: full

    property var backend

    readonly property bool hasTrack: backend !== null && backend !== undefined && backend.active
    readonly property color accentColor: {
        switch (Plasmoid.configuration.visualizerColor) {
        case "accent": return Kirigami.Theme.highlightColor
        case "theme": return Kirigami.Theme.textColor
        default: return Util.lively(cover.highlightColor, Kirigami.Theme.highlightColor)
        }
    }

    Layout.minimumWidth: Kirigami.Units.gridUnit * 18
    Layout.preferredWidth: Kirigami.Units.gridUnit * 22
    Layout.minimumHeight: Kirigami.Units.gridUnit * 12
    Layout.preferredHeight: column.implicitHeight

    ColumnLayout {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.largeSpacing

        // ------------------------------------------------------------ head
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                implicitWidth: Kirigami.Units.iconSizes.small
                implicitHeight: Kirigami.Units.iconSizes.small
                source: full.backend ? full.backend.playerIcon : "media-playback-start"
                opacity: 0.8
                visible: full.backend && full.backend.hasPlayer
            }

            Text {
                text: full.backend && full.backend.identity.length > 0
                      ? full.backend.identity : "No player"
                color: Kirigami.Theme.textColor
                opacity: 0.6
                font: Kirigami.Theme.smallFont
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PlasmaComponents.ToolButton {
                icon.name: "window"
                display: PlasmaComponents.AbstractButton.IconOnly
                text: "Bring the player forward"
                visible: full.backend && full.backend.canRaise
                onClicked: full.backend.raisePlayer()
            }
        }

        // ------------------------------------------------------------ cover
        AlbumArt {
            id: cover

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(column.width, Kirigami.Units.gridUnit * 13)
            Layout.preferredHeight: Layout.preferredWidth
            visible: Plasmoid.configuration.popupArt
            shadowed: true
            cornerRadius: Kirigami.Units.cornerRadius * 2
            source: full.backend ? full.backend.artUrl : ""
        }

        Visualizer {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
            visible: Plasmoid.configuration.popupVisualizer
            style: Plasmoid.configuration.visualizerStyle
            /* The popup has room for a denser reading than the panel. */
            bars: Math.max(Plasmoid.configuration.visualizerBars,
                           Plasmoid.configuration.visualizerStyle === "pulse" ? 3 : 24)
            speed: Plasmoid.configuration.visualizerSpeed
            color: full.accentColor
            active: full.backend && (full.backend.playing
                                     || (Plasmoid.configuration.visualizerWhenPaused && full.hasTrack))
            seed: full.backend ? Util.seedOf(full.backend.track + full.backend.artist) : 0
            opacity: full.hasTrack ? 1 : 0.4
        }

        // ------------------------------------------------------------ title
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: full.backend && full.backend.track.length > 0
                      ? full.backend.track : "Nothing is playing"
                color: Kirigami.Theme.textColor
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.25
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Text {
                text: full.backend ? full.backend.artist : ""
                visible: text.length > 0
                color: Kirigami.Theme.textColor
                opacity: 0.75
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Text {
                text: full.backend ? full.backend.album : ""
                visible: text.length > 0
                color: Kirigami.Theme.textColor
                opacity: 0.5
                font: Kirigami.Theme.smallFont
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Text {
                text: "Start something in a player or a browser tab and it shows up here."
                visible: !full.hasTrack
                color: Kirigami.Theme.textColor
                opacity: 0.5
                font: Kirigami.Theme.smallFont
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
            }
        }

        // ------------------------------------------------------------- seek
        SeekBar {
            Layout.fillWidth: true
            visible: Plasmoid.configuration.popupSeek && full.hasTrack
            backend: full.backend
            accentColor: full.accentColor
        }

        // --------------------------------------------------------- controls
        TransportControls {
            Layout.fillWidth: true
            visible: full.hasTrack
            backend: full.backend
            accentColor: full.accentColor
        }

        // ----------------------------------------------------------- volume
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            visible: Plasmoid.configuration.popupVolume && full.hasTrack

            Kirigami.Icon {
                implicitWidth: Kirigami.Units.iconSizes.small
                implicitHeight: Kirigami.Units.iconSizes.small
                source: full.backend && full.backend.volume < 0.01
                        ? "audio-volume-muted" : "audio-volume-high"
                opacity: 0.7
            }

            PlasmaComponents.Slider {
                id: volumeSlider
                Layout.fillWidth: true
                from: 0
                to: 1
                onMoved: if (full.backend) full.backend.setVolume(value)
            }

            Binding {
                target: volumeSlider
                property: "value"
                value: full.backend ? full.backend.volume : 0
                when: !volumeSlider.pressed
                restoreMode: Binding.RestoreBindingOrValue
            }
        }

        // ---------------------------------------------------------- players
        Card {
            title: "Players"
            accentColor: Util.accent.glow
            visible: Plasmoid.configuration.popupPlayers && players.count > 2

            PlayerList {
                id: players
                Layout.fillWidth: true
                backend: full.backend
            }
        }

        Item { Layout.preferredHeight: Kirigami.Units.smallSpacing }
    }
}
