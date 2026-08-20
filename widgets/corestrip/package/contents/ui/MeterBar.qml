/* Horizontal meter.  Either a single `value` or a list of stacked
   `segments` ([{ value: 0..1, color: c }]) as memory uses. */
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: meter

    property real value: 0
    property color barColor: Kirigami.Theme.highlightColor
    property var segments: []
    property color trackColor: Qt.rgba(Kirigami.Theme.textColor.r,
                                       Kirigami.Theme.textColor.g,
                                       Kirigami.Theme.textColor.b,
                                       0.12)

    implicitHeight: Math.round(Kirigami.Units.gridUnit * 0.34)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: meter.trackColor
    }

    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            visible: !meter.segments || meter.segments.length === 0
            height: parent.height
            radius: height / 2
            width: Math.max(meter.value > 0 ? height : 0,
                            parent.width * Math.max(0, Math.min(1, meter.value)))
            color: meter.barColor

            Behavior on width {
                NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
            }
        }

        Row {
            visible: meter.segments && meter.segments.length > 0
            height: parent.height

            Repeater {
                model: meter.segments

                Rectangle {
                    height: parent.height
                    width: meter.width * Math.max(0, Math.min(1, modelData.value))
                    color: modelData.color

                    Behavior on width {
                        NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}
