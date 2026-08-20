/*
 * What hovering shows: the cover, the track and who is playing it.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../code/util.js" as Util

RowLayout {
    id: tip

    property var backend

    spacing: Kirigami.Units.largeSpacing

    AlbumArt {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
        source: tip.backend ? tip.backend.artUrl : ""
        cornerRadius: Kirigami.Units.cornerRadius
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 0

        Text {
            text: tip.backend && tip.backend.track.length > 0
                  ? tip.backend.track : "Nothing is playing"
            color: Kirigami.Theme.textColor
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            text: tip.backend ? tip.backend.artist : ""
            visible: text.length > 0
            color: Kirigami.Theme.textColor
            opacity: 0.75
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            text: tip.backend ? tip.backend.album : ""
            visible: text.length > 0
            color: Kirigami.Theme.textColor
            opacity: 0.5
            font: Kirigami.Theme.smallFont
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing
            visible: tip.backend && tip.backend.hasPlayer

            Kirigami.Icon {
                implicitWidth: Kirigami.Units.iconSizes.small
                implicitHeight: Kirigami.Units.iconSizes.small
                source: tip.backend ? tip.backend.playerIcon : ""
                opacity: 0.7
            }

            Text {
                text: {
                    if (!tip.backend)
                        return ""
                    var where = tip.backend.identity
                    if (tip.backend.length > 0)
                        return where + " · " + Util.duration(tip.backend.position)
                               + " / " + Util.duration(tip.backend.length)
                    return where
                }
                color: Kirigami.Theme.textColor
                opacity: 0.6
                font: Kirigami.Theme.smallFont
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}
