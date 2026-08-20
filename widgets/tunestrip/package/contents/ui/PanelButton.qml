/*
 * A flat icon button sized for the panel: no frame until the pointer is on it.
 */
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: button

    property string source: ""
    property real size: Kirigami.Units.iconSizes.small
    property string tooltip: ""

    signal clicked()

    implicitWidth: Math.round(size * 1.25)
    implicitHeight: Math.round(size * 1.25)
    opacity: enabled ? 1 : 0.35

    Rectangle {
        anchors.fill: parent
        radius: Kirigami.Units.cornerRadius
        color: Kirigami.Theme.textColor
        opacity: mouse.containsMouse && button.enabled ? (mouse.pressed ? 0.22 : 0.12) : 0
        Behavior on opacity { NumberAnimation { duration: 90 } }
    }

    Kirigami.Icon {
        anchors.centerIn: parent
        width: Math.round(button.size)
        height: width
        source: button.source
        selected: false
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: button.enabled
        acceptedButtons: Qt.LeftButton
        onClicked: button.clicked()
    }
}
