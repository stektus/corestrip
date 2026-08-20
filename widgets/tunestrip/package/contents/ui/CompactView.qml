/* What lives in the panel: album art, the equalizer, the title block and the
   transport buttons — each optional, in whatever order the settings ask for.

   The repeater model is the ordered list of enabled keys, so it changes only
   when the configuration does: a ticking position or a new track updates
   bindings instead of rebuilding items. */
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

    property bool showArt: Plasmoid.configuration.showArt
    property bool showVisualizer: Plasmoid.configuration.showVisualizer
    property bool showText: Plasmoid.configuration.showText
    property bool showControls: Plasmoid.configuration.showControls
    property string panelOrder: Plasmoid.configuration.panelOrder
    property int fontScale: Plasmoid.configuration.fontScale
    property int textWidthUnits: Plasmoid.configuration.textWidthUnits
    property bool showArtistLine: Plasmoid.configuration.showArtistLine
    property bool scrollText: Plasmoid.configuration.scrollText
    property bool progressLine: Plasmoid.configuration.progressLine
    property bool hideWhenIdle: Plasmoid.configuration.hideWhenIdle
    property bool wheelVolume: Plasmoid.configuration.wheelVolume
    property bool middleClickPause: Plasmoid.configuration.middleClickPause

    property string visualizerStyle: Plasmoid.configuration.visualizerStyle
    property int visualizerBars: Plasmoid.configuration.visualizerBars
    property int visualizerSpeed: Plasmoid.configuration.visualizerSpeed
    property string visualizerColorSource: Plasmoid.configuration.visualizerColor
    property bool visualizerWhenPaused: Plasmoid.configuration.visualizerWhenPaused

    readonly property bool hasTrack: backend !== null && backend !== undefined && backend.active
    readonly property bool playing: hasTrack && backend.playing
    readonly property bool collapsed: !hasTrack && hideWhenIdle
    readonly property bool animating: playing || (visualizerWhenPaused && hasTrack)

    readonly property real padding: Math.round(Kirigami.Units.smallSpacing / 2)
    readonly property real available: (vertical ? width : height) - padding * 2
    readonly property real fontFactor: Math.max(0.5, Math.min(1.5, fontScale / 100))

    /* One anchor size — the title — and everything else is a share of it, so
       the text scale moves the whole strip instead of one line of it. */
    readonly property int stackedTitleSize: Math.round(Math.max(8, Math.min(available * 0.46,
                                                                            available * 0.40 * fontFactor)))
    readonly property int inlineTitleSize: Math.round(Math.max(9, Math.min(available * 0.74,
                                                                           available * 0.52 * fontFactor)))
    readonly property bool twoLines: showArtistLine && artistText.length > 0
                                     && available >= stackedTitleSize * 1.2 + Math.round(stackedTitleSize * 0.82) * 1.35
    readonly property int titleSize: twoLines ? stackedTitleSize : inlineTitleSize
    readonly property int artistSize: Math.round(Math.max(7, titleSize * 0.82))

    readonly property real artSize: Math.round(available)
    readonly property real visualizerHeight: Math.round(available * 0.66)
    readonly property real visualizerWidth: visualizerStyle === "pulse"
                                            ? visualizerHeight
                                            : Math.round(Math.max(12, visualizerBars * available * 0.17))
    readonly property real buttonSize: Math.round(Math.max(10, available * 0.58))
    readonly property real textLimit: Math.round(Kirigami.Units.gridUnit * Math.max(4, textWidthUnits))

    readonly property string titleText: backend && backend.track.length > 0
                                        ? backend.track
                                        : (backend && backend.artist.length > 0 ? backend.artist : "")
    readonly property string artistText: backend ? backend.artist : ""

    /* Album colours need a rendered image: a cover that arrives over http —
       browsers hand those out — never loads from a plain URL. So a stand-in
       cover is drawn behind the strip at a hint of opacity, purely to be
       sampled. Qt caches the image, so it costs nothing beyond the pixels. */
    readonly property bool needsSampler: visualizerColorSource === "album"
    readonly property color albumColor: sampler.highlightColor

    readonly property color visualizerColor: {
        switch (visualizerColorSource) {
        case "accent": return Kirigami.Theme.highlightColor
        case "theme": return Kirigami.Theme.textColor
        default: return Util.lively(albumColor, Kirigami.Theme.highlightColor)
        }
    }

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    visible: !collapsed

    onClicked: function (mouse) {
        if (mouse.button === Qt.MiddleButton) {
            if (middleClickPause && backend)
                backend.playPause()
            return
        }
        compact.toggleRequested()
    }

    onWheel: function (wheel) {
        if (!wheelVolume || !backend) {
            wheel.accepted = false
            return
        }
        var steps = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
        backend.nudgeVolume(steps > 0 ? 0.04 : -0.04)
    }

    implicitWidth: collapsed ? 0 : content.implicitWidth
    implicitHeight: collapsed ? 0 : content.implicitHeight

    Layout.minimumWidth: vertical ? Kirigami.Units.gridUnit : implicitWidth
    Layout.maximumWidth: vertical ? Number.POSITIVE_INFINITY : implicitWidth
    Layout.preferredWidth: vertical ? Kirigami.Units.gridUnit * 3 : implicitWidth
    Layout.minimumHeight: vertical ? implicitHeight : Kirigami.Units.gridUnit
    Layout.maximumHeight: vertical ? implicitHeight : Number.POSITIVE_INFINITY
    Layout.preferredHeight: vertical ? implicitHeight : Kirigami.Units.gridUnit * 2

    /* The invisible colour source described above. */
    AlbumArt {
        id: sampler
        width: 12
        height: 12
        z: -1
        opacity: compact.needsSampler ? 0.01 : 0
        visible: compact.needsSampler
        source: compact.backend ? compact.backend.artUrl : ""
    }

    readonly property var layoutKeys: {
        var keys = []
        if (!hasTrack) {
            /* Silence still deserves a shape: the resting equalizer, or a
               single quiet icon when it is switched off. */
            keys.push(showVisualizer ? "visualizer" : "idle")
            return keys
        }
        var wanted = String(panelOrder).split(",")
        for (var i = 0; i < wanted.length; i++) {
            var key = wanted[i].trim()
            if (key === "art" && showArt)
                keys.push("art")
            else if (key === "visualizer" && showVisualizer)
                keys.push("visualizer")
            else if (key === "text" && showText && titleText.length > 0)
                keys.push("text")
            else if (key === "controls" && showControls)
                keys.push("controls")
        }
        if (keys.length === 0)
            keys.push("idle")
        return keys
    }

    ColumnLayout {
        id: content

        anchors.centerIn: parent
        spacing: 0

        GridLayout {
            id: strip

            Layout.alignment: Qt.AlignCenter
            rows: compact.vertical ? compact.layoutKeys.length : 1
            columns: compact.vertical ? 1 : compact.layoutKeys.length
            rowSpacing: Math.round(Kirigami.Units.smallSpacing / 2)
            columnSpacing: Kirigami.Units.smallSpacing

            Repeater {
                model: compact.layoutKeys

                Loader {
                    id: slot

                    required property string modelData

                    Layout.alignment: Qt.AlignCenter
                    sourceComponent: {
                        switch (modelData) {
                        case "art": return compact.artItem
                        case "visualizer": return compact.visualizerItem
                        case "text": return compact.textItem
                        case "controls": return compact.controlsItem
                        }
                        return compact.idleItem
                    }
                }
            }
        }

        /* Progress under the whole strip: a hairline, so it reads as part of
           the panel rather than as a widget of its own. */
        Item {
            Layout.fillWidth: true
            Layout.topMargin: Math.round(Kirigami.Units.smallSpacing / 2)
            implicitHeight: visible ? Math.max(2, Math.round(compact.available * 0.06)) : 0
            visible: compact.progressLine && compact.hasTrack && compact.backend.length > 0

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Kirigami.Theme.textColor
                opacity: 0.18
            }

            Rectangle {
                width: Math.round(parent.width * (compact.backend ? compact.backend.progress : 0))
                height: parent.height
                radius: height / 2
                color: compact.visualizerColor
                opacity: 0.9
            }
        }
    }

    property Component artItem: Component {
        AlbumArt {
            id: panelArt
            source: compact.backend ? compact.backend.artUrl : ""
            implicitWidth: compact.artSize
            implicitHeight: compact.artSize
            cornerRadius: Math.max(2, Kirigami.Units.cornerRadius * 0.7)
        }
    }

    property Component visualizerItem: Component {
        Visualizer {
            style: compact.visualizerStyle
            bars: compact.visualizerBars
            speed: compact.visualizerSpeed
            color: compact.visualizerColor
            active: compact.animating
            seed: Util.seedOf(compact.titleText + compact.artistText)
            opacity: compact.hasTrack ? 1 : 0.45
            implicitWidth: compact.visualizerWidth
            implicitHeight: compact.visualizerHeight
        }
    }

    property Component textItem: Component {
        ColumnLayout {
            spacing: 0

            MarqueeText {
                text: compact.titleText
                pixelSize: compact.titleSize
                weight: Font.DemiBold
                scrolling: compact.scrollText
                Layout.preferredWidth: Math.min(compact.textLimit, implicitWidth)
                Layout.preferredHeight: Math.round(compact.titleSize * 1.25)
            }

            MarqueeText {
                text: compact.artistText
                pixelSize: compact.artistSize
                textColor: Kirigami.Theme.textColor
                opacity: 0.62
                scrolling: compact.scrollText
                visible: compact.twoLines
                Layout.preferredWidth: visible ? Math.min(compact.textLimit, implicitWidth) : 0
                Layout.preferredHeight: visible ? Math.round(compact.artistSize * 1.25) : 0
            }
        }
    }

    property Component controlsItem: Component {
        RowLayout {
            spacing: 0

            PanelButton {
                source: "media-skip-backward"
                size: compact.buttonSize
                enabled: compact.backend && compact.backend.canGoPrevious
                onClicked: compact.backend.previous()
            }

            PanelButton {
                source: compact.playing ? "media-playback-pause" : "media-playback-start"
                size: compact.buttonSize
                enabled: compact.backend && compact.backend.canControl
                onClicked: compact.backend.playPause()
            }

            PanelButton {
                source: "media-skip-forward"
                size: compact.buttonSize
                enabled: compact.backend && compact.backend.canGoNext
                onClicked: compact.backend.next()
            }
        }
    }

    property Component idleItem: Component {
        Kirigami.Icon {
            source: "media-playback-start"
            opacity: 0.4
            implicitWidth: Math.round(compact.available * 0.7)
            implicitHeight: implicitWidth
        }
    }
}
