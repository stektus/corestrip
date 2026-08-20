/* Rounded panel with a quiet caption row, the popup's building block. */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: card

    property string title
    property string headline
    property color accentColor: Kirigami.Theme.highlightColor
    property real contentSpacing: Kirigami.Units.smallSpacing * 2
    default property alias content: contentColumn.data

    color: Qt.rgba(Kirigami.Theme.textColor.r,
                   Kirigami.Theme.textColor.g,
                   Kirigami.Theme.textColor.b,
                   0.055)
    radius: Kirigami.Units.cornerRadius * 1.5
    border.width: 1
    border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                          Kirigami.Theme.textColor.g,
                          Kirigami.Theme.textColor.b,
                          0.07)

    implicitHeight: layout.implicitHeight + Kirigami.Units.largeSpacing * 2
    Layout.fillWidth: true

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: card.contentSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            visible: card.title.length > 0

            Rectangle {
                implicitWidth: Kirigami.Units.smallSpacing
                implicitHeight: Kirigami.Units.smallSpacing
                radius: implicitWidth / 2
                color: card.accentColor
                Layout.alignment: Qt.AlignVCenter
            }

            Kirigami.Heading {
                text: card.title
                level: 6
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 0.7
                font.weight: Font.DemiBold
                opacity: 0.65
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: card.headline
                visible: card.headline.length > 0
                color: Kirigami.Theme.textColor
                opacity: 0.55
                font: Kirigami.Theme.smallFont
            }
        }

        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            spacing: card.contentSpacing
        }
    }
}
