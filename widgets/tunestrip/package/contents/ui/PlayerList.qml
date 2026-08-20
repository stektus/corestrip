/*
 * Which player the widget follows. The first row is the automatic choice that
 * MPRIS itself maintains — whatever made a sound last; the rest are the
 * players currently running.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../code/util.js" as Util

ColumnLayout {
    id: list

    property var backend
    readonly property int count: rows.count

    spacing: Math.round(Kirigami.Units.smallSpacing / 2)

    Repeater {
        id: rows
        model: list.backend ? list.backend.sources : null

        delegate: Rectangle {
            id: row

            required property int index
            required property var model

            readonly property bool current: list.backend
                                            && list.backend.sources.currentIndex === index

            Layout.fillWidth: true
            implicitHeight: rowLayout.implicitHeight + Kirigami.Units.smallSpacing * 2
            radius: Kirigami.Units.cornerRadius
            color: Kirigami.Theme.textColor
            opacity: row.current ? 0.12 : (rowMouse.containsMouse ? 0.07 : 0)

            Behavior on opacity { NumberAnimation { duration: 90 } }

            RowLayout {
                id: rowLayout
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                    source: row.model.isMultiplexer
                            ? "media-playback-start"
                            : (row.model.iconName || "audio-x-generic")
                    opacity: row.current ? 1 : 0.75
                }

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true

                    Text {
                        text: row.model.isMultiplexer ? "Whatever is playing" : row.model.identity
                        color: Kirigami.Theme.textColor
                        font.weight: row.current ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: Util.oneLine(row.model.track, row.model.artist)
                        visible: text.length > 0
                        color: Kirigami.Theme.textColor
                        opacity: 0.5
                        font: Kirigami.Theme.smallFont
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: list.backend.selectPlayer(row.index)
            }
        }
    }
}
