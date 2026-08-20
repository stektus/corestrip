/*
 * Album cover with rounded corners, and something reasonable to look at when
 * the player offers no artwork (browsers often do not).
 */
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: art

    property string source: ""
    property real cornerRadius: Kirigami.Units.cornerRadius
    property bool shadowed: false
    property string placeholderIcon: "media-optical-audio"

    readonly property bool hasArt: source.length > 0 && cover.status === Image.Ready

    /* Colours sampled off the cover, for whoever wants to tint by album.
       A cover on disk is read straight from the file; a cover from a browser
       arrives over http, which ImageColors will not fetch, so that one is
       sampled from the drawn item instead. */
    readonly property bool localSource: source.length > 0
                                        && (source.indexOf("file:") === 0 || source.charAt(0) === "/")
    readonly property color dominantColor: colors.dominant
    readonly property color highlightColor: colors.highlight

    Kirigami.ImageColors {
        id: colors
        source: art.localSource ? art.source : cover
    }

    onSourceChanged: colors.update()

    /* Placeholder behind the cover: a quiet tile with a note on it, in the
       widget's own style rather than a broken-image box. */
    Kirigami.ShadowedRectangle {
        anchors.fill: parent
        visible: !art.hasArt
        radius: art.cornerRadius
        color: Qt.rgba(Kirigami.Theme.textColor.r,
                       Kirigami.Theme.textColor.g,
                       Kirigami.Theme.textColor.b,
                       0.09)
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                              Kirigami.Theme.textColor.g,
                              Kirigami.Theme.textColor.b,
                              0.08)

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.round(Math.min(parent.width, parent.height) * 0.5)
            height: width
            source: art.placeholderIcon
            opacity: 0.45
        }
    }

    Kirigami.ShadowedImage {
        id: cover

        anchors.fill: parent
        source: art.source
        radius: art.cornerRadius
        /* Never hidden, even with nothing loaded: sampling the colours grabs
           this item, and grabbing an item that is not being drawn comes back
           blank — and leaves it drawing blank afterwards. A transparent
           underlay makes an empty cover harmless instead. */
        color: "transparent"
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        shadow.size: art.shadowed ? Kirigami.Units.gridUnit : 0
        shadow.yOffset: art.shadowed ? Math.round(Kirigami.Units.smallSpacing / 2) : 0
        shadow.color: Qt.rgba(0, 0, 0, 0.35)

        onStatusChanged: if (status === Image.Ready) colors.update()
    }
}
